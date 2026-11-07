from pathlib import Path
import hashlib,json,re,sys
from PIL import Image,ImageDraw
from pypdf import PdfReader
sys.path.append(r'D:\data science\tmp\spanish_deps')
import pymupdf
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'output/reading-pdfs'; BUILD=ROOT.parent/'tmp/student-dropout-pdf-build'
reports=[]
for i,path in enumerate(sorted(OUT.glob('*.pdf')),1):
    reader=PdfReader(path); doc=pymupdf.open(path)
    texts=[page.extract_text() or '' for page in reader.pages]
    assert texts and all(len(t.strip())>25 for t in texts),(path,len(texts))
    assert not any('\ufffd' in t or '\u25a0' in t for t in texts),path
    assert not any('<U+' in t for t in texts),('Unresolved display encoding',path)
    if i==1:assert len(texts)==18
    elif i==2:
        text=' '.join('\n'.join(texts).split())
        assert all(f'Slide {n}:' in text for n in range(1,9))
        assert 'Quiz 7 pointed us to Data to Viz' in text and '187' in text and '222' in text
    else:
        text='\n'.join(texts)
        assert all(s in text for s in ['从零看懂','Independence','Separation','Sufficiency','64/144','34/141','0.31','Data to Viz'])
    image_paths=[]; out_of_bounds=[]
    for n,page in enumerate(doc,1):
        scale=1100/page.rect.width
        png=BUILD/f'pdf{i}-page-{n:02}.png'
        page.get_pixmap(matrix=pymupdf.Matrix(scale,scale),alpha=False).save(png); image_paths.append(png)
        if i>1:
            for block in page.get_text('blocks'):
                if block[0]<30 or block[2]>page.rect.width-30 or block[1]<15 or block[3]>page.rect.height-15:
                    out_of_bounds.append(dict(page=n,rect=list(block[:4]),text=block[4][:80]))
    for start in range(0,len(image_paths),6):
        # QA overview only: the generated document pages themselves are unchanged.
        canvas=Image.new('RGB',(1290,1000 if i==1 else 1600),'#E6EAF0');draw=ImageDraw.Draw(canvas)
        for j,png in enumerate(image_paths[start:start+6]):
            thumb=Image.open(png).convert('RGB');thumb.thumbnail((610,315 if i==1 else 500))
            x=20+(j%2)*640;y=25+(j//2)*(330 if i==1 else 530)
            canvas.paste(thumb,(x,y));draw.text((x,y-16),f'FILE {i} / PAGE {start+j+1}',fill='#20364D')
        canvas.save(BUILD/f'pdf{i}-overview-{start//6+1}.png')
    reports.append(dict(file=path.name,pages=len(reader.pages),bytes=path.stat().st_size,
        sha256=hashlib.sha256(path.read_bytes()).hexdigest(),text_characters=[len(t) for t in texts],out_of_bounds=out_of_bounds))
assert all(not r['out_of_bounds'] for r in reports),reports
preserved=json.loads((ROOT/'results/visual-preservation.json').read_text())
for item in preserved['files']:
    assert hashlib.sha256((ROOT/item['path']).read_bytes()).hexdigest()==item['after_sha256']
(ROOT/'results/pdf-reading-validation.json').write_text(json.dumps(dict(files=reports,
    preserved_numerical_files=len(preserved['files']),quiz_summary_created=False,
    spoken_words=json.loads((ROOT/'results/script-timing.json').read_text())['total_words']),ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps([dict(file=r['file'],pages=r['pages'],bytes=r['bytes']) for r in reports],ensure_ascii=False))
