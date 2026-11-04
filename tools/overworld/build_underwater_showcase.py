"""Normalize generated marine props to flat palettes, alpha and grounded pivots."""
from pathlib import Path
import argparse,json,shutil
import numpy as np
from PIL import Image
from refresh_plains_flat import limited_palette

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/overworld/kits/submerso-v1'
GAME=ROOT/'godot/assets/overworld/kits/submerso-v1'
OUT=ROOT/'documentation/overworld/submerso-v1'

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--kelp',type=Path,required=True);parser.add_argument('--coral',type=Path,required=True);args=parser.parse_args()
    for base in [ART,GAME,OUT]:base.mkdir(parents=True,exist_ok=True)
    (ART/'fontes').mkdir(exist_ok=True)
    props={}
    for id,source,width,palette in [('algas',args.kelp,52,['397C70','67A28C','285357','293A49','7C9360']),('coral',args.coral,104,['C77965','DEA28A','76546A','293A49','AA796F'])]:
        shutil.copy2(source,ART/'fontes'/f'{id}.png')
        im=Image.open(source).convert('RGBA')
        im.putalpha(im.getchannel('A').point(lambda value:255 if value>=200 else 0))
        im=im.crop(im.getbbox());height=round(im.height*width/im.width)
        im=im.resize((width,height),Image.Resampling.LANCZOS)
        alpha=im.getchannel('A')
        color=limited_palette(np.asarray(im.convert('RGB')),palette).convert('RGBA');color.putalpha(alpha)
        sprite=Image.new('RGBA',(width+16,height+16));sprite.alpha_composite(color,(8,8))
        ys,xs=np.where(np.asarray(sprite)[:,:,3]>80);bottom=int(ys.max());pivot=[float(np.median(xs[ys>=bottom-3])),bottom]
        for base in [ART,GAME]:
            (base/'props').mkdir(exist_ok=True);sprite.save(base/'props'/f'{id}.png')
        props[id]={'file':f'props/{id}.png','source':f'fontes/{id}.png','pivot':pivot,'size':list(sprite.size),'palette':palette,'collision':'none-visual-only'}
    manifest={'schema':'underwater-showcase-1','grid':[64,32],'props':props,'campaignIntegrated':False,
              'sharedTransition':'res://shaders/overworld/terrain_transition.gdshaderinc','loopSeconds':8,
              'reusedSurfaces':['areia-v1/surfaces/areia.png','cavernas-v3/surfaces/rocha-cinza.png']}
    for base in [ART,GAME]:(base/'library.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    (OUT/'preparacao.json').write_text(json.dumps(props,indent=2),encoding='utf-8')
    print(json.dumps(props,indent=2))

if __name__=='__main__':main()
