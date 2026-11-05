from pathlib import Path
import json,hashlib,shutil,html
from PIL import Image,ImageOps,ImageDraw
A=Path(__file__).resolve().parent;R=A.parents[2];D=R/'documentation/creatures/coruja-balanca-chart-v1';D.mkdir(parents=True,exist_ok=True)
G=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f')
items=json.loads((A/'geracao-pre.json').read_text(encoding='utf-8'));nodes=[]
for x in items:
    F=A/x['id']/'concept-v1';F.mkdir(parents=True,exist_ok=True);src=next(G.glob(x['prefix']+'*.png'));p=F/'concept.png';shutil.copy2(src,p)
    (F/'prompt.txt').write_text(x['prompt'],encoding='utf-8')
    (F/'brief.md').write_text('# '+x['name']+'\n\nDefinido: pré-evoluções da coruja guerreira ciano/roxo aprovada.\n\nProposta: '+x['story']+' Herança: disco facial marfim, bico ciano, tufos roxos, olhos âmbar, membranas e varetas claras. O desenvolvimento da arma acompanha o domínio do equilíbrio.\n\nVerbo: '+['equilibrar','sustentar','estabilizar'][x['stage']-1]+'. Limitação proposta: '+['não manipula cargas','carga nas asas restringe o voo','precisa das duas mãos para conter os pratos'][x['stage']-1]+'. Nomes, habilidades, obtenção e regras de evolução indefinidos. Uma rabiola com dois terminais, mesma almática. Sem integração.\n',encoding='utf-8')
    obs=['Bebê sem torso ou pernas: cabeça-pipa, duas abas laterais e terminal bifurcado.','Criança com duas asas e duas pernas; três garras frontais em cada pé; dois pratos ligados às pontas das asas.','Jovem com duas mãos na travessa, duas pernas e penas alares laterais; sem armadura completa ou haste vertical. A ligação entre asas e braços merece vista posterior antes do rig.'][x['stage']-1]
    (F/'revisao.md').write_text('# Conferência\n\n'+obs+' Paleta e traço conferidos com adulto. Figura completa, pratos e rabiola visíveis. Concept proposto; sem aprovação destas três novas formas. Não é pixel art técnico, recorte ou animação validada.\n',encoding='utf-8')
    im=Image.open(p);(F/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen',source=src.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),dimensions=list(im.size),mode=im.mode,alpha='A' in im.getbands(),prompt='prompt.txt',own_reference_inputs='Adulto aprovado e formas desta própria família; nenhuma arte externa.',decision_status='proposed',production_status='concept',integration_status='not_integrated'),ensure_ascii=False,indent=2),encoding='utf-8')
    rel='../../../art/creatures/coruja-balanca/'+x['id']+'/concept-v1/'
    nodes.append(dict(id=x['id'],name=x['name'],kind='stage',stage=x['stage'],identity='Ciano/roxo, disco facial marfim, olhos âmbar, nós e balança.',story=x['story'],decision_status='proposed',production_status='concept',art=rel+'concept.png',brief=rel+'brief.md'))
note='2026-11-04 — autor: “ótimo aprovado faça as pré evoluções agora”. Escopo: adulto guerreiro coruja visual; mecânicas continuam propostas.'
F=A/'concept-v1';m=F/'manifest.json';v=json.loads(m.read_text(encoding='utf-8'));v['decision_status']='approved';v['approval_note']=note;m.write_text(json.dumps(v,ensure_ascii=False,indent=2),encoding='utf-8')
for filename in ['brief.md','revisao.md']:
    p=F/filename;s=p.read_text(encoding='utf-8')
    if note not in s:p.write_text(s+'\n## Aprovação visual\n'+note+'\n',encoding='utf-8')
nodes.append(dict(id='coruja-balanca',name='Adulto — guerreiro da balança',kind='stage',stage=4,identity='Coruja robusta, armadura e balança de haste.',story='Usa uma base forte para manejar a balança e manter a guarda.',decision_status='approved',approval_note=note,production_status='concept',art='../../../art/creatures/coruja-balanca/concept-v1/concept.png',brief='../../../art/creatures/coruja-balanca/concept-v1/brief.md'))
edges=[dict(**{'from':nodes[i]['id'],'to':nodes[i+1]['id']},kind='reweaving',reason=nodes[i+1]['story'],decision_status='proposed') for i in range(3)]
(D/'chart.json').write_text(json.dumps(dict(family_id='coruja-balanca',scope='Adulto visual aprovado e três pré-evoluções propostas. Sem integração.',nodes=nodes,edges=edges),ensure_ascii=False,indent=2),encoding='utf-8')
sheet=Image.new('RGB',(2400,900),'white');draw=ImageDraw.Draw(sheet)
for i,n in enumerate(nodes):
    im=ImageOps.contain(Image.open(D/n['art']).convert('RGB'),(565,790));sheet.paste(im,(i*600+(600-im.width)//2,75+(790-im.height)//2));draw.text((i*600+18,25),['Bebe / proposta','Crianca / proposta','Jovem / proposta','Adulto / aprovado'][i],fill='#402354')
sheet.save(D/'familia.png')
(D/'CHART.md').write_text('# Coruja da balança\n\nBebê face-pipa → criança ave de pratos alares → jovem que segura travessa → adulto guerreiro de balança em haste.\n\nProposta de história: descobrir equilíbrio, sustentar, estabilizar e finalmente controlar a guarda. A arma muda com a capacidade corporal. Jovem tem pouca proteção e exige duas mãos; adulto tem tronco robusto e proteção completa.\n\nTrês novos designs propostos; adulto aprovado. Relações de Remonta, correspondência I Cafifa / II Pipa / III Arraia / IV Pandorga e condições são documentais/propostas. Nomes e gameplay indefinidos.\n\nPesquisa de robustez já realizada: ../../../art/creatures/coruja-balanca/concept-v1/ESTUDO.md. Sem novas referências externas na geração das pré-evoluções.\n',encoding='utf-8')
cards=''.join('<article><h2>'+html.escape(n['name'])+'</h2><a href="'+n['art']+'"><img src="'+n['art']+'" alt="'+html.escape(n['story'])+'"></a><p>'+html.escape(n['story'])+'</p><p>'+n['decision_status']+'</p><a href="'+n['brief']+'">Brief</a></article>' for n in nodes)
(D/'index.html').write_text('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Coruja da balança</title><style>body{font:18px system-ui;background:#eef3f5;color:#402354;margin:32px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:24px}article{background:white;padding:24px}img{width:100%;height:450px;object-fit:contain}a:focus-visible{outline:3px solid #007f91}</style><h1>Coruja da balança</h1><p>Adulto aprovado, três pré-evoluções propostas.</p><main>'+cards+'</main></html>',encoding='utf-8')
(A/'DECISOES.md').write_text('# Aprovação e propostas\n\n'+note+'\n\nTrês pré-evoluções criadas após o pedido, ainda propostas. O equilíbrio como história da linha é proposta de design, não regra canônica. Sem código, rig ou integração.\n',encoding='utf-8')
print(D)
import runpy
runpy.run_path(str(D/'aprovar_pre.py'))
