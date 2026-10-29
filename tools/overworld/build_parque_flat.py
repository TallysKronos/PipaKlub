"""Editable native SVG surfaces: quiet flat colors, exact corner masks, no paintover collision."""
from pathlib import Path
import json, shutil
ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/overworld/kits/parque'
GAME=ROOT/'godot/assets/overworld/kits/parque'
kit=json.loads((ART/'kit.json').read_text(encoding='utf-8'))
colors={'grama':'#86AA60','terra':'#DDA854','mato':'#5C8D44','piso':'#E8D7A8','bosque':'#486C42'}
ink={'grama':'#7CA056','terra':'#D09B49','mato':'#477736','piso':'#DCCA9B','bosque':'#41643C'}
diamond='32,0 64,16 32,32 0,16'
corners=[[(32,0),(64,16),(32,16)],[(64,16),(32,32),(32,16)],[(32,32),(0,16),(32,16)],[(0,16),(32,0),(32,16)]]
# Corner regions meet at edge midpoints, matching the renderer's UV wedges.
wedges=['32,0 48,8 32,16 16,8','64,16 48,24 32,16 48,8','32,32 16,24 32,16 48,24','0,16 16,8 32,16 16,24']
files=[]
def save(relative,body,bleed=False):
    clip='' if bleed else ' clip-path="url(#tile)"'
    svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="32" viewBox="0 0 64 32"><defs><clipPath id="tile"><polygon points="{diamond}"/></clipPath></defs><g{clip}>{body}</g></svg>\n'
    for directory in [ART,GAME]:
        dest=directory/relative;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(svg,encoding='utf-8')
    files.append(relative)

for material,color in colors.items():
    names=[]
    for variant in range(4):
        # 0.7 px same-color bleed prevents translucent raster edges from
        # exposing the dark context between two otherwise identical tiles.
        body=f'<polygon points="{diamond}" fill="{color}" stroke="{color}" stroke-width="1.4"/>'
        if material in ['grama','bosque']:
            x,y=[(26,14),(40,18),(20,18),(34,12)][variant]
            body+=f'<path d="M{x} {y}l-2 -2m2 2l2 -1" fill="none" stroke="{ink[material]}" stroke-width=".7"/>'
        elif material=='mato':
            for x,y in [(18,15),(29,20),(37,12),(46,18)]:
                body+=f'<path d="M{x} {y}l-2 -4m2 4l1 -5m-1 5l3 -3" fill="none" stroke="{ink[material]}" stroke-width="1"/>'
        elif material=='terra':
            x,y=[(24,15),(39,18),(30,20),(34,11)][variant]
            body+=f'<path d="M{x} {y}l2 0m8 3h1" stroke="{ink[material]}" stroke-width=".7"/>'
        elif variant==2:
            body+=f'<path d="M22 15l3 1 1 2" fill="none" stroke="{ink[material]}" stroke-width=".6"/>'
        name=f'chao-flat/{material}-{variant}.svg';save(name,body,bleed=True);names.append(name)
    kit['materials'][material]['variants']=names

for pair,entry in kit['transitions'].items():
    a,b=pair.split('/');names=[]
    for mask in range(16):
        # Transparent native diamond: no extra full-cell border or baked shadow.
        body=f'<polygon points="{diamond}" fill="{colors[a]}" stroke="{colors[a]}" stroke-width="1.4"/>'
        for bit,poly in enumerate(wedges):
            if mask&(1<<bit):body+=f'<polygon points="{poly}" fill="{colors[b]}" stroke="{colors[b]}" stroke-width="1.4"/>'
        name=f'transicoes-flat/{a}-{b}-{mask:02}.svg';save(name,body,bleed=True);names.append(name)
    entry['files']=names
kit['surfaceTreatment']={'kind':'native-editable-svg-flat','colors':colors,'source':'tools/overworld/build_parque_flat.py',
                         'note':'surfaces only; masonry and gazebo remain reused raster assets; ramp is still renderer geometry'}
kit['approval']='pending_owner_review_flat_v1'
for directory in [ART,GAME]:(directory/'kit.json').write_text(json.dumps(kit,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(ART/'superficies-flat.json').write_text(json.dumps({'files':files,'palette':colors,'maskBits':['top','right','bottom','left'],
    'provenance':'Original editable vector surfaces authored for this repository; no external source imagery.'},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'native_svg_files':len(files),'materials':len(colors),'geometry_edited':False}))
