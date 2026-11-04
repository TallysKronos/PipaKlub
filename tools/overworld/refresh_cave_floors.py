"""Refresh only cave floors from generated source art; preserve walls, props and rigs."""
from pathlib import Path
import argparse
import json
import shutil
import numpy as np
from PIL import Image
from build_terrain_library import periodic, variants, project, MASKS, mosaic

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT/'art/overworld/kits/cavernas-v3'
GAME = ROOT/'godot/assets/overworld/kits/cavernas-v3'
REVIEW = ROOT/'documentation/overworld/cavernas-v3/revisao-piso'

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--stone',type=Path,required=True)
    parser.add_argument('--path',type=Path,required=True)
    args=parser.parse_args()
    for source,name in [(args.stone,'piso-placas-v4'),(args.path,'piso-terra-v4')]:
        shutil.copy2(source,ART/'fontes'/f'{name}.png')
    manifest=json.loads((ART/'library.json').read_text(encoding='utf-8'))
    report=[]
    for id,source in [('rocha-cinza',args.stone),('rocha-umida',args.stone),('terra-gruta',args.path),('cascalho-gruta',args.path)]:
        im=Image.open(source).convert('RGB')
        shutil.copy2(source,ART/'fontes'/f'{id}.png')
        surface=periodic(im,512)
        textures=variants(im)
        atlas=Image.new('RGBA',(512,224));images={}
        def save(image,relative):
            for base in [ART,GAME]:
                target=base/relative;target.parent.mkdir(parents=True,exist_ok=True);image.save(target)
        save(Image.fromarray(surface),f'surfaces/{id}.png')
        for i,mask in enumerate(MASKS):
            tile=project(textures[0],mask);images[mask]=tile
            save(tile,f'tiles/{id}/blob-{mask:03}.png')
            atlas.alpha_composite(tile,((i%8)*64,(i//8)*32))
        for i,rgb in enumerate(textures):
            tile=project(rgb)
            save(tile,f'tiles/{id}/centro-{i}.png')
            atlas.alpha_composite(tile,(i*64,192))
        save(atlas,f'atlas/{id}.png')
        repeated=Image.new('RGB',(1536,1536))
        for y in range(3):
            for x in range(3):repeated.paste(Image.fromarray(surface),(x*512,y*512))
        repeated.save(REVIEW/f'{id}-repeticao-3x3.png')
        layout=[[int(0<x<9 and 0<y<9 and not(x>5 and y>5)) for x in range(10)] for y in range(10)]
        mosaic(images,layout).save(REVIEW/f'{id}-encaixes.png')
        manifest['floors'][id]['revision']='floor-v4-plates-and-earth'
        report.append({'id':id,'tileSize':[64,32],'masks':47,'centers':8,
                       'xBoundaryError':int(abs(surface[:,0].astype(int)-surface[:,-1]).max()),
                       'yBoundaryError':int(abs(surface[0].astype(int)-surface[-1]).max())})
    for base in [ART,GAME]:(base/'library.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
    (REVIEW/'encaixes.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps(report,indent=2))

if __name__=='__main__':main()
