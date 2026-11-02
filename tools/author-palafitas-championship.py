"""Author district metadata without changing map geometry or existing saves."""
import json
from pathlib import Path
root=Path(__file__).resolve().parent.parent
path=root/'godot/assets/campaign/championship/districts.json'
data=json.loads(path.read_text(encoding='utf-8'))
d=next(x for x in data['districts'] if x['id']=='palafitas')
d.update(playable=True,startFlag='mormacoLiberto')
d['emblem']['name']='Insígnia das Palafitas'
cast=[
 ('seyran','Seyran',24,[22,28],'patient','O piso pode oscilar. Sua atenção, não. Vamos encontrar o equilíbrio.','Você encontrou apoio sem prender o movimento. Boa linha.','Relaxe os ombros e encontre o apoio antes de puxar.'),
 ('oruvo','Oruvo',25,[30,16],'reader','Uma vela precisa de espaço para respirar. Seu parceiro também! Vamos voar?','Olha só esse voo! Tem lugar para você na nossa roda.','Não tente vencer o vento no grito. Deixe a linha responder.'),
 ('kessai','Kessai',25,[18,28],'aggressive','Na travessia, hesitar também muda o rumo. Quero ver suas decisões!','Você acompanhou minha mudança de lado. Boa travessia!','Olhou só para mim e esqueceu o vento. Tente outra vez!'),
 ('veldren','Veldren',26,[30,12],'patient','Uma passarela firme começa em cada apoio. Mostre como cuida da sua linha.','Vocês souberam esperar. Caio está na doca da parte C.','Pressa não conserta apoio ruim. Descanse e tente de novo.'),
 ('caio-garca','Caio Garça',27,[26,12],'reader','O vento chega para todos. Quero ver o que vocês fazem quando ele muda.','O emblema é de vocês. Mantenham firme o vínculo, não a mão.','Ainda há vento para outra tentativa. Cuide do parceiro; eu espero.'),
]
for i,(npc,name,level,at,style,before,won,lost) in enumerate(cast):
 s=d['stages'][i]
 s.update(npcId=npc,name=name,npcName=name,level=level,scene='kronasta-palafitas-'+s['part'].lower(),storySpritePath='res://assets/npc-ds/palafitas-v1/'+('caio' if i==4 else npc)+'.png',point=at,authored=True,rounds=3 if i==4 else 2,styles=[style],foes=[{'name':name,'color':[2,3,1,2,2][i]}])
 s['before']=[[name,before]];s['won']=[[name,won]];s['lost']=[[name,lost]]
 s['reward']={'coins':38+i*2,'xp':360+i*20,'item':''}
path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Authored five Palafitas duels; existing battle species palette, crocodilian combat art pending')
