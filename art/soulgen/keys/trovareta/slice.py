"""Mechanical source crops; no generated pixel redraw or background replacement."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageChops
import json

root = Path(__file__).resolve().parent / 'cutout-rig-v1'
source = Image.open(root / 'source.png').convert('RGBA')
boxes = {'body': [229,79,258,294], 'head': [676,119,273,244],
         'wingNear': [1067,12,422,403], 'wingFar': [91,388,437,351],
         'legNear': [686,409,221,330], 'legFar': [1166,405,306,329],
         'tailNear': [13,744,605,229], 'tailFar': [585,748,501,247]}
polygons = {'tailNear': [(0,740),(618,740),(618,850),(400,900),(300,1010),(0,1010)],
            'tailFar': [(650,748),(1125,748),(1125,1024),(585,1024),(585,850),(650,850)]}
report = {'sourceSize': list(source.size), 'method': 'Source RGBA crops with semantic masks excluding neighboring tail fragments.', 'parts': {}}
for name, box in boxes.items():
    image = source.copy()
    if name in polygons:
        mask = Image.new('L', source.size)
        ImageDraw.Draw(mask).polygon(polygons[name], fill=255)
        image.putalpha(ImageChops.multiply(source.getchannel('A'), mask))
    x,y,w,h = box
    image.crop((x,y,x+w,y+h)).save(root / (name+'.png'))
    report['parts'][name] = {'crop': box}
    if name in polygons:
        report['parts'][name]['semantic_polygon'] = polygons[name]
(root / 'slices.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf8')
