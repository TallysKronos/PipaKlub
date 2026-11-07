from pathlib import Path
import json,os,shutil,hashlib
from html import escape
from PIL import Image,ImageOps,ImageDraw,ImageFont
D=Path(__file__).resolve().parent
R=D.parents[2]
G=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f')
prompts=json.loads((D/'prompts.json').read_text(encoding='utf-8'))
specs=[
('riscotim','Riscotim','Bebê','Cabeça-pipa sem tronco ou patas, orelhas assimétricas e duas fitas curtas.','Aprende a equilibrar sua construção compacta antes de adquirir apoios.','exec-3b77c944-6943-4711-9628-99980080bd28.png'),
('riscaz','Riscaz','Criança existente','Roedor baixo carvão e creme, incisivos, olho verde, vela e rabiola desigual.','Base autoral preservada; maturidade é organização documental.',None),
('riscavela','Riscavela','Jovem','Ratazana baixa e robusta, dorso arqueado, focinho longo, orelhas pequenas e quatro patas de dedos alongados.','Aprende a ancorar os apoios e tensionar a vela; essa estrutura prepara a balista do adulto.','exec-089f9ec5-e087-4837-8edb-be13c6177d58.png'),
('riscarion','Riscárion','Adulto cavaleiro','Elmo fechado em cunha, armadura leve, rabiola inteira e balista portátil.','Transformação cavaleiresca sombria e venenosa pedida pelo autor; voto e origem continuam abertos.',None)]
nodes=[]
refs=['art/soulgen/keys/riscaz/cutout-rig-v1/preview.png','art/creatures/onze-cavaleiros-v1/riscarion/concept-v1/concept.png']
for stage,(id,name,age,identity,story,source) in enumerate(specs,1):
 if source:
  folder=R/'art/creatures/riscaz-family-v1'/id/('concept-v2' if id=='riscavela' else 'concept-v1');folder.mkdir(parents=True,exist_ok=True)
  art=folder/'concept.png';shutil.copy2(G/source,art)
  (folder/'prompt.txt').write_text(prompts[id],encoding='utf-8')
  brief=folder/'brief.md'
  brief.write_text(f'# {name} — {age}\n\nDefinido pelo autor: criar bebê e jovem da linha após aprovação do cavaleiro.\nObservado na base: carvão/creme/verde, incisivos, orelhas assimétricas, vela única e duas fitas principais.\nProposta: {identity}\nHistória visual: {story}\nNome e relações evolutivas são propostas. Não estabelece receita, poderes novos da base, vínculo com Rato ou condição de obtenção. Alma na rabiola conectada.\n45% criatura, 45% construção funcional de pipa, 10% acabamento pixel seletivo/2D mangá; sem alegação de pixel art técnico.\n',encoding='utf-8')
  review='Sem torso ou patas; dois incisivos, duas orelhas diferentes e duas fitas conectadas; grande redução de componentes em relação à criança.' if id=='riscotim' else 'Quatro patas distintas com dedos longos, face de ratazana, dois incisivos, duas orelhas pequenas, uma vela e duas fitas inteiras. Corpo baixo e robusto, dorso arqueado e focinho comprido; substitui leitura de coelho/cervídeo rejeitada pelo autor.'
  (folder/'revisao.md').write_text('# Conferência visual\n\n'+review+'\nCores amplas e sombras simples; algum facetamento e suavização permanecem na ilustração. Concept completo, não recortes animáveis ou rig. Novas artes aguardam avaliação do autor.\n',encoding='utf-8')
  with Image.open(art) as im:meta=dict(id=id,source=str(G/source),tool='image_gen.imagegen',width=im.width,height=im.height,mode=im.mode,sha256=hashlib.sha256(art.read_bytes()).hexdigest(),decision_status='proposed',production_status='concept',references=refs+(['art/creatures/rabbito-family-v1/arauto-da-tempestade/concept-v2/concept.png'] if id=='riscavela' else []),external_images_used_for_generation=False,technical_pixel_art=False)
  (folder/'manifest.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf-8')
 elif id=='riscaz':
  art=R/'art/soulgen/keys/riscaz/cutout-rig-v1/preview.png';brief=R/'art/soulgen/keys/riscaz/README.md'
 else:
  art=R/'art/creatures/onze-cavaleiros-v1/riscarion/concept-v1/concept.png';brief=art.parent/'brief.md'
  mf=art.parent/'manifest.json';m=json.loads(mf.read_text(encoding='utf-8'));m.update(decision_status='approved',approval_note='Autor: aprovado agr baby e jovem. Aprovação visual; nome, voto, obtenção e integração não confirmados.');mf.write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
 rel=lambda p:os.path.relpath(p,D).replace('\\','/')
 n=dict(id=id,name=name,kind='stage',stage=stage,age=age,identity=identity,story=story,decision_status='proposed' if source else 'approved',production_status='concept',art=rel(art),brief=rel(brief))
 if not source:n['approval_note']='Base final autoral preservada.' if id=='riscaz' else 'Aprovação visual explícita: aprovado agr baby e jovem.'
 nodes.append(n)
