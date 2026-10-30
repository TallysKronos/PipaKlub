"""Select cycles from local run videos and emit palette-locked Aseprite grids.

Read-only raster processing. Source frames are extracted by ffmpeg; final pixel
art is drawn and exported by Aseprite. No per-frame fit or optical interpolation.
"""
from pathlib import Path
import argparse, importlib.util, json, subprocess, re, hashlib
from PIL import Image, ImageChops, ImageStat
ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'art/characters/kael-locomotion-v1'
DIRS=['s','sw','w','nw','n','ne','e','se']
spec=importlib.util.spec_from_file_location('video_sheet',ROOT/'tools/pixelgen/video-to-sheet.py')
video=importlib.util.module_from_spec(spec);spec.loader.exec_module(video)

def choose(direction):
    source=OUT/'video-original'/f'kael-run-{direction}.mp4'
    folder=ROOT/'tmp/kael-run-frames'/direction/hashlib.sha256(source.read_bytes()).hexdigest()[:12]
    folder.mkdir(parents=True,exist_ok=True)
    if len(list(folder.glob('*.png')))<124:
        subprocess.run([str(video.FFMPEG),'-hide_banner','-loglevel','error','-y','-i',str(OUT/'video-original'/f'kael-run-{direction}.mp4'),'-vf','fps=24','-frames:v','124',str(folder/'%03d.png')],check=True)
    files=sorted(folder.glob('*.png'))
    features=[];valid=[]
    for file in files:
        with Image.open(file) as image:
            image=video.key_image(image.resize((64,64),Image.Resampling.BOX))
            alpha=image.getchannel('A')
            border=[alpha.getpixel((x,y)) for y in range(64) for x in range(64) if x<2 or x>=62 or y<2 or y>=62]
            valid.append(sum(border)/(255*len(border))<.005)
            bg=Image.new('RGB',image.size);bg.paste(image,mask=image.getchannel('A'))
            features.append(bg)
    def diff(i,j):return sum(ImageStat.Stat(ImageChops.difference(features[i],features[j])).mean)/3
    best=None
    for start in range(12,len(files)-35):
        for length in range(12,29):
            end=start+length
            if end+1>=len(files)-6:continue
            if not all(valid[start-1:end+2]):continue
            score=sum(diff(start+k,end+k) for k in [-1,0,1])/3
            activity=diff(start,start+length//4)+diff(start,start+length//2)
            if activity<3:continue
            score+=abs(length-18)*.015
            if best is None or score<best[0]:best=(score,start,length)
    if not best:raise ValueError('No active loop: '+direction)
    score,start,length=best
    picks=[start+round(i*length/8) for i in range(8)]
    images=[video.key_image(Image.open(files[i])) for i in picks]
    boxes=[image.getchannel('A').getbbox() for image in images]
    # One transform for the entire clip: retain actual knee lift and flight.
    left=min(b[0] for b in boxes);right=max(b[2] for b in boxes)
    top=min(b[1] for b in boxes);bottom=max(b[3] for b in boxes)
    scale=min(86/(bottom-top),58/(right-left))
    width=round((right-left)*scale);height=round((bottom-top)*scale)
    palette=json.loads((OUT/'palette.json').read_text())
    colors=[tuple(bytes.fromhex(c[1:7])) for c in palette[1:]]
    cache={};grids=[]
    for image in images:
        image=image.crop((left,top,right,bottom)).resize((width,height),Image.Resampling.NEAREST)
        native=Image.new('RGBA',(64,96));native.paste(image,((64-width)//2,94-height))
        rows=[]
        for y in range(96):
            line=''
            for x in range(64):
                color=native.getpixel((x,y))
                if not color[3]:line+='.';continue
                rgb=color[:3]
                if rgb not in cache:cache[rgb]=min(range(len(colors)),key=lambda i:sum((rgb[k]-colors[i][k])**2 for k in range(3)))
                line+='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'[cache[rgb]]
            rows.append(line)
        grids.append(rows)
    record={'direction':direction,'frames':picks,'timestamps':[round(i/24,4) for i in picks],'sourceCycleMs':round(length/24*1000),'matchingScore':round(score,4),'crop':[left,top,right,bottom],'scale':scale,'offset':[(64-width)//2,94-height],'grids':grids}
    (OUT/'selections'/f'run-{direction}.json').write_text(json.dumps(record,indent=2))
    print(direction,picks,score)

def draw(frame,sprite,partial=False):
    palette=json.loads((OUT/'palette.json').read_text())
    legend={c:color for c,color in zip('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',palette[1:])}
    ops=[{'kind':'clear'}]
    for row,direction in enumerate(DIRS):
        if partial and not (OUT/'selections'/f'run-{direction}.json').exists():continue
        data=json.loads((OUT/'selections'/f'run-{direction}.json').read_text())
        for y,line in enumerate(data['grids'][frame-1]):
            for run in re.finditer(r'[^.]+',line):
                ops.append({'kind':'grid','x':run.start(),'y':row*96+y,'rows':[run.group()],'legend':{c:legend[c] for c in set(run.group())}})
    print(json.dumps({'sprite':sprite,'layer':'Corrida','frame':frame,'createCel':True,'paletteLock':True,'ops':ops},ensure_ascii=True))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--select',nargs='*');p.add_argument('--frame',type=int);p.add_argument('--sprite',default='#215');p.add_argument('--partial',action='store_true');a=p.parse_args()
    if a.select is not None:
        for direction in a.select or DIRS:choose(direction)
    if a.frame:draw(a.frame,a.sprite,a.partial)
