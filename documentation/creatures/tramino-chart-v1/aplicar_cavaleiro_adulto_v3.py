from pathlib import Path
import json,hashlib,shutil,os
from html import escape
from PIL import Image,ImageOps,ImageDraw,ImageFont
D=Path(__file__).resolve().parent;R=D.parents[2];F=R/'art/creatures/tramino-family-v1/tramadraco';G=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f')
for s in json.loads((D/'cavaleiro-adulto.json').read_text(encoding='utf-8')):
 P=F/s['id'];P.mkdir(parents=True,exist_ok=True)
 if not(P/'concept.png').exists():shutil.copy2(G/s['file'],P/'concept.png')
 (P/'prompt.txt').write_text(s['prompt'],encoding='utf-8')
 (P/'brief.md').write_text('# Cavaleiro adulto de Tramino — rótulo Tramadraco\n\nDefinido pelo autor: acima da jovem aceita, cavaleiro próximo da estrutura de Alphamon, cristal de pipa no alto do peito, capa destruída e espada. Correção posterior: parte superior do helmet com shape de dragão e parte inferior com viseira fechada.\n\nProposta: armadura índigo/marfim de grandes superfícies laminadas, bordas estruturais douradas e acentos coral herdados. Cristal âmbar em pipa no esterno alto; cabeça pequena diante de ombros largos e braços pesados. Capa índigo forrada de marfim com grandes rasgos; espada única de guarda em tirantes e nó; rabiola com duas abas. Continuidade da face anterior reorganizada em armadura craniana, sem rosto infantil ou boca exposta.\n\nNome definitivo, requisitos, voto e poder do cristal não definidos. Referência própria de geração: jovem concept-v7; a revisão usa o próprio primeiro cavaleiro. Fonte externa estudada, sem imagem no input: https://digimon.net/reference_en/detail.php?directory_name=alphamon, consultada em 04/11/2026. Perfil associa Alphamon a função cavaleiresca e capa; leitura visual de grande massa de ombros/antebraços, cintura flexível e cabeça menor. Não transportar símbolos, elmo exato, poderes, afiliação ou painel por painel.\n\n45% criatura /45% pipa /10% acabamento são direção, não medida em pixels. Sem integração, lore adicional ou alteração de rigs existentes.',encoding='utf-8')
 (P/'revisao.md').write_text('# Conferência\n\n'+s['review']+'\n\nFundo branco opaco; leves transições suaves e facetas residuais, não pixel art de grade validada. Concept em avaliação, sem rig, animação ou integração.',encoding='utf-8')
 with Image.open(P/'concept.png') as im:size=list(im.size);mode=im.mode
 (P/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen built-in',source=str(G/s['file']),sha256=hashlib.sha256((P/'concept.png').read_bytes()).hexdigest(),dimensions=size,mode=mode,reference_role='Own young Tramassauro concept-v7 ancestry' if s['id']=='concept-v2' else 'Own adult knight concept-v2, directed helmet edit',external_generation_inputs=False,decision_status=s['status'],production_status='concept',implementation_status='not_integrated'),ensure_ascii=False,indent=2),encoding='utf-8')
Y=R/'art/creatures/tramino-family-v1/tramassauro/concept-v7/manifest.json';m=json.loads(Y.read_text(encoding='utf-8'));m.update(decision_status='approved',approval_note='Autor: Ok tudo bem para esse, agora gere um cavaleiro que vai ficar acima dessa evolução',approval_scope='Concept jovem v7; não rig ou integração.');Y.write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
chart=json.loads((D/'chart.json').read_text(encoding='utf-8'));P=F/'concept-v3'
for n in chart['nodes']:
 if n['id']=='tramassauro':n.update(decision_status='approved',approval_note=m['approval_note'],review_note='Jovem v7 aceita antes do pedido de cavaleiro adulto.')
 if n['id']=='tramadraco':n.update(name='Tramadraco — cavaleiro (nome proposto)',art=Path(os.path.relpath(P/'concept.png',D)).as_posix(),brief=Path(os.path.relpath(P/'brief.md',D)).as_posix(),identity='Cavaleiro de armadura índigo/marfim, elmo dracônico com viseira fechada, cristal de pipa alto no peito, capa destruída e espada.',story='A técnica de sustentar tensão torna-se guarda e compromisso, interpretados como cavaleiro adulto.',decision_status='proposed',revision='concept-v3',review_note='Nova direção adulta solicitada, correção de elmo em avaliação.')
for e in chart['edges']:
 if e['to']=='tramadraco':e.update(decision_status='proposed',reason='O autor pediu cavaleiro acima da jovem; peito e tirantes se reorganizam em armadura, elmo e guarda de espada.',requirements_status='undefined')
chart['scope']='Jovem v7 aprovada visualmente. Cavaleiro adulto v3 com elmo corrigido em avaliação. Bebê/criança preservadas, sem integração.'
(D/'chart.json').write_text(json.dumps(chart,ensure_ascii=False,indent=2),encoding='utf-8')
cards=[];sheet=Image.new('RGB',(1800,1400),'#faf7f0');draw=ImageDraw.Draw(sheet);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',24)
for k,n in enumerate(chart['nodes']):
 status='Jovem aprovada' if n['id']=='tramassauro' else 'Cavaleiro em avaliação' if n['id']=='tramadraco' else 'Preservado'
 with Image.open(D/n['art']) as im:t=ImageOps.contain(im.convert('RGB'),(850,590));x=k%2*900;y=k//2*700;sheet.paste(t,(x+(900-t.width)//2,y+75+(590-t.height)//2))
 draw.text((x+20,y+15),n['name']+' · '+status,font=font,fill='#282443')
 cards.append('<article><h2>'+escape(n['name'])+'</h2><b>'+status+'</b><a href="'+n['art']+'"><img src="'+n['art']+'" alt="'+escape(n['identity'])+'"></a><p>'+escape(n['story'])+'</p><a href="'+n['brief']+'">Brief</a></article>')
sheet.save(D/'familia.png')
(D/'index.html').write_text('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Tramino · jovem e cavaleiro</title><style>body{max-width:1250px;margin:auto;padding:24px;background:#faf5e9;color:#282443;font:18px/1.6 system-ui}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px}article{padding:24px;background:white}img{width:100%;height:430px;object-fit:contain}a:focus-visible{outline:3px solid #cf4c2e}@media(max-width:700px){.grid{grid-template-columns:1fr}}</style><h1>Tramino · do parceiro ao cavaleiro</h1><p>Jovem v7 aprovada. Cavaleiro adulto v3 com elmo dracônico e viseira inferior fechada em avaliação; nomes novos e requisitos não definidos.</p><a href="CHART.md">Decisões</a> · <a href="familia.png">Comparativo</a><main class="grid">'+''.join(cards)+'</main></html>',encoding='utf-8')
note='\n\n## Jovem aceita e cavaleiro adulto\n\nAutor aceitou jovem v7 e pediu adulto com estrutura de Alphamon, cristal em pipa alto no peito, capa destruída e espada. Cavaleiro v2 recebeu correção de elmo: v3 possui parte superior dracônica e visor inferior fechado. Adulto em avaliação. Nova direção supera o dragão adulto genérico v1 rejeitado.\n'
p=D/'CHART.md';text=p.read_text(encoding='utf-8')
if '## Jovem aceita e cavaleiro adulto' not in text:p.write_text(text+note,encoding='utf-8')
print('Jovem aceita registrada, adulto v3 salvo e chart atualizado.')
exec(compile((D/'aplicar_primeiros_v2.py').read_text(encoding='utf-8'),str(D/'aplicar_primeiros_v2.py'),'exec'),{'__file__':str(D/'aplicar_primeiros_v2.py')})
