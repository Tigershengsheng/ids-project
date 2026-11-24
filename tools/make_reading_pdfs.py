"""Print the spoken script and the separate Chinese rehearsal guide as A4 PDFs.

First knit speaker-notes.Rmd. The spoken text, translated cues and timing targets
come from the two human-readable source documents. No model is fitted here.
"""

from pathlib import Path
import json
import re
from xml.sax.saxutils import escape

from lxml import html
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import KeepTogether, PageBreak, Paragraph, SimpleDocTemplate, Spacer


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "output" / "reading-pdfs"
FONTS = Path("C:/Windows/Fonts")
INK = colors.HexColor("#202A29")
TEAL = colors.HexColor("#005D55")
MUTED = colors.HexColor("#465758")
RULE = colors.HexColor("#C8CFCB")

for name, filename in [("Script", "segoeui.ttf"), ("ScriptBold", "segoeuib.ttf"),
                       ("Chinese", "msyh.ttc"), ("ChineseBold", "msyhbd.ttc")]:
    pdfmetrics.registerFont(TTFont(name, str(FONTS / filename), subfontIndex=0))


def para(text, role, *, chinese=False):
    fonts = ("Chinese", "ChineseBold") if chinese else ("Script", "ScriptBold")
    # Size, leading and inter-paragraph space are set for printing at 100%.
    styles = {
        "title": (fonts[1], 22, 28, INK, 8),
        "heading": (fonts[1], 13, 20, TEAL, 5),
        "speech": (fonts[0], 12.5, 19, INK, 7),
        "body": (fonts[0], 11.2, 19.5, INK, 8),
        "cue": (fonts[0], 10.3, 15.5, MUTED, 8),
    }
    font, size, leading, colour, after = styles[role]
    style = ParagraphStyle(role, fontName=font, fontSize=size, leading=leading,
                           textColor=colour, spaceAfter=after,
                           wordWrap="CJK" if chinese else None,
                           keepWithNext=role in ("heading", "title"))
    return Paragraph(escape(text), style)


def save(name, story, label, chinese=False):
    font = "Chinese" if chinese else "Script"

    def footer(canvas, doc):
        canvas.setStrokeColor(RULE)
        canvas.line(43, 40, A4[0] - 43, 40)
        canvas.setFont(font, 8.5)
        canvas.setFillColor(MUTED)
        canvas.drawString(43, 25, label)
        canvas.drawRightString(A4[0] - 43, 25, str(doc.page))

    OUTPUT.mkdir(exist_ok=True, parents=True)
    path = OUTPUT / name
    document = SimpleDocTemplate(str(path), pagesize=A4, leftMargin=44,
                                 rightMargin=44, topMargin=45, bottomMargin=51,
                                 title=label, author="Strong Tiger")
    document.build(story, onFirstPage=footer, onLaterPages=footer)
    return path


def plain(node):
    return " ".join(node.text_content().split())


def english_notes():
    document = html.fromstring((ROOT / "speaker-notes.html").read_text(encoding="utf-8-sig"))
    spoken = document.xpath('//div[@data-slide and @data-speaker]')
    if [int(node.get("data-slide")) for node in spoken] != list(range(1, 11)):
        raise ValueError("Knit speaker-notes.Rmd first. Expected slides 1–10.")
    story = []
    timing = []
    previous_speaker = None
    for node in spoken:
        slide = int(node.get("data-slide"))
        speaker = node.get("data-speaker")
        section = node.getparent()
        name = plain(section.find("h2"))
        cue = plain(section.xpath('./div[contains(concat(" ", @class, " "), " cue ")]')[0])
        seconds = int(re.match(r"(\d+) seconds", cue).group(1))
        if speaker != previous_speaker:
            if previous_speaker:
                story.append(PageBreak())
            story += [para(speaker, "title")]
            if slide == 1:
                story += [para("English rehearsal script · Ten spoken slides, then sources for questions. "
                               "Target 6:48, including handovers, pointing and pauses.", "cue")]
            previous_speaker = speaker
        text = plain(node)
        story.append(KeepTogether([para(name, "heading"), para(text, "speech"), para(cue, "cue")]))
        story.append(Spacer(1, 9))
        words = len(re.findall(r"\b[\w]+(?:['’.,-][\w]+)*\b", text))
        timing.append({"slide": slide, "speaker": speaker, "words": words, "target_seconds": seconds})
    path = save("02_Speaker_Notes.pdf", story, "IDS Final Project · English rehearsal script")
    timing_summary = {
        "method": "Written-word count; times are planning targets including pointing, pauses and handovers. Human rehearsal pending.",
        "slides": timing, "total_words": sum(row["words"] for row in timing),
        "target_seconds": sum(row["target_seconds"] for row in timing),
    }
    (ROOT / "results/script-timing.json").write_text(json.dumps(timing_summary, indent=2), encoding="utf-8")
    return path


def chinese_notes():
    guide = (ROOT / "private-study/排练与理解.md").read_text(encoding="utf-8-sig")
    story = []
    paragraphs = []
    for line in (text.strip() for text in guide.splitlines() if text.strip()):
        if line.startswith("# "):
            title = line[2:]
        elif line.startswith("## "):
            if paragraphs:
                story.extend(paragraphs)
                story.append(PageBreak())
            elif not story:
                story.extend([para(title, "title", chinese=True), para(intro, "cue", chinese=True)])
            paragraphs = [para(line[3:], "heading", chinese=True)]
        elif line.startswith("### "):
            paragraphs += [Spacer(1, 6), para(line[4:], "heading", chinese=True)]
        elif not paragraphs:
            intro = line
        else:
            paragraphs.append(para(line, "body", chinese=True))
    story.extend(paragraphs)
    return save("03_中文排练稿.pdf", story, "大学生退学预警 · 四人排练稿", chinese=True)


if __name__ == "__main__":
    print(english_notes())
    if (ROOT / "private-study/排练与理解.md").is_file():
        print(chinese_notes())

