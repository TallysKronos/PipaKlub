from pathlib import Path
import json,re,shutil,zipfile
from PIL import Image,ImageDraw,ImageFont
import numpy as np

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'documentation/overworld/planicie-v1'

def main():
    source=Image.open(OUT/'solo-sem-objetos-1280x720.png').convert('RGB')
    board=Image.new('RGB',(1440,610),'#D0D4B2');draw=ImageDraw.Draw(board)
    font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',25)
    crops=[((425,330,690,485),'GRAMA / TERRA'),((545,210,705,315),'GRAMA / PEDRA')]
    for i,(bounds,title) in enumerate(crops):
        im=source.crop(bounds);im.thumbnail((690,500))
        im=im.resize((690,round(im.height*690/im.width)),Image.Resampling.NEAREST)
        board.paste(im,(i*720,65));draw.text((i*720+15,18),title,font=font,fill='#283E39')
    board.save(OUT/'DETALHES-TRANSICOES.png')
    old=np.asarray(Image.open(ROOT/'tmp/cave-before-shared-mask.png').convert('RGB')).astype(int)
    new=np.asarray(Image.open(ROOT/'documentation/overworld/cavernas-v3/ventos/gruta-ventos-1280x720.png').convert('RGB')).astype(int)
    diff=abs(old-new)
    report={'nativeResolution':[1280,720],'nativeViews':3,'groundMaterials':3,
            'sharedTransitionInclude':'terrain_transition.gdshaderinc','caveMaximumPixelDifferenceAfterExtraction':int(diff.max()),
            'caveMeanPixelDifferenceAfterExtraction':float(diff.mean()),'inspectedWithoutProps':True,
            'campaignIntegrated':False,'gameplayTestsRun':False}
    (OUT/'auditoria.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    for name in ['plains-native.log','plains-import.log','plains-shared-cave-review.log']:shutil.copy2(ROOT/'tmp'/name,OUT/name)
    # Walk actual res:// dependencies rather than maintaining an incomplete file list.
    pending=[ROOT/'godot/scenes/overworld/plains/planicie-dos-ventos.tscn']
    included=set()
    while pending:
        path=pending.pop()
        if path in included:continue
        included.add(path)
        if path.suffix in ['.gd','.tscn','.tres','.gdshader','.gdshaderinc']:
            text=path.read_text(encoding='utf-8-sig')
            for relative in re.findall(r'res://([^"\s]+\.(?:gdshaderinc|gdshader|png|tscn|tres|gd))(?=["\s])',text):pending.append(ROOT/'godot'/relative)
    # The script chooses tree texture dynamically through its manifest.
    for path in (ROOT/'godot/assets/overworld/kits/planicie-v1').rglob('*'):
        if path.is_file() and path.suffix!='.import':included.add(path)
    included.add(ROOT/'godot/assets/overworld/kits/cavernas-v3/props/rocha-solta.png')
    with zipfile.ZipFile(OUT/'planicie-dos-ventos-godot.zip','w',zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(included):archive.write(path,path.relative_to(ROOT))
        archive.write(OUT/'README.md','README.md')
    # Existing cave packages must also ship the new shared include dependency.
    for package in [ROOT/'documentation/overworld/cavernas-v3/gruta-dos-elos-v3-godot.zip',ROOT/'documentation/overworld/cavernas-v3/ventos/gruta-com-ventos-godot.zip']:
        replacement=package.with_suffix('.refresh.zip')
        targets=['godot/shaders/overworld/cave_ground_blend.gdshader','godot/shaders/overworld/terrain_transition.gdshaderinc']
        with zipfile.ZipFile(package) as old_zip,zipfile.ZipFile(replacement,'w',zipfile.ZIP_DEFLATED) as archive:
            for entry in old_zip.infolist():
                if entry.filename not in targets:archive.writestr(entry,old_zip.read(entry.filename))
            for target in targets:archive.write(ROOT/target,target)
        replacement.replace(package)
    print(json.dumps(report,indent=2))

if __name__=='__main__':main()
