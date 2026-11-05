from pathlib import Path
import json,shutil,hashlib,os
from html import escape
from html.parser import HTMLParser
from PIL import Image,ImageOps,ImageDraw,ImageFont
D=Path(__file__).resolve().parent;R=D.parents[2];G=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f');prompts=json.loads((D/'prompts.json').read_text(encoding='utf-8'))
specs=[
 dict(id='gotim',name='Gotim',age='Bebê',action='Equilibrar',identity='Cabeça-pipa retangular de capivara, sem tronco/patas, crescente de flutuação inferior e uma aba na rabiola.',story='Aprende a manter a primeira dobra equilibrada sobre a corrente.',source='exec-e0096096-377d-453e-91d3-db26a1aeecc2.png',floats=1,refs=['art/creatures/capivara-boia/child-manga-v1/concept.png']),
 dict(id='capivara-boia',name='Capiboia',age='Criança',action='Flutuar',identity='Capivara de papel menta e creme, quatro pés escuros, crescente nos quadris, vela curva e três abas na rabiola.',story='Ganha quatro apoios e uma vela para aprender a navegar sem abandonar a margem.',source='exec-02f123c0-5296-4cd7-b7ba-7b8b2bb24da9.png',floats=3,refs=['art/creatures/capivara-boia/model-d-v1/prancha-d.png','art/creatures/yaguaru-family-v1/yaguarda/concept-v1/concept.png']),
 dict(id='remansa',name='Remansa',age='Jovem',action='Estabilizar',identity='Corpo baixo e largo, membros palmados fortes, flutuação lateral e duas velas estabilizadoras; quatro abas na rabiola.',story='Aprende a sustentar direção em correntes mais fortes e abre passagem com os apoios dianteiros.',source='exec-1ed3efaf-cbf7-4fcb-b9f5-d1d1f2880459.png',floats=4,refs=['art/creatures/capivara-boia/child-manga-v1/concept.png']),
 dict(id='marevia',name='Marévia',age='Adulto',action='Abrigar a passagem',identity='Capivara de peito elevado e corpo petróleo, gola de quebra-mar, mantos laterais e vela-leque arqueada; cinco abas na rabiola.',story='Reorganiza a flutuação em abrigo que desvia correntes ao redor de quem acompanha.',source='exec-bc63fc6c-04c4-4b14-9277-8394e72b7ded.png',floats=5,refs=['art/creatures/capivara-boia/child-manga-v1/concept.png','art/creatures/capivara-boia-family-v1/remansa/concept-v1/concept.png'])]
for s in specs:
 folder=R/'art/creatures/capivara-boia/child-manga-v1' if s['id']=='capivara-boia' else R/'art/creatures/capivara-boia-family-v1'/s['id']/'concept-v1'
 folder.mkdir(parents=True,exist_ok=True);s['folder']=folder;s['art']=folder/'concept.png';shutil.copy2(G/s['source'],s['art'])
