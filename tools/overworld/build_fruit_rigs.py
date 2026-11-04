"""Slice separately authored parts; assemble editable Soulgen tree rigs.
No pixel painting/inpainting. Sources and original concepts are preserved.
"""
from pathlib import Path
import base64, json, math, shutil
from PIL import Image, ImageChops
from build_urban_library import write

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/overworld/kits/frutiferas'
RIG=ROOT/'art/soulgen/keys/arvores-frutiferas'
RUNTIME=ROOT/'godot/assets/overworld/kits/frutiferas'

def split_source(path):
    im=Image.open(path).convert('RGBA')
    if im.getchannel('A').getextrema()[0]!=0:raise ValueError('Opaque parts sheet: '+str(path))
    im.putalpha(im.getchannel('A').point(lambda a:0 if a<100 else a))
    # Alpha-connected components allow overlapping X ranges without slicing a branch.
    # Keep the three main authored parts, discarding isolated generated haze/specks.
    alpha=im.getchannel('A');width,height=im.size
    remaining=bytearray(1 if a>=100 else 0 for a in alpha.tobytes());components=[]
    for seed in range(len(remaining)):
        if not remaining[seed]:continue
        remaining[seed]=0;stack=[seed];pixels=[]
        while stack:
            at=stack.pop();pixels.append(at);x=at%width
            for q in ((at-1 if x else -1),(at+1 if x<width-1 else -1),at-width,at+width):
                if 0<=q<len(remaining) and remaining[q]:remaining[q]=0;stack.append(q)
        if len(pixels)>100:components.append(pixels)
    components=sorted(components,key=len,reverse=True)[:3]
    if len(components)!=3:raise ValueError('Expected 3 separate painted parts: '+str(path))
    components.sort(key=lambda p:sum(at%width for at in p)/len(p))
    parts=[];bounds=[]
    for pixels in components:
        mask=bytearray(width*height)
        for at in pixels:mask[at]=255
        layer=im.copy();layer.putalpha(ImageChops.multiply(alpha,Image.frombytes('L',im.size,bytes(mask))))
        b=layer.getchannel('A').getbbox()
        parts.append(layer.crop(b));bounds.append([b[0],b[1],b[2]-b[0],b[3]-b[1]])
    return parts,bounds

def fit(im,w,h):
    scale=min(w/im.width,h/im.height)
    return [round(im.width*scale,3),round(im.height*scale,3)]

def ident(**kw):return dict(x=0,y=0,rotation=0,scaleX=1,scaleY=1,**kw)

