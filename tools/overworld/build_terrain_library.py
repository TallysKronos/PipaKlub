"""Generated materials -> exact modular geometry; no campaign changes.
Raster processing is periodic seam repair, UV projection, masks and atlas packing.
"""
from pathlib import Path
import json,math,shutil
import numpy as np
from PIL import Image,ImageDraw
from build_urban_library import write,font

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/overworld/kits/terrenos-v1'
RUNTIME=ROOT/'godot/assets/overworld/kits/terrenos-v1'
REVIEW=ROOT/'documentation/overworld/terrenos-v1'
NEIGHBORS=[(0,-1),(1,-1),(1,0),(1,1),(0,1),(-1,1),(-1,0),(-1,-1)]

def canonical(mask):
    for diagonal,a,b in [(1,0,2),(3,2,4),(5,4,6),(7,6,0)]:
        if not (mask&(1<<a) and mask&(1<<b)):mask &= ~(1<<diagonal)
    return mask
MASKS=sorted(set(canonical(i) for i in range(256)))

def port_report():
    yy,xx=np.meshgrid(np.arange(64)+.5,np.arange(64)+.5,indexing='ij')
    ports={m:shape(m,xx,yy) for m in MASKS};pairs=set()
    for bits in range(1<<16):
        def occupied(x,y):return bool(bits&(1<<(y*4+x)))
        if not occupied(1,1) or not occupied(2,1):continue
        a=canonical(sum(1<<i for i,(dx,dy) in enumerate(NEIGHBORS) if occupied(1+dx,1+dy)))
        b=canonical(sum(1<<i for i,(dx,dy) in enumerate(NEIGHBORS) if occupied(2+dx,1+dy)))
        pairs.add((a,b))
    errors=[(a,b) for a,b in pairs if not np.array_equal(ports[a][:,-1],ports[b][:,0])]
    return {'canonicalStates':len(MASKS),'consistentHorizontalPairs':len(pairs),'edgePortMismatches':errors,
            'note':'Rotationally symmetric geometry; horizontal port audit covers rotated edges. Raster/layout review still required.'}

def periodic(im,size):
    p=np.asarray(im.convert('RGB').resize((size,size),Image.Resampling.LANCZOS),dtype=float)
    v=np.zeros_like(p);v[0]=p[-1]-p[0];v[-1]=-v[0];d=p[:,-1]-p[:,0];v[:,0]+=d;v[:,-1]-=d
    yy,xx=np.meshgrid(np.arange(size),np.arange(size),indexing='ij')
    den=2*np.cos(2*np.pi*xx/size)+2*np.cos(2*np.pi*yy/size)-4;den[0,0]=1
    s=np.fft.fft2(v,axes=(0,1))/den[:,:,None];s[0,0]=0;p-=np.fft.ifft2(s,axes=(0,1)).real
    # Exact opposite boundary texels, with a soft correction collar.
    for axis in [0,1]:
        a=np.moveaxis(p,axis,0)
        for i in range(4):
            w=(1-i/4)*.5;left=a[i].copy();right=a[-1-i].copy();a[i]=left*(1-w)+right*w;a[-1-i]=right*(1-w)+left*w
    return np.clip(np.rint(p),0,255).astype('uint8')

def variants(im,pattern_lock=False):
    large=im.convert('RGB').resize((512,512),Image.Resampling.LANCZOS)
    base=periodic(large,64);yy,xx=np.meshgrid(np.arange(64),np.arange(64),indexing='ij')
    weight=np.clip(np.minimum.reduce([xx,yy,63-xx,63-yy])/10,0,1)[:,:,None]
    result=[base]
    # Shared texture phase at the boundary; only the interior varies.
    for i in range(1,8):
        x=(i*83)%384;y=(i*137)%384
        sample=np.asarray(large.crop((x,y,x+128,y+128)).resize((64,64),Image.Resampling.LANCZOS),dtype=float)
        sample+=base.mean(axis=(0,1))-sample.mean(axis=(0,1))
        if pattern_lock:
            # Manufactured grout/board patterns keep their exact phase and scale.
            # Only a faint material variation from the source enters the centre.
            sample=base.astype(float)+(sample-sample.mean(axis=(0,1)))*.10
        result.append(np.clip(np.rint(base*(1-weight)+sample*weight),0,255).astype('uint8'))
    return result

