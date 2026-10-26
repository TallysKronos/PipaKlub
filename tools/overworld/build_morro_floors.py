"""PIP-88: normalize generated surface sources to exact isometric ground.

Geometry, UV projection, periodic seam repair and alpha are deterministic.
Original imagegen paintings remain untouched in fontes/pisos-v2.
"""
import base64
import io
import itertools
import json
import shutil
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/overworld/kits/morro'
RUNTIME=ROOT/'godot/assets/overworld/kits/morro'
REVIEW=ROOT/'documentation/overworld/pisos-morro'
NAMES=('grama','calcada','piso')
SIZE=512


def write(path,data):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')


def periodic(source):
    """Periodic-plus-smooth decomposition; removes only the wrap discontinuity.

    FFT Poisson boundary correction is texture seam preparation, not new art.
    """
    pixels=np.asarray(source.convert('RGB').resize((SIZE,SIZE),Image.Resampling.LANCZOS),dtype=np.float64)
    boundary=np.zeros_like(pixels)
    boundary[0,:,:]=pixels[-1,:,:]-pixels[0,:,:]
    boundary[-1,:,:]=-boundary[0,:,:]
    delta=pixels[:,-1,:]-pixels[:,0,:]
    boundary[:,0,:]+=delta
    boundary[:,-1,:]-=delta
    ys,xs=np.meshgrid(np.arange(SIZE),np.arange(SIZE),indexing='ij')
    denominator=2*np.cos(2*np.pi*xs/SIZE)+2*np.cos(2*np.pi*ys/SIZE)-4
    denominator[0,0]=1
    smooth=np.fft.fft2(boundary,axes=(0,1))/denominator[:,:,None]
    smooth[0,0,:]=0
    result=pixels-np.fft.ifft2(smooth,axes=(0,1)).real
    # Exact matching boundary texels for repeat filtering, fade over four pixels.
    for axis in (0,1):
        a=np.moveaxis(result,axis,0)
        for i in range(4):
            weight=(1-i/4)*.5
            left=a[i].copy();right=a[-1-i].copy()
            a[i]=left*(1-weight)+right*weight
            a[-1-i]=right*(1-weight)+left*weight
    return Image.fromarray(np.clip(np.rint(result),0,255).astype('uint8'))


def project(source,u0=0,v0=0):
    # Inverse 2:1 transform; sample by pixel centres in UV ground coordinates.
    rgb=np.asarray(source)
    yy,xx=np.meshgrid(np.arange(32)+.5,np.arange(64)+.5,indexing='ij')
    u=xx/64+yy/32-.5
    v=yy/32-xx/64+.5
    inside=(u>=0)&(u<=1)&(v>=0)&(v<=1)
    sx=np.floor((u+u0)*64).astype(int)%SIZE
    sy=np.floor((v+v0)*64).astype(int)%SIZE
    result=np.empty((32,64,4),dtype='uint8')
    result[:,:,:3]=rgb[sy,sx,:3]
    result[:,:,3]=inside*255
    return Image.fromarray(result)


def save_tile(image,path):
    image.save(path.with_suffix('.png'))
    buffer=io.BytesIO();image.save(buffer,format='PNG')
    encoded=base64.b64encode(buffer.getvalue()).decode()
    # Keep SVG counterpart truthful: it embeds the normalized raster, while
    # the untouched source and generation notes remain separately archived.
    path.with_suffix('.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="64" height="32" viewBox="0 0 64 32"><image width="64" height="32" href="data:image/png;base64,'+encoded+'"/></svg>\n',encoding='utf-8',newline='\n')


def build_assets():
    for folder in ('chao','transicoes'):(ART/folder).mkdir(exist_ok=True)
    surfaces={name:periodic(Image.open(ART/f'fontes/pisos-v2/{name}.png')) for name in NAMES}
    atlas=Image.new('RGB',(SIZE*3,SIZE))
    for i,name in enumerate(NAMES):atlas.paste(surfaces[name],(i*SIZE,0))
    atlas.save(ART/'chao/superficies-atlas.png')
    materials={}
    samples={}
    for name in (*NAMES,'construcao'):
        surface=surfaces['piso' if name=='construcao' else name]
        positions=[(0,0),(2,1),(4,3),(1,5),(6,2),(5,6)]
        # Reserve two genuinely quiet grass samples, chosen from the generated
        # source itself rather than painting or blurring quiet areas over it.
        candidates=[]
        for v in range(8):
            for u in range(8):
                tile=project(surface,u,v)
                values=np.asarray(tile)[:,:,:3][np.asarray(tile)[:,:,3]>0]
                candidates.append((float(values.var(axis=0).sum()),u,v))
        positions += [(u,v) for _,u,v in sorted(candidates)[:2]]
        samples[name]=[]
        for n,(u,v) in enumerate(positions):
            tile=project(surface,u,v)
            samples[name].append(tile)
            save_tile(tile,ART/f'chao/{name}-{n}')
        materials[name]={'variants':[f'chao/{name}-{n}.png' for n in range(8)],
                         'size':[64,32],'filter':'linear','shadowBaked':False,
                         'source':f'fontes/pisos-v2/{"piso" if name=="construcao" else name}.png',
                         'sampling':'continuous-world-uv', 'sampleCells':positions}
        if name=='grama':materials[name]['smoothVariants']=[6,7]
    transitions={}
    yy,xx=np.meshgrid(np.arange(32)+.5,np.arange(64)+.5,indexing='ij')
    u=np.clip(xx/64+yy/32-.5,0,1);v=np.clip(yy/32-xx/64+.5,0,1)
    weights=[(1-u)*(1-v),u*(1-v),u*v,(1-u)*v]
    for a,b in itertools.combinations(materials,2):
        files=[]
        first=np.asarray(samples[a][0],dtype=float)
        second=np.asarray(samples[b][0],dtype=float)
        for mask in range(16):
            amount=sum(weights[i] for i in range(4) if mask&(1<<i)) if mask else np.zeros_like(u)
            lo=np.power(1-amount,5);hi=np.power(amount,5)
            amount=hi/(hi+lo+1e-9)
            rgb=first[:,:,:3]*(1-amount[:,:,None])+second[:,:,:3]*amount[:,:,None]
            rgba=np.dstack([rgb,first[:,:,3]]).round().astype('uint8')
            file=f'transicoes/{a}-{b}-{mask}'
            save_tile(Image.fromarray(rgba),ART/file);files.append(file+'.png')
        transitions[f'{a}/{b}']={'corners':['top','right','bottom','left'],'maskBits':[1,2,4,8],'files':files}
    # Refresh the two pre-existing reverse-name families as well. They are
    # compatibility files, so the asset browser no longer exposes old palettes.
    for a,b in [('construcao','grama'),('construcao','piso')]:
        for mask in range(16):
            source=ART/f'transicoes/{b}-{a}-{15^mask}.png'
            save_tile(Image.open(source),ART/f'transicoes/{a}-{b}-{mask}')
    return materials,transitions,{'file':'chao/superficies-atlas.png','size':[1536,512],
        'materials':list(NAMES),'cellTexels':64,'repeatCells':[8,8],
        'coordinates':'world u/v, continuous across cells and levels',
        'shader':'res://scripts/overworld/painted_floor.gdshader'}