nodes=[]
for stage,s in enumerate(specs,1):
 folder=s['folder'];brief=folder/'brief.md'
 brief.write_text(f'''# {s['name']} — {s['age']}

## Definido pelo autor
A opção D anterior é um sketch fora do traço desejado. O autor definiu essa forma como criança e pediu a linha completa no estilo atual.

## Observado e preservado
Capivara menta/creme com pés escuros, boia nos quadris, vela curva de bambu e rabiola flutuante. Sketch anterior fica preservado; o ID capivara-boia é mantido na criança. Não confundir com Capimansa caramelo nem usar as opções A/B/C como evoluções automáticas.

## Proposta desta forma
{s['identity']}
Verbo: {s['action']}. {s['story']}
Nomes e arquitetura novos são propostas. A alma continua na rabiola inteira: {s['floats']} abas flutuantes são partes da mesma peça, não almas extras. Progressão visual de abas 1/3/4/5; não é quantidade canônica já confirmada. Nenhum vínculo evolutivo com Capimansa foi estabelecido. Esta linha aquática independente é uma proposta de trabalho baseada no pedido atual.

## História de amadurecimento
Equilibrar a si → manter flutuação → estabilizar a corrente → abrigar a passagem dos outros. Adulto é criatura quadrúpede protetora; não se presume que toda linha termine em cavaleiro. Requisitos, atributos, obtenção e capacidade de transporte/abrigo no gameplay não definidos.

## Acabamento
45% criatura/45% construção de pipa/10% contorno seletivo pixel e 2D mangá: cores chapadas menta/creme/petróleo, coral focal, papel tensionado, varetas e nós estruturais. Sem pelagem ou pastel do sketch. Não é pixel art técnico, rig, animação ou integração. Arte em avaliação.
''',encoding='utf-8')
 (folder/'prompt.txt').write_text(prompts[s['id']],encoding='utf-8')
 review=('Sem tronco/patas: cabeça retangular, duas orelhas redondas e uma aba conectada; crescente inferior é estrutura de flutuação, não torso.' if stage==1 else 'Quatro apoios palmados visíveis, focinho retangular de roedor e dois incisivos; sem nariz de gato/cão. ')+({1:'Olhar semicerrado mantém calma da família; poderá ser suavizado se o autor quiser maior curiosidade infantil.',2:'Contorno e cor substituem o acabamento do sketch; a vela e os três flutuadores preservam a escolha D.',3:'Quatro abas foram produzidas, embora prompt pedisse três: adotadas nesta proposta como crescimento estrutural a avaliar, não aprovação automática. Lobo lateral distante parcialmente ocluído pelo corpo; exigirá costas antes de rig.',4:'Cinco abas, gola de onda e dois mantos laterais; vela arqueada com recorte inferior. Cabeça mais alta e nova distribuição de massa distinguem adulto do jovem.'}[stage])
 (folder/'revisao.md').write_text('# Conferência visual\n\n'+review+'\nImagens conferidas individualmente após geração. Cores amplas e contornos nítidos; alguma suavização e sombreamento extra permanecem na ilustração. Rabiolas visíveis e contínuas; produção de vistas e peças será necessária para provar encaixes em animação. Concepts novos aguardam avaliação.\n',encoding='utf-8')
 with Image.open(s['art']) as im:meta=dict(id=s['id'],name=s['name'],stage=stage,tool='image_gen.imagegen',source=str(G/s['source']),width=im.width,height=im.height,mode=im.mode,alpha='A' in im.getbands(),sha256=hashlib.sha256(s['art'].read_bytes()).hexdigest(),references=s['refs'],decision_status='proposed',production_status='concept',implementation='não integrado',external_images_used_for_generation=False,technical_pixel_art=False,prompt='prompt.txt',review='revisao.md',brief='brief.md')
 (folder/'manifest.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf-8')
 rel=lambda p:os.path.relpath(p,D).replace('\\','/')
 nodes.append(dict(id=s['id'],name=s['name'],age=s['age'],kind='stage',stage=stage,identity=s['identity'],story=s['story'],decision_status='proposed',production_status='concept',art=rel(s['art']),brief=rel(brief)))
edges=[dict(**{'from':a['id'],'to':b['id']},kind='reweaving',decision_status='proposed',reason=r) for a,b,r in zip(nodes,nodes[1:],['Equilíbrio inicial adquire quatro apoios, crescente nos quadris e primeira vela.','Flutuação se distribui pelas laterais; quatro pés controlam direção e impulso.','Estruturas laterais se abrem em abrigo e quebra-mar; a vela vira leque arqueado.'])]
(D/'chart.json').write_text(json.dumps(dict(family_id='capivara-boia',scope='Linha de quatro concepts, criança definida pelo autor, novas artes em avaliação; sem integração.',nodes=nodes,edges=edges),ensure_ascii=False,indent=2),encoding='utf-8')
(D/'CHART.md').write_text('# Capivara de água — da gota ao abrigo\n\nGotim → Capiboia (ID capivara-boia) → Remansa → Marévia. Nomes propostos.\n\nA criança é o redesign da opção D escolhida, agora em papel vivo/2D mangá. Bebê não tem tronco ou patas; criança aprende a flutuar; jovem baixo e largo estabiliza correntes; adulto ganha gola de quebra-mar, mantos laterais e vela-leque. Não é apenas crescimento de escala.\n\nTodas as novas artes estão em avaliação. O pedido atual define a maturidade da opção D, mas não decide parentesco com Capimansa. Esta família aquática fica proposta independentemente, sem vínculo adicional. Não se altera bíblia, gameplay, montaria ou animação anterior. Sketch e A/B/C preservados. Sem alegação de rig, vistas completas ou pixel art técnico.\n',encoding='utf-8')
(D/'fontes.json').write_text(json.dumps(dict(date='2026-11-04',author_request='Refazer sketch como criança no estilo atual e criar linha completa.',local_sources=['art/creatures/capivara-boia/DECISOES.md','art/creatures/capivara-boia/model-d-v1/README.md','art/creatures/capivara-boia/model-d-v1/prancha-d.png','documentation/creatures/evolucoes-v1/briefs/capivara-boia.md'],external_research='Não realizado novo benchmark externo nesta revisão de identidade própria; referências de traço são do projeto.',unresolved='Parentesco com Capimansa, nomes e requisitos continuam propostas.'),ensure_ascii=False,indent=2),encoding='utf-8')
mini=D/'miniaturas';mini.mkdir(exist_ok=True);sheet=Image.new('RGB',(1600,1400),'white');draw=ImageDraw.Draw(sheet);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',25)
for i,n in enumerate(nodes):
 with Image.open(D/n['art']) as im:t=ImageOps.contain(im.convert('RGB'),(750,600),Image.Resampling.LANCZOS)
 t.save(mini/(n['id']+'.png'));x=i%2*800;y=i//2*700;sheet.paste(t,(x+(800-t.width)//2,y+(610-t.height)//2));draw.text((x+24,y+632),n['name']+' · '+n['age'],font=font,fill='#164b43')
