"""Normalize generated basalt/lava paintings; preserve exact periodic edges."""
from pathlib import Path
import argparse,json,shutil
from PIL import Image
import numpy as np
from build_terrain_library import periodic
from refresh_plains_flat import limited_palette

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/overworld/kits/lava-v1'
GAME=ROOT/'godot/assets/overworld/kits/lava-v1'
OUT=ROOT/'documentation/overworld/lava-v1'

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--basalt',type=Path,required=True);parser.add_argument('--lava',type=Path,required=True);args=parser.parse_args()
    report=[]
    for base in [ART,GAME,OUT]:base.mkdir(parents=True,exist_ok=True)
    (ART/'fontes').mkdir(exist_ok=True)
    for id,source,colors in [('basalto',args.basalt,['3C3548','514659','252634','745045']),('lava',args.lava,['E46B29','B83D28','F6B34C','3A2938','252634'])]:
        shutil.copy2(source,ART/'fontes'/f'{id}.png')
        surface=limited_palette(periodic(Image.open(source),512),colors)
        for base in [ART,GAME]:
            (base/'surfaces').mkdir(exist_ok=True);surface.save(base/'surfaces'/f'{id}.png')
        array=np.asarray(surface)
        report.append({'id':id,'size':[512,512],'colors':len(surface.getcolors(65536)),'palette':colors,
                       'oppositeXMaxDifference':int(abs(array[:,0].astype(int)-array[:,-1]).max()),
                       'oppositeYMaxDifference':int(abs(array[0].astype(int)-array[-1]).max())})
        repeated=Image.new('RGB',(1536,1536))
        for y in range(3):
            for x in range(3):repeated.paste(surface,(x*512,y*512))
        repeated.save(OUT/f'{id}-repeticao-3x3.png')
    manifest={'schema':'lava-showcase-1','grid':[64,32],'campaignIntegrated':False,'collision':'not-authored',
              'surfaces':report,'sharedTransition':'res://shaders/overworld/terrain_transition.gdshaderinc',
              'scene':'res://scenes/overworld/lava/rio-de-brasa.tscn','loopSeconds':8,'lavaDepthPx':24}
    for base in [ART,GAME]:(base/'library.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    (OUT/'preparacao.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps(report))

if __name__=='__main__':main()
