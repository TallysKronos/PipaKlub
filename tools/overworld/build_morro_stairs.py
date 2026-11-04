"""Exact 2:1 stone-stair derivatives from the approved floor/wall materials."""
import json
import shutil
import numpy as np
from PIL import Image
from build_morro_walls import ART, RUNTIME, save
from build_morro_floors import write


def quad(canvas, points, uv, texture, tint=(1,1,1)):
    pixels=np.asarray(texture.convert('RGB'))
    width,height=canvas.size
    output=np.asarray(canvas).copy()
    for indices in ((0,1,2),(0,2,3)):
        p=np.asarray([points[i] for i in indices],dtype=float)
        matrix=np.column_stack((p[1]-p[0],p[2]-p[0]))
        if abs(np.linalg.det(matrix))<1e-8:continue
        x0=max(0,int(np.floor(p[:,0].min())));x1=min(width,int(np.ceil(p[:,0].max())))
        y0=max(0,int(np.floor(p[:,1].min())));y1=min(height,int(np.ceil(p[:,1].max())))
        yy,xx=np.meshgrid(np.arange(y0,y1)+.5,np.arange(x0,x1)+.5,indexing='ij')
        weights=np.stack((xx-p[0,0],yy-p[0,1]),axis=-1)@np.linalg.inv(matrix).T
        inside=(weights[:,:,0]>=-1e-7)&(weights[:,:,1]>=-1e-7)&(weights.sum(axis=2)<=1+1e-7)
        tex=np.asarray([uv[i] for i in indices],dtype=float)
        coords=tex[0]+weights[:,:,0,None]*(tex[1]-tex[0])+weights[:,:,1,None]*(tex[2]-tex[0])
        sx=np.floor(coords[:,:,0]).astype(int)%pixels.shape[1]
        sy=np.floor(coords[:,:,1]).astype(int)%pixels.shape[0]
        sample=np.rint(pixels[sy,sx]*np.array(tint)).clip(0,255).astype('uint8')
        target=output[y0:y1,x0:x1]
        target[inside,:3]=sample[inside]
        target[inside,3]=255
    return Image.fromarray(output)


def update_kit(kit):
    paving=Image.open(ART/'chao/superficies-atlas.png').crop((512,0,1024,512))
    stone=Image.open(ART/'muros/pedra-superficie.png')
    for direction in ('u+','u-','v+','v-'):
        fu,fv=(1,2) if direction[0]=='u' else (2,1)
        image=Image.new('RGBA',((fu+fv)*32,(fu+fv)*16+64))
        project=lambda point,z:((fv+point[0]-point[1])*32,64+(point[0]+point[1])*16-z)
        parts=[]
        across_u=direction.startswith('v')
        for step in range(8):
            t=step/8;n=(step+1)/8;z=(step+1)*8
            if direction=='u+':q=[(t,0),(n,0),(n,2),(t,2)]
            elif direction=='u-':q=[(1-n,0),(1-t,0),(1-t,2),(1-n,2)]
            elif direction=='v+':q=[(0,t),(2,t),(2,n),(0,n)]
            else:q=[(0,1-n),(2,1-n),(2,1-t),(0,1-t)]
            parts.append((sum(u+v for u,v in q)/4,[project(p,z) for p in q],[(u*64,v*64) for u,v in q],paving,(1,1,1)))
            edge=[q[0],q[3]] if direction=='u+' else [q[1],q[2]] if direction=='u-' else [q[0],q[1]] if direction=='v+' else [q[2],q[3]]
            flanks=[[q[0],q[1]],[q[3],q[2]]] if not across_u else [[q[0],q[3]],[q[1],q[2]]]
            for side,bottom,along_u,offset in [(edge,z-8,across_u,.0001)]+[(f,0,not across_u,-.0001) for f in flanks]:
                a,b=side
                ua=(a[0] if along_u else a[1])*128;ub=(b[0] if along_u else b[1])*128
                points=[project(a,z),project(b,z),project(b,bottom),project(a,bottom)]
                uv=[(ua,-z*4),(ub,-z*4),(ub,-bottom*4),(ua,-bottom*4)]
                parts.append(((sum(a)+sum(b))*.5+offset,points,uv,stone,(.86,.83,.78) if along_u else (1,1,1)))
        back=[(fu,0),(fu,fv)] if direction=='u+' else [(0,0),(0,fv)] if direction=='u-' else [(0,fv),(fu,fv)] if direction=='v+' else [(0,0),(fu,0)]
        a,b=back;ua=(a[0] if across_u else a[1])*128;ub=(b[0] if across_u else b[1])*128
        parts.append(((sum(a)+sum(b))*.5+.0002,[project(a,64),project(b,64),project(b,0),project(a,0)],[(ua,-256),(ub,-256),(ub,0),(ua,0)],stone,(.86,.83,.78) if across_u else (1,1,1)))
        for _,points,uv,texture,tint in sorted(parts,key=lambda part:part[0]):image=quad(image,points,uv,texture,tint)
        save(image,ART/f'escadas/{direction}')
        entry=kit['stairs'][direction]
        entry['renderer']='projected-stone-steps'
        entry['source']={'generator':'tools/overworld/build_morro_stairs.py','materials':['chao/superficies-atlas.png','muros/pedra-superficie.png']}
    return kit


def build():
    kit=update_kit(json.loads((ART/'kit.json').read_text(encoding='utf-8')))
    for root in (ART,RUNTIME):write(root/'kit.json',kit)
    for file in (ART/'escadas').iterdir():
        if file.suffix in ('.png','.svg'):shutil.copy2(file,RUNTIME/'escadas'/file.name)
    print('Stone stair derivatives: four directions, same footprints, eight risers, rise 64px')


if __name__=='__main__':build()
