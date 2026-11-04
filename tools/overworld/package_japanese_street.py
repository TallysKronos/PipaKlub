"""Package the native street scene and close-up evidence, without gameplay tests."""
from pathlib import Path
import re,json,zipfile,shutil
from PIL import Image,ImageDraw,ImageFont

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'documentation/overworld/rua-japonesa-v1'

def main():
    image=Image.open(OUT/'passeio-sem-fachadas-1280x720.png').convert('RGB')
    crops=[('Acesso esquerdo',(402,329,554,441)),('Acesso direito',(611,430,763,542)),('Bueiro e grelha',(612,278,764,390))]
    board=Image.new('RGB',(912,260),'#27333B')
    draw=ImageDraw.Draw(board)
    for i,(label,bounds) in enumerate(crops):
        board.paste(image.crop(bounds).resize((304,224),Image.Resampling.NEAREST),(304*i,36))
        draw.text((304*i+12,12),label,fill='#F2E7CA')
    board.save(OUT/'DETALHES-PASSEIO.png')
    board=Image.new('RGB',(1024,424),'#27333B')
    draw=ImageDraw.Draw(board)
    font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',19)
    for i,(name,label,bounds) in enumerate([
        ('casa-apoio-1280x720.png','VARANDA · piso, apoios e guarda-corpo',(430,300,830,600)),
        ('loja-apoio-1280x720.png','TOLDO · tecido e estrutura fixa',(480,310,880,610))]):
        detail=Image.open(OUT/name).crop(bounds).resize((512,384),Image.Resampling.LANCZOS)
        board.paste(detail,(i*512,40))
        draw.text((i*512+12,10),label,fill='#F2E7CA',font=font)
    board.save(OUT/'VARANDA-TOLDO-JANELAS.png')
    frames=[Image.open(path).convert('RGB').crop((620,365,895,545)).resize((550,360),Image.Resampling.LANCZOS) for path in sorted((OUT/'toldo-frames').glob('toldo-*.png'))]
    if frames:
        frames[0].save(OUT/'TOLDO-ANIMADO.webp',save_all=True,append_images=frames[1:],duration=140,loop=0,lossless=True)
    report={'nativeResolution':[1280,720],'views':['rua','sem fachadas','geometria','casa ampliada','loja ampliada'],'heightsPx':{'road':0,'sidewalk':10,'channel':-3},'ramps':2,'manholes':1,'openGrates':2,'runtimeProps':8,'asphaltOppositeEdgesDifference':0,'buildings':{'nativePlanes':True,'legacyWholeSpritesRendered':False,'wallHeightPx':108,'ridgeAboveWallPx':34,'shopFootprintCells':[[.2,2.2],[3.5,5.2]],'houseFootprintCells':[[10.2,3.0],[13,5.4]],'foundationLevelPx':10},'campaignIntegrated':False,'gameplayTestsRun':False}
    report['artRevision']='manga-v4: native projecting balcony, supported fabric awning, raised window frames and sills; original foundation preserved'
    report['facadeDepth']={'balconies':1,'floorProjectionCells':.65,'floorLevelAboveFoundationPx':62,'floorThicknessPx':4,'railHeightPx':21,'awnings':1,'awningProjectionCells':.8,'windowFrames':3,'openShutters':2,'clothFrames':len(frames),'clothLoopSeconds':4.48,'animation':'only the free lower fabric edge moves'}
    (OUT/'auditoria.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    for file in ['street-import.log','street-native.log']:shutil.copy2(ROOT/'tmp'/file,OUT/file)
    pending=[ROOT/'godot/scenes/overworld/street/rua-das-rabiolas.tscn',ROOT/'godot/tools/japanese_street_preview.gd']
    included=set()
    while pending:
        path=pending.pop()
        if path in included:continue
        included.add(path)
        if path.suffix in ['.gd','.tscn','.tres','.gdshader','.gdshaderinc']:
            for relative in re.findall(r'res://([^"\s]+\.(?:gdshaderinc|gdshader|png|tscn|tres|gd))(?=["\s])',path.read_text(encoding='utf-8-sig')):
                pending.append(ROOT/'godot'/relative)
    for path in (ROOT/'godot/assets/overworld/kits/rua-japonesa-v1').rglob('*'):
        if path.is_file() and path.suffix!='.import':included.add(path)
    with zipfile.ZipFile(OUT/'rua-das-rabiolas-godot.zip','w',zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(included):archive.write(path,path.relative_to(ROOT))
        archive.write(OUT/'README.md','README.md')
    print(json.dumps(report,indent=2))

if __name__=='__main__':main()
