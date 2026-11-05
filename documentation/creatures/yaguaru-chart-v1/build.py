from pathlib import Path
import json,shutil,hashlib,os
from html import escape
from PIL import Image,ImageOps,ImageDraw,ImageFont
D=Path(__file__).resolve().parent;R=D.parents[2];G=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f')
prompts=json.loads((D/'prompts.json').read_text(encoding='utf-8'))
specs=[('yaguim','Yaguim','Bebê','Cabeça-pipa felina sem torso ou patas, faixa diagonal e rabiola curta.','Aprende a sustentar a primeira dobra e o primeiro nó.','exec-8f85115e-cf49-4949-be48-2d55bc0d31b4.png'),('yaguaru-memoria','Yaguarú','Criança existente','Onça ocre de rosetas angulares, faixas creme, vela e cauda com fitas.','Base autoral preservada; classificação de maturidade documental.',None),('yaguarda','Yaguarda','Jovem','Onça quadrúpede de ombros robustos, placas iniciais e manoplas de garras.','Protege com apoios firmes e aprende a distribuir tensão pelas faixas.','exec-7c578b45-1ae2-40b3-8d27-ca67b31c2b39.png'),('yaguarion','Yaguarion','Adulto cavaleiro','Elmo de onça cobre região ocular; nariz e boca humanoides visíveis, couraça de faixas e manoplas.','Reorganiza corpo e construção em cavaleiro; origem e voto indefinidos.',None)]
refs=['art/soulgen/keys/yaguaru-memoria/color-rig-v2/preview.png','art/creatures/onze-cavaleiros-v1/yaguarion/concept-v2/concept.png'];nodes=[]
for stage,(id,name,age,identity,story,source) in enumerate(specs,1):
 if source:
  folder=R/'art/creatures/yaguaru-family-v1'/id/'concept-v1';folder.mkdir(parents=True,exist_ok=True);art=folder/'concept.png';shutil.copy2(G/source,art)
  (folder/'prompt.txt').write_text(prompts[id],encoding='utf-8');brief=folder/'brief.md'
  brief.write_text(f'# {name} — {age}\n\nPedido: criar bebê e jovem da mesma linhagem do cavaleiro aprovado. Base Yaguarú atual, não Jaguarluar.\nProposta: {identity}\nHistória visual: {story}\nHerança: ocre/creme, rosetas angulares, faixas estruturais, nós vermelhos e rabiola vermelha/verde inteira. Nome, anatomia de novo estágio e requisitos são propostas; não incorporar ao cânone como regras.\n45% criatura,45% pipa viva,10% acabamento seletivo pixel/2D mangá; sem alegação de pixel art técnico. Concept em avaliação, sem rig ou integração.\n',encoding='utf-8')
  review='Sem tronco ou patas; duas orelhas, face felina, faixa acima dos olhos e rabiola curta conectada. Muito mais simples que a criança.' if id=='yaguim' else 'Quatro patas visíveis, face felina madura sem rosto humano, ombreira assimétrica, garras em duas proteções dianteiras e dois painéis dorsais unidos. Cauda curva e fitas completas. Densidade de nós e faixas maior que no bebê; conferir em escala de jogo ao produzir sprite.'
  (folder/'revisao.md').write_text('# Conferência\n\n'+review+'\nContornos limpos e sombra cel; alguns planos facetados permanecem na ilustração. Aguardando aprovação do autor. Imagem isolada com fundo branco, sem recortes animáveis.\n',encoding='utf-8')
  with Image.open(art) as im:meta=dict(id=id,tool='image_gen.imagegen',source=str(G/source),width=im.width,height=im.height,mode=im.mode,sha256=hashlib.sha256(art.read_bytes()).hexdigest(),references=refs,decision_status='proposed',production_status='concept',implementation='não integrado',external_images_used_for_generation=False,technical_pixel_art=False)
  (folder/'manifest.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf-8')
 elif id=='yaguaru-memoria':art=R/refs[0];brief=R/'art/soulgen/keys/yaguaru-memoria/README.md'
 else:art=R/refs[1];brief=art.parent/'brief.md'
 rel=lambda p:os.path.relpath(p,D).replace('\\','/')
 n=dict(id=id,name=name,age=age,kind='stage',stage=stage,identity=identity,story=story,decision_status='proposed' if source else 'approved',production_status='concept',art=rel(art),brief=rel(brief))
 if not source:n['approval_note']='README registra base final importada do autor.' if id=='yaguaru-memoria' else 'Autor: aprovadissimo, após revisão do elmo concept-v2.'
 nodes.append(n)
