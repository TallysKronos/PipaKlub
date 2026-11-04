from pathlib import Path
import json,re,shutil,zipfile
import numpy as np
from PIL import Image,ImageDraw,ImageFont

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'documentation/overworld/lava-v1'

def main():
    paths=sorted((OUT/'frames').glob('lava-*.png'))
    if len(paths)!=96:raise ValueError('Expected 96 native frames')
    frames=[Image.open(p).convert('RGB') for p in paths]
    first=np.asarray(frames[0]).astype(int)
    end=np.asarray(Image.open(OUT/'loop-final.png').convert('RGB')).astype(int)
    diff=abs(first-end)
    duration=[80,80,90]*32
    small=[f.resize((960,540),Image.Resampling.LANCZOS) for f in frames]
    small[0].save(OUT/'RIO-DE-BRASA.webp',save_all=True,append_images=small[1:],duration=duration,loop=0,quality=90)
    palette=small[0].quantize(colors=256)
    gif=[f.quantize(palette=palette,dither=Image.Dither.NONE) for f in small]
    gif[0].save(OUT/'RIO-DE-BRASA.gif',save_all=True,append_images=gif[1:],duration=duration,loop=0,disposal=2)
    details=[f.crop((435,315,845,465)).resize((1025,375),Image.Resampling.NEAREST) for f in frames]
    details[0].save(OUT/'MARGEM-ANIMADA.webp',save_all=True,append_images=details[1:],duration=duration,loop=0,lossless=True)
    details[0].save(OUT/'DETALHE-MARGEM.png')
    geometry=json.loads((OUT/'geometria.json').read_text(encoding='utf-8'))
    mask=Image.open(OUT/'geometria-1280x720.png').convert('RGB')
    upper_mask=np.all(np.asarray(mask)==[83,104,117],axis=2)
    motion=abs(first-np.asarray(frames[24]).astype(int))
    report={'nativeResolution':[1280,720],'animationFrames':96,'loopSeconds':8,
            'loopMaximumChannelDifference':int(diff.max()),'loopMeanChannelDifference':float(diff.mean()),
            'quarterCycleChangedPixels':int(np.any(motion>2,axis=2).sum()),
            'upperGroundMaximumAnimationDifference':int(motion[upper_mask].max()) if upper_mask.any() else None,
            'geometry':geometry,'reducedMotionCapture':True,'campaignIntegrated':False,'gameplayTestsRun':False}
    (OUT/'auditoria.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    for name in ['lava-native.log','lava-import.log']:shutil.copy2(ROOT/'tmp'/name,OUT/name)
    pending=[ROOT/'godot/scenes/overworld/lava/rio-de-brasa.tscn'];included=set()
    while pending:
        path=pending.pop()
        if path in included:continue
        included.add(path)
        if path.suffix in ['.gd','.tscn','.tres','.gdshader','.gdshaderinc']:
            source=path.read_text(encoding='utf-8-sig')
            for relative in re.findall(r'res://([^"\s]+\.(?:gdshaderinc|gdshader|png|tscn|tres|gd))(?=["\s])',source):pending.append(ROOT/'godot'/relative)
    for path in (ROOT/'godot/assets/overworld/kits/lava-v1').rglob('*'):
        if path.is_file() and path.suffix!='.import':included.add(path)
    with zipfile.ZipFile(OUT/'rio-de-brasa-godot.zip','w',zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(included):archive.write(path,path.relative_to(ROOT))
        archive.write(OUT/'README.md','README.md')
    print(json.dumps(report,indent=2))

if __name__=='__main__':main()
