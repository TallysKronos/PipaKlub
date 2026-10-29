"""Normalize approved generated art and preserve the previous runtime files."""
import json
from pathlib import Path
import shutil
from PIL import Image, ImageOps

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'art/professor-identity-v3'
OUT.mkdir(parents=True,exist_ok=True)
(OUT/'previous').mkdir(exist_ok=True)
sources={
    'portrait-assis.png':Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f/exec-838fe59f-1204-44f6-a493-e16e0375c63d.png'),
    'assis-overworld.png':Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f/exec-5d868d8e-eaa2-4f2f-aee4-5963e690a65e.png'),
}
report={}
for name,source in sources.items():
    runtime=ROOT/'godot/assets/campaign'/name
    backup=OUT/'previous'/name
    if not backup.exists():shutil.copy2(runtime,backup)
    shutil.copy2(source,OUT/('source-'+name))
    image=Image.open(source).convert('RGBA')
    old_size=Image.open(backup).size
    if name=='assis-overworld.png':
        # Technical sprite normalization only; do not repaint or alter alpha.
        bounds=image.getchannel('A').point(lambda a:255 if a>24 else 0).getbbox()
        image=image.crop(bounds)
        fitted=ImageOps.contain(image,(old_size[0]-4,old_size[1]-4),Image.Resampling.LANCZOS)
        result=Image.new('RGBA',old_size)
        result.alpha_composite(fitted,((old_size[0]-fitted.width)//2,old_size[1]-fitted.height-2))
    else:
        fitted=ImageOps.contain(image,old_size,Image.Resampling.LANCZOS)
        result=Image.new('RGBA',old_size)
        result.alpha_composite(fitted,((old_size[0]-fitted.width)//2,old_size[1]-fitted.height))
    result.save(runtime)
    result.save(OUT/name)
    report[name]={'source':str(source),'runtime':str(runtime.relative_to(ROOT)),
                  'size':result.size,'alpha_range':result.getchannel('A').getextrema(),
                  'visible_bounds':result.getchannel('A').point(lambda a:255 if a>24 else 0).getbbox(),
                  'previous':str(backup.relative_to(ROOT))}
(OUT/'normalization.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