def shape(mask,x,y):
    inside=np.ones_like(x,dtype=bool)
    # Four quadrants. Missing diagonal makes a concave corner; two absent sides
    # make a convex rounded corner. Thin strips and isolated cells are included.
    for sx,sy,a,b,d in [(-1,-1,6,0,7),(1,-1,2,0,1),(1,1,2,4,3),(-1,1,6,4,5)]:
        region=((x<32) if sx<0 else (x>=32))&((y<32) if sy<0 else (y>=32))
        u=x if sx<0 else 64-x;v=y if sy<0 else 64-y
        pa=bool(mask&(1<<a));pb=bool(mask&(1<<b));pd=bool(mask&(1<<d))
        keep=np.ones_like(x,dtype=bool)
        if not pa:keep &= u>=6
        if not pb:keep &= v>=6
        if not pa and not pb:keep &= ~((u<18)&(v<18))|((u-18)**2+(v-18)**2<=12**2)
        # Concave radius equals the missing-side inset: adjacent edge ports agree.
        if pa and pb and not pd:keep &= u*u+v*v>=6**2
        inside[region]=keep[region]
    return inside

def project(rgb,mask=255):
    yy,xx=np.meshgrid(np.arange(32)+.5,np.arange(64)+.5,indexing='ij')
    u=xx/64+yy/32-.5;v=yy/32-xx/64+.5
    diamond=(u>=0)&(u<1)&(v>=0)&(v<1)
    x=np.floor(u*64).astype(int)%64;y=np.floor(v*64).astype(int)%64
    alpha=diamond&shape(mask,u*64,v*64)
    return Image.fromarray(np.dstack([rgb[y,x],alpha.astype('uint8')*255]))

def paint_quad(canvas,points,texture,tint=1.0,uv=(0,0,128,256)):
    arr=np.asarray(canvas).copy();h,w=arr.shape[:2]
    a,b,_,d=np.array(points,dtype=float);matrix=np.column_stack([b-a,d-a]);inv=np.linalg.inv(matrix)
    yy,xx=np.meshgrid(np.arange(h)+.5,np.arange(w)+.5,indexing='ij');local=np.stack([xx-a[0],yy-a[1]],axis=-1)@inv.T
    u,v=local[:,:,0],local[:,:,1];inside=(u>=0)&(u<1)&(v>=0)&(v<1)
    sx=np.floor(uv[0]+u*uv[2]).astype(int)%texture.shape[1];sy=np.floor(uv[1]+v*uv[3]).astype(int)%texture.shape[0]
    arr[inside,:3]=np.clip(texture[sy[inside],sx[inside]]*tint,0,255).astype('uint8');arr[inside,3]=255
    return Image.fromarray(arr)

def panel(texture,side,phase=0):
    im=Image.new('RGBA',(32,80));a=(0,16) if side=='u' else (0,0);b=(32,0) if side=='u' else (32,16)
    return paint_quad(im,[a,b,(b[0],b[1]+64),(a[0],a[1]+64)],texture,1 if side=='u' else .86,(phase*128,0,128,256))

def corner(texture,inner,phase):
    im=Image.new('RGBA',(64,96))
    if inner:
        im.alpha_composite(panel(texture,'u',phase),(0,0));im.alpha_composite(panel(texture,'v',phase),(32,0))
    else:
        im.alpha_composite(panel(texture,'v',phase),(0,16));im.alpha_composite(panel(texture,'u',phase),(32,16))
    return im

def termination(texture,side,end):
    a=np.array((4,18) if side=='u' else (4,2),float);b=a+np.array((32,-16) if side=='u' else (32,16))
    normal=np.array((4,2) if side=='u' else (-4,2));down=np.array((0,64));im=Image.new('RGBA',(40,84))
    at=b if end else a
    im=paint_quad(im,[at,at+normal,at+normal+down,at+down],texture,.72,(0,0,16,256))
    im=paint_quad(im,[a,b,b+normal,a+normal],texture,1.08,(0,0,128,16))
    return paint_quad(im,[a,b,b+down,a+down],texture,1 if side=='u' else .86)

