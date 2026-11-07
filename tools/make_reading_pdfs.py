"""Create readable PDFs from the current, R-rendered script and Chinese guide.

No fitting, resampling or new statistical calculations are performed here.
"""
from pathlib import Path
import hashlib, html as std_html, json, re, shutil, sys
from xml.sax.saxutils import escape
from lxml import html
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT, TA_RIGHT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (SimpleDocTemplate,Paragraph,Spacer,PageBreak,
    KeepTogether,Table,TableStyle,Preformatted,HRFlowable)

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'output/reading-pdfs'
BUILD=ROOT.parent/'tmp/student-dropout-pdf-build'
OUT.mkdir(parents=True,exist_ok=True); BUILD.mkdir(parents=True,exist_ok=True)
for name,file in [('Segoe','segoeui.ttf'),('SegoeBold','segoeuib.ttf'),('SegoeItalic','segoeuii.ttf')]:
    pdfmetrics.registerFont(TTFont(name,str(Path('C:/Windows/Fonts')/file)))
try:
    pdfmetrics.registerFont(TTFont('Chinese','C:/Windows/Fonts/msyh.ttc',subfontIndex=0))
    pdfmetrics.registerFont(TTFont('ChineseBold','C:/Windows/Fonts/msyhbd.ttc',subfontIndex=0))
except Exception:
    pdfmetrics.registerFont(TTFont('Chinese','C:/Windows/Fonts/simhei.ttf'))
    pdfmetrics.registerFont(TTFont('ChineseBold','C:/Windows/Fonts/simhei.ttf'))
pdfmetrics.registerFontFamily('Segoe',normal='Segoe',bold='SegoeBold',italic='SegoeItalic',boldItalic='SegoeBold')
pdfmetrics.registerFontFamily('Chinese',normal='Chinese',bold='ChineseBold',italic='Chinese',boldItalic='ChineseBold')
NAVY=colors.HexColor('#20364D'); TEAL=colors.HexColor('#087F74'); GREY=colors.HexColor('#607184')
WIDTH=A4[0]-96
STYLES={}
for lang,font in [('en','Segoe'),('zh','Chinese')]:
    wrap='CJK' if lang=='zh' else None
    STYLES[lang]={
        'title':ParagraphStyle('title-'+lang,fontName=font,fontSize=23,leading=31,textColor=NAVY,spaceAfter=12,wordWrap=wrap),
        'h1':ParagraphStyle('h1-'+lang,fontName='SegoeBold' if lang=='en' else 'ChineseBold',fontSize=16,leading=23,textColor=NAVY,spaceBefore=15,spaceAfter=9,keepWithNext=True,wordWrap=wrap),
        'h2':ParagraphStyle('h2-'+lang,fontName='SegoeBold' if lang=='en' else 'ChineseBold',fontSize=12.2,leading=18,textColor=TEAL,spaceBefore=12,spaceAfter=7,keepWithNext=True,wordWrap=wrap),
        'body':ParagraphStyle('body-'+lang,fontName=font,fontSize=11.3 if lang=='en' else 10.5,leading=17.5,spaceAfter=8,textColor=NAVY,wordWrap=wrap),
        'spoken':ParagraphStyle('spoken-'+lang,fontName=font,fontSize=13.2,leading=20.8,spaceAfter=13,textColor=NAVY,wordWrap=wrap),
        'small':ParagraphStyle('small-'+lang,fontName=font,fontSize=9.1,leading=14,textColor=GREY,spaceAfter=7,wordWrap=wrap),
        'cell':ParagraphStyle('cell-'+lang,fontName=font,fontSize=8.7,leading=13.1,textColor=NAVY,wordWrap='CJK'),
        'headcell':ParagraphStyle('headcell-'+lang,fontName='SegoeBold' if lang=='en' else 'ChineseBold',fontSize=8.7,leading=13.1,textColor=colors.white,wordWrap='CJK'),
        'code':ParagraphStyle('code-'+lang,fontName='Chinese',fontSize=8.3,leading=12.7,textColor=NAVY,spaceAfter=9,backColor=colors.HexColor('#F3F5F8'),borderPadding=7),
    }

def normal(text):
    # knitr under the Windows C locale can emit literal <U+XXXX> display escapes.
    text=re.sub(r'<U\+([0-9A-Fa-f]{4,6})>',lambda m:chr(int(m.group(1),16)),text)
    return text.replace('\u2011','-').replace('\u2013','-').replace('\u2014','-').replace('\xa0',' ')

def plain(node):return re.sub(r'\s+',' ',normal(node.text_content())).strip()

