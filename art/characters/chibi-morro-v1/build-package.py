"""Read generated originals and package measured atlas metadata. No pixel edits."""
import hashlib
import json
import statistics
import zipfile
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent
DIRECTIONS = ['south', 'west', 'east', 'north']
NAMES = {'sr-assis':'Sr. Assis','zeca':'Zeca','bia':'Bia','juninho':'Juninho','lia':'Lia','tiao':'Tião'}
manifest = {'version':1,'tool':'built-in image_gen','kind':'overworld-chibi','columns':4,'rows':2,'directions':DIRECTIONS,'characters':{}}
reports = []
for identifier,name in NAMES.items():
    filename = identifier + ('-v2.png' if identifier in ['sr-assis','juninho'] else '.png')
    path = ROOT/'sheets'/filename
    with Image.open(path) as im:
        assert im.mode == 'RGBA'
        width,height = im.size
        assert im.getchannel('A').getextrema() == (0,255)
        alpha = im.getchannel('A')
        search = range(round(height*.47),round(height*.56))
        blank = [y for y in search if not alpha.crop((0,y,width,y+1)).point(lambda a:255 if a>96 else 0).getbbox()]
        runs=[]
        for y in blank:
            if not runs or y!=runs[-1][-1]+1:runs.append([])
            runs[-1].append(y)
        gap=max(runs,key=len)
        split=gap[len(gap)//2]
        xs=[round(i*width/4) for i in range(5)]
        ys=[0,split,height]
        frames=[]
        checks=[]
        hashes=[]
        for idx in range(8):
            c,r=idx%4,idx//4
            x,y=xs[c],ys[r]
            w,h=xs[c+1]-x,ys[r+1]-y
            tile=im.crop((x,y,x+w,y+h))
            mask=tile.getchannel('A').point(lambda a:255 if a>96 else 0)
            b=mask.getbbox()
            assert b
            margin=min(b[0],b[1],w-b[2],h-b[3])
            assert margin>=4,(identifier,idx,margin)
            bounds={'x':b[0],'y':b[1],'w':b[2]-b[0],'h':b[3]-b[1]}
            frames.append({'x':x,'y':y,'w':w,'h':h,'bounds':bounds,'direction':DIRECTIONS[c],'pose':'idle' if r==0 else 'step','footAnchor':{'x':round((b[0]+b[2])/2,2),'y':b[3]}})
            hashes.append(hashlib.sha256(tile.tobytes()).hexdigest())
            checks.append({'frame':idx,'margin':margin,'bounds':bounds})
        assert len(set(hashes))==8
        reference_height=statistics.median(f['bounds']['h'] for f in frames[:4])
        actor={'name':name,'image':'sheets/'+filename,'directions':DIRECTIONS,'frames':frames,'size':{'w':width,'h':height},'referenceHeight':reference_height,'animations':{d:{'idle':[i],'walk':[i,i+4],'durations':[170,170],'loop':True} for i,d in enumerate(DIRECTIONS)},'status':'art-v1-animation-review'}
        manifest['characters'][identifier]=actor
        (ROOT/(identifier+'.json')).write_text(json.dumps(actor,ensure_ascii=False,indent=2),encoding='utf-8')
        reports.append({'id':identifier,'size':[width,height],'format':'RGBA','transparent':True,'frameCount':8,'uniqueFrames':len(set(hashes)),'alphaThreshold':96,'rowSplit':split,'minimumMargin':min(c['margin'] for c in checks),'geometryPassed':True,'checks':checks,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'visualReview':{'identity':'Chibi silhouette, clothes, colors and four directions inspected.','limitations':['Minor thin color fringes remain on some contours.','Reel hand/occlusion is simplified and sometimes changes across views; review before close-up use.','Two-pose walk matches Kael overworld contract; this is not a full four-step walk cycle.']}})
manifest.update(characterCount=6,frameCount=48)
for filename,value in [('atlas.json',manifest),('validation.json',reports)]:
    (ROOT/filename).write_text(json.dumps(value,ensure_ascii=False,indent=2),encoding='utf-8')
(ROOT/'atlas-data.js').write_text('window.CHIBI_ATLAS = '+json.dumps(manifest,ensure_ascii=False)+';\n',encoding='utf-8')
with zipfile.ZipFile(ROOT/'chibi-professor-morro-v1.zip','w',zipfile.ZIP_DEFLATED) as archive:
    for p in ROOT.rglob('*'):
        selected_pngs={v['image'] for v in manifest['characters'].values()}
        if p.is_file() and p.suffix in ['.png','.json','.html','.js','.md'] and (p.suffix!='.png' or p.relative_to(ROOT).as_posix() in selected_pngs):
            archive.write(p,p.relative_to(ROOT))
print(json.dumps({'characters':6,'frames':48,'geometryPassed':all(r['geometryPassed'] for r in reports),'margins':{r['id']:r['minimumMargin'] for r in reports},'zip':str(ROOT/'chibi-professor-morro-v1.zip')},ensure_ascii=False))