sheet.save(D/'familia.png')
cards=''.join(f'<article><h2>{escape(n["name"])} · {n["age"]}</h2><a href="{n["art"]}"><img src="miniaturas/{n["id"]}.png" alt="{escape(n["identity"])}"></a><p>{escape(n["story"])}</p><a href="{n["brief"]}">Brief</a></article>' for n in nodes)
page='<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Capivara de água · família</title><style>body{max-width:1250px;margin:auto;padding:24px;background:#edf5ed;color:#163e37;font:18px/1.6 system-ui}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px}article{background:white;padding:24px}img{width:100%;height:430px;object-fit:contain}a{color:#19665a}a:focus-visible{outline:3px solid #cc654c}@media(max-width:700px){.grid{grid-template-columns:1fr}}</style><h1>Capivara de água · da gota ao abrigo</h1><p>Quatro novos concepts no traço atual. Criança definida pelo autor; nomes e ligações são propostas. Artes em avaliação, sem integração.</p><p><a href="familia.png">Comparar família</a> · <a href="CHART.md">Decisões</a> · <a href="../../../art/creatures/capivara-boia/model-d-v1/prancha-d.png">Sketch preservado</a></p><main class="grid">'+cards+'</main></html>'
(D/'index.html').write_text(page,encoding='utf-8')
class Links(HTMLParser):
 def __init__(self):super().__init__();self.paths=[]
 def handle_starttag(self,t,attrs):
  self.paths.extend(v for k,v in attrs if k in ('href','src'))
l=Links();l.feed(page);missing=[p for p in l.paths if not(D/p).is_file()];(D/'validacao.json').write_text(json.dumps(dict(ok=not missing,nodes=4,edges=3,new_concepts=4,missing_links=missing,scope='Arquivos, imagens e links; não prova animação ou integração.'),ensure_ascii=False,indent=2),encoding='utf-8')
dec=R/'art/creatures/capivara-boia-family-v1/DECISOES.md';dec.write_text('# Linha da capivara de água\n\n2026-11-04: autor definiu sketch D como criança e pediu redesign e linha completa no traço próprio. Quatro novos concepts propostos; originais preservados. Esta etapa não aprova Capimansa como parente nem altera a integração aquática anterior.\n',encoding='utf-8')
print(json.dumps(dict(concepts=4,missing_links=missing),ensure_ascii=False))
if missing:raise SystemExit(1)
exec(compile((D/'aplicar_revisoes.py').read_text(encoding='utf-8'),str(D/'aplicar_revisoes.py'),'exec'),{'__file__':str(D/'aplicar_revisoes.py')})
exec(compile((D/'aplicar_piloto_v4.py').read_text(encoding='utf-8'),str(D/'aplicar_piloto_v4.py'),'exec'),{'__file__':str(D/'aplicar_piloto_v4.py')})
exec(compile((D/'aplicar_child_v3.py').read_text(encoding='utf-8'),str(D/'aplicar_child_v3.py'),'exec'),{'__file__':str(D/'aplicar_child_v3.py')})
exec(compile((D/'aplicar_alternativas_aprovadas.py').read_text(encoding='utf-8'),str(D/'aplicar_alternativas_aprovadas.py'),'exec'),{'__file__':str(D/'aplicar_alternativas_aprovadas.py')})
exec(compile((D/'aplicar_adultos_alternativos.py').read_text(encoding='utf-8'),str(D/'aplicar_adultos_alternativos.py'),'exec'),{'__file__':str(D/'aplicar_adultos_alternativos.py')})
