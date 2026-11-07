"""Publish the current PDF reading set and editable PowerPoint locally."""
from pathlib import Path
import hashlib
import json
import shutil

root = Path(__file__).resolve().parents[1]
delivery = root.parent / 'output/student-dropout-delivery'
delivery.mkdir(parents=True, exist_ok=True)

def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

record = root / 'results/visual-preservation.json'
if record.exists():
    for item in json.loads(record.read_text(encoding='utf-8'))['files']:
        assert sha(root / item['path']) == item['after_sha256'], item['path']

copies = {
    'output/reading-pdfs/01_Presentation.pdf': '01_Presentation.pdf',
    'output/reading-pdfs/02_英文演讲稿.pdf': '02_英文演讲稿.pdf',
    'output/reading-pdfs/03_中文解释与复习.pdf': '03_中文解释与复习.pdf',
    'output/powerpoint/Student_Dropout_Presentation.pptx':
        'Student_Dropout_Presentation.pptx',
}
for source, name in copies.items():
    source = root / source
    shutil.copy2(source, delivery / name)
    assert sha(source) == sha(delivery / name), name

manifest = {
    name: {'bytes': (delivery / name).stat().st_size,
           'sha256': sha(delivery / name)}
    for name in copies.values()
}
(delivery / 'delivery-manifest.json').write_text(
    json.dumps(manifest, indent=2, ensure_ascii=False), encoding='utf-8')
print(json.dumps({'delivery': str(delivery), 'files': len(manifest)},
                 ensure_ascii=False))