def rich(node):
    result=escape(normal(node.text or ''))
    for child in node:
        if child.tag=='br':inside='<br/>'
        else:
            inside=rich(child)
            if child.tag in ('b','strong'):inside='<b>'+inside+'</b>'
            elif child.tag in ('i','em'):inside='<i>'+inside+'</i>'
            elif child.tag=='a' and child.get('href','').startswith('http'):
                inside='<link href="'+escape(child.get('href'),{'"':'&quot;'})+'" color="#087F74">'+inside+'</link>'
            elif child.tag=='sup':inside='<super>'+inside+'</super>'
        result+=inside+escape(normal(child.tail or ''))
    return result

def para(text,lang='en',style='body'):return Paragraph(escape(normal(text)),STYLES[lang][style])

class ReadingDoc(SimpleDocTemplate):
    def afterFlowable(self,flowable):
        if isinstance(flowable,Paragraph) and flowable.style.name.startswith(('h1-','h2-')):
            text=flowable.getPlainText(); key='section-'+str(self.seq.nextf('bookmark'))
            self.canv.bookmarkPage(key)
            self.canv.addOutlineEntry(text,key,level=0 if flowable.style.name.startswith('h1-') else 1,closed=False)

def footer(label,font):
    def draw(canvas,doc):
        canvas.saveState(); canvas.setStrokeColor(colors.HexColor('#DEE5EB')); canvas.line(48,37,A4[0]-48,37)
        canvas.setFont(font,8.2); canvas.setFillColor(GREY); canvas.drawString(48,23,label)
        canvas.drawRightString(A4[0]-48,23,str(doc.page)); canvas.restoreState()
    return draw

def build(name,story,lang,label):
    path=OUT/name
    doc=ReadingDoc(str(path),pagesize=A4,leftMargin=48,rightMargin=48,topMargin=43,bottomMargin=51,
                   title=label,author='Strong Tiger',allowSplitting=True)
    doc.build(story,onFirstPage=footer(label,'Segoe' if lang=='en' else 'Chinese'),onLaterPages=footer(label,'Segoe' if lang=='en' else 'Chinese'))
    return path

def container(path):
    page=html.fromstring(path.read_text(encoding='utf-8-sig'))
    roots=page.xpath('//*[contains(concat(" ",normalize-space(@class)," ")," main-container ")]')
    return roots[0] if roots else page

notes=container(ROOT/'speaker-notes.html')
sections={}
for sec in notes.xpath('.//div[contains(concat(" ",normalize-space(@class)," ")," level2 ")]'):
    headings=sec.xpath('./h2')
    if headings:
        m=re.match(r'Slide (\d+):',plain(headings[0]))
        if m:sections[int(m.group(1))]=sec
spoken=notes.xpath('.//div[contains(concat(" ",normalize-space(@class)," ")," spoken ")]')
assert len(spoken)==8 and len(sections)==8
script={int(s.get('data-slide')):plain(s) for s in spoken}
count=lambda text:len(re.findall(r"[A-Za-z0-9]+(?:['-][A-Za-z0-9]+)*",text))
words=sum(count(t) for t in script.values())
assert 550 <= words <= 700,('Main talk needs a timing review',words)

english=[]
for speaker in range(1,5):
    if speaker>1:english.append(PageBreak())
    if speaker==1:
        english+=[para('Student dropout warnings','en','title'),para('English presentation script','en','h1'),
          para(f'Main talk: slides 1-8 | {words} words in the spoken blocks | 4 suggested speakers','en','small'),
          para(f'The spoken blocks take about {words/100:.1f} minutes at 100 words per minute, before pauses. Their main transitions are included. Rehearse aloud; the appendices are preparation material, not extra speech.','en','small')]
    english.append(para(f'Speaker {speaker} | Slides {2*speaker-1}-{2*speaker}','en','h1'))
    for number in [2*speaker-1,2*speaker]:
        header=plain(sections[number].xpath('./h2')[0])
        english.append(para(header,'en','h2')); english.append(para(script[number],'en','spoken'))
        # The timed paragraphs now include the main links. Do not add the
        # alternative handover sentences again to the main reading script.
        english.append(Spacer(1,15))
english+=[PageBreak(),para('Preparation notes','en','h1'),
          para('Use these explanations selectively when discussing the figures or answering questions. They are not additions to the timed talk.','en','small')]
for number in [2,3,5,7]:
    ps=[p for p in sections[number].xpath('./p') if plain(p).startswith('Our figure-review explanation')]
    if ps:
        english.append(para(f'Slide {number}: why we presented the figure this way','en','h2'))
        text=plain(ps[0]).split(':',1)[-1].strip(); english.append(para(text,'en'))
english+=[PageBreak(),para('Our reasons for key choices','en','h1'),
          para('Preparation material: use the reasoning relevant to a question; do not add every paragraph to the timed talk.','en','small')]
for number in [2,4,5,6,7]:
    decision=sections[number].xpath('.//div[contains(concat(" ",normalize-space(@class)," ")," decision-note-en ")]')
    assert len(decision)==1,number
    english.append(para(f'Slide {number}: our reasoning','en','h2'))
    english.append(para(plain(decision[0]).removeprefix('Our reasoning: '),'en'))