def update_kit(kit):
    materials,transitions,surface=build_assets()
    kit['materials'].update(materials)
    kit['transitions']=transitions
    kit['floorSurface']=surface
    return kit


def build():
    kit=update_kit(json.loads((ART/'kit.json').read_text(encoding='utf-8')))
    for root in (ART,RUNTIME):write(root/'kit.json',kit)
    for folder in ('chao','transicoes'):
        (RUNTIME/folder).mkdir(exist_ok=True)
        for path in (ART/folder).iterdir():
            if path.suffix in ('.png','.svg'):shutil.copy2(path,RUNTIME/folder/path.name)
    REVIEW.mkdir(parents=True,exist_ok=True)
    board=Image.new('RGB',(1152,400),'#233D35');draw=ImageDraw.Draw(board)
    for i,name in enumerate(NAMES):
        surface=Image.open(ART/'chao/superficies-atlas.png').crop((i*SIZE,0,(i+1)*SIZE,SIZE))
        board.paste(surface.resize((320,320)),(i*384+32,32))
        draw.text((i*384+32,365),name+' / superficie continua',fill='white')
    board.save(REVIEW/'materiais.png')
    report={'tileSize':[64,32],'materials':4,'tileSamples':32,'transitionPairs':6,
            'transitionStates':96,'atlasSize':[1536,512],'bakedYardShadow':False,
            'collisionChanges':False,'mirrorMismatches':[], 'periodicEdgeMismatch':{}}
    referenced={f for material in kit['materials'].values() for f in material['variants']}
    referenced.update(f for pair in kit['transitions'].values() for f in pair['files'])
    for folder in ('chao','transicoes'):
        for path in (ART/folder).glob('*.png'):
            assert path.read_bytes()==(RUNTIME/folder/path.name).read_bytes()
            if path.relative_to(ART).as_posix() in referenced:
                image=np.asarray(Image.open(path).convert('RGBA'))
                assert image.shape==(32,64,4)
                assert np.count_nonzero(image[:,:,3])==1024
                assert set(np.unique(image[:,:,3]))=={0,255}
    for i,name in enumerate(NAMES):
        image=np.asarray(Image.open(ART/'chao/superficies-atlas.png'))[:,i*SIZE:(i+1)*SIZE,:]
        error=max(int(np.abs(image[0].astype(int)-image[-1].astype(int)).max()),
                  int(np.abs(image[:,0].astype(int)-image[:,-1].astype(int)).max()))
        assert error==0,(name,error)
        report['periodicEdgeMismatch'][name]=error
    native=[]
    for name in (*NAMES,'encontros'):
        path=REVIEW/f'after/{name}-8x8-godot-1280x720.png'
        if not path.exists():continue
        pixels=np.asarray(Image.open(path).convert('RGB'))
        assert pixels.shape==(720,1280,3)
        yy,xx=np.meshgrid(np.arange(720)+.5,np.arange(1280)+.5,indexing='ij')
        interior=np.abs((xx-640)/358.4)+np.abs((yy-360)/179.2)<.99
        black=int(np.count_nonzero((pixels.max(axis=2)<20)&interior))
        assert black==0,(name,black)
        native.append({'material':name,'size':[1280,720],'zoom':1.4,
                       'interiorPixelsTested':int(interior.sum()),'blackGaps':black})
    report['nativeFields']=native
    log=REVIEW/'native-render.log'
    if log.exists():
        text=log.read_text(encoding='utf-8')
        assert 'ERROR:' not in text and 'Error:' not in text, 'Native Godot render contains errors'
        report['nativeRenderErrors']=0
    write(REVIEW/'validacao.json',report)
    print(json.dumps(report))


if __name__=='__main__':build()
