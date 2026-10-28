"""Prepare the Japanese-inspired street's generated sources for native Godot."""
from pathlib import Path
import argparse, json, shutil
import numpy as np
from PIL import Image
from build_terrain_library import periodic
from refresh_plains_flat import limited_palette

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/overworld/kits/rua-japonesa-v1'
GAME=ROOT/'godot/assets/overworld/kits/rua-japonesa-v1'
OUT=ROOT/'documentation/overworld/rua-japonesa-v1'

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--sources',type=Path,default=ART/'fontes/proveniencia.json')
    args=parser.parse_args()
    specs=json.loads(args.sources.read_text(encoding='utf-8'))
    for base in [ART,GAME]:
        for sub in ['surfaces','props']: (base/sub).mkdir(parents=True,exist_ok=True)
    (ART/'fontes').mkdir(parents=True,exist_ok=True)
    OUT.mkdir(parents=True,exist_ok=True)
    for name,info in specs.items():
        destination=ART/'fontes'/f'{name}.png'
        source=Path(info['path'])
        if not source.exists():source=destination
        if source.resolve()!=destination.resolve():shutil.copy2(source,destination)
    (ART/'fontes/proveniencia.json').write_text(json.dumps(specs,ensure_ascii=False,indent=2),encoding='utf-8')
    asphalt=limited_palette(periodic(Image.open(ART/'fontes/asfalto.png'),512),['414B59','485361','303A48'])
    for base in [ART,GAME]:asphalt.save(base/'surfaces/asfalto.png')
    manifest={'name':'Rua das Rabiolas','projection':'2:1 terrain; illustrated props','heights':{'road':0,'sidewalk':10,'channel':-3},'props':{}}
    for name,box in [('loja',(240,220)),('casa',(220,210)),('maquina',(55,80))]:
        im=Image.open(ART/'fontes'/f'{name}.png').convert('RGBA')
        alpha=np.asarray(im.getchannel('A')).copy()
        alpha[alpha<200]=0
        im.putalpha(Image.fromarray(alpha))
        im=im.crop(im.getbbox())
        im.thumbnail(box,Image.Resampling.LANCZOS)
        # Keep crisp silhouettes after resampling and preserve actual contact feet.
        a=np.asarray(im.getchannel('A')).copy(); a[a<100]=0
        rgb=im.convert('RGB').quantize(colors=24,dither=Image.Dither.NONE).convert('RGBA')
        rgb.putalpha(Image.fromarray(a))
        canvas=Image.new('RGBA',(im.width+16,im.height+16))
        canvas.paste(rgb,(8,8))
        aa=np.asarray(canvas.getchannel('A')); ys,xs=np.where(aa>128)
        bottom=int(ys.max()); pivot=[int(np.median(xs[ys>=bottom-2])),bottom]
        for base in [ART,GAME]:canvas.save(base/'props'/f'{name}.png')
        manifest['props'][name]={'file':f'props/{name}.png','pivot':pivot,'size':list(canvas.size)}
    arr=np.asarray(asphalt).astype(int)
    for name,source in [('vaso','vaso-ceramica'),('poste','poste-ferro'),('banco','banco-madeira')]:
        path=ROOT/'art/overworld/kits/comum/pecas'/f'{source}.png'
        im=Image.open(path).convert('RGBA')
        # Existing approved sprites retain their palette and native dimensions.
        aa=np.asarray(im.getchannel('A')); ys,xs=np.where(aa>128)
        bottom=int(ys.max()); pivot=[int(np.median(xs[ys>=bottom-2])),bottom]
        for base in [ART,GAME]:shutil.copy2(path,base/'props'/f'{name}.png')
        manifest['props'][name]={'file':f'props/{name}.png','pivot':pivot,'size':list(im.size),'scale':0.6,'reusedFrom':str(path.relative_to(ROOT))}
    manifest['asphalt']={'file':'surfaces/asfalto.png','size':[512,512],'opposite_x_difference':int(abs(arr[:,0]-arr[:,-1]).max()),'opposite_y_difference':int(abs(arr[0]-arr[-1]).max())}
    facade_source=ART/'fontes/fachadas-v2.png'
    if (ART/'fontes/fachadas-v3-manga.png').exists():facade_source=ART/'fontes/fachadas-v3-manga.png'
    if (ART/'fontes/fachadas-v4-volumes.png').exists():facade_source=ART/'fontes/fachadas-v4-volumes.png'
    if facade_source.exists():
        atlas=Image.open(facade_source).convert('RGB').resize((1024,1024),Image.Resampling.LANCZOS)
        atlas=atlas.quantize(colors=32,dither=Image.Dither.NONE).convert('RGB')
        for base in [ART,GAME]:atlas.save(base/'surfaces/fachadas.png')
        manifest['projection']='2:1 native terrain, walls and roofs; orthographic elevation textures'
        manifest['buildings']={'construction':'native planes, not complete sprite','atlas':'surfaces/fachadas.png','wallHeightPx':108,'ridgeHeightAboveWallsPx':34,'foundationLevelPx':10,'legacySpritesUsed':False}
        manifest['buildings']['artSource']=str(facade_source.relative_to(ART)).replace('\\','/')
        manifest['buildings']['facadeDepth']={'balconyProjectionCells':.65,'balconyFloorPx':62,'balconyThicknessPx':4,'railHeightPx':21,'awningProjectionCells':.8,'windowSillProjectionCells':.24,'clothRoot':'fixed outer spar; only free lower edge moves'}
    roof_source=ART/'fontes/telhado-v3-manga.png'
    if roof_source.exists():
        roof=Image.open(roof_source).convert('RGB').resize((512,512),Image.Resampling.LANCZOS)
        roof=roof.quantize(colors=8,dither=Image.Dither.NONE).convert('RGB')
        for base in [ART,GAME]:roof.save(base/'surfaces/telhado-manga.png')
        manifest['buildings']['roofArt']='surfaces/telhado-manga.png'
        manifest['buildings']['artDirection']='flat manga; broad cel patches, selective ink, no roof wire grid'
    for base in [ART,GAME]:(base/'library.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
    board=Image.new('RGB',(1536,1536))
    for y in range(3):
        for x in range(3):board.paste(asphalt,(512*x,512*y))
    board.save(OUT/'asfalto-repeticao-3x3.png')
    print(json.dumps(manifest,ensure_ascii=False,indent=2))

if __name__=='__main__':main()
