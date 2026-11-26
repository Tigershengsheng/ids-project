"""Recover the existing PDF layout and R figure vectors for a PowerPoint copy.

This reads source evidence; it performs no modelling or statistical calculations.
"""
from pathlib import Path
from html.parser import HTMLParser
import argparse, base64, json, math, re, statistics
import pymupdf

ROOT = Path(__file__).resolve().parents[1]

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
        family = ('Georgia' if 'Georgia' in fontname else
                  'Segoe UI' if 'Segoe' in fontname else
                  'Times New Roman' if 'Times' in fontname else 'Arial')
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
    """Extract each explicitly tagged spoken paragraph and its stage direction."""
    def __init__(self):
        super().__init__()
        self.slide = 0
        self.depth = 0
        self.sections = {}

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == 'div' and 'spoken' in attrs.get('class', '').split():
            self.slide = int(attrs['data-slide'])
            self.sections[self.slide] = [attrs.get('data-speaker', '').strip()]
            self.depth = 1
        elif self.depth and tag == 'div':
            self.depth += 1
        if self.depth and tag in ('p','br'):
            self.sections[self.slide].append('\n')

    def handle_endtag(self, tag):
        if self.depth and tag == 'div':
            self.depth -= 1

    def handle_data(self, data):
        if self.depth:
            self.sections[self.slide].append(data)

def read_notes(build, root, count):
    local = build / 'notes.json'
    if local.exists():
        notes = json.loads(local.read_text(encoding='utf-8-sig'))
    else:
        parser = NotesParser()
        parser.feed((root / 'speaker-notes.html').read_text(encoding='utf-8-sig'))
        notes = [''.join(parser.sections.get(i, [])).strip() for i in range(1, count)]
        notes.append('Sources. Leave this slide visible for questions.')
    if len(notes) == count and not notes[-1]:
        notes[-1] = 'Sources. Leave this slide visible for questions.'
    if len(notes) != count or any(not isinstance(line, str) or not line.strip() for line in notes):
        raise ValueError('Missing slide-specific presenter notes. Rebuild speaker-notes.html first.')
    return notes

def image_object(page, plan):
    """Match each browser image to its printed image bounds."""
    images = [block for block in page.get_text('dict')['blocks'] if block['type'] == 1]
    if len(plan['images']) != len(images):
        raise ValueError(f"Image roster differs on {plan['title']!r}: {len(plan['images'])} vs {len(images)}")
    for source in plan['images']:
        target = (source['x'] * page.rect.width, source['y'] * page.rect.height,
                  (source['x'] + source['w']) * page.rect.width,
                  (source['y'] + source['h']) * page.rect.height)
        block = min(images, key=lambda candidate: sum(abs(a-b) for a,b in zip(candidate['bbox'], target)))
        images.remove(block)
        rect = pymupdf.Rect(block['bbox'])
        info = min(page.get_image_info(xrefs=True), key=lambda obj: sum(abs(a-b) for a,b in zip(obj['bbox'], rect)))
        if not info['xref']:
            raise ValueError(f"Could not identify the image on {plan['title']!r}")
        yield Path(source['asset']), rect, info['xref'], block['image'], source['alt']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build-dir', type=Path, required=True)
    parser.add_argument('--project', type=Path, default=ROOT)
    args = parser.parse_args()
    build, root = args.build_dir, args.project.resolve()
    source = json.loads((build/'slides.json').read_text(encoding='utf-8-sig'))
    slides = []
    with pymupdf.open(build/'browser.pdf') as printed:
        if len(printed) != source['total']:
            raise ValueError('Printed page count differs from the HTML slide count.')
        notes = read_notes(build, root, len(printed))
        for n, (page, plan) in enumerate(zip(printed,source['slides']), 1):
            sx, sy = 1280/page.rect.width, 720/page.rect.height
            elements = extract_page(page, (0,0,1280,720))
            for asset, rect, xref, pixels, alt in image_object(page, plan):
                if asset.is_absolute() or '..' in asset.parts or not asset.stem:
                    raise ValueError(f'Missing or invalid R figure asset on slide {n}')
                if len(asset.parts) == 1:
                    asset = Path('figures')/asset
                box = (rect.x0*sx, rect.y0*sy, rect.width*sx, rect.height*sy)
                if asset.stem == 'talk-cohort' or asset.parts[0] == 'img':
                    # The cover's 4,424 dots form one replaceable illustration.
                    elements.append(dict(type='image',data=base64.b64encode(pixels).decode(),
                                         x=box[0],y=box[1],w=box[2],h=box[3],alt=alt, mime='image/jpeg' if pixels.startswith(b'\xff\xd8') else 'image/png'))
                else:
                    with pymupdf.open(root/asset.with_suffix('.pdf')) as graphic:
                        elements += extract_page(graphic[0], box)
                        page.delete_image(xref)
                        page.show_pdf_page(rect, graphic, 0, keep_proportion=False)
            links=[]
            for link in page.get_links():
                if link.get('uri'):
                    b=link['from']
                    links.append(dict(uri=link['uri'],x=b.x0*sx,y=b.y0*sy,w=b.width*sx,h=b.height*sy))
            slides.append(dict(number=n,elements=elements,notes=notes[n-1],links=links,title=plan['title']))
        printed.set_metadata(dict(title='Student Dropout Warnings: How Accurate Are They, and Who Gets Missed?',
                                  author='Strong Tiger',subject='Introduction to Data Science – Final Project'))
        printed.save(build/'01_Presentation.pdf',garbage=4,deflate=True)
    (build/'source-layout.json').write_text(json.dumps(dict(width=1280,height=720,slides=slides),ensure_ascii=False),encoding='utf-8')
    print(f'{len(slides)} pages prepared; R charts retain their original vectors and text.')

if __name__ == '__main__':
    main()
