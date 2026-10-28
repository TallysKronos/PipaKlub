"""Compose source/native review boards and archive the cave visual library."""
from pathlib import Path
import json,zipfile,shutil
import numpy as np
from PIL import Image,ImageDraw
from build_urban_library import font,write
ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/overworld/kits/cavernas-v2'
REVIEW=ROOT/'documentation/overworld/cavernas-v2'

def main():
    manifest=json.loads((ART/'library.json').read_text(encoding='utf-8'))
    board=Image.new('RGB',(1600,1030),'#19262D');d=ImageDraw.Draw(board)
    d.text((25,18),'GRUTA DOS ELOS · IDENTIDADE 2D FLAT',font=font(35),fill='#E6D8B3')
    d.text((25,68),'Arte fonte ampliada · dobras, linhas e nós na forma dos materiais',font=font(22),fill='#9CB7C3')
    for i,(id,info) in enumerate(manifest['props'].items()):
        x=(i%4)*400;y=120+(i//4)*435
        im=Image.open(ART/f'fontes/{id}.png').convert('RGBA');im=im.crop(im.getbbox());im.thumbnail((340,330),Image.Resampling.LANCZOS)
        board.paste(im,(x+(400-im.width)//2,y+330-im.height),im)
        d.text((x+24,y+352),info['name'],font=font(25),fill='#E6D8B3')
    board.save(REVIEW/'IDENTIDADE-FLAT.png')
    sources=sorted((REVIEW/'nativo').glob('*1280x720.png'))
    sheet=Image.new('RGB',(1280,60+180*((len(sources)+3)//4)),'#19262D');d=ImageDraw.Draw(sheet)
    d.text((20,10),'REVISÃO NATIVA · GODOT · 1280×720',font=font(28),fill='#E6D8B3')
    for i,p in enumerate(sources):sheet.paste(Image.open(p).convert('RGB').resize((320,180),Image.Resampling.LANCZOS),((i%4)*320,60+(i//4)*180))
    sheet.save(REVIEW/'AUDITORIA-NATIVA.png')
    frames=[Image.open(p).convert('RGB') for p in sorted((REVIEW/'nativo/frames').glob('gruta-*.png'))]
    if len(frames)!=48:raise ValueError('Expected 48 captured frames')
    end=np.asarray(Image.open(REVIEW/'nativo/gruta-loop-final.png').convert('RGB')).astype(int)
    first=np.asarray(frames[0]).astype(int);diff=abs(first-end)
    motion=abs(first-np.asarray(frames[12]).astype(int))
    report={'renderer':'Godot 4.7.2 native OpenGL','nativePages':len(sources),'resolution':[1280,720],'animationFrames':48,'loopSeconds':4,'loopMaximumChannelDifference':int(diff.max()),'loopMeanChannelDifference':float(diff.mean()),'quarterCycleChangedPixels':int(np.any(motion>2,axis=2).sum()),'savedScenesInstantiated':2,'campaignIntegrated':False,'gameplayTestsRun':False}
    write(REVIEW/'auditoria-animacao.json',report)
    small=[f.resize((960,540),Image.Resampling.LANCZOS) for f in frames]
    small[0].save(REVIEW/'GRUTA-ANIMADA.webp',save_all=True,append_images=small[1:],duration=[80,80,90]*16,loop=0,quality=85,method=4)
    palette=small[0].quantize(colors=256);gif=[f.quantize(palette=palette,dither=Image.Dither.NONE) for f in small]
    gif[0].save(REVIEW/'GRUTA-ANIMADA.gif',save_all=True,append_images=gif[1:],duration=[80,80,90]*16,loop=0,optimize=False,disposal=2)
    joint=Image.open(REVIEW/'nativo/gruta-inundada-1280x720.png').crop((820,185,980,410)).resize((480,675),Image.Resampling.NEAREST)
    joint.save(REVIEW/'JUNTA-CACHOEIRA.png')
    for src,dest in [('cavernas-v2-import.log','godot-import.log'),('cavernas-v2-native.log','godot-native.log')]:shutil.copy2(ROOT/'tmp'/src,REVIEW/dest)
    archive=REVIEW/'gruta-dos-elos-v2-godot.zip'
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for folder in ['godot/assets/overworld/kits/cavernas-v2','godot/assets/overworld/kits/aguas-v1','godot/scenes/overworld/caves-v2']:
            for p in (ROOT/folder).rglob('*'):
                if p.is_file() and p.suffix!='.import':z.write(p,p.relative_to(ROOT))
        for folder,names in [('godot/scripts/overworld',['water_patch.gd','waterfall.gd','water_effect.gd','cave_water.gd','cave_waterfall.gd']),('godot/shaders/overworld',['water_surface.gdshader','water_fall.gdshader','water_foam.gdshader','cave_floor.gdshader'])]:
            for name in names:
                p=ROOT/folder/name;z.write(p,p.relative_to(ROOT));uid=Path(str(p)+'.uid')
                if uid.exists():z.write(uid,uid.relative_to(ROOT))
        z.write(ART/'README.md','README.md');z.write(ART/'DIRECAO-VISUAL.md','DIRECAO-VISUAL.md')
    print(json.dumps(report,indent=2));print('ZIP bytes: '+str(archive.stat().st_size))

if __name__=='__main__':main()
