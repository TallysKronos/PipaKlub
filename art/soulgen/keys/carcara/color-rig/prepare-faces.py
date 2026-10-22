"""Register AI-painted facial regions onto one invariant original body.
Only crop/resample/composite; no procedural eye drawing or silhouette changes.
"""
from PIL import Image, ImageDraw, ImageFilter
from pathlib import Path
import json,hashlib
root=Path(__file__).resolve().parent
original=Image.open(root/'body-reference.png').convert('RGBA')
sheet=Image.open(root/'expressions-generated.png').convert('RGBA')
mask=Image.new('L',original.size)
# Fixed registered facial windows. Feather stays inside these windows.
windows=[(14,143,62,200),(90,155,145,219)]
for x0,y0,x1,y1 in windows:
    box=Image.new('L',(x1-x0,y1-y0));d=ImageDraw.Draw(box)
    d.rounded_rectangle((4,4,box.width-5,box.height-5),radius=6,fill=255)
    box=box.filter(ImageFilter.GaussianBlur(1.5));mask.paste(box,(x0,y0))
mask.save(root/'face-registration-mask.png')
report={}
for name,(x0,y0,x1,y1) in {
    'fierce':(683,12,1158,612),'hurt':(101,652,578,1251),
    'happy':(683,652,1158,1251),
}.items():
    target=sheet.crop((x0,y0,x1,y1)).resize(original.size,Image.Resampling.LANCZOS)
    result=Image.composite(target,original,mask)
    # Alpha, silhouette, beak and external anatomy always come from the original.
    result.putalpha(original.getchannel('A'))
    result.save(root/f'body-{name}.png')
    changed=0
    for a,b,m in zip(original.getdata(),result.getdata(),mask.getdata()):
        assert a[3]==b[3]
        if not m:assert a==b,'Pixel changed outside facial registration'
        changed+=a!=b
    report[name]={'size':result.size,'changed_pixels':changed,'alpha_identical':True,
        'outside_face_identical':True,'sha256':hashlib.sha256((root/f'body-{name}.png').read_bytes()).hexdigest()}
(root/'face-validation.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
preview=Image.new('RGBA',(280*4,361),(36,56,69,255))
for i,name in enumerate(['normal','fierce','hurt','happy']):
    p=original if name=='normal' else Image.open(root/f'body-{name}.png')
    preview.alpha_composite(p,(280*i,0))
preview.save(root/'faces-comparison.png')
print('Facial variants registered; alpha and every pixel outside facial windows identical.')
