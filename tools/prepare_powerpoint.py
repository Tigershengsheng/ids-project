"""Recover the existing PDF layout and R figure vectors for a PowerPoint copy.

This reads source evidence; it performs no modelling or statistical calculations.
"""
from pathlib import Path
from html.parser import HTMLParser
import argparse, base64, html, json, math, re, statistics, sys
try:
    import pymupdf
except ImportError:
    # An existing local PDF-tool environment; no package installation is hidden here.
    import PIL
    sys.path.append(r'D:\data science\tmp\spanish_deps')
    import pymupdf

ROOT = Path(__file__).resolve().parents[1]
FIGURES = {2:'recorded-outcomes',3:'entry-profiles',5:'validation-threshold',7:'group-fairness',
           12:'fairness-gaps',13:'bootstrap-fnr-gap',14:'probability-calibration',18:'course-composition'}

def colour(value,opacity=1):
    if value is None: return 'none'
    if isinstance(value,(float,int)): value=(value,)*3
    rgb='#'+''.join(f'{max(0,min(255,round(v*255))):02x}' for v in value[:3])
    return rgb if opacity is None or opacity>=.999 else f'{rgb}/{opacity*100:.3f}'

def inside(rect,other):
    return rect.x0>=other.x0-.3 and rect.y0>=other.y0-.3 and rect.x1<=other.x1+.3 and rect.y1<=other.y1+.3

def clip_line(a,b,rect):
    dx=b.x-a.x; dy=b.y-a.y; lo=0.; hi=1.
    for p,q in [(-dx,a.x-rect.x0),(dx,rect.x1-a.x),(-dy,a.y-rect.y0),(dy,rect.y1-a.y)]:
        if abs(p)<1e-12:
            if q<0:return None
        else:
            t=q/p
            if p<0:lo=max(lo,t)
            else:hi=min(hi,t)
            if lo>hi:return None
    return pymupdf.Point(a.x+lo*dx,a.y+lo*dy),pymupdf.Point(a.x+hi*dx,a.y+hi*dy)

