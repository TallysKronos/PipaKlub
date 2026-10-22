"""Measure Eremor's generated PNGs; preserve original image bytes."""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
PACK = ROOT / 'assets/creatures/eremor-v1'

def inspect(file, columns, rows, xs=None, ys=None):
    image = Image.open(file)
    assert image.mode == 'RGBA', 'PNG RGBA required'
    alpha = image.getchannel('A')
    assert alpha.getextrema()[0] == 0, 'Real transparent pixels required'
    width, height = image.size
    frames, checks = [], []
    for index in range(columns * rows):
        col, row = index % columns, index // columns
        x, right = (xs[col],xs[col+1]) if xs else (round(col * width / columns), round((col+1) * width / columns))
        y, bottom = (ys[row],ys[row+1]) if ys else (round(row * height / rows), round((row+1) * height / rows))
        a = alpha.crop((x,y,right,bottom))
        bounds = a.point(lambda value: 255 if value > 32 else 0).getbbox()
        assert bounds, ('empty cell',index)
        l,t,r,b = bounds
        margin = min(l,t,right-x-r,bottom-y-b)
        assert margin >= 8, ('unsafe cell margin',index,margin)
        frame = {'x':x,'y':y,'w':right-x,'h':bottom-y,
                 'bounds':{'x':l,'y':t,'w':r-l,'h':b-t},
                 'footAnchor':{'x':(l+r)/2,'y':b}}
        frames.append(frame)
        checks.append({'index':index,'margin':margin,'bounds':frame['bounds']})
    return frames, {'size':[width,height], 'alphaRange':alpha.getextrema(),
                    'alphaThreshold':32,'minimumMargin':min(c['margin'] for c in checks),
                    'sha256':hashlib.sha256(file.read_bytes()).hexdigest(),
                    'frames':checks,'geometryValid':True,
                    'animationApproval':'manual-review-required'}

def save(path, data):
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

if __name__ == '__main__':
    # Generated battle columns are not uniform. These measured crop boundaries
    # pass through transparent gutters, preserving all original pixels.
    battle, battle_report = inspect(PACK/'battle/eremor.png',4,4,
                                    xs=[0,350,642,950,1254],ys=[0,313,627,940,1254])
    world, world_report = inspect(PACK/'overworld/eremor.png',4,2)
    states={'idle':([0,1,2,3],[220,150,220,220],True),
            'flight':([4,5,6,7],[180,160,180,160],True),
            'skill':([8,9,10,11],[200,240,150,220],False),
            'hurt':([12,13],[160,240],False),'victory':([14,15],[400,500],True)}
    frames={}
    for state,(indexes,durations,loop) in states.items():
        for index,duration in zip(indexes,durations):
            f=battle[index];frames[f'eremor_{index:02}']={'frame':{k:f[k] for k in ['x','y','w','h']},
                'contentBounds':f['bounds'],'footAnchor':f['footAnchor'],
                'pivot':{'x':f['footAnchor']['x']/f['w'],'y':f['footAnchor']['y']/f['h']},
                'duration':duration,'state':state,'rotated':False,'trimmed':False,
                'sourceSize':{'w':f['w'],'h':f['h']}}
    atlas={'frames':frames,'animations':{s:[f'eremor_{i:02}' for i in data[0]] for s,data in states.items()},
           'playback':{s:{'durations':d[1],'loop':d[2],'returnTo':None if d[2] else 'idle'} for s,d in states.items()},
           'meta':{'image':'eremor.png','size':{'w':1254,'h':1254},'columns':4,'rows':4,
                   'uniformGrid':False,'referenceHeight':max(f['bounds']['h'] for f in battle),
                   'filter':'nearest','status':'preview-only-pending-art-review',
                   'renderContract':'measured rectangles; fixed scale; footAnchor alignment; do not divide sheet width by four'}}
    save(PACK/'battle/eremor.json',atlas)
    # The companion renderer consumes this actor schema directly, without a grant.
    actor = {'id':'eremor','name':'Eremor','image':'creatures/eremor-v1/overworld/eremor.png',
             'referenceHeight':max(f['bounds']['h'] for f in world),'scale':1.65,
             'frameMs':240,'frames':world,
             'animations':{'idle':[[0],[1],[2],[3]],'move':[[0,4],[1,5],[2,6],[3,7]]},
             'status':'preview-only-pending-art-review'}
    save(PACK/'overworld/manifest.json',{'version':1,'directions':['south','west','east','north'],
         'species':{'eremor':actor}})
    save(PACK/'validation.json',{'battle':battle_report,'overworld':world_report,
         'pixelEdits':False,'integrated':False,'battleUniformGrid':False,
         'battleCropBoundaries':[0,350,642,950,1254]})
    print(json.dumps({'battle':battle_report['size'],'overworld':world_report['size'],
                     'minimumMargins':[battle_report['minimumMargin'],world_report['minimumMargin']]}))
