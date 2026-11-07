"""Typeset the beginner handbook; read frozen R results without refitting."""
from pathlib import Path
from xml.sax.saxutils import escape
import hashlib
import json
import re
import sys
import csv
from lxml import html as lhtml

from PIL import Image as PILImage, ImageDraw
from pypdf import PdfReader
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (SimpleDocTemplate, Paragraph, Spacer,
    PageBreak, Table, TableStyle, Image, Preformatted, Flowable, KeepTogether)

sys.path.append(r'D:\data science\tmp\spanish_deps')
import pymupdf

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT.parent / 'tmp/pdfs/student-dropout-handbook'
BUILD.mkdir(parents=True, exist_ok=True)
SOURCE = ROOT / 'docs/zero-to-project.zh-CN.md'
PDF = BUILD / '03_中文解释与复习.pdf'

for name, file in [('Zh', 'msyh.ttc'), ('ZhBold', 'msyhbd.ttc')]:
    pdfmetrics.registerFont(TTFont(name, 'C:/Windows/Fonts/' + file,
                                 subfontIndex=0))
pdfmetrics.registerFont(TTFont('Mono', 'C:/Windows/Fonts/consola.ttf'))
pdfmetrics.registerFontFamily('Zh', normal='Zh', bold='ZhBold',
                             italic='Zh', boldItalic='ZhBold')
NAVY = colors.HexColor('#20364D')
TEAL = colors.HexColor('#087F74')
GREY = colors.HexColor('#607184')
PALE = colors.HexColor('#F1F6F8')
W = A4[0] - 96

styles = {
    'title': ParagraphStyle('title', fontName='ZhBold', fontSize=20,
        leading=28, textColor=NAVY, spaceAfter=15, wordWrap='CJK', keepWithNext=True),
    'sub': ParagraphStyle('sub', fontName='ZhBold', fontSize=13,
        leading=21, textColor=TEAL, spaceBefore=9, spaceAfter=7,
        wordWrap='CJK', keepWithNext=True),
    'body': ParagraphStyle('body', fontName='Zh', fontSize=12,
        leading=20.3, textColor=NAVY, spaceAfter=9, wordWrap='CJK'),
    'small': ParagraphStyle('small', fontName='Zh', fontSize=8.7,
        leading=13.5, textColor=GREY, spaceAfter=7, wordWrap='CJK'),
    'cell': ParagraphStyle('cell', fontName='Zh', fontSize=10.2,
        leading=16.5, textColor=NAVY, wordWrap='CJK'),
    'head': ParagraphStyle('head', fontName='ZhBold', fontSize=10.2,
        leading=16.5, textColor=colors.white, wordWrap='CJK'),
    'code': ParagraphStyle('code', fontName='Mono', fontSize=9.5,
        leading=15, textColor=NAVY, backColor=PALE, borderPadding=9,
        spaceBefore=5, spaceAfter=12),
}

def normal(text):
    return (text.replace('\u2011', '-').replace('\u2013', '-')
            .replace('\u2014', '-').replace('\xa0', ' '))

def inline(text):
    # Code and bold are typographic aids; the handbook has no hidden executable text.
    text = escape(normal(text))
    text = re.sub(r'``(.*?)``', lambda m: '<font color="#087F74">' + m[1] + '</font>', text)
    text = re.sub(r'`([^`]+)`', lambda m: '<font color="#087F74">' + m[1] + '</font>', text)
    return re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', text)

def p(text, style='body'):
    return Paragraph(inline(text), styles[style])

class SectionMark(Flowable):
    def __init__(self, slug, title, expected):
        super().__init__()
        self.slug, self.title, self.expected = slug, title, expected
        self.width = self.height = 0
    def draw(self):
        self.canv.bookmarkPage(self.slug)
        self.canv.addOutlineEntry(self.title, self.slug, 0, False)
        self.canv._handbook_current_title = self.title

