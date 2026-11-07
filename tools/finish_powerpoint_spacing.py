"""Preserve measured source letter spacing in the exported native text boxes."""
from pathlib import Path
import json, sys, zipfile
from lxml import etree as ET
build=Path(sys.argv[1])
rows=json.loads((build/'text-spacing.json').read_text())
lookup={(r['slide'],r['name']):r['spacing'] for r in rows}
ns={'p':'http://schemas.openxmlformats.org/presentationml/2006/main','a':'http://schemas.openxmlformats.org/drawingml/2006/main'}
with zipfile.ZipFile(build/'candidate.pptx') as source, zipfile.ZipFile(build/'candidate-spaced.pptx','w',zipfile.ZIP_DEFLATED) as target:
    for item in source.infolist():
        data=source.read(item.filename)
        if item.filename.startswith('ppt/slides/slide') and item.filename.endswith('.xml'):
            number=int(Path(item.filename).stem.removeprefix('slide'))
            tree=ET.fromstring(data)
            for shape in tree.findall('.//p:sp',ns):
                prop=shape.find('./p:nvSpPr/p:cNvPr',ns)
                if prop is None: continue
                spacing=lookup.get((number,prop.get('name')))
                if spacing is None: continue
                for run in shape.findall('.//a:rPr',ns)+shape.findall('.//a:defRPr',ns):
                    run.set('spc',str(round(spacing*75)))
            data=ET.tostring(tree,xml_declaration=True,encoding='UTF-8',standalone=True)
        target.writestr(item,data)
print('Original letter spacing restored.')
