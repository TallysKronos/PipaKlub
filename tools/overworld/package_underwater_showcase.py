from pathlib import Path
import json,re,shutil,zipfile
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'documentation/overworld/submerso-v1'

def main():
    paths=sorted((OUT/'frames').glob('submerso-*.png'))
    if len(paths)!=96:raise ValueError('Expected 96 native frames')
    frames=[Image.open(path).convert('RGB') for path in paths]
    first=np.asarray(frames[0]).astype(int)
    end=np.asarray(Image.open(OUT/'loop-final.png').convert('RGB')).astype(int)
    difference=abs(first-end)
    duration=[80,80,90]*32
    small=[frame.resize((960,540),Image.Resampling.LANCZOS) for frame in frames]
    small[0].save(OUT/'JARDIM-DAS-MARES.webp',save_all=True,append_images=small[1:],duration=duration,loop=0,quality=90)
    palette=small[0].quantize(colors=256)
    gif=[frame.quantize(palette=palette,dither=Image.Dither.NONE) for frame in small]
    gif[0].save(OUT/'JARDIM-DAS-MARES.gif',save_all=True,append_images=gif[1:],duration=duration,loop=0,disposal=2)
    details=[frame.crop((340,310,595,465)).resize((765,465),Image.Resampling.NEAREST) for frame in frames]
    details[0].save(OUT/'ALGAS-ANIMADAS.webp',save_all=True,append_images=details[1:],duration=duration,loop=0,lossless=True)
    details[24].save(OUT/'DETALHE-ALGAS.png')
    report={'nativeResolution':[1280,720],'nativeViews':7,'frames':96,'loopSeconds':8,
            'loopMaximumChannelDifference':int(difference.max()),'loopMeanChannelDifference':float(difference.mean()),
            'quarterCycleChangedPixels':int(np.any(abs(first-np.asarray(frames[24]).astype(int))>2,axis=2).sum()),
            'animatedPlantClusters':6,'plantRootVertexWeight':0,'effectsDisabledCapture':True,'reducedMotionCapture':True,
            'campaignIntegrated':False,'gameplayTestsRun':False}
    if (OUT/'relevo/geometria.json').exists():report['terrain']=json.loads((OUT/'relevo/geometria.json').read_text(encoding='utf-8'))
    (OUT/'auditoria.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    for name in ['underwater-native.log','underwater-import.log']:shutil.copy2(ROOT/'tmp'/name,OUT/name)
    pending=[ROOT/'godot/scenes/overworld/underwater/jardim-das-mares.tscn'];included=set()
    while pending:
        path=pending.pop()
        if path in included:continue
        included.add(path)
        if path.suffix in ['.gd','.tscn','.tres','.gdshader','.gdshaderinc']:
            source=path.read_text(encoding='utf-8-sig')
            for relative in re.findall(r'res://([^"\s]+\.(?:gdshaderinc|gdshader|png|tscn|tres|gd))(?=["\s])',source):pending.append(ROOT/'godot'/relative)
    for path in (ROOT/'godot/assets/overworld/kits/submerso-v1').rglob('*'):
        if path.is_file() and path.suffix!='.import':included.add(path)
    with zipfile.ZipFile(OUT/'jardim-das-mares-godot.zip','w',zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(included):archive.write(path,path.relative_to(ROOT))
        archive.write(OUT/'README.md','README.md')
    print(json.dumps(report,indent=2))

if __name__=='__main__':main()
