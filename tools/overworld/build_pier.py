from pathlib import Path
import argparse,json,shutil
import numpy as np
from PIL import Image
from build_terrain_library import periodic
from refresh_plains_flat import limited_palette

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/overworld/kits/cais-v1'
GAME=ROOT/'godot/assets/overworld/kits/cais-v1'

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--sources',type=Path,default=ART/'fontes/origem.json');args=parser.parse_args()
    specs=json.loads(args.sources.read_text(encoding='utf-8'))
    for base in [ART,GAME]:
        for folder in ['surfaces','palma']:(base/folder).mkdir(parents=True,exist_ok=True)
    (ART/'fontes').mkdir(exist_ok=True)
    palettes={'madeira':['BA7A45','D9A66A','8C563B','2C3D42'],'rocha':['435B60','6B7E77','2C404C','A18862'],'palha':['B99A51','DDC67D','847447','334B45']}
    for id,info in specs.items():
        source=Path(info['path']);destination=ART/'fontes'/f'{id}.png'
        if source.exists() and source.resolve()!=destination.resolve():shutil.copy2(source,destination)
        if id in ['madeira','palha']:
            # Preserve the painted broad planes; FFT correction amplified source
            # gradients into visible pepper near hard palette thresholds.
            image=Image.open(destination).convert('RGB').resize((512,512),Image.Resampling.LANCZOS)
            pixels=np.asarray(image).copy()
            for axis in [0,1]:
                if axis==0:
                    common=((pixels[0].astype(int)+pixels[-1].astype(int))//2).astype('uint8')
                    pixels[0]=common;pixels[-1]=common
                else:
                    common=((pixels[:,0].astype(int)+pixels[:,-1].astype(int))//2).astype('uint8')
                    pixels[:,0]=common;pixels[:,-1]=common
            image=Image.fromarray(pixels).quantize(colors=8,dither=Image.Dither.NONE).convert('RGB')
        else:image=limited_palette(periodic(Image.open(destination),512),palettes[id])
        for base in [ART,GAME]:image.save(base/'surfaces'/f'{id}.png')
    (ART/'fontes/origem.json').write_text(json.dumps(specs,ensure_ascii=False,indent=2),encoding='utf-8')
    for id,source in [('areia','areia-v1/surfaces/areia.png'),('grama','planicie-v1/surfaces/grama.png')]:
        for base in [ART,GAME]:shutil.copy2(ROOT/'godot/assets/overworld/kits'/source,base/'surfaces'/f'{id}.png')
    if (ART/'fontes/coqueiro-manga/origem.json').exists():
        from prepare_pier_palm import main as prepare_palm
        prepare_palm()
    else:
        rig=ROOT/'godot/assets/overworld/kits/frutiferas/rigs/coqueiro'
        for base in [ART,GAME]:
            for file in ['rig.json','trunk.png','canopy.png','fruit.png']:shutil.copy2(rig/file,base/'palma'/file)
    print('Pier materials and articulated palm copied to runtime.')

if __name__=='__main__':main()
