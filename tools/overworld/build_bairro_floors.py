"""Normalize the approved Bairro surface paintings for continuous world UVs.

Original generations remain intact in fontes/pisos-v2. This only prepares
periodic textures, fixed-size samples and small editable ground hardware.
"""
from pathlib import Path
import json, shutil, math
import numpy as np
from PIL import Image
from build_morro_floors import periodic, project, save_tile
from build_bairro import Ink

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/overworld/kits/bairro'
RUNTIME=ROOT/'godot/assets/overworld/kits/bairro'

def hardware():
    dest=ART/'decalques';dest.mkdir(exist_ok=True)
    p=lambda u,v:(32+(u-v)*32,(u+v)*16)
    for axis in ['u','v']:
        c=Ink(64,32)
        q=lambda u,v:p(u,v) if axis=='u' else p(v,u)
        for lo,hi,front,back,col in [(.13,.87,.28,.72,'#26394D'),(.17,.83,.33,.67,'#8A9899'),(.21,.79,.39,.61,'#26394D')]:
            c.poly([q(lo,front),q(hi,front),q(hi,back),q(lo,back)],col,None)
        for u in np.arange(.24,.8,.09):c.line([q(u,.36),q(u,.64)],'#7D8F97',1)
        c.save(dest/f'ralo-{axis}')
    c=Ink(64,32)
    for box,col in [((16,7,48,25),'#26394D'),((18,8,46,23),'#88949A'),((21,10,43,21),'#465969'),((23,11,41,20),'#71828D')]:c.ellipse(box,col,'#344C60',.65)
    c.line([(24,13),(37,17)],'#3A5266',.6);c.save(dest/'tampa-inspecao')
    for variant in range(3):
        c=Ink(64,32);offset=variant*2
        c.line([(16,9+offset),(24,12),(29,11),(34,16),(44,19)],'#73796866',.65)
        c.line([(29,11),(31,7+offset)],'#73796855',.5)
        c.save(dest/f'fissura-{variant}')

def update_kit(kit):
    surfaces={}
    for name in ['calcada','asfalto','canteiro','terra']:
        file=ART/f'fontes/pisos-v2/{name}.png'
        if name=='calcada': file=ART/'fontes/pisos-v2/calcada-placas.png'
        surface=periodic(Image.open(file))
        (ART/'superficies').mkdir(exist_ok=True)
        surface.save(ART/f'superficies/{name}.png')
        surfaces[name]=surface
    surfaces['construcao']=surfaces['calcada']
    kit['surfaceMaterials']={name:{'file':f'superficies/{"calcada" if name=="construcao" else name}.png','repeatCells':8,'size':[512,512]} for name in surfaces}
    kit['surfaceShader']='res://shaders/bairro_surface.gdshader'
    samples={}
    for name,surface in surfaces.items():
        samples[name]=[]
        for variant,(u,v) in enumerate([(0,0),(2,1),(5,3),(3,6)]):
            tile=project(surface,u,v);samples[name].append(tile)
            save_tile(tile,ART/f'chao/{name}-{variant}')
        kit['materials'][name].update({'source':f'fontes/pisos-v2/{"calcada-placas" if name in ["calcada","construcao"] else name}.png','sampling':'continuous-world-uv; navigation tile boundaries do not define slab joints'})
    # Keep the modular corner-mask browser in the same palette as the runtime.
    yy,xx=np.mgrid[:32,:64];u=np.clip((xx+.5)/64+(yy+.5)/32-.5,0,1);v=np.clip((yy+.5)/32-(xx+.5)/64+.5,0,1)
    weights=[(1-u)*(1-v),u*(1-v),u*v,(1-u)*v]
    for pair,entry in kit['transitions'].items():
        a,b=pair.split('/');first=np.array(samples[a][0]);second=np.array(samples[b][0])
        for mask,file in enumerate(entry['files']):
            amount=sum(weights[bit] for bit in range(4) if mask&(1<<bit)) if mask else np.zeros_like(u)
            tile=np.where((amount>=.5)[:,:,None],second,first)
            Image.fromarray(tile).save(ART/file)
    hardware()
    kit['groundDetails']=[
        {'file':'decalques/ralo-u.png','point':[8.5,14.15]},
        {'file':'decalques/ralo-u.png','point':[23.5,14.15]},
        {'file':'decalques/ralo-u.png','point':[36.5,18.85]},
        {'file':'decalques/tampa-inspecao.png','point':[14.3,16.5]},
        {'file':'decalques/tampa-inspecao.png','point':[32.5,16.1]},
        {'file':'decalques/fissura-0.png','point':[11.3,12.5]},
        {'file':'decalques/fissura-1.png','point':[23.4,25.2]},
        {'file':'decalques/fissura-2.png','point':[34.6,11.2]}]
    return kit

def main():
    kit=update_kit(json.loads((ART/'kit.json').read_text(encoding='utf-8')))
    for dest in [ART,RUNTIME]:
        (dest/'kit.json').write_text(json.dumps(kit,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
    for folder in ['superficies','chao','transicoes','decalques']:shutil.copytree(ART/folder,RUNTIME/folder,dirs_exist_ok=True)
    print('Bairro: four continuous painted surfaces, 20 native samples, refreshed corner masks and ground hardware.')

if __name__=='__main__':main()
