"""Normalize generated sand and sandstone; no procedural replacement of source art."""
from pathlib import Path
import argparse,json,shutil
from PIL import Image
import numpy as np
from build_terrain_library import periodic
from refresh_plains_flat import limited_palette

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/overworld/kits/areia-v1'
GAME=ROOT/'godot/assets/overworld/kits/areia-v1'
OUT=ROOT/'documentation/overworld/areia-v1'

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--sand',type=Path,required=True);parser.add_argument('--stone',type=Path,required=True);args=parser.parse_args()
    for base in [ART,GAME,OUT]:base.mkdir(parents=True,exist_ok=True)
    (ART/'fontes').mkdir(exist_ok=True)
    shutil.copy2(args.sand,ART/'fontes/areia.png');shutil.copy2(args.stone,ART/'fontes/arenito.png')
    sand=limited_palette(periodic(Image.open(args.sand),512),['DDBD7D','EACF97','C4A366','927449'])
    stone=Image.open(args.stone).convert('RGBA')
    stone.putalpha(stone.getchannel('A').point(lambda x:255 if x>=200 else 0))
    stone=stone.crop(stone.getbbox());height=round(stone.height*112/stone.width)
    stone=stone.resize((112,height),Image.Resampling.LANCZOS)
    alpha=stone.getchannel('A')
    stone=limited_palette(np.asarray(stone.convert('RGB')),['D6B278','B98E56','8B6246','3C3540','E7C98D']).convert('RGBA')
    stone.putalpha(alpha)
    prop=Image.new('RGBA',(128,height+16));prop.alpha_composite(stone,(8,8))
    ys,xs=np.where(np.asarray(prop)[:,:,3]>80);bottom=int(ys.max());pivot=[float(np.median(xs[ys>=bottom-3])),bottom]
    for base in [ART,GAME]:
        (base/'surfaces').mkdir(exist_ok=True);(base/'props').mkdir(exist_ok=True)
        sand.save(base/'surfaces/areia.png');prop.save(base/'props/arenito.png')
    array=np.asarray(sand)
    report={'sandSize':[512,512],'sandColors':len(sand.getcolors(65536)),
            'oppositeXMaxDifference':int(abs(array[:,0].astype(int)-array[:,-1]).max()),
            'oppositeYMaxDifference':int(abs(array[0].astype(int)-array[-1]).max()),'stonePivot':pivot,'stoneSize':list(prop.size)}
    manifest={'schema':'sand-showcase-1','grid':[64,32],'campaignIntegrated':False,'collision':'not-authored',
              'sand':{'file':'surfaces/areia.png','source':'fontes/areia.png','size':[512,512],'repeatCells':8},
              'props':{'arenito':{'file':'props/arenito.png','source':'fontes/arenito.png','pivot':pivot,'size':list(prop.size)}},
              'sharedTransition':'res://shaders/overworld/terrain_transition.gdshaderinc','duneHeightPx':18}
    for base in [ART,GAME]:(base/'library.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    (OUT/'preparacao.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    repeated=Image.new('RGB',(1536,1536))
    for y in range(3):
        for x in range(3):repeated.paste(sand,(x*512,y*512))
    repeated.save(OUT/'areia-repeticao-3x3.png')
    print(json.dumps(report))

if __name__=='__main__':main()