edges=[dict(**{'from':a['id'],'to':b['id']},kind='reweaving',decision_status='proposed',reason=reason) for a,b,reason in zip(nodes,nodes[1:],['Cabeça-pipa passa a sustentar corpo e apoios.','Apoios alongados e tensão da vela antecipam função de ancoragem.','Postura quadrúpede se reorganiza em cavaleiro com elmo e balista.'])]
(D/'chart.json').write_text(json.dumps(dict(family_id='riscaz',scope='Dois novos concepts; sem integração ou alterações na base.',nodes=nodes,edges=edges),ensure_ascii=False,indent=2),encoding='utf-8')
(D/'CHART.md').write_text('# Riscaz — da primeira dobra à balista\n\nRiscotim → Riscaz → Riscavela → Riscárion.\n\nBebê é cabeça-pipa; criança é a base existente; jovem ganha corpo robusto de ratazana, apoios baixos e proteção inicial; adulto reorganiza postura, face e função como cavaleiro. As duas novas artes e nomes são propostas. Riscárion aprovado visualmente pelo autor.\n\nNão se atribui veneno à criança retroativamente. Sombrio não significa vilão ou possuído. Voto, conto, receitas e obtenção permanecem indefinidos. Pesquisa externa está registrada no brief de Riscárion, sem imagens externas na geração. Não foi alterado jogo, rig ou arte autoral existente.\n',encoding='utf-8')
mini=D/'miniaturas';mini.mkdir(exist_ok=True)
sheet=Image.new('RGB',(1600,1400),'white');draw=ImageDraw.Draw(sheet);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',26)
for i,n in enumerate(nodes):
 with Image.open(D/n['art']) as im:
  a=im.convert('RGBA');box=a.getchannel('A').getbbox();a=a.crop(box) if box else a
  white=Image.new('RGBA',a.size,'white');white.alpha_composite(a);t=ImageOps.contain(white.convert('RGB'),(750,600),Image.Resampling.LANCZOS)
 t.save(mini/(n['id']+'.png'));x=i%2*800;y=i//2*700;sheet.paste(t,(x+(800-t.width)//2,y+(610-t.height)//2));draw.text((x+24,y+635),n['name']+' · '+n['age'],font=font,fill='#233c31')
sheet.save(D/'familia.png')
cards=''.join(f'<article><h2>{escape(n["name"])} · {n["age"]}</h2><a href="{n["art"]}"><img src="miniaturas/{n["id"]}.png" alt="{escape(n["identity"])}"></a><p>{escape(n["story"])}</p><a href="{n["brief"]}">Brief</a></article>' for n in nodes)
(D/'index.html').write_text('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Linha Riscaz</title><style>body{max-width:1250px;margin:auto;padding:24px;background:#f3f1e8;color:#22382e;font:18px/1.6 system-ui}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px}article{background:white;padding:24px}img{width:100%;height:430px;object-fit:contain}a{color:#27583e}a:focus-visible{outline:3px solid #946a25}@media(max-width:700px){.grid{grid-template-columns:1fr}}</style><h1>Riscaz · da primeira dobra à balista</h1><p>Novos bebê e jovem em avaliação; criança autoral preservada e adulto aprovado. Nomes novos e ligações são propostas. Sem integração.</p><p><a href="familia.png">Comparação da família</a> · <a href="CHART.md">Decisões</a></p><main class="grid">'+cards+'</main></html>',encoding='utf-8')
print('Salvos 2 concepts e chart documental de 4 formas.')
exec(compile((D/'registrar_aprovacao.py').read_text(encoding='utf-8'),str(D/'registrar_aprovacao.py'),'exec'),{'__file__':str(D/'registrar_aprovacao.py')})
