"""Check the two English professor-facing PDFs and preserve numerical files."""
from pathlib import Path
import hashlib,json,re,sys
from PIL import Image,ImageDraw
from pypdf import PdfReader
sys.path.append(r'D:\data science\tmp\spanish_deps')
import pymupdf
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'output/reading-pdfs'
BUILD=ROOT.parent/'tmp/student-dropout-pdf-build'
BUILD.mkdir(parents=True,exist_ok=True)
HAN=re.compile('[\u3400-\u4dbf\u4e00-\u9fff]')
reports=[]
names=['01_Presentation.pdf','02_Speaker_Notes.pdf']
for i,name in enumerate(names,1):
    path=OUT/name
    reader=PdfReader(path)
    doc=pymupdf.open(path)
    texts=[p.extract_text() or '' for p in reader.pages]
    assert not any(HAN.search(t) for t in texts),name
    assert not any('\ufffd' in t or '\u25a0' in t or '<U+' in t for t in texts),name
    if i==1:
        assert len(texts)==18
    else:
        text=' '.join('\n'.join(texts).split())
        assert all(f'Slide {n}:' in text for n in range(1,9))
        assert all(value in text for value in ['187','222','Our reasons for key choices'])
    image_paths=[]
    out_of_bounds=[]
    for n,page in enumerate(doc,1):
        scale=1100/page.rect.width
        png=BUILD/f'pdf{i}-page-{n:02}.png'
        page.get_pixmap(matrix=pymupdf.Matrix(scale,scale),alpha=False).save(png)
        image_paths.append(png)
        if i==2:
            for block in page.get_text('blocks'):
                if block[0]<30 or block[2]>page.rect.width-30 or block[1]<15 or block[3]>page.rect.height-15:
                    out_of_bounds.append({'page':n,'rect':list(block[:4]),'text':block[4][:80]})
    for start in range(0,len(image_paths),6):
        canvas=Image.new('RGB',(1290,1000 if i==1 else 1600),'#E6EAF0')
        draw=ImageDraw.Draw(canvas)
        for j,png in enumerate(image_paths[start:start+6]):
            thumb=Image.open(png).convert('RGB')
            thumb.thumbnail((610,315 if i==1 else 500))
            x=20+(j%2)*640;y=25+(j//2)*(330 if i==1 else 530)
            canvas.paste(thumb,(x,y))
            draw.text((x,y-16),f'FILE {i} / PAGE {start+j+1}',fill='#20364D')
        canvas.save(BUILD/f'pdf{i}-overview-{start//6+1}.png')
    assert not out_of_bounds,out_of_bounds
    reports.append({'file':name,'pages':len(reader.pages),'bytes':path.stat().st_size,
                    'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
                    'han_characters':0,'out_of_bounds':out_of_bounds})
protected=json.loads((ROOT/'results/visual-preservation.json').read_text(encoding='utf-8'))['files']
for item in protected:
    assert hashlib.sha256((ROOT/item['path']).read_bytes()).hexdigest()==item['after_sha256']
(ROOT/'results/pdf-reading-validation.json').write_text(json.dumps({
    'files':reports,'professor_facing_language':'English','preserved_numerical_files':len(protected),
    'spoken_words':json.loads((ROOT/'results/script-timing.json').read_text(encoding='utf-8'))['total_words']},
    ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(reports,ensure_ascii=False))
