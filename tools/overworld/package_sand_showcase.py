from pathlib import Path
import json,re,shutil,zipfile
from PIL import Image
import numpy as np

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'documentation/overworld/areia-v1'

def main():
    paths=sorted((OUT/'frames').glob('areia-*.png'))
    if len(paths)!=96:raise ValueError('Expected 96 native frames')
    frames=[Image.open(path).convert('RGB') for path in paths]
    difference=abs(np.asarray(frames[0]).astype(int)-np.asarray(Image.open(OUT/'loop-final.png').convert('RGB')).astype(int))
    duration=[80,80,90]*32
    small=[frame.resize((960,540),Image.Resampling.LANCZOS) for frame in frames]
    small[0].save(OUT/'AREIAS-DO-VENTO.webp',save_all=True,append_images=small[1:],duration=duration,loop=0,quality=90)
    palette=small[0].quantize(colors=256)
    gif=[frame.quantize(palette=palette,dither=Image.Dither.NONE) for frame in small]
    gif[0].save(OUT/'AREIAS-DO-VENTO.gif',save_all=True,append_images=gif[1:],duration=duration,loop=0,disposal=2)
    Image.open(OUT/'sem-objetos-1280x720.png').crop((435,300,855,485)).resize((1050,463),Image.Resampling.NEAREST).save(OUT/'DETALHE-TRANSICAO.png')
    report={'nativeResolution':[1280,720],'nativeViews':5,'frames':96,'loopSeconds':8,
            'loopMaximumChannelDifference':int(difference.max()),'loopMeanChannelDifference':float(difference.mean()),
            'geometry':json.loads((OUT/'geometria.json').read_text(encoding='utf-8')),
            'reducedMotionCapture':True,'campaignIntegrated':False,'gameplayTestsRun':False}
    (OUT/'auditoria.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    for name in ['sand-native.log','sand-import.log']:shutil.copy2(ROOT/'tmp'/name,OUT/name)
    pending=[ROOT/'godot/scenes/overworld/sand/areias-do-vento.tscn'];included=set()
    while pending:
        path=pending.pop()
        if path in included:continue
        included.add(path)
        if path.suffix in ['.gd','.tscn','.tres','.gdshader','.gdshaderinc']:
            source=path.read_text(encoding='utf-8-sig')
            for relative in re.findall(r'res://([^"\s]+\.(?:gdshaderinc|gdshader|png|tscn|tres|gd))(?=["\s])',source):pending.append(ROOT/'godot'/relative)
    for path in (ROOT/'godot/assets/overworld/kits/areia-v1').rglob('*'):
        if path.is_file() and path.suffix!='.import':included.add(path)
    with zipfile.ZipFile(OUT/'areias-do-vento-godot.zip','w',zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(included):archive.write(path,path.relative_to(ROOT))
        archive.write(OUT/'README.md','README.md')
    print(json.dumps(report,indent=2))

if __name__=='__main__':main()
