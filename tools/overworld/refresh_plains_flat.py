"""Normalize generated flat terrain to a limited palette and exact periodic edges."""
from pathlib import Path
import argparse,json,shutil
from PIL import Image
import numpy as np
from build_terrain_library import periodic

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/overworld/kits/planicie-v1'
GAME=ROOT/'godot/assets/overworld/kits/planicie-v1'
OUT=ROOT/'documentation/overworld/planicie-v1/revisao-flat'

def limited_palette(rgb,colors):
    palette=Image.new('P',(1,1))
    values=[]
    for color in colors:values.extend(bytes.fromhex(color))
    palette.putpalette(values+values[-3:]*(256-len(colors)))
    return Image.fromarray(rgb).quantize(palette=palette,dither=Image.Dither.NONE).convert('RGB')

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--grass',type=Path,required=True);parser.add_argument('--earth',type=Path,required=True);args=parser.parse_args()
    OUT.mkdir(parents=True,exist_ok=True)
    specs=[('grama',args.grass,['7F9B54','93AD65','536F40','304934']),('terra',args.earth,['B98C57','C89C65','916D49','624C36'])]
    report=[]
    for id,source,colors in specs:
        shutil.copy2(source,ART/'fontes'/f'{id}-flat-v2.png')
        surface=limited_palette(periodic(Image.open(source),512),colors)
        for base in [ART,GAME]:surface.save(base/'surfaces'/f'{id}.png')
        array=np.asarray(surface)
        report.append({'id':id,'size':[512,512],'palette':colors,'runtimeColors':len(surface.getcolors(65536)),
                       'oppositeXMaxDifference':int(abs(array[:,0].astype(int)-array[:,-1]).max()),
                       'oppositeYMaxDifference':int(abs(array[0].astype(int)-array[-1]).max())})
        repeat=Image.new('RGB',(1536,1536))
        for y in range(3):
            for x in range(3):repeat.paste(surface,(x*512,y*512))
        repeat.save(OUT/f'{id}-repeticao-3x3.png')
    manifest=json.loads((ART/'library.json').read_text(encoding='utf-8'))
    manifest['revision']='flat-manga-v2'
    manifest['grass']['source']='fontes/grama-flat-v2.png'
    manifest['earth']={'file':'surfaces/terra.png','source':'fontes/terra-flat-v2.png','size':[512,512]}
    manifest['reusedAssets']=[name for name in manifest['reusedAssets'] if name not in ['cavernas-v3/surfaces/terra-gruta.png','parque/decalques/capim-a.png']]
    for base in [ART,GAME]:(base/'library.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
    (OUT/'preparacao.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps(report,indent=2))

if __name__=='__main__':main()
