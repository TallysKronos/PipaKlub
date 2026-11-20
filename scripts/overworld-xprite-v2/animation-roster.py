"""Build editable motion annotations from the 194 visually reviewed source sheets.
Reads PNGs for bounds only. Aseprite owns all pixel output.
"""
from pathlib import Path
from PIL import Image
import json
ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / 'art/creatures/soulmonsters-overworld-v2'
OUT = ROOT / 'art/creatures/overworld-animacoes-v1'
OUT.mkdir(exist_ok=True)
groups = {
 'quadrupede': '''aurorastro-jovem brancofaro-jovem brejoto brotozaino caimbira-memoria capiboia-condutor capiboia-contensor capimansa capivara-boia caramund-child caramund-young dirubalu dirupac doberman-c dobrim etrupim etrusvara fiafalso gambalhote-young gata-lunar-child gata-lunar-young glacerol guaravento guelfita herravento hiponilo jaguarluar jubarco lacertubo lobo-cordeiro lupisco marfenda-jovem micofolha mirafim miralis mormaco mormaco-possuido nebripasso nevagume papisco raigume raivela raiztrope rasacopa remansa roscapata saltalodo stegaru tramassauro tricerafan trincaguarda velalvo velcao velumbrio ventalume yaguarda yaguaru-memoria lince-de-cerco-child lince-de-cerco-young lince-de-cerco avelince-child avelince-young avelince''',
 'voador': '''alvaneve araruna-memoria auriflama azulao azulfazo-possuido azultor caramastro caravento carcara flautrevo folhante lequeiro mata-verde mestre-dos-fios orelavela ossavento pteralis raiatar raisoberano rastro-dos-ventos rasapena singravel-jovem tufanocorte trovareta verdestrama vesperina''',
 'serpentino': 'anaconda-baby anaconda-child anaconda-young rabiolava najarcal-child najarcal-young najarcal serpelume',
 'nadador': 'azulongo marulume',
 'multipatas': 'pernalume trincasco ventucravo viuva-child viuva-young',
 'pequeno': '''azulim bolotim braseco brasim brotim brumim caramund-baby carquim casulim dobrinco dirum etrim farpim gambalhote-baby gata-lunar-baby giripipa girobroto gotamar goticra gotim infusim lanzinho lunim mirim-fio nozinho pavioz penabroto pirilume plumico raibroto riscotim sussurim traminho viuva-baby yaguim lince-de-cerco-baby avelince-baby najarcal-baby mico-baby'''
}
lookup = {id:kind for kind, ids in groups.items() for id in ids.split()}
short_stride=set('bicapena brejoto brotim carquim chaspiral gambalhote-adult gata-lunar-child gotim guelfita infusim luziquino miralis nevagume platyx rabbito raibroto riscavela riscaz riscotim roscapata singravel-cavaleiro-da-alvorada-austral tramassauro tramino trinca-brasas najarcal-baby'.split())
data=[]
for asset in json.loads((ART/'manifest.json').read_text(encoding='utf-8'))['assets']:
    id=asset['id']
    if id=='azulfazo': continue
    image=Image.open(ART/id/'duas-vistas.png').convert('RGBA')
    kind=lookup.get(id,'bipede')
    entry=dict(id=id, anatomy=kind, stage=asset['stage'], family=asset['family'], views=[])
    entry['coupled_head']=id in ['etrim','mirim-fio']
    entry['steady_walk']=id in 'bicapena carquim luziquino platyx rabbito riscavela riscaz riscotim tramassauro tramino trinca-brasas'.split()
    for view in range(2):
        cell=image.crop((view*112,0,(view+1)*112,112))
        x0,y0,x1,y1=cell.getbbox(); w,h=x1-x0,y1-y0
        # The annotation is saved per model/view and can be overridden without
        # touching motion code. Defaults use the silhouette, not a fixed cast rig.
        entry['views'].append(dict(bounds=[x0,y0,x1,y1],center=round((x0+x1)/2),
            head_row=round(y0+h*(.42 if kind=='bipede' else .48)),
            hip_row=round(y0+h*(.73 if kind=='bipede' else .71)),
            core_left=round(x0+w*.30),core_right=round(x0+w*.70),
            stride=(1 if h<60 else 2) if id in short_stride else (2 if h<60 else 3),amplitude=1 if h<60 else 2))
    data.append(entry)
(OUT/'anatomias.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
print('193 annotations:',{kind:sum(d['anatomy']==kind for d in data) for kind in sorted({d['anatomy'] for d in data})})
