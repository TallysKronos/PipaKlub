from pathlib import Path
import json,hashlib,shutil,html
from PIL import Image,ImageOps,ImageDraw
A=Path(__file__).resolve().parent;R=A.parents[2]
D=R/'documentation/creatures/pangolim-trovao-chart-v1';D.mkdir(parents=True,exist_ok=True)
G=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f')
items=json.loads((A/'geracao.json').read_text(encoding='utf-8'));nodes=[]
decision='Autor: "A jovem ficou parecendo uma outra alternativa da adulto, portanto coloque as duas como nivel adulto e crie uma jovem que seja o intermédio", 2026-11-04. Define classificação das duas formas como adultas; não implica aprovação de mecânicas ou nomes.'
for item in items:
    F=A/item['id']/'concept-v1';F.mkdir(parents=True,exist_ok=True)
    src=next(G.glob(item['prefix']+'*.png'));shutil.copy2(src,F/'concept.png')
    (F/'prompt.txt').write_text(item['prompt'],encoding='utf-8')
    if item.get('fix'):
        (F/'prompt-correcao.txt').write_text(item['fix'],encoding='utf-8');shutil.copy2(G/'exec-0718b2af-c71a-4c89-ba1d-f844bb36da28.png',F/'antes-correcao.png')
    (F/'brief.md').write_text('# '+item['name']+'\n\nDefinido: pangolim trovejante, adulto dragão com estudo de Goddramon/Ouryumon/Machinedramon/WarGreymon. Autor definiu dois adultos alternativos e pediu uma nova jovem intermediária.\n\nProposta: '+item['story']+' Herança: cobalto/ciano, violeta, marfim, nós laranja, bordas de varetas ocres, cauda de escamas e condutores. Escamas são membranas de pipa, não metal colado num animal.\n\nNomes e especialidades das rotas são propostas. Não definidos: condições de bifurcação, níveis, skills, obtenção e regras. A alma permanece na rabiola; raios não criam outra identidade.\n\n'+(decision if item['stage']==4 else '')+'\n',encoding='utf-8')
    extra=''
    if item['id']=='pangolim-adult-bastiao':extra='Reclassificado de jovem para adulto pelo autor. Correção removeu pata extra: agora quatro patas. Original preservado.'
    if item['id']=='pangolim-adult-dragao':extra='Dois braços, duas pernas, dois leques, cauda e rabiola completos. Contagem de garras nas mãos difere; padronizar em vistas técnicas.'
    if item['stage']==3:extra='Nova jovem sem leques abertos: quatro membros, cauda mais curta, pequenas proteções nos antebraços. Mão junto ao peito tem garras parcialmente sobrepostas.'
    (F/'revisao.md').write_text('# Conferência\n\n'+extra+' Planos amplos, parentesco de paleta e nós visível. Algumas transições suaves permanecem; não certificar dois tons exatos nem pixel art técnico. Rabiola com dois terminais visíveis. Arte proposta, sem aprovação explícita nova, recortes, rig ou integração.\n',encoding='utf-8')
    im=Image.open(F/'concept.png')
    (F/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen',source=src.name,sha256=hashlib.sha256((F/'concept.png').read_bytes()).hexdigest(),dimensions=list(im.size),mode=im.mode,alpha='A' in im.getbands(),prompt='prompt.txt',own_reference_inputs='Destino adulto próprio para primeiras formas; criança própria para nova jovem; Borealvo v2 apenas para acabamento do adulto dragão.',decision_status='proposed',stage_decision=decision if item['stage']==4 else None,production_status='concept',integration_status='not_integrated'),ensure_ascii=False,indent=2),encoding='utf-8')
    rel='../../../art/creatures/pangolim-trovao-family-v1/'+item['id']+'/concept-v1/'
    nodes.append(dict(id=item['id'],name=item['name'],kind='stage',stage=item['stage'],maturity=['Bebê','Criança','Jovem','Adulto'][item['stage']-1],identity=item['story'],story=item['story'],decision_status='proposed',production_status='concept',art=rel+'concept.png',brief=rel+'brief.md'))
pairs=[(0,1),(1,2),(2,3),(2,4)]
edges=[dict(**{'from':nodes[i]['id'],'to':nodes[j]['id']},kind='reweaving',reason=nodes[j]['story'],decision_status='proposed') for i,j in pairs]
(D/'chart.json').write_text(json.dumps(dict(family_id='pangolim-trovao',scope='Bebê, criança, jovem e dois adultos alternativos definidos em estágio pelo autor; sem integração.',nodes=nodes,edges=edges),ensure_ascii=False,indent=2),encoding='utf-8')
sheet=Image.new('RGB',(2750,800),'white')
for i,n in enumerate(nodes):
    im=ImageOps.contain(Image.open(D/n['art']).convert('RGB'),(530,700));sheet.paste(im,(550*i+(550-im.width)//2,65+(700-im.height)//2))
    ImageDraw.Draw(sheet).text((550*i+15,20),['Bebe','Crianca','Nova jovem','Adulto quadrupede','Adulto dragao'][i],fill='black')
sheet.save(D/'familia.png')
(D/'CHART.md').write_text('# Pangolim trovejante\n\nBebê → criança → nova jovem → dois adultos alternativos: quadrúpede e dragão erguido. A bifurcação e classificação em estágio IV foram solicitadas pelo autor. Nova jovem foi criada com menor massa, cauda curta e proteção fechada. Nomes e regras das rotas não definidos.\n\n'+decision+'\n\nRecolher → armazenar → conduzir → descarregar é narrativa proposta de maturidade. Bastião e Fulguar são nomes provisórios. Quatro membros em todas as formas corporais; leques dorsais são membranas extras da carapaça, não braços. Rabiola preserva uma identidade. Escamas amplas são estrutura de pipa; raios são controlados por caminhos de corda e varetas.\n\nLimites: diferenças de contagem das garras no adulto dragão, garras parcialmente ocultas na jovem; sem vistas técnicas ou integração. Adulto quadrúpede tem correção de pata extra com original preservado.\n',encoding='utf-8')
cards=''.join('<article><h2>'+html.escape(n['name'])+'</h2><img src="'+n['art']+'" alt="'+html.escape(n['identity'])+'"><p>'+html.escape(n['story'])+'</p><a href="'+n['brief']+'">Brief</a></article>' for n in nodes)
(D/'index.html').write_text('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>Pangolim trovejante</title><style>body{font:18px system-ui;background:#edf1fc;color:#282244;margin:40px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:24px}article{background:white;padding:20px;border:1px solid #acb7d4}img{width:100%;height:390px;object-fit:contain}a:focus{outline:3px solid #ed8100}</style><h1>Pangolim trovejante</h1><p>Bebê → criança → jovem → adulto quadrúpede OU adulto dragão. <a href="ESTUDO.md">Referências estudadas</a></p><main>'+cards+'</main></html>',encoding='utf-8')
(A/'DECISOES.md').write_text('# Pangolim trovejante\n\n'+decision+'\n\nNova jovem sem leques completos criada após a decisão. Artes anteriores preservadas, incluindo correção do adulto quadrúpede. Sem aprovação de nomes, mecânicas ou integração.\n',encoding='utf-8')
print(D)