def extract_page(page, box, table_mode=False, clip_images=False):
    """Map real PDF paths and text to editable slide objects in a specified frame."""
    x,y,w,h=box; sx=w/page.rect.width; sy=h/page.rect.height
    def point(p): return dict(x=x+p.x*sx,y=y+p.y*sy)
    elements=[]; table_rects=[]
    if table_mode:
        for table in page.find_tables().tables:
            rect=pymupdf.Rect(table.bbox); table_rects.append(rect)
            widths=[pymupdf.Rect(c).width*sx for c in table.rows[0].cells]
            heights=[max(pymupdf.Rect(c).height for c in row.cells if c)*sy for row in table.rows]
            elements.append(dict(type='table',x=x+rect.x0*sx,y=y+rect.y0*sy,w=rect.width*sx,h=rect.height*sy,
                                 widths=widths,heights=heights,values=table.extract()))
    active_clips={}
    for path in page.get_drawings(extended=True):
        level=path.get('level',0)
        active_clips={k:v for k,v in active_clips.items() if k<level}
        if path['type']=='clip':
            active_clips[level]=pymupdf.Rect(path['scissor']); continue
        if path['type']=='group':continue
        clip=page.rect
        for value in active_clips.values():clip=clip&value
        if not path['rect'].intersects(clip) and path['rect'].width>0 and path['rect'].height>0:continue
        if any(inside(path['rect'],tr) for tr in table_rects): continue
        if not path['items']: continue
        commands=[]; last=None
        def move(p):
            nonlocal last
            v=point(p)
            if last is None or abs(v['x']-last['x'])+abs(v['y']-last['y'])>.01:
                commands.append(dict(moveTo=v))
            last=v
        def line(p):
            nonlocal last
            last=point(p); commands.append(dict(lineTo=last))
        for item in path['items']:
            if item[0]=='l':
                segment=clip_line(item[1],item[2],clip)
                if segment: move(segment[0]); line(segment[1])
            elif item[0]=='c':
                move(item[1]); a,b,c=map(point,item[2:5]); commands.append(dict(cubicBezTo=dict(x1=a['x'],y1=a['y'],x2=b['x'],y2=b['y'],x=c['x'],y=c['y']))); last=c
            elif item[0]=='re':
                rect=item[1]; points=[rect.tl,rect.tr,rect.br,rect.bl]
                move(points[0])
                for p in points[1:]: line(p)
                commands.append(dict(close={})); last=None
            elif item[0]=='qu':
                q=item[1]; move(q.ul)
                for p in [q.ur,q.lr,q.ll]: line(p)
                commands.append(dict(close={})); last=None
        if path.get('closePath') and commands: commands.append(dict(close={}))
        if not commands: continue
        dash=path.get('dashes') or ''
        style='solid'
        nums=re.findall(r'[0-9.]+',dash.split(']')[0])
        if nums: style='dotted' if len(nums)>0 and float(nums[0])<1.5 else ('dash-dot' if len(nums)>=4 else 'dashed')
        elements.append(dict(type='path',commands=commands,fill=colour(path.get('fill'),path.get('fill_opacity',1)),
                             stroke=colour(path.get('color'),path.get('stroke_opacity',1)),width=(path.get('width') or 0)*sx,
                             style=style,seq=path['seqno']))
    fontmap={}
    for font in page.get_fonts():
        try:
            buffer=page.parent.extract_font(font[0])[3]
            if buffer: fontmap[font[3].split('+')[-1]]=pymupdf.Font(fontbuffer=buffer)
        except Exception: pass
    seen=set()
    for span in page.get_texttrace():
        if span.get('type')==3: continue
        rect=pymupdf.Rect(span['bbox'])
        if any(inside(rect,tr) for tr in table_rects): continue
        chars=span['chars']; text=''.join(chr(c[0]) for c in chars)
        if not text.strip(): continue
        identity=(text,tuple(round(v,3) for v in span['bbox']),span['font'])
        if identity in seen:continue
        seen.add(identity)
        fontname=span['font']; rotation=math.degrees(math.atan2(-span['dir'][1],span['dir'][0]))
        size=span['size']*sx
        family='Segoe UI' if 'Segoe' in fontname else 'Arial'
        bold=bool('Bold' in fontname or 'Semibold' in fontname or span['flags']&16)
        if 'Semibold' in fontname:family='Segoe UI Semibold'; bold=False
        spacing=0
        font=fontmap.get(fontname)
        if font and abs(rotation)<.1 and len(chars)>2:
            diffs=[]
            for current,nxt in zip(chars,chars[1:]):
                if current[0] in (32,9): continue
                nominal=font.glyph_advance(current[0])*span['size']
                if nominal>0: diffs.append(nxt[2][0]-current[2][0]-nominal)
            if diffs: spacing=statistics.median(diffs)*sx
        if abs(rotation)<.1:
            left=x+chars[0][2][0]*sx; top=y+(chars[0][2][1]-span['size']*.94)*sy
            width=rect.width*sx+max(5,size*.4); height=size*1.55
        else:
            # The unrotated textbox is centred on the original vertical span.
            width=rect.height*sy+5; height=size*1.55
            cx=x+(rect.x0+rect.x1)*sx/2; cy=y+(rect.y0+rect.y1)*sy/2
            left=cx-width/2; top=cy-height/2; rotation=270 if rotation>0 else 90
        elements.append(dict(type='text',text=text,x=left,y=top,w=width,h=height,size=size,
                             family=family,bold=bold,italic=bool(span['flags']&2),colour=colour(span['color']),
                             spacing=spacing,rotation=rotation,seq=span['seqno']))
    return elements

class NotesParser(HTMLParser):
    def __init__(self): super().__init__(); self.sections={}; self.current=None; self.heading=False; self.headingtext=''; self.parts=[]; self.skip=0
    def handle_starttag(self,tag,attrs):
        if tag in ('script','style'): self.skip+=1
        if tag=='h2':
            if self.current: self.sections[self.current]=''.join(self.parts).strip()
            self.heading=True; self.headingtext=''; self.parts=[]; self.current=None
        if tag in ('p','div','li','br','tr','h3'): self.parts.append('\n')
        if tag=='a':
            href=dict(attrs).get('href','')
            if href.startswith('http'): self.parts.append(' ['+href+'] ')
    def handle_endtag(self,tag):
        if tag in ('script','style'): self.skip=max(0,self.skip-1)
        if tag=='h2':
            self.heading=False; match=re.match(r'Slide (\d+):',self.headingtext.strip())
            if match: self.current=int(match.group(1))
        if tag in ('p','li','div'): self.parts.append('\n')
    def handle_data(self,data):
        if self.skip: return
        if self.heading: self.headingtext+=data
        else: self.parts.append(data)
    def finish(self):
        if self.current:self.sections[self.current]=''.join(self.parts).strip()