class HandbookDoc(SimpleDocTemplate):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.section_pages = []
    def afterFlowable(self, flowable):
        if isinstance(flowable, SectionMark):
            self.section_pages.append({'section': flowable.slug,
                'expected_page': flowable.expected, 'page': self.page,
                'title': flowable.title})

def decorate(canvas, doc):
    canvas.saveState()
    canvas.setFont('Zh', 8.2)
    canvas.setFillColor(GREY)
    canvas.drawString(48, A4[1] - 25, 'IDS Final Project | 从零读懂')
    canvas.drawRightString(A4[0] - 48, A4[1] - 25, '2026.11.06')
    canvas.setStrokeColor(colors.HexColor('#DCE5EB'))
    canvas.line(48, 37, A4[0] - 48, 37)
    canvas.drawString(48, 23, '大学生退学预警 | 学习材料，不是额外演讲内容')
    canvas.drawRightString(A4[0] - 48, 23, f'{doc.page} / {len(sections)}')
    canvas.restoreState()

def table(lines):
    rows = [[c.strip() for c in line.strip().strip('|').split('|')]
            for line in lines]
    rows = [r for r in rows if not all(re.fullmatch(r':?-{3,}:?', c) for c in r)]
    n = len(rows[0])
    assert all(len(r) == n for r in rows), rows
    # Pick widths from actual contents rather than force every column equally wide.
    if n == 2:
        widths = [W * .37, W * .63]
    elif n == 3:
        widths = [W * .42, W * .29, W * .29]
    elif n == 4:
        widths = [W * .26, W * .23, W * .23, W * .28]
    else:
        widths = [W * .28] + [W * .72 / (n - 1)] * (n - 1)
    body = [[p(c, 'head' if i == 0 else 'cell') for c in row]
            for i, row in enumerate(rows)]
    tab = Table(body, colWidths=widths, repeatRows=1, hAlign='LEFT')
    tab.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), NAVY),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, PALE]),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('RIGHTPADDING', (0, 0), (-1, -1), 6),
        ('TOPPADDING', (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ('LINEBELOW', (0, 0), (-1, -1), .35, colors.HexColor('#D5DFE6')),
    ]))
    return KeepTogether([tab, Spacer(1, 10)])

raw = normal(SOURCE.read_text(encoding='utf-8'))
current_notes=lhtml.fromstring((ROOT/'speaker-notes.html').read_text(encoding='utf-8-sig'))
spoken=current_notes.xpath('.//div[contains(concat(" ",normalize-space(@class)," ")," spoken ")]')
assert len(spoken)==8
current_words=sum(len(re.findall(r"[A-Za-z0-9]+(?:['-][A-Za-z0-9]+)*",s.text_content())) for s in spoken)
raw=raw.replace('{{SPOKEN_WORDS}}',str(current_words))
sections = re.findall(r'<!-- PAGE: ([\w-]+) -->\s*([\s\S]*?)(?=<!-- PAGE:|\Z)', raw)
assert len(sections) == 41, len(sections)
story = []
for number, (slug, text) in enumerate(sections, 1):
    if number > 1:
        story.append(PageBreak())
    lines = text.strip().splitlines()
    title = next(line[2:] for line in lines if line.startswith('# '))
    story.append(SectionMark(slug, title, number))
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if not line:
            i += 1
            continue
        if line.startswith('```'):
            i += 1
            code = []
            while i < len(lines) and not lines[i].strip().startswith('```'):
                code.append(lines[i]); i += 1
            assert all(pdfmetrics.stringWidth(t, 'Mono', 9.5) < W - 20 for t in code), code
            story.append(Preformatted('\n'.join(code), styles['code']))
            i += 1
        elif line.startswith('# '):
            story.append(p(line[2:], 'title')); i += 1
        elif line.startswith('## '):
            story.append(p(line[3:], 'sub')); i += 1
        elif line.startswith('|'):
            rows = []
            while i < len(lines) and lines[i].strip().startswith('|'):
                rows.append(lines[i]); i += 1
            story.append(table(rows))
        elif line.startswith('!['):
            match = re.fullmatch(r'!\[(.*?)\]\((.*?)\)', line)
            assert match, line
            path = ROOT / match[2]
            with PILImage.open(path) as img:
                image_w, image_h = img.size
            h = W * image_h / image_w
            story.append(Image(str(path), width=W, height=h))
            story.append(p(match[1] + '。原图来自当前R分析输出。', 'small'))
            i += 1
        else:
            para = [line]
            i += 1
            while i < len(lines) and lines[i].strip() and not re.match(r'^(#|\||!\[|```|\d+\.)', lines[i].strip()):
                para.append(lines[i].strip()); i += 1
            story.append(p(' '.join(para)))

