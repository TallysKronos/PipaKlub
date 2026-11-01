"""Author native terrain footprints; no concept image is copied into runtime."""
import json, shutil
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
layout=json.loads((ROOT/'art/overworld/kits/veredas-reference-v4/layout.json').read_text(encoding='utf-8'))
layout['schema']='veredas-modular-5'
layout['coordinateContract']='Legacy save domain mapped to native terrain plan; shared height field for meshes and actors.'
layout['approval']='Native modular rebuild, visual review pending'
layout.pop('foreground',None)
for anchor in layout['anchors']:
 if anchor['old']==[1260,195]:anchor['map']=[1100,230]
layout['paths']=[[[220,855],[295,792],[382,740],[401,604],[446,536],[480,489]],
 [[440,805],[546,800],[700,822],[830,842],[1000,820],[1030,761]],
 [[193,438],[302,470],[409,476],[523,489],[645,477],[805,520],[1090,560],[1130,611],[1105,690]],
 [[350,460],[365,366],[362,285],[465,291],[551,305],[659,284],[760,260],[855,266],[917,291]],
 [[451,204],[491,282]],[[917,291],[962,224],[1100,205],[1256,215]],
 [[917,321],[1062,390],[1188,438],[1340,485]],
 [[1000,820],[1044,748],[1100,694]]]
for f in layout['floors']:
 if f['name']=='Escada do mirante':f['points']=[[428,201],[481,184],[529,278],[469,301]]
 # Widen the landscape around trails so it reads as land, not hanging paths.
 if f['name']=='Caminho norte':f['points']=[[318,241],[413,238],[493,245],[556,255],[645,236],[737,203],[829,202],[893,228],[921,267],[911,307],[816,302],[748,310],[683,326],[611,342],[536,350],[463,333],[390,329],[329,302]]
layout['obstacles']=[o for o in layout['obstacles'] if o['name']!='Canos posteriores']
layout['obstacles']=[o if o['name']!='Canos frontais' else {'name':'Canos frontais','points':[[1195,219],[1248,212],[1320,242],[1260,268]]} for o in layout['obstacles']]
layout['landmass']=[[110,400],[160,300],[280,250],[320,160],[420,110],[580,110],[660,190],[810,165],[905,125],[1120,75],[1300,80],[1450,145],[1490,255],[1430,350],[1460,470],[1420,600],[1290,685],[1210,840],[1080,915],[850,965],[640,940],[430,900],[330,860],[230,940],[140,915],[100,830],[95,680],[130,550]]
layout['raised']=[
 {'points':[[337,173],[391,137],[459,133],[516,142],[551,169],[527,192],[480,206],[434,206],[389,215],[347,205]],'height':48},
 {'points':[[434,206],[480,206],[523,296],[469,296]],'height':48,'ramp':True,'top':206,'bottom':296},
 {'points':[[934,153],[1021,141],[1110,128],[1193,105],[1251,109],[1277,129],[1363,148],[1428,182],[1460,214],[1462,251],[1422,280],[1374,307],[1281,301],[1190,280],[1102,281],[1041,269],[991,261],[965,250],[918,250],[918,218]],'height':80},
 {'points':[[918,250],[965,250],[929,330],[866,330]],'height':80,'ramp':True,'top':250,'bottom':330}]
out=ROOT/'godot/assets/overworld/kits/veredas-modular-v5'
out.mkdir(parents=True,exist_ok=True)
shutil.copy2(ROOT/'godot/assets/overworld/kits/veredas-reference-v4/bau.png',out/'bau.png')
(out/'layout.json').write_text(json.dumps(layout,ensure_ascii=False,separators=(',',':')),encoding='utf-8')
print('Native layout:',len(layout['floors']),'surfaces; no background image')