def build():
    specs=json.loads((ART/'briefs.json').read_text(encoding='utf-8-sig'))['assets']
    records=[]
    for s in specs:
        id=s['id'];directory=RIG/id;directory.mkdir(parents=True,exist_ok=True)
        pieces,bounds=split_source(ART/f'fontes/articuladas/{id}.png')
        assets={}
        for key,im in zip(['trunk','canopy','fruit'],pieces):
            # Uniform downsample only; editable layer sources remain up to 768 px.
            if max(im.size)>768:
                f=768/max(im.size);im=im.resize((round(im.width*f),round(im.height*f)),Image.Resampling.LANCZOS)
            im.save(directory/(key+'.png'))
            assets[key]={'src':f'/art/soulgen/keys/arvores-frutiferas/{id}/{key}.png','width':im.width,'height':im.height,'name':key}
        h=s['height'];w=320;cx=w/2;top=24;base=top+h
        palm=id=='coqueiro';banana=id=='bananeira'
        cw,ch=fit(pieces[1],(sum(s['visualFootprint'])*32-8),h*(.49 if palm else .65))
        tw,th=fit(pieces[0],cw*(.9 if palm else .5 if banana else .59),h*(.70 if palm else .69))
        # Crown overlaps the upper trunk; generous painted branches remain concealed.
        trunk_rect=[cx-tw/2,base-th,tw,th]
        crown_rect=[cx-cw/2,top,cw,ch]
        pivot=[cx,top+ch*.78]
        crown_anchor=[.5,.78]
        if palm:
            # The curved trunk's top is left of its root. Attach the leaf-stem hub
            # to an actual opaque cross-section of the neck, not the image centre.
            neck_y=.075
            row_y=round((pieces[0].height-1)*neck_y)
            row=pieces[0].getchannel('A').crop((0,row_y,pieces[0].width,row_y+1)).getbbox()
            neck_x=(row[0]+row[2])*.5/pieces[0].width
            pivot=[trunk_rect[0]+neck_x*tw,trunk_rect[1]+neck_y*th]
            crown_anchor=[.49,.72]
            crown_rect=[pivot[0]-crown_anchor[0]*cw,pivot[1]-crown_anchor[1]*ch,cw,ch]
        fw,fh=fit(pieces[2],10 if palm else 5.5 if id=='jabuticabeira' else 17,12 if palm else 6 if id=='jabuticabeira' else 20)
        parts=[{'id':'trunk','name':'Tronco e raízes — base fixa','asset':'trunk','source':[0,0,assets['trunk']['width'],assets['trunk']['height']],
                'rect':trunk_rect,'pivot':[cx,base],'z':0,'parent':None,'visible':True},
               {'id':'canopy','name':'Copa — balanço','asset':'canopy','source':[0,0,assets['canopy']['width'],assets['canopy']['height']],
                'rect':crown_rect,'pivot':pivot,'z':1,'parent':'trunk','visible':True}]
        if id=='jabuticabeira':
            # Small irregular clusters seated on bark, never a vertical row of berries.
            positions=[(.23,0),(.48,3),(.78,5),(.32,8),(.68,12),(.45,15),(.28,21),(.61,24),
                       (.76,27),(.40,30),(.62,33),(.24,38),(.52,41),(.74,44),(.38,48),(.65,51)]
        elif palm:positions=[(-6,-2),(3,1),(-1,8)]
        elif banana:positions=[(.08,.49)]
        else:positions=[(-.22,.40),(.21,.47),(-.04,.59),(.30,.30)]
        for i,(px,py) in enumerate(positions):
            x=cx+px*cw;y=top+py*ch
            if palm:x,y=pivot[0]+px,pivot[1]+py
            if id=='jabuticabeira':
                y=top+ch-1+py
                # Position each cauliflorous fruit on actual bark alpha at that row.
                local_y=max(0,min(pieces[0].height-1,round((y-trunk_rect[1])*pieces[0].height/th)))
                row=pieces[0].getchannel('A').crop((0,local_y,pieces[0].width,local_y+1))
                painted=[j for j,a in enumerate(row.tobytes()) if a>=200]
                x=trunk_rect[0]+(painted[round((len(painted)-1)*px)] if painted else pieces[0].width*.5)*tw/pieces[0].width
            parts.append({'id':f'fruit{i+1}','name':f'Fruto {i+1} — destacável','asset':'fruit','source':[0,0,assets['fruit']['width'],assets['fruit']['height']],
                          'rect':[x-fw/2,y,fw,fh],'pivot':[x,y],'z':2+i,'parent':'trunk' if id=='jabuticabeira' else 'canopy','visible':True})
        def frame(t,angle=0,fruit=None):
            values={'root':ident(),'trunk':ident(),'canopy':{**ident(),'rotation':angle}}
            for q in parts[2:]:values[q['id']]=ident()
            if fruit:values['fruit1'].update(fruit)
            return {'t':t,'ease':'smooth','values':values}
        fallen=base-parts[2]['rect'][1]-fh
        clips={
          'idle':{'seconds':3.2,'loop':True,'frames':[frame(0),frame(.8,1.25),frame(1.6),frame(2.4,-1.25),frame(3.2)]},
          'hit':{'seconds':1.2,'loop':False,'hitTime':.14,'frames':[frame(0),frame(.08,-6),frame(.18,8),frame(.34,-4),frame(.56,2),frame(.8,-.7),frame(1.2)]},
          'drop':{'seconds':1.6,'loop':False,'hitTime':.14,'frames':[frame(0),frame(.14,7),frame(.32,-4,{'x':7,'y':18,'rotation':25}),
                   frame(.62,2,{'x':18,'y':fallen,'rotation':65}),frame(.75,-1,{'x':22,'y':fallen-9,'rotation':77}),
                   frame(.95,0,{'x':25,'y':fallen,'rotation':85}),frame(1.6,0,{'x':25,'y':fallen,'rotation':85})]}}
        p={'schema':'soulgen-studio','version':1,'name':s['name']+' · árvore articulada','width':w,'height':base+48,
           'rootPivot':[cx,base],'assets':assets,'parts':parts,'clips':clips,
           'brief':{'species':s['name'],'personality':'Cenário vivo e interativo','kiteAnatomy':'Não é criatura: árvore com tronco fixo, copa articulada e frutos destacados.',
                    'view':'Overworld isométrico','notes':'idle: brisa; hit: reação sem queda; drop: estudo visual de queda de um fruto. Runtime usa evento separado e esgota frutos visíveis.'},
           'environment':{'kind':'fruit-tree','species':id,'rootContact':[cx,base],'trunkCollision':[1,1],
                          'harvestAttachment':'trunk' if id=='jabuticabeira' else 'canopy','dropTime':.14,'cropBounds':bounds,
                          'jointStatus':'requires_visual_extremes_review'}}
        # The canopy pivot must remain seated in the fixed trunk during all clips.
        ratio=cw/tw
        p['anatomy']={'version':1,'ratios':[{'part':'canopy','relativeTo':'trunk','min':round(ratio*.9,3),'max':round(ratio*1.1,3),'label':'Copa/tronco aprovado para esta espécie'}],
                      'behind':[{'part':'trunk','other':'canopy'}],
                      'joints':[{'part':'canopy','parent':'trunk','anchor':crown_anchor,
                                 'socket':[(pivot[0]-trunk_rect[0])/tw,(pivot[1]-trunk_rect[1])/th],'maxGap':.5}],
                      'notes':'Frutos não têm junta permanente: o clip drop demonstra desprendimento intencional.'}
        write(directory/(id+'.soulgen.json'),p)
        portable=json.loads(json.dumps(p))
        for key,a in portable['assets'].items():a['src']='data:image/png;base64,'+base64.b64encode((directory/(key+'.png')).read_bytes()).decode()
        write(directory/(id+'.portable.soulgen.json'),portable)
        runtime=RUNTIME/'rigs'/id;runtime.mkdir(parents=True,exist_ok=True)
        for key in assets:shutil.copy2(directory/(key+'.png'),runtime/(key+'.png'))
        write(runtime/'rig.json',p)
        records.append({'id':id,'name':s['name'],'project':str((directory/(id+'.soulgen.json')).relative_to(ROOT)).replace('\\','/'),
                        'portable':str((directory/(id+'.portable.soulgen.json')).relative_to(ROOT)).replace('\\','/'),
                        'runtime':f'res://assets/overworld/kits/frutiferas/rigs/{id}/rig.json','sourceBounds':bounds})
    write(ART/'rigs.json',records)
    print('12 Soulgen rigs, 36 cutout parts, portable projects and Godot rig definitions.')

if __name__=='__main__':build()