edges=[dict(**{'from':a['id'],'to':b['id']},kind='reweaving',decision_status='proposed',reason=r) for a,b,r in zip(nodes,nodes[1:],['Primeira cabeça-pipa adquire quatro apoios e vela.','Faixas e apoios ganham função de proteção e contenção.','Postura se reorganiza em cavaleiro de elmo e couraça de faixas.'])]
(D/'chart.json').write_text(json.dumps(dict(family_id='yaguaru-memoria',scope='Dois concepts novos; base e cavaleiro preservados; sem integração.',nodes=nodes,edges=edges),ensure_ascii=False,indent=2),encoding='utf-8')
(D/'CHART.md').write_text('# Yaguarú — da primeira faixa à armadura\n\nYaguim → Yaguarú → Yaguarda → Yaguarion.\n\nBebê e jovem são novos concepts em avaliação. Base final do autor e cavaleiro concept-v2 preservados. Nome dos novos, distribuição por estágios, ligações, obtenção e voto continuam propostas ou indefinidos. O rosto humanoide aparece apenas no cavaleiro; jovem mantém cabeça inteiramente felina.\n\nInputs próprios: montagem atual do Yaguarú e Yaguarion aprovado. Nenhum design externo foi usado como input. Não alterados rigs, código, história ou gameplay.\n',encoding='utf-8')
mini=D/'miniaturas';mini.mkdir(exist_ok=True);sheet=Image.new('RGB',(1600,1400),'white');draw=ImageDraw.Draw(sheet);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',25)
for i,n in enumerate(nodes):
 with Image.open(D/n['art']) as im:
  a=im.convert('RGBA');box=a.getchannel('A').getbbox();a=a.crop(box) if box else a;w=Image.new('RGBA',a.size,'white');w.alpha_composite(a);t=ImageOps.contain(w.convert('RGB'),(750,600),Image.Resampling.LANCZOS)
 t.save(mini/(n['id']+'.png'));x=i%2*800;y=i//2*700;sheet.paste(t,(x+(800-t.width)//2,y+(610-t.height)//2));draw.text((x+24,y+632),n['name']+' · '+n['age'],font=font,fill='#4c301d')
sheet.save(D/'familia.png')
cards=''.join(f'<article><h2>{escape(n["name"])} · {n["age"]}</h2><a href="{n["art"]}"><img src="miniaturas/{n["id"]}.png" alt="{escape(n["identity"])}"></a><p>{escape(n["story"])}</p><a href="{n["brief"]}">Brief</a></article>' for n in nodes)
(D/'index.html').write_text('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Família Yaguarú</title><style>body{max-width:1250px;margin:auto;padding:24px;background:#f4f0e5;color:#463321;font:18px/1.6 system-ui}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px}article{background:white;padding:24px}img{width:100%;height:430px;object-fit:contain}a{color:#27604b}a:focus-visible{outline:3px solid #b05021}@media(max-width:700px){.grid{grid-template-columns:1fr}}</style><h1>Yaguarú · da primeira faixa à armadura</h1><p>Bebê e jovem em avaliação; criança autoral e adulto aprovado preservados. Nomes novos e ligações são propostas. Sem integração.</p><p><a href="familia.png">Comparar família</a> · <a href="CHART.md">Decisões</a></p><main class="grid">'+cards+'</main></html>',encoding='utf-8')
print('Salvos bebê, jovem e chart de quatro formas.')
exec(compile((D/'registrar_aprovacao.py').read_text(encoding='utf-8'),str(D/'registrar_aprovacao.py'),'exec'),{'__file__':str(D/'registrar_aprovacao.py')})