def main():
    parser=argparse.ArgumentParser(); parser.add_argument('--build-dir',required=True); args=parser.parse_args()
    build=Path(args.build_dir); build.mkdir(parents=True,exist_ok=True)
    doc=pymupdf.open(ROOT/'output/pdf/Student_Dropout_Presentation.pdf')
    notes=NotesParser(); notes.feed((ROOT/'speaker-notes.html').read_text(encoding='utf-8-sig')); notes.finish()
    source=html.unescape(re.search(r'<textarea[^>]*id="source"[^>]*>(.*?)</textarea>',(ROOT/'presentation.html').read_text(encoding='utf-8-sig'),re.S).group(1))
    remark=re.split(r'\n---\s*\n',source)
    slides=[]
    for n,page in enumerate(doc,1):
        elements=extract_page(page,(0,0,1280,720),table_mode=True)
        # Preserve the existing cover/closing artwork as original source assets.
        # Data figures are recovered from their R PDF as editable paths and text.
        figure=FIGURES.get(n)
        if figure:
            blocks=[b for b in page.get_text('dict')['blocks'] if b['type']==1]
            assert len(blocks)==1,(n,len(blocks))
            bbox=pymupdf.Rect(blocks[0]['bbox']); sx=1280/page.rect.width; sy=720/page.rect.height
            graphic=pymupdf.open(ROOT/f'figures/{figure}.pdf')
            elements+=extract_page(graphic[0],(bbox.x0*sx,bbox.y0*sy,bbox.width*sx,bbox.height*sy))
        elif n in (1,8):
            # The source's backdrop is an existing raster/gradient design asset.
            # Extract only the original backdrop, never the foreground content.
            # Original PDF image blocks contain its backdrop; use the first large block.
            blocks=[b for b in page.get_text('dict')['blocks'] if b['type']==1]
            bgblocks=[b for b in blocks if pymupdf.Rect(b['bbox']).width>page.rect.width*.9]
            if bgblocks:
                block=bgblocks[0]
                elements.insert(0,dict(type='image',data=base64.b64encode(block['image']).decode(),x=0,y=0,w=1280,h=720))
            # PDF soft-mask fills are not standalone artwork. Retain the original
            # backdrop and circle outlines; the gradient word stays editable text.
            elements=[e for e in elements if not (e['type']=='path' and e['fill']!='none')]
        text=page.get_text()
        rendered_notes=notes.sections.get(n,'')
        fallback=remark[n-1].split('???',1)[1].strip() if n<=len(remark) and '???' in remark[n-1] else ''
        uris=sorted({link.get('uri') for link in page.get_links() if link.get('uri')})
        citations='\n\nSources: UCI dataset 697, https://doi.org/10.24432/C5MC89 ; Realinho et al. (2022), https://doi.org/10.3390/data7110146 .'
        notes_text=rendered_notes or fallback or text+citations
        if uris:notes_text+='\n\nLinks on this slide:\n'+'\n'.join(uris)
        links=[]
        for link in page.get_links():
            if link.get('uri'):
                b=link['from']; links.append(dict(uri=link['uri'],x=b.x0*1280/page.rect.width,y=b.y0*720/page.rect.height,w=b.width*1280/page.rect.width,h=b.height*720/page.rect.height))
        slides.append(dict(number=n,elements=elements,notes=notes_text,links=links,title=text.splitlines()[0]))
    output=dict(width=1280,height=720,slides=slides,source_pdf=str(ROOT/'output/pdf/Student_Dropout_Presentation.pdf'))
    (build/'source-layout.json').write_text(json.dumps(output,ensure_ascii=False),encoding='utf-8')
    print(json.dumps(dict(slides=len(slides),text_boxes=sum(e['type']=='text' for s in slides for e in s['elements']),editable_paths=sum(e['type']=='path' for s in slides for e in s['elements']),native_tables=sum(e['type']=='table' for s in slides for e in s['elements']),main_notes=len(notes.sections))))

if __name__=='__main__': main()