english+=[PageBreak(),para('Questions to practise','en','h1')]

def add_table(table,story,lang):
    rows=[[plain(c) for c in r.xpath('./th|./td')] for r in table.xpath('.//tr')]
    rows=[r for r in rows if r]
    if not rows:return
    n=max(map(len,rows)); rows=[r+['']*(n-len(r)) for r in rows]
    chunks=[list(range(n))] if n<=6 else [[0]+list(range(start,min(start+5,n))) for start in range(1,n,5)]
    for index,columns in enumerate(chunks):
        lead=[para(f'Table continuation {index+1}/{len(chunks)}; the first column is repeated.',lang,'small')] if len(chunks)>1 else []
        body=[[Paragraph(escape(row[c]),STYLES[lang]['headcell' if r==0 else 'cell']) for c in columns] for r,row in enumerate(rows)]
        col_widths=[WIDTH/len(columns)]*len(columns)
        if len(columns)>=4:
            col_widths=[WIDTH*.26]+[WIDTH*.74/(len(columns)-1)]*(len(columns)-1)
        tab=Table(body,colWidths=col_widths,repeatRows=1,hAlign='LEFT')
        tab.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),NAVY),('VALIGN',(0,0),(-1,-1),'TOP'),
          ('LEFTPADDING',(0,0),(-1,-1),7),('RIGHTPADDING',(0,0),(-1,-1),7),
          ('TOPPADDING',(0,0),(-1,-1),7),('BOTTOMPADDING',(0,0),(-1,-1),7),
          ('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.white,colors.HexColor('#F2F6F8')]),
          ('LINEBELOW',(0,0),(-1,-1),.4,colors.HexColor('#D8E0E8'))]))
        story.append(KeepTogether(lead+[tab,Spacer(1,10)]))

def convert(node,story,lang):
    tag=node.tag
    if not isinstance(tag,str) or tag in ('script','style') or node.get('id') in ('header','TOC'):return
    if tag in ('h1','h2','h3','h4'):
        story.append(para(plain(node),lang,'h1' if tag in ('h1','h2') else 'h2'))
    elif tag=='p':
        if plain(node):story.append(Paragraph(rich(node),STYLES[lang]['body']))
    elif tag in ('ul','ol'):
        for i,li in enumerate(node.xpath('./li'),1):
            prefix=(str(i)+'. ') if tag=='ol' else '• '
            story.append(Paragraph(escape(prefix)+rich(li),STYLES[lang]['body']))
    elif tag=='table':add_table(node,story,lang)
    elif tag=='pre':
        text=normal(node.text_content()); lines=[]
        for line in text.splitlines():
            current=''
            for char in line:
                if pdfmetrics.stringWidth(current+char,'Chinese',8.3)>WIDTH-20:
                    lines.append(current); current='    '+char
                else:current+=char
            lines.append(current)
        story.append(Preformatted('\n'.join(lines),STYLES[lang]['code']))
    else:
        for child in node:convert(child,story,lang)

qa=[sec for sec in notes.xpath('.//div[contains(concat(" ",normalize-space(@class)," ")," level2 ")]')
    if sec.xpath('./h2') and plain(sec.xpath('./h2')[0])=='Questions to practise']
assert len(qa)==1
for child in qa[0]:
    if child.tag!='h2':convert(child,english,'en')
english.extend([Spacer(1,10),para('Figure-design references','en','h2'),
 para('Data to Viz: The Boxplot and its pitfalls - https://www.data-to-viz.com/caveat/boxplot.html','en','small'),
 para('Data to Viz: The issue with error bars - https://www.data-to-viz.com/caveat/error_bar.html','en','small')])
english_path=build('02_Speaker_Notes.pdf',english,'en','Student dropout warnings | English script')

presentation=OUT/'01_Presentation.pdf'
shutil.copy2(ROOT/'output/pdf/Student_Dropout_Presentation.pdf',presentation)

timing_path=ROOT/'results/script-timing.json'
timing=json.loads(timing_path.read_text())
timing['method']='Current spoken blocks, including embedded transitions; optional alternative handovers and pauses excluded; no human rehearsal performed'
timing['total_words']=words
for row in timing['slides']:
    row['words']=count(script[row['slide']]); row['seconds_at_100wpm']=row['words']*.6; row['seconds_at_120wpm']=row['words']*.5
timing_path.write_text(json.dumps(timing,indent=2),encoding='utf-8')
source=ROOT/'results/pdf-reading-source.json'
source.write_text(json.dumps(dict(english_spoken_blocks=script,spoken_words=words,
   quiz_summary_created=False,website_reasoning_in_spoken_slide=3,
   files=[str(p) for p in [presentation,english_path]]),ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(dict(created=[str(p) for p in [presentation,english_path]],spoken_words=words),ensure_ascii=False))
