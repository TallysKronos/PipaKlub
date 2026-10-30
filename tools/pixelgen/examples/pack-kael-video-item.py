"""Build the front-facing receive-item gesture; motion comes from the local H3 clip.

The runtime uses real directional standing poses for the turn from any angle.
All selected video frames use one body scale, sole root, palette and material policy.
"""
import json
from pathlib import Path
import runpy
import subprocess
from PIL import Image,ImageDraw

ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'art/characters/kael-video-item-v1'
W,H=96,144
# One raising pose is deliberately reused in reverse for a readable hand-to-hip return.
TIMES=[.75,.9167,1,1.0417,1.0833,1.125,1.1667,1.3333,2,3,4,4.625,1,4.6667,4.8333,5]
DURATIONS=[80,80,65,65,65,65,90,110,180,220,220,120,90,80,80,100]

def main():
    target=OUT/'pacote';target.mkdir(parents=True,exist_ok=True)
    source=OUT/'selecoes';source.mkdir(exist_ok=True)
    base=json.loads((ROOT/'art/characters/kael-video-eight-directions-v1/pacote/kael-eight.pixelgen.json').read_text())
    palette=base['palette'];colors=[tuple(c[:3]) for c in palette[1:]]
    pal=Image.new('P',(1,1));pal.putpalette([v for c in colors for v in c]+list(colors[0])*(256-len(colors)))
    lookup={c:i+1 for i,c in enumerate(colors)}
    jump=runpy.run_path(str(Path(__file__).with_name('pack-kael-video-jump.py')))
    cleanup=runpy.run_path(str(Path(__file__).with_name('clean-kael-jump.py')))
    key=jump['key'];clean=cleanup['clean']
    video=next((OUT/'video-original').glob('*.mp4'))
    scale=.21634615384615385/(410/512)
    frames=[];images=[];records=[]
    for i,t in enumerate(TIMES):
        path=source/f'{i:02d}.png'
        subprocess.run([str(jump['FFMPEG']),'-v','error','-y','-ss',str(t),'-i',str(video),'-frames:v','1',str(path)],check=True)
        im=key(Image.open(path));box=im.getchannel('A').getbbox();root=(256,box[3])
        resized=im.resize((round(512*scale),round(512*scale)),Image.Resampling.NEAREST)
        native=Image.new('RGBA',(W,H));native.paste(resized,(round(W//2-root[0]*scale),round(H-2-root[1]*scale)))
        q=native.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).convert('RGB')
        indices=[lookup.get(rgb,1) if a else 0 for rgb,a in zip(q.getdata(),native.getchannel('A').getdata())]
        # Standing legs are stationary in this gesture. Keep their gray-blue material fixed.
        indices,report=clean(indices,[32,111,65,132],W,H)
        rgba=Image.new('RGBA',(W,H));rgba.putdata([tuple(palette[v]) for v in indices])
        bounds=rgba.getchannel('A').getbbox()
        assert bounds and bounds[0]>0 and bounds[1]>0 and bounds[2]<W and bounds[3]<H,(i,bounds)
        images.append(rgba)
        frames.append({'name':f'item-S-{i+1}','duration':DURATIONS[i],'indices':indices,'cels':[indices]})
        records.append({'time':t,'root':root,'bounds':bounds,'cleanup':report})
    project={'kind':'pixelgen','version':2,'name':'Kael · recebeu item · aponta para o céu','width':W,'height':H,'cols':16,'rows':1,
        'palette':palette,'layers':[{'name':'Kael item','visible':True,'locked':False}],'frames':frames,
        'settings':{'width':W,'height':H,'cols':16,'rows':1,'margin':2,'colors':32},
        'sequences':[{'name':'item-S','start':0,'end':15,'loop':False,'direction':'forward'}]}
    (target/'kael-item.pixelgen.json').write_text(json.dumps(project,ensure_ascii=False),encoding='utf8')
    sheet=Image.new('RGBA',(W*16,H))
    board=Image.new('RGB',(W*4*8,(H*4+24)*2),'#e9e2d4');draw=ImageDraw.Draw(board)
    gif=[]
    for i,im in enumerate(images):
        sheet.paste(im,(i*W,0));zoom=im.resize((W*4,H*4),Image.Resampling.NEAREST)
        x=i%8*W*4;y=i//8*(H*4+24);board.paste(zoom,(x,y+24),zoom);draw.text((x+8,y+5),f'{i+1} / {TIMES[i]:.3f}s',fill='#152339')
        panel=Image.new('RGB',(W*3,H*3),'#172438');up=im.resize(panel.size,Image.Resampling.NEAREST);panel.paste(up,(0,0),up);gif.append(panel)
    sheet.save(target/'kael-item.png');board.save(target/'revisao.png')
    gif[0].save(target/'item.gif',save_all=True,append_images=gif[1:],duration=DURATIONS,loop=0,disposal=2)
    metadata={'cell':[W,H],'pivot':[48,142],'durationsMs':DURATIONS,'durationMs':sum(DURATIONS),'turnMs':240,'loop':False}
    (target/'item.json').write_text(json.dumps(metadata,indent=2))
    (target/'manifest.json').write_text(json.dumps({'sourceVideo':str(video.relative_to(OUT)),'job':'70d5e310-a34d-45ad-b2f1-eb384fc10489',
        'scale':scale,'paletteSharedWithWalk':True,'materialPolicy':{'pantsRegion':[32,111,65,132],'base':6,'shadow':19,'ink':31},
        'records':records,'status':'motion and pixel study, native-scale visual review required'},indent=2))
    runtime=ROOT/'godot/assets/kael-video';sheet.save(runtime/'kael-item.png');(runtime/'item.json').write_text(json.dumps(metadata))
    print(json.dumps({'frames':16,'cell':[W,H],'poseMs':sum(DURATIONS),'totalWithTurnMs':sum(DURATIONS)+240}))

if __name__=='__main__':main()
