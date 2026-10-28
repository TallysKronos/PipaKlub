from pathlib import Path
import json,re,shutil,zipfile
from PIL import Image,ImageDraw,ImageFont

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'documentation/overworld/cais-v1'

def main():
    font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',22)
    board=Image.new('RGB',(1280,800),'#20343E');draw=ImageDraw.Draw(board)
    for i,(name,label) in enumerate([('escada-central-1280x720','ESCADA CENTRAL'),('escada-praia-1280x720','ACESSO À PRAIA'),('torre-1280x720','TORRE E ANDARES'),('geometria-1280x960','GEOMETRIA SEM DECORAÇÃO')]):
        x=(i%2)*640;y=(i//2)*400
        im=Image.open(OUT/f'{name}.png').convert('RGB')
        im.thumbnail((640,360),Image.Resampling.LANCZOS)
        board.paste(im,(x+(640-im.width)//2,y+40))
        draw.text((x+16,y+10),label,font=font,fill='#EEDFB6')
    board.save(OUT/'DETALHES-ESTRUTURA.png')
    comparison=Image.new('RGB',(1856,924),'#20343E');draw=ImageDraw.Draw(comparison)
    for i,(name,label) in enumerate([('referencia-cais.png','REFERÊNCIA FORNECIDA'),('cais-1280x960.png','RECONSTRUÇÃO NO GODOT · ARTE MANGÁ')]):
        im=Image.open(OUT/name).convert('RGB');im.thumbnail((928,860),Image.Resampling.LANCZOS)
        comparison.paste(im,(928*i+(928-im.width)//2,64+(860-im.height)//2))
        draw.text((928*i+20,20),label,font=font,fill='#EEDFB6')
    comparison.save(OUT/'REFERENCIA-E-RECONSTRUCAO.png')
    layout=json.loads((OUT/'layout.json').read_text())
    routes=json.loads((OUT/'percurso-da-sonda.json').read_text())
    points=[p for value in routes.values() if isinstance(value,dict) for p in value['observations']]
    report={'nativeResolutions':[[1280,960],[1280,720]],'surfaceCount':len(layout['surfaces']),'stairFlights':sum('steps' in s for s in layout['surfaces']),'stairRisers':sum(s.get('steps',0) for s in layout['surfaces']),'supportElevationsPx':sorted(set(s['height'] for s in layout['surfaces'])),'reviewedProbeTargets':len(points),'reachedProbeTargets':sum(p['arrived'] for p in points),'separateLowerAndUpperSurfaceIds':True,'campaignIntegrated':False,'projectTestSuitesRun':False,'scope':'isolated geometry, visual capture and local support/movement probe'}
    report['visibility']=layout.get('orderingReview',{})
    report['corrections']=layout.get('corrections',{})
    walkthrough=OUT/'jogavel/percurso.json'
    if walkthrough.exists():
        play=json.loads(walkthrough.read_text(encoding='utf-8'))
        report['playableTraversal']={'scene':'godot/scenes/overworld/pier/cais-jogavel.tscn','destinations':len(play['observations']),'reached':sum(p['arrived'] for p in play['observations']),'miranteCompleted':play['finished'],'depthAtlasSize':play['depthAtlasSize'],'campaignSaveUsed':False}
        proof=Image.new('RGB',(1280,800),'#20343E');labels=ImageDraw.Draw(proof)
        for i,(name,label) in enumerate([('01-desembarque','KAEL E RABBITO · DESEMBARQUE'),('03-sob-o-deck','PASSAGEM SOB O DECK'),('08-patamar-alto','ESCADAS E PATAMARES'),('07-mirante','CHEGADA AO MIRANTE')]):
            x=(i%2)*640;y=(i//2)*400
            im=Image.open(OUT/'jogavel'/f'{name}.png').convert('RGB').resize((640,360),Image.Resampling.LANCZOS)
            proof.paste(im,(x,y+40));labels.text((x+14,y+10),label,font=font,fill='#EEDFB6')
        proof.save(OUT/'jogavel/TRAVESSIA-NATIVA.png')
        shutil.copy2(ROOT/'tmp/pier-play-native.log',OUT/'jogavel/pier-play-native.log')
    (OUT/'auditoria.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    for name in ['pier-import.log','pier-native.log']:shutil.copy2(ROOT/'tmp'/name,OUT/name)
    pending=[ROOT/'godot/scenes/overworld/pier/cais-dos-elos.tscn',ROOT/'godot/tools/pier_preview.gd',ROOT/'godot/scenes/overworld/pier/cais-jogavel.tscn',ROOT/'godot/tools/pier_play_preview.gd'];included=set()
    while pending:
        path=pending.pop()
        if path in included:continue
        included.add(path)
        if path.suffix in ['.gd','.tscn','.tres','.gdshader','.gdshaderinc']:
            for rel in re.findall(r'res://([^"\s]+\.(?:gdshaderinc|gdshader|png|tscn|tres|gd))(?=["\s])',path.read_text(encoding='utf-8-sig')):pending.append(ROOT/'godot'/rel)
    for path in (ROOT/'godot/assets/overworld/kits/cais-v1').rglob('*'):
        if path.is_file() and path.suffix!='.import':included.add(path)
    # Dynamic avatar/skin paths are deliberately rooted in these asset families.
    for folder in ['godot/assets/kael','godot/assets/campaign/ui-recorte','godot/assets/campaign/ui-modern/fonts']:
        for path in (ROOT/folder).rglob('*'):
            if path.is_file() and path.suffix!='.import':included.add(path)
    for name in ['rabbito.png','rabbito.json']:included.add(ROOT/'godot/assets'/name)
    with zipfile.ZipFile(OUT/'cais-dos-elos-godot.zip','w',zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(included):archive.write(path,path.relative_to(ROOT))
        archive.write(OUT/'README.md','README.md')
        archive.writestr('godot/project.godot','config_version=5\n[application]\nconfig/name="Cais dos Elos · prévia independente"\nrun/main_scene="res://scenes/overworld/pier/cais-jogavel.tscn"\nconfig/features=PackedStringArray("4.7", "GL Compatibility")\n[display]\nwindow/size/viewport_width=1280\nwindow/size/viewport_height=720\nwindow/stretch/mode="canvas_items"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
    print(json.dumps(report,indent=2))

if __name__=='__main__':main()