doc = HandbookDoc(str(PDF), pagesize=A4, leftMargin=48, rightMargin=48,
    topMargin=49, bottomMargin=52,
    title='大学生退学预警：从零看懂项目与答辩', author='Strong Tiger',
    subject='中文逐步讲解、真实项目数据、代码解释与自测', allowSplitting=True)
doc.build(story, onFirstPage=decorate, onLaterPages=decorate)
reader = PdfReader(PDF)
text_pages = [page.extract_text() or '' for page in reader.pages]
assert len(reader.pages) == 41, {'pages': len(reader.pages), 'section_pages': doc.section_pages}
assert all(item['page'] == item['expected_page'] for item in doc.section_pages), doc.section_pages
assert all(len(t) > 170 for t in text_pages), [len(t) for t in text_pages]
assert all(not any(s in t for s in ['\ufffd', '\u25a0', '<U+']) for t in text_pages)

# Cross-check teaching numbers against the frozen R-produced CSV/JSON output.
r = json.loads((ROOT / 'results/analysis-summary.json').read_text(encoding='utf-8'))
m = r['metrics'][2]
f, male = r['group_metrics']
assert (m['n'], m['TP'], m['FP'], m['FN'], m['TN']) == (889, 187, 222, 98, 382)
assert (f['n'], f['TP'], f['FP'], f['FN'], f['TN']) == (575, 80, 138, 64, 293)
assert (male['n'], male['TP'], male['FP'], male['FN'], male['TN']) == (314, 107, 84, 34, 89)
assert r['threshold'] == .31 and r['bootstrap_reps'] == 5000
assert tuple(r['configuration'][k] for k in ['training_n', 'validation_n', 'test_n']) == (2652, 883, 889)
assert round(r['threshold_row'][0]['Sensitivity'] * 284) == 200
assert all(s in raw for s in ['64/144=44.4%', '34/141=24.1%',
    '80/218=36.7%', '107/191=56.0%', '64/357=17.9%', '34/123=27.6%'])
assert round(f['FNR'] * 100, 1) == 44.4
assert round(male['FNR'] * 100, 1) == 24.1
assert round(m['Sensitivity'] * 100, 1) == 65.6
assert round(m['PPV'] * 100, 1) == 45.7
fn_gap = next(x for x in r['gaps'] if x['metric'] == 'FNR')
assert round(-fn_gap['estimate'] * 100, 1) == 20.3
assert (round(-fn_gap['upper'] * 100, 1), round(-fn_gap['lower'] * 100, 1)) == (9.5, 30.7)
assert (m['TP'] - r['metrics'][1]['TP'], m['FP'] - r['metrics'][1]['FP']) == (107, 177)
assert round(m['WarningRate'] * 100, 1) == 46.0
assert round(r['metrics'][0]['Accuracy'] * 100, 1) == 67.9
assert round(r['metrics'][1]['Accuracy'] * 100, 1) == 71.9
assert round(m['AUC'], 3) == .718 and round(m['Brier'], 3) == .188
for group, expected in [(f, [37.9, 32.0, 44.4, 36.7, 17.9]),
                        (male, [60.8, 48.6, 24.1, 56.0, 27.6])]:
    assert [round(group[k] * 100, 1) for k in ['WarningRate', 'FPR', 'FNR', 'PPV', 'FOR']] == expected
