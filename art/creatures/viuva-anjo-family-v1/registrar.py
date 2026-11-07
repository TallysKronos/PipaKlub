from pathlib import Path
import json,hashlib,shutil,html
from PIL import Image,ImageOps,ImageDraw
A=Path(__file__).resolve().parent;R=A.parents[2]
D=R/'documentation/creatures/viuva-anjo-chart-v1';D.mkdir(parents=True,exist_ok=True)
G=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f')
items=json.loads((A/'geracao.json').read_text(encoding='utf-8'));nodes=[]
for item in items:
    F=A/item['id']/'concept-v1';F.mkdir(parents=True,exist_ok=True)
    src=next(G.glob(item['prefix']+'*.png'));shutil.copy2(src,F/'concept.png')
    (F/'prompt.txt').write_text(item['prompt'],encoding='utf-8')
    if item.get('fix'):
        (F/'prompt-correcao.txt').write_text(item['fix'],encoding='utf-8')
        shutil.copy2(G/'exec-8bd5aa99-a78a-4f97-bcaa-de4500950f43.png',F/'antes-correcao.png')
    (F/'brief.md').write_text('# '+item['name']+' — viúva-anjo\n\nDefinido: linha de viúva-negra; adulta cavaleira-anjo, acabamento próximo da gata, referências Angewomon, LadyDevimon e Mastemon.\n\nProposta: '+item['story']+' Herança: preto-ameixa, marfim, vermelho, nós de seda, ampulheta e oito membros reorganizados. Verbo: prender → tecer → abrir → proteger. Limitação proposta: asas largas precisam de espaço e tensão; não constitui regra de gameplay.\n\nA adulta é maturação da mesma identidade, não Entrelaço. Rabiola preserva a alma; halo e asas não são almas adicionais. Nomes, elemento, habilidades, obtenção e condições permanecem abertos.\n',encoding='utf-8')
    (F/'revisao.md').write_text('# Conferência\n\n'+item['review']+'\n\nConcept proposto sem aprovação. Planos amplos e sombra simples; alguns tons claros têm transições leves. Sem pixel art técnico, rig, animação ou integração. Imagens externas não foram inputs.\n',encoding='utf-8')
    im=Image.open(F/'concept.png')
    (F/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen',source=src.name,sha256=hashlib.sha256((F/'concept.png').read_bytes()).hexdigest(),dimensions=list(im.size),mode=im.mode,alpha='A' in im.getbands(),prompt='prompt.txt',own_references='Adulta própria como destino; bebê como origem da criança; Noctiluna própria apenas como acabamento da adulta. Correção jovem usa original próprio.',decision_status='proposed',production_status='concept',integration_status='not_integrated'),ensure_ascii=False,indent=2),encoding='utf-8')
    rel='../../../art/creatures/viuva-anjo-family-v1/'+item['id']+'/concept-v1/'
    nodes.append(dict(id=item['id'],name=item['name'],kind='stage',stage=item['stage'],maturity=['Bebê','Criança','Jovem','Adulto'][item['stage']-1],identity=item['story'],story=item['story'],decision_status='proposed',production_status='concept',art=rel+'concept.png',brief=rel+'brief.md'))
edges=[dict(**{'from':nodes[i]['id'],'to':nodes[i+1]['id']},kind='reweaving',reason=nodes[i+1]['story'],decision_status='proposed') for i in range(3)]
(D/'chart.json').write_text(json.dumps(dict(family_id='viuva-anjo',scope='Quatro concepts e pesquisa; sem integração.',nodes=nodes,edges=edges),ensure_ascii=False,indent=2),encoding='utf-8')
sheet=Image.new('RGB',(2400,850),'white')
for i,n in enumerate(nodes):
    im=ImageOps.contain(Image.open(D/n['art']).convert('RGB'),(570,750));sheet.paste(im,(600*i+(600-im.width)//2,65+(750-im.height)//2))
    ImageDraw.Draw(sheet).text((600*i+18,20),['Bebe','Crianca','Jovem corrigida','Adulta'][i]+' / proposta',fill='black')
sheet.save(D/'familia.png')
(D/'CHART.md').write_text('# Viúva-negra — tecelã angelical\n\nBebê → criança de oito pernas → jovem com quatro apoios e quatro asas → Seraf Seda, cavaleira-anjo (nome proposto). A reorganização preserva oito membros: adulta com dois braços, duas pernas e quatro asas. É proposta fantástica, não biologia real. Todos os designs aguardam aprovação.\n\nReferências e estudo em ESTUDO.md. A rabiola preserva uma identidade, sem fusão imposta ou alma no halo. Mecânicas e nomes em aberto. Jovem corrigida para remover apoios excedentes; versão anterior preservada.\n',encoding='utf-8')
cards=''.join('<article><h2>'+html.escape(n['name'])+'</h2><img src="'+n['art']+'" alt="'+html.escape(n['identity'])+'"><p>'+html.escape(n['story'])+'</p><a href="'+n['brief']+'">Brief</a></article>' for n in nodes)
(D/'index.html').write_text('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>Viúva-anjo</title><style>body{font:18px system-ui;background:#f7eeee;color:#30212c;margin:40px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:24px}article{background:white;padding:22px;border:1px solid #c1a9ae}img{width:100%;height:420px;object-fit:contain}a:focus{outline:3px solid #c52a50}</style><h1>Viúva-negra: linha angelical</h1><p>Concepts propostos. <a href="ESTUDO.md">Estudo das referências</a></p><main>'+cards+'</main></html>',encoding='utf-8')
(A/'DECISOES.md').write_text('# Viúva-anjo\n\nAutor solicitou linha de viúva-negra terminando em cavaleira-anjo no acabamento da gata, referências Angewomon, LadyDevimon e Mastemon. Quatro concepts propostos, jovem corrigida quanto aos apoios. Seraf Seda é nome proposto. Sem aprovação ou integração.\n',encoding='utf-8')
print(D)
