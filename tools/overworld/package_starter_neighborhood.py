from pathlib import Path
import json,re,shutil,zipfile
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'documentation/overworld/bairro-inicial-v2'

def main():
    font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',22)
    for filename,items in [
        ('BAIRRO-NATIVO.png',[('casa-kael-1280x720','CASA DO KAEL · QUINTAL E VARANDA'),('jogavel/dialogo-assis','PROFESSOR · RUA ALTA'),('jogavel/dialogo-lia','LOJINHA · LINHA & PAPEL'),('escala-ponto-onibus-1280x720','PROPORÇÃO · KAEL, VEÍCULOS E ABRIGO')]),
        ('ESTRUTURA-E-ENCAIXES.png',[('escadaria-encaixes-1280x720','ESCADARIA E APOIOS'),('ladeira-1280x720','LADEIRA E BARRANCOS'),('rampa-baixa-1280x720','REBAIXO DA CALÇADA'),('geometria-1280x720','GEOMETRIA SEM PROPS')])]:
        board=Image.new('RGB',(1280,800),'#20343E');draw=ImageDraw.Draw(board)
        for i,(source,label) in enumerate(items):
            x=(i%2)*640;y=(i//2)*400
            image=Image.open(OUT/(source+'.png')).convert('RGB').resize((640,360),Image.Resampling.LANCZOS)
            board.paste(image,(x,y+40));draw.text((x+12,y+10),label,font=font,fill='#EEDFB6')
        board.save(OUT/filename)
    route=json.loads((OUT/'jogavel/percurso.json').read_text())
    layout=json.loads((OUT/'layout.json').read_text())
    report={'status':'local_playable_pending_art_approval','nativeResolution':[1280,720], 'streets':layout['roads'],'houses':len(layout['houses']),'npcConversations':list(route['greeted']),'parkedVehicles':3,'shortcutSteps':8,'elevationDifferencePx':48,'walkthroughDestinations':len(route['observations']),'walkthroughReached':sum(p['arrived'] for p in route['observations']),'campaignIntegrated':False,'projectTestSuitesRun':False,'visibility':layout['depth']}
    report['propScaleReview']=json.loads((OUT/'escala-urbana.json').read_text(encoding='utf-8'))
    report['walkthroughScope']='Historical walkthrough before current prop/collider and stair revisions; not repeated in this visual revision.'
    (OUT/'auditoria.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    for name in ['neighborhood-import.log','neighborhood-native.log','neighborhood-play-native.log']:
        shutil.copy2(ROOT/'tmp'/name,OUT/name)
    pending=[ROOT/'godot/scenes/overworld/neighborhood/bairro-jogavel.tscn',ROOT/'godot/tools/neighborhood_preview.gd',ROOT/'godot/tools/neighborhood_play_preview.gd'];included=set()
    while pending:
        path=pending.pop()
        if path in included:continue
        if not path.is_file():raise FileNotFoundError(path)
        included.add(path)
        if path.suffix in ['.gd','.tscn','.tres','.gdshader','.gdshaderinc']:
            for rel in re.findall(r'res://([^"\s]+\.(?:gdshaderinc|gdshader|png|svg|json|ttf|tscn|tres|gd))(?=["\s])',path.read_text(encoding='utf-8-sig')):
                pending.append(ROOT/'godot'/rel)
    for folder in ['godot/assets/kael','godot/assets/overworld/kits/bairro-inicial-v2','godot/assets/overworld/kits/cais-v1','godot/assets/campaign/ui-recorte','godot/assets/campaign/ui-modern/fonts']:
        for path in (ROOT/folder).rglob('*'):
            if path.is_file() and path.suffix!='.import':included.add(path)
    for name in ['fusca-azul','kombi-oficina','jipe-pesquisa']:included.add(ROOT/'godot/assets/overworld/kits/mobilidade/pecas'/f'{name}-default.png')
    with zipfile.ZipFile(OUT/'bairro-inicial-godot.zip','w',zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(included):archive.write(path,path.relative_to(ROOT))
        archive.write(OUT/'README.md','README.md')
        archive.writestr('godot/project.godot','config_version=5\n[application]\nconfig/name="Vila do Primeiro Vento"\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="PipaKlub-Bairro-Preview"\nrun/main_scene="res://scenes/overworld/neighborhood/bairro-jogavel.tscn"\nconfig/features=PackedStringArray("4.7", "GL Compatibility")\n[display]\nwindow/size/viewport_width=1280\nwindow/size/viewport_height=720\nwindow/stretch/mode="canvas_items"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
    print(json.dumps(report,ensure_ascii=False))
if __name__=='__main__':main()