gender_extra = list(csv.DictReader((ROOT / 'results/fairness-gender-inclusive.csv').open(encoding='utf-8')))
assert [round(float(g['FNR']) * 100, 1) for g in gender_extra] == [56.9, 9.2]
assert [round(float(g['FPR']) * 100, 1) for g in gender_extra] == [19.5, 71.7]
assert [round(v['AUC'], 3) for v in r['sensitivity']] == [.756, .758]
assert [v['n'] for v in r['sensitivity']] == [729, 729]
assert round(r['sensitivity'][1]['Sensitivity'] * 100, 1) == 81.8

preserved = json.loads((ROOT / 'results/visual-preservation.json').read_text(encoding='utf-8'))
for item in preserved['files']:
    assert hashlib.sha256((ROOT / item['path']).read_bytes()).hexdigest() == item['after_sha256'], item['path']

pdf_doc = pymupdf.open(PDF)
outside = []
for n, page in enumerate(pdf_doc, 1):
    for block in page.get_text('blocks'):
        if block[0] < 40 or block[2] > page.rect.width - 40 or block[1] < 10 or block[3] > page.rect.height - 15:
            outside.append({'page': n, 'rect': list(block[:4]), 'text': block[4][:80]})
    page.get_pixmap(matrix=pymupdf.Matrix(1.45, 1.45), alpha=False).save(BUILD / f'page-{n:02}.png')
assert not outside, outside
for start in range(0, len(reader.pages), 8):
    overview = PILImage.new('RGB', (1440, 1060), '#E6EAF0')
    draw = ImageDraw.Draw(overview)
    for j, n in enumerate(range(start + 1, min(start + 9, len(reader.pages) + 1))):
        with PILImage.open(BUILD / f'page-{n:02}.png') as image:
            image.thumbnail((345, 490))
            x, y = 10 + (j % 4) * 360, 26 + (j // 4) * 520
            overview.paste(image, (x, y))
        draw.text((x, y - 18), f'PAGE {n}', fill='#20364D')
    overview.save(BUILD / f'overview-{start // 8 + 1}.png')

evidence_files = ['R/analysis.R', 'results/analysis-summary.json',
    'results/test-metrics.csv', 'results/fairness-group-metrics.csv',
    'results/fairness-gaps.csv', 'results/fairness-gender-inclusive.csv',
    'results/enrolled-definition-sensitivity.csv', 'results/calibration-bins.csv',
    'results/training-summary.csv', 'docs/source-notes.md', 'docs/course-map.md']
report = {
    'pages': len(reader.pages), 'section_pages': doc.section_pages,
    'bytes': PDF.stat().st_size,
    'pdf_sha256': hashlib.sha256(PDF.read_bytes()).hexdigest(),
    'source_sha256': hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
    'out_of_bounds': outside,
    'preserved_numerical_files': len(preserved['files']),
    'text_characters': list(map(len, text_pages)),
    'evidence': {s: hashlib.sha256((ROOT / s).read_bytes()).hexdigest() for s in evidence_files},
    'new_analysis_or_refitting': False,
    'checks': ['41 complete sections and correct page starts',
        'Confusion counts and test metrics agree with R results',
        'All five group rates and their denominators agree with R results',
        'Bootstrap gap sign and endpoints agree with R results',
        'Gender and Enrolled sensitivity-check values agree with R results',
        'No missing-glyph markers or unresolved text escapes',
        'No text blocks beyond safe page margins',
        'All 31 protected numerical files are unchanged'],
    'visual_review': 'Pending human visual inspection of generated page images',
}
(ROOT / 'results/handbook-validation.json').write_text(
    json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps({'pdf': str(PDF), 'pages': len(reader.pages),
    'bytes': PDF.stat().st_size, 'preserved_numerical_files': len(preserved['files'])}, ensure_ascii=False))
