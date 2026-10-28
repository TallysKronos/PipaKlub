"""Package reusable resources and animation evidence; never modifies campaign."""
from pathlib import Path
import json,zipfile,shutil
import numpy as np
from PIL import Image,ImageDraw
from build_urban_library import font,write
ROOT=Path(__file__).resolve().parents[2]
REVIEW=ROOT/'documentation/overworld/aguas-v1'

def main():
    report={'renderer':'Godot 4.7.2 native OpenGL','captureSize':[1280,720],'framesPerLoop':48,'loopSeconds':4,'campaignIntegrated':False,'animations':[]}
    for stem,name in [('agua','AGUA-ANIMADA'),('cachoeiras','CACHOEIRAS-ANIMADAS')]:
        frames=[Image.open(p).convert('RGB') for p in sorted((REVIEW/'nativo/frames').glob(stem+'-*.png'))]
        if len(frames)!=48:raise ValueError('Expected 48 native frames, got '+str(len(frames)))
        end=np.asarray(Image.open(REVIEW/f'nativo/{stem}-loop-final.png').convert('RGB')).astype(int)
        first=np.asarray(frames[0]).astype(int)
        diff=np.abs(first-end)
        motion=np.abs(first-np.asarray(frames[12]).astype(int))
        report['animations'].append({'id':stem,'loopBoundaryMaximumChannelDifference':int(diff.max()),'loopBoundaryMeanChannelDifference':float(diff.mean()),'quarterCycleChangedPixels':int(np.any(motion>2,axis=2).sum())})
        small=[f.resize((960,540),Image.Resampling.LANCZOS) for f in frames]
        small[0].save(REVIEW/f'{name}.webp',save_all=True,append_images=small[1:],duration=[80,80,90]*16,loop=0,quality=85,method=4)
        palette=small[0].quantize(colors=256)
        gif=[f.quantize(palette=palette,dither=Image.Dither.NONE) for f in small]
        gif[0].save(REVIEW/f'{name}.gif',save_all=True,append_images=gif[1:],duration=[80,80,90]*16,loop=0,optimize=False,disposal=2)
    sheet=Image.new('RGB',(1280,810),'#193B3D');d=ImageDraw.Draw(sheet)
    d.text((24,12),'ÁGUAS VIVAS · AUDITORIA NO GODOT',font=font(30),fill='#EAD6AA')
    for i,name in enumerate(['01-seis-aguas-1280x720','02-rios-1280x720','03-cachoeiras-1280x720','04-efeitos-1280x720']):
        im=Image.open(REVIEW/f'nativo/{name}.png').resize((620,349),Image.Resampling.LANCZOS)
        sheet.paste(im,(10+(i%2)*640,70+(i//2)*365))
    sheet.save(REVIEW/'AUDITORIA-NATIVA.png')
    # Magnified native joints remain unobscured by props or vegetation.
    im=Image.open(REVIEW/'nativo/03-cachoeiras-1280x720.png')
    crops=[im.crop((100,210,240,390)),im.crop((915,185,1040,420))]
    joint=Image.new('RGB',(760,590),'#193B3D');jd=ImageDraw.Draw(joint)
    jd.text((16,10),'LÁBIO E IMPACTO · CAPTURA NATIVA',font=font(27),fill='#EAD6AA')
    for i,crop in enumerate(crops):
        crop.thumbnail((340,480),Image.Resampling.NEAREST)
        factor=min(340/crop.width,480/crop.height)
        crop=crop.resize((round(crop.width*factor),round(crop.height*factor)),Image.Resampling.NEAREST)
        joint.paste(crop,(30+i*370,70))
    joint.save(REVIEW/'DETALHES-DAS-QUEDAS.png')
    for src,target in [('aguas-import.log','godot-import.log'),('aguas-native.log','godot-native.log')]:
        shutil.copy2(ROOT/'tmp'/src,REVIEW/target)
    write(REVIEW/'auditoria-animacao.json',report)
    output=REVIEW/'aguas-animadas-v1-godot.zip'
    with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED) as z:
        for folder in ['godot/assets/overworld/kits/aguas-v1','godot/scenes/overworld/water']:
            for p in (ROOT/folder).rglob('*'):
                if p.is_file() and p.suffix!='.import':z.write(p,p.relative_to(ROOT))
        for folder,names in [('godot/scripts/overworld',['water_patch.gd','waterfall.gd','water_effect.gd']),('godot/shaders/overworld',['water_surface.gdshader','water_fall.gdshader','water_foam.gdshader'])]:
            for name in names:
                p=ROOT/folder/name;z.write(p,p.relative_to(ROOT))
                uid=Path(str(p)+'.uid')
                if uid.exists():z.write(uid,uid.relative_to(ROOT))
        z.write(ROOT/'art/overworld/kits/aguas-v1/README.md','README.md')
    print(json.dumps(report,ensure_ascii=False,indent=2));print('ZIP: '+str(output.stat().st_size))

if __name__=='__main__':main()