def save(im,relative):
    dest=ART/relative;dest.parent.mkdir(parents=True,exist_ok=True);im.save(dest)
    target=RUNTIME/relative;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dest,target)

def mosaic(tiles,layout,bg=None):
    h=len(layout);w=len(layout[0]);im=Image.new('RGBA',((w+h)*32+32,(w+h)*16+32),'#B6B4A1')
    for y,row in enumerate(layout):
        for x,solid in enumerate(row):
            px=(x-y)*32+h*32;py=(x+y)*16
            if bg is not None:im.alpha_composite(bg,(px,py))
            if solid:
                m=sum((1<<i) for i,(dx,dy) in enumerate(NEIGHBORS) if 0<=y+dy<h and 0<=x+dx<w and layout[y+dy][x+dx])
                im.alpha_composite(tiles[canonical(m)],(px,py))
    return im

def build():
    specs=json.loads((ART/'briefs.json').read_text(encoding='utf-8-sig'))['assets']
    manifest={'schema':'terrain-library-1','grid':[64,32],'levelPx':64,'campaignIntegrated':False,'approval':'pending_owner_review',
              'maskOrder':['N','NE','E','SE','S','SW','W','NW'],'canonicalMasks':MASKS,'floors':{},'walls':{}}
    REVIEW.mkdir(parents=True,exist_ok=True);report=[]
    geometry=port_report();write(REVIEW/'geometria-encaixes.json',geometry)
    if geometry['edgePortMismatches']:raise ValueError('Inconsistent geometry ports: '+str(geometry['edgePortMismatches'][:8]))
    grass_bg=project(variants(Image.open(ART/'fontes/grama-campo.png'))[0])
    earth_bg=project(variants(Image.open(ART/'fontes/terra-ocre.png'))[0])
    for s in specs:
        original=Image.open(ART/f"fontes/{s['id']}.png").convert('RGB')
        id=s['id'];kind=s['kind'];surface=periodic(original,512);save(Image.fromarray(surface),f'superficies/{id}.png')
        if kind=='floor':
            textures=variants(original,pattern_lock=id not in ['grama-campo','grama-seca','grama-musgo','terra-ocre','terra-vermelha','areia-clara','cascalho','barro-umido'])
            tiles={m:project(textures[0],m) for m in MASKS};files=[]
            atlas=Image.new('RGBA',(512,224))
            for i,m in enumerate(MASKS):
                file=f'pisos/{id}/blob-{m:03d}.png';save(tiles[m],file);atlas.alpha_composite(tiles[m],((i%8)*64,(i//8)*32));files.append({'mask':m,'file':file,'atlas':[i%8,i//8]})
            centers=[]
            for i,rgb in enumerate(textures):
                file=f'pisos/{id}/centro-{i}.png';tile=project(rgb);save(tile,file);atlas.alpha_composite(tile,(i*64,192));centers.append({'file':file,'atlas':[i,6]})
            save(atlas,f'atlas/{id}.png')
            manifest['floors'][id]={'name':s['name'],'atlas':f'atlas/{id}.png','surface':f'superficies/{id}.png','tiles':files,'centers':centers,
                 'size':[64,32],'terrainMode':'corners-and-sides','outsideTerrain':-1,'source':f'fontes/{id}.png','geometry':'flat-overlay-not-height','shadowBaked':False}
            repeat=Image.new('RGBA',(64*8,32*8))
            # Both orthographic UV repeat and diamond arrangement are retained.
            uv=Image.new('RGB',(512,512))
            for y in range(8):
                for x in range(8):uv.paste(Image.fromarray(textures[(x*3+y*5)%8]),(x*64,y*64))
            uv.save(REVIEW/f'{id}-repeticao-8x8.png')
            shape_layout=[[int(1<=x<=8 and 1<=y<=8 and not (x>=5 and y>=5) and not (x==3 and y==3)) for x in range(10)] for y in range(10)]
            mosaic(tiles,shape_layout,earth_bg if id.startswith('grama') else grass_bg).save(REVIEW/f'{id}-encaixes.png')
            report.append({'id':id,'blobStates':len(tiles),'centers':len(centers),'centerCoverage':int(np.count_nonzero(np.asarray(project(textures[0]))[:,:,3])),
                           'oppositeEdgeError':int(np.abs(textures[0][0].astype(int)-textures[0][-1].astype(int)).max())})
        else:
            files=[]
            for side in ['u','v']:
                for phase in range(4):
                    file=f'paredes/{id}/{side}-{phase}.png';save(panel(surface,side,phase),file);files.append({'file':file,'role':'continuous-face','side':side,'phase':phase})
            for inner in [False,True]:
                for phase in range(2):
                    file=f'paredes/{id}/canto-{"interno" if inner else "externo"}-{phase}.png';save(corner(surface,inner,phase),file);files.append({'file':file,'role':'inner-corner' if inner else 'outer-corner'})
            for side in ['u','v']:
                for end in [False,True]:
                    file=f'paredes/{id}/{side}-{"fim" if end else "inicio"}.png';save(termination(surface,side,end),file);files.append({'file':file,'role':'end-cap','side':side})
            manifest['walls'][id]={'name':s['name'],'source':f'fontes/{id}.png','surface':f'superficies/{id}.png','files':files,'height':64,'phaseOrder':[0,1,2,3],
                                  'note':'Continuous world UV recommended; isolated corner pieces are geometry examples, not an automatic elevation solver.'}
    write(ART/'library.json',manifest);write(RUNTIME/'library.json',manifest);write(REVIEW/'preparacao.json',report)
    boards(manifest)
    print(f'{len(manifest["floors"])} floors ×55 + {len(manifest["walls"])} walls ×16 = 1512 modular cutouts. Sources retained.')

def boards(manifest):
    board=Image.new('RGB',(1920,1440),'#ECDFC1');d=ImageDraw.Draw(board)
    for i,(id,item) in enumerate(manifest['floors'].items()):
        im=Image.open(REVIEW/f'{id}-encaixes.png').convert('RGBA');im.thumbnail((300,235),Image.Resampling.LANCZOS)
        x=i%6*320;y=i//6*360;board.paste(im,(x+(320-im.width)//2,y+35),im)
        d.text((x+12,y+278),item['name'],font=font(20),fill='#23394A')
        d.text((x+12,y+312),'47 encaixes + 8 centros',font=font(16),fill='#56645A')
    board.save(REVIEW/'CATALOGO-24-PISOS.png')
    board=Image.new('RGB',(1680,1050),'#ECDFC1');d=ImageDraw.Draw(board)
    for i,(id,item) in enumerate(manifest['walls'].items()):
        x=i%4*420;y=i//4*350
        for j,file in enumerate([f'paredes/{id}/canto-externo-0.png',f'paredes/{id}/canto-interno-0.png',f'paredes/{id}/u-fim.png']):
            im=Image.open(ART/file).convert('RGBA');im=im.resize((im.width*2,im.height*2),Image.Resampling.NEAREST)
            board.paste(im,(x+15+j*135,y+35),im)
        d.text((x+15,y+260),item['name'],font=font(21),fill='#23394A')
        d.text((x+15,y+295),'Faces · cantos · terminações',font=font(17),fill='#56645A')
    board.save(REVIEW/'CATALOGO-12-PAREDES.png')
    # Technical chart: all masks visibly distinct and labelled, like the supplied sketch.
    sample=next(iter(manifest['floors'].values()));chart=Image.new('RGB',(1024,768),'#ECDFC1');d=ImageDraw.Draw(chart)
    d.text((20,12),'47 ESTADOS · BORDAS, CANTOS, CORREDORES E ILHAS',font=font(25),fill='#23394A')
    for i,entry in enumerate(sample['tiles']):
        im=Image.open(ART/entry['file']).convert('RGBA').resize((112,56),Image.Resampling.NEAREST)
        x=i%8*128;y=70+i//8*112;chart.paste(im,(x+8,y),im)
        d.text((x+20,y+65),f"máscara {entry['mask']:03d}",font=font(15),fill='#23394A')
    chart.save(REVIEW/'GUIA-47-ENCAIXES.png')

if __name__=='__main__':build()
