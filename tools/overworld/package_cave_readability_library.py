"""Compose source/native review boards and archive the cave visual library."""
from pathlib import Path
import json,zipfile,shutil
import numpy as np
from PIL import Image,ImageDraw,ImageOps
from build_urban_library import font,write
ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/overworld/kits/cavernas-v3'
REVIEW=ROOT/'documentation/overworld/cavernas-v3'

def main():
    manifest=json.loads((ART/'library.json').read_text(encoding='utf-8'))
    board=Image.new('RGB',(1600,1030),'#19262D');d=ImageDraw.Draw(board)
    d.text((25,18),'GRUTA DOS ELOS · HIERARQUIA E COR · V3',font=font(35),fill='#E6D8B3')
    d.text((25,68),'Arte fonte · silhuetas preservadas, famílias de materiais distintas',font=font(22),fill='#9CB7C3')
    for i,(id,info) in enumerate(manifest['props'].items()):
        x=(i%4)*400;y=120+(i//4)*435
        im=Image.open(ART/f'fontes/{id}.png').convert('RGBA');im=im.crop(im.getbbox());im.thumbnail((340,330),Image.Resampling.LANCZOS)
        board.paste(im,(x+(400-im.width)//2,y+330-im.height),im)
        d.text((x+24,y+352),info['name'],font=font(25),fill='#E6D8B3')
    board.save(REVIEW/'IDENTIDADE-FLAT.png')
    comparison=Image.new('RGB',(1920,1210),'#19262D');cd=ImageDraw.Draw(comparison)
    cd.text((20,8),'SEPARAÇÃO VISUAL · CAPTURAS NATIVAS',font=font(32),fill='#E6D8B3')
    for column,version in enumerate(['cavernas-v2','cavernas-v3']):
        native=Image.open(ROOT/f'documentation/overworld/{version}/nativo/gruta-inundada-1280x720.png').convert('RGB')
        gray=ImageOps.grayscale(native)
        if column==1:gray.save(REVIEW/'GRUTA-ESCALA-DE-CINZA.png')
        cd.text((20+column*960,55),'ANTES · V2' if column==0 else 'DEPOIS · V3',font=font(25),fill='#E6D8B3')
        comparison.paste(native.resize((960,540),Image.Resampling.LANCZOS),(column*960,95))
        comparison.paste(gray.convert('RGB').resize((960,540),Image.Resampling.LANCZOS),(column*960,660))
    comparison.save(REVIEW/'ANTES-DEPOIS-COR-E-CINZA.png')
    pool_review=REVIEW/'revisao-poco'
    if (pool_review/'antes-1280x720.png').exists():
        before=Image.open(pool_review/'antes-1280x720.png').convert('RGB')
        after=Image.open(REVIEW/'nativo/gruta-inundada-1280x720.png').convert('RGB')
        pool_board=Image.new('RGB',(1920,650),'#19262D');pd=ImageDraw.Draw(pool_board)
        pd.text((20,10),'POÇO · RECORTE DO SOLO, MARGEM E COTA INFERIOR',font=font(31),fill='#E6D8B3')
        for i,(im,title) in enumerate([(before,'ANTES · mesma cota'),(after,'DEPOIS · água 24 px abaixo do solo')]):
            pd.text((20+i*960,62),title,font=font(24),fill='#E6D8B3')
            pool_board.paste(im.resize((960,540),Image.Resampling.LANCZOS),(i*960,105))
        pool_board.save(pool_review/'ANTES-DEPOIS-POCO.png')
        detail=after.crop((695,185,980,460)).resize((855,825),Image.Resampling.NEAREST)
        detail.save(pool_review/'DETALHE-MARGEM-E-IMPACTO.png')
    # Source measurements describe the paintings, not gameplay accessibility scores.
    values=[]
    specs=json.loads((ART/'briefs.json').read_text(encoding='utf-8'))['assets']
    for spec in specs:
        if spec['kind'] not in ['floor','wall','prop']:continue
        src=np.asarray(Image.open(ART/f"fontes/{spec['id']}.png").convert('RGBA'))
        y=src[:,:,:3]@np.array([.2126,.7152,.0722]);valid=src[:,:,3]>240
        values.append({'id':spec['id'],'role':spec['kind'],'opaquePixelMedianLuma':round(float(np.median(y[valid])),2)})
    write(REVIEW/'valores-das-fontes.json',{'note':'Source-image luminance on opaque pixels; visual hierarchy also reviewed in native grayscale captures. Not a UI contrast conformance claim.','paintings':values})
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
    for src,dest in [('cavernas-v3-import.log','godot-import.log'),('cavernas-v3-native.log','godot-native.log')]:shutil.copy2(ROOT/'tmp'/src,REVIEW/dest)
    archive=REVIEW/'gruta-dos-elos-v3-godot.zip'
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for folder in ['godot/assets/overworld/kits/cavernas-v3','godot/assets/overworld/kits/aguas-v1','godot/scenes/overworld/caves-v3']:
            for p in (ROOT/folder).rglob('*'):
                if p.is_file() and p.suffix!='.import':z.write(p,p.relative_to(ROOT))
        for folder,names in [('godot/scripts/overworld',['water_patch.gd','waterfall.gd','water_effect.gd','cave_water.gd','cave_waterfall.gd','cave_basin.gd','cave_wind.gd','cave_ground.gd']),('godot/shaders/overworld',['water_surface.gdshader','water_fall.gdshader','water_foam.gdshader','cave_floor.gdshader','cave_prop_outline.gdshader','cave_basin_water.gdshader','cave_wind_paper.gdshader','cave_ground_blend.gdshader','terrain_transition.gdshaderinc'])]:
            for name in names:
                p=ROOT/folder/name;z.write(p,p.relative_to(ROOT));uid=Path(str(p)+'.uid')
                if uid.exists():z.write(uid,uid.relative_to(ROOT))
        z.write(ART/'README.md','README.md');z.write(ART/'DIRECAO-VISUAL.md','DIRECAO-VISUAL.md')
    print(json.dumps(report,indent=2));print('ZIP bytes: '+str(archive.stat().st_size))

if __name__=='__main__':main()
