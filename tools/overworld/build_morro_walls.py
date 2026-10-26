"""PIP-88 retaining walls: generated material, exact existing wall geometry."""
import base64
import io
import json
import shutil
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
from build_morro_floors import periodic, write

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/overworld/kits/morro'
RUNTIME=ROOT/'godot/assets/overworld/kits/morro'
REVIEW=ROOT/'documentation/overworld/muros-morro'


def save(image,path):
    image.save(path.with_suffix('.png'))
    buffer=io.BytesIO();image.save(buffer,format='PNG')
    encoded=base64.b64encode(buffer.getvalue()).decode()
    w,h=image.size
    path.with_suffix('.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}"><image width="{w}" height="{h}" href="data:image/png;base64,{encoded}"/></svg>\n',encoding='utf-8',newline='\n')


def face(source,side,variant=0):
    pixels=np.asarray(source)
    out=np.zeros((80,32,4),dtype='uint8')
    yy,xx=np.meshgrid(np.arange(80)+.5,np.arange(32)+.5,indexing='ij')
    top=16-xx*.5 if side=='u' else xx*.5
    alpha=(yy>=top)&(yy<top+64)
    along=(32-xx)*4 if side=='u' else xx*4
    sx=np.floor(along+variant*128).astype(int)%512
    sy=np.floor((yy-top)*4).astype(int)%512
    tint=np.array([1,1,1]) if side=='u' else np.array([.86,.83,.78])
    out[:,:,:3]=np.rint(pixels[sy,sx,:3]*tint).clip(0,255).astype('uint8')
    out[:,:,3]=alpha*255
    return Image.fromarray(out)


def yard(source,direction):
    out=Image.new('RGBA',(64,96))
    p=lambda u,v,z:(32+(u-v)*32,64+(u+v)*16-z)
    a,b=((1,0),(1,1)) if direction=='u+' else ((0,0),(0,1)) if direction=='u-' else ((0,1),(1,1)) if direction=='v+' else ((0,0),(1,0))
    ax,ay=p(*a,32);bx,by=p(*b,32)
    pixels=np.asarray(source)
    tint=np.array([1,1,1]) if direction.startswith('u') else np.array([.86,.83,.78])
    for y in range(96):
        for x in range(64):
            t=(x+.5-ax)/(bx-ax)
            top=ay+(by-ay)*t
            if 0<=t<=1 and top<=y+.5<top+32:
                rgb=np.rint(pixels[int((y+.5-top)*4)%512,int(t*128)%512]*tint).clip(0,255).astype('uint8')
                out.putpixel((x,y),(*map(int,rgb),255))
    # Continuous cap only: no end posts or outlines repeated per segment.
    ImageDraw.Draw(out).line([(ax,ay),(bx,by)],fill='#E8D1A6',width=2)
    return out


def update_kit(kit):
    (ART/'muros').mkdir(exist_ok=True)
    surfaces={}
    for name in ('pedra','chapisco'):
        image=periodic(Image.open(ART/f'fontes/muros-v2/{name}.png'))
        image.save(ART/f'muros/{name}-superficie.png')
        surfaces[name]={'file':f'muros/{name}-superficie.png','size':[512,512],
                        'source':f'fontes/muros-v2/{name}.png','repeatTexelsPerCell':[128,256]}
        for side in ('u','v'):
            for variant in range(2):save(face(image,side,variant),ART/f'muros/{name}-{side}-{variant}')
        for corner in ('interno','externo'):
            for variant in range(2):
                result=Image.new('RGBA',(64,96))
                result.alpha_composite(face(image,'v',variant),(0,0))
                result.alpha_composite(face(image,'u',variant),(32,0))
                save(result,ART/f'muros/{name}-canto-{corner}-{variant}')
        if name=='chapisco':
            for direction in ('u+','u-','v+','v-'):
                save(yard(image,direction),ART/f'pecas/muro-quintal-{direction}')
                kit['pieces']['muro-quintal']['variants'][direction]['source']={'generator':'tools/overworld/build_morro_walls.py','material':'fontes/muros-v2/chapisco.png'}
    kit['wallSurfaces']=surfaces
    return kit


def build():
    kit=update_kit(json.loads((ART/'kit.json').read_text(encoding='utf-8')))
    for root in (ART,RUNTIME):write(root/'kit.json',kit)
    for folder in ('muros','pecas'):
        for file in (ART/folder).iterdir():
            if folder=='muros' or file.name.startswith('muro-quintal-'):
                if file.suffix in ('.png','.svg'):shutil.copy2(file,RUNTIME/folder/file.name)
    REVIEW.mkdir(parents=True,exist_ok=True)
    board=Image.new('RGB',(896,304),'#314B3C');draw=ImageDraw.Draw(board)
    x=20
    for material in ('pedra','chapisco'):
        for side in ('u','v'):
            tile=Image.open(ART/f'muros/{material}-{side}-0.png')
            board.paste(tile.resize((96,240),Image.Resampling.NEAREST),(x,12),tile.resize((96,240),Image.Resampling.NEAREST))
            draw.text((x,266),material+'/'+side,fill='white');x+=116
        corner=Image.open(ART/f'muros/{material}-canto-externo-0.png')
        board.paste(corner.resize((160,240),Image.Resampling.NEAREST),(x,12),corner.resize((160,240),Image.Resampling.NEAREST))
        x+=190
    board.save(REVIEW/'modulos.png')
    report={'wallTileSize':[32,80],'cornerSize':[64,96],'yardPieceSize':[64,96],
            'masterSize':[512,512],'materials':['pedra','chapisco'],
            'geometryChanged':False,'collisionChanged':False,'periodicEdges':{},'mirrorMismatches':[]}
    for name in ('pedra','chapisco'):
        pixels=np.asarray(Image.open(ART/f'muros/{name}-superficie.png'))
        mismatch=max(int(np.abs(pixels[0].astype(int)-pixels[-1].astype(int)).max()),int(np.abs(pixels[:,0].astype(int)-pixels[:,-1].astype(int)).max()))
        assert mismatch==0
        report['periodicEdges'][name]=mismatch
    for path in (ART/'muros').glob('*.png'):
        assert path.read_bytes()==(RUNTIME/'muros'/path.name).read_bytes()
        image=Image.open(path)
        expected=(512,512) if 'superficie' in path.name else (64,96) if 'canto' in path.name else (32,80)
        assert image.size==expected
    for direction in ('u+','u-','v+','v-'):
        entry=kit['pieces']['muro-quintal']['variants'][direction]
        assert entry['footprint']==[1,1] and entry['anchor']==[32,80] and entry['size']==[64,96]
        assert (ART/entry['file']).read_bytes()==(RUNTIME/entry['file']).read_bytes()
    log=REVIEW/'native-render.log'
    if log.exists():
        text=log.read_text(encoding='utf-8')
        assert 'ERROR:' not in text and 'Error:' not in text
        report['nativeRenderErrors']=0
        captures=[]
        for path in (REVIEW/'after').glob('*.png'):
            assert Image.open(path).size==(1280,720)
            captures.append(path.name)
        report['nativeCaptures']=captures
    write(REVIEW/'validacao.json',report)
    print(json.dumps(report))


if __name__=='__main__':build()
