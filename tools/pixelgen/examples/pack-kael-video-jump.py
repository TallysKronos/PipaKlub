"""One-shot jump poses from local H3; fixed walk scale/palette, explicit source roots."""
import json
import subprocess
import runpy
from pathlib import Path
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'art/characters/kael-video-jump-v1'
FFMPEG=ROOT/'tmp/video-encoder/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe'
W,H=96,112
TIMES={
    'SE':[0,.4583,.75,1.5,1.5833,1.625,1.7083,1.8333,2.5,3.0833,3.2083,3.2917,3.375,3.75,4.1667,4.5],
    'NE':[0,.4583,.75,1.8333,1.9167,1.9583,2,2.0833,2.5,3.75,3.9167,4.0833,4.1667,4.2083,4.25,4.5]}
DURATIONS=[30,30,30,30,60,60,60,60,60,60,60,60,60,50,50,60]

def key(image):
    out=image.convert('RGBA')
    out.putdata([(r,g,b,0 if (r>g+65 and b>g+55) or (g>r+65 and g>b+65) else 255) for r,g,b,a in out.getdata()])
    return out

def main():
    target=OUT/'pacote';target.mkdir(parents=True,exist_ok=True)
    base=json.loads((ROOT/'art/characters/kael-video-eight-directions-v1/pacote/kael-eight.pixelgen.json').read_text(encoding='utf8'))
    palette=base['palette'];colors=[tuple(c[:3]) for c in palette[1:]]
    pal=Image.new('P',(1,1));flat=[v for c in colors for v in c];pal.putpalette(flat+list(colors[0])*(256-len(colors)))
    lookup={tuple(c):i+1 for i,c in enumerate(colors)}
    scale=json.loads((ROOT/'art/characters/kael-video-eight-directions-v1/pacote/manifest.json').read_text())['alignment']['scale']
    frames=[];natives=[];records=[]
    cleanup=runpy.run_path(str(Path(__file__).with_name('clean-kael-jump.py')))
    for direction in ['SE','NE']:
        videos=list((OUT/'video-original'/direction).glob('*.mp4'))
        if len(videos)!=1:raise ValueError(f'Exactly one reviewed video per view: {direction}')
        source=OUT/'selecoes'/direction;source.mkdir(parents=True,exist_ok=True)
        for i,t in enumerate(TIMES[direction]):
            path=source/f'{i:02d}.png'
            subprocess.run([str(FFMPEG),'-v','error','-y','-ss',str(t),'-i',str(videos[0]),'-frames:v','1',str(path)],check=True)
            im=key(Image.open(path));bounds=im.getchannel('A').getbbox()
            if bounds is None:raise ValueError('Empty pose')
            # Only translation varies, never scale. Runtime supplies the actual flight arc.
            # Lowest visible sole is the explicit local root for these selected poses.
            root=(256,bounds[3]);native=Image.new('RGBA',(W,H))
            resized=im.resize((round(512*scale),round(512*scale)),Image.Resampling.NEAREST)
            native.paste(resized,(round(W//2-root[0]*scale),round(H-2-root[1]*scale)))
            quant=native.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).convert('RGB')
            indices=[lookup.get(rgb,1) if a else 0 for rgb,a in zip(quant.getdata(),native.getchannel('A').getdata())]
            indices,clean_report=cleanup['clean'](indices,cleanup['REGIONS'][len(frames)])
            rgba=Image.new('RGBA',(W,H));rgba.putdata([tuple(palette[v]) for v in indices])
            box=rgba.getchannel('A').getbbox()
            if not box or box[0]==0 or box[1]==0 or box[2]==W or box[3]==H:raise ValueError(f'Clipped {direction}/{i}: {box}')
            frame={'name':f'jump-{direction}-{i+1}','duration':DURATIONS[i],'indices':indices,'cels':[indices]}
            frames.append(frame);natives.append(rgba)
            records.append({'direction':direction,'timestamp':t,'root':root,'bounds':bounds,'video':str(videos[0].relative_to(OUT)),'cleanup':clean_report})
    project={k:base[k] for k in ['kind','version','palette','layers']}
    project.update(name='Kael · salto de barranco · vídeo',width=W,height=H,cols=16,rows=2,frames=frames,
        settings={'width':W,'height':H,'cols':16,'rows':2,'margin':2,'colors':len(palette)-1},
        sequences=[{'name':'jump-'+d,'start':i*16,'end':i*16+15,'loop':False,'direction':'forward'} for i,d in enumerate(['SE','NE'])])
    (target/'kael-jump.pixelgen.json').write_text(json.dumps(project,ensure_ascii=False),encoding='utf8')
    sheet=Image.new('RGBA',(W*16,H*2))
    board=Image.new('RGB',(W*16*2,H*2*2+40),'#eee8da');draw=ImageDraw.Draw(board)
    for i,im in enumerate(natives):
        x=i%16*W;y=i//16*H;sheet.paste(im,(x,y));zoom=im.resize((W*2,H*2),Image.Resampling.NEAREST)
        board.paste(zoom,(x*2,y*2+20*(i//16+1)),zoom);draw.text((x*2+4,y*2+20*(i//16+1)-15),str(i%16+1),fill='#172437')
    sheet.save(target/'kael-jump.png');board.save(target/'revisao.png')
    preview=[]
    for j in range(16):
        panel=Image.new('RGB',(400,360),'#152338')
        for row in range(2):
            im=natives[row*16+j].resize((192,288),Image.Resampling.NEAREST)
            panel.paste(im,(row*200,40),im)
        preview.append(panel)
    preview[0].save(target/'salto.gif',save_all=True,append_images=preview[1:],duration=DURATIONS,loop=0,disposal=2)
    manifest={'cell':[W,H],'pivot':[W//2,H-2],'frames':32,'directions':['SE','NE'],'loop':False,'durationMs':sum(DURATIONS),'scale':scale,
        'paletteSharedWithWalk':True,'rootPolicy':'fixed source x=256; selected sole baseline; translation only, runtime owns arc',
        'cleanup':{'version':1,'policy':'../cleanup/policy.json','pantsBaseIndex':6,'pantsShadowIndex':19,'outlineIndex':31,'detachedIslandMaxPixels':2},
        'records':records,'status':'video-derived pixel draft; inspect timing, soles and anatomy at game scale'}
    (target/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
    runtime=ROOT/'godot/assets/kael-video';runtime.mkdir(parents=True,exist_ok=True)
    sheet.save(runtime/'kael-jump.png')
    (runtime/'kael-walk-eight.png').write_bytes((ROOT/'art/characters/kael-video-eight-directions-v1/pacote/kael-walk-eight.png').read_bytes())
    (runtime/'jump.json').write_text(json.dumps({'framesPerDirection':16,'durationMs':sum(DURATIONS),'durationsMs':DURATIONS,'cell':[W,H],'pivot':[W//2,H-2],'loop':False}),encoding='utf8')
    print(json.dumps({'frames':32,'durationMs':sum(DURATIONS),'scale':scale,'out':str(target)}))

if __name__=='__main__':main()
