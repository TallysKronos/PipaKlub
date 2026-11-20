from pathlib import Path
import json,hashlib,shutil,os
from PIL import Image,ImageOps,ImageDraw,ImageFont
D=Path(__file__).resolve().parent;R=D.parents[2];F=R/'art/creatures/tramino-family-v1/tramassauro';G=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f')
for s in json.loads((D/'cabeca-c-correcao.json').read_text(encoding='utf-8')):
 P=F/s['id'];P.mkdir(parents=True,exist_ok=True)
 if not(P/'concept.png').exists():shutil.copy2(G/s['file'],P/'concept.png')
 (P/'prompt.txt').write_text(s['prompt'],encoding='utf-8')
 (P/'brief.md').write_text('# Cabeça correta e proporção\n\nAutor esclareceu por imagem que pretendia a cabeça índigo/marfim (C/Tirante), não o focinho longo B/Espreita. Corrige a interpretação anterior. Criar corpo semiereto compacto para esta cabeça; após v6, autor pediu diminuir cabeça exagerada. V7 aplica edição proporcional com meta de 30%, sem redesenho deliberado do corpo. Escolha facial não aprova automaticamente corpo ou versão final.\n\nOrigem autoral: rostos-v1/c-tirante/concept.png. Bebê e criança preservados. Adulto antigo rejeitado, sem substituição nesta revisão. Sem integração.',encoding='utf-8')
 (P/'revisao.md').write_text('# Conferência\n\n'+s['review']+'\n\nFundo branco e sombras suaves residuais. Ilustração manga, não pixel art de grid validado ou prova de animação.',encoding='utf-8')
 with Image.open(P/'concept.png') as im:size=list(im.size);mode=im.mode
 (P/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen built-in',source=str(G/s['file']),sha256=hashlib.sha256((P/'concept.png').read_bytes()).hexdigest(),dimensions=size,mode=mode,reference_role='Own selected C/Tirante face' if s['id']=='concept-v6' else 'Own body concept-v6, head proportional edit',external_generation_inputs=False,decision_status=s['status'],production_status='concept',implementation_status='not_integrated'),ensure_ascii=False,indent=2),encoding='utf-8')
for face in ['b-espreita','c-tirante']:
 P=F/'rostos-v1'/face/'manifest.json';m=json.loads(P.read_text(encoding='utf-8'));m.update(decision_status='selected_by_author' if face=='c-tirante' else 'proposed',selection_note='Autor esclareceu por imagem: a direção é C/Tirante. Referência anterior a B foi interpretada incorretamente.');P.write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
P=F/'concept-v5/manifest.json';m=json.loads(P.read_text(encoding='utf-8'));m.update(decision_status='superseded_wrong_direction',decision_note='Corpo criado para focinho longo por interpretação errada da seleção; não é a direção solicitada.');P.write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
P=F/'concept-v7';chart=json.loads((D/'chart.json').read_text(encoding='utf-8'));oldart=None
for n in chart['nodes']:
 if n['id']=='tramassauro':
  oldart=n['art'];n.update(art=Path(os.path.relpath(P/'concept.png',D)).as_posix(),brief=Path(os.path.relpath(P/'brief.md',D)).as_posix(),identity='Jovem semiereto índigo/coral de cabeça C/Tirante em escala menor, corpo compacto e membrana no antebraço.',story='Aprende a sustentar e orientar tensão com base firme e gestos controlados.',decision_status='proposed',revision='concept-v7',head_direction='C/Tirante — confirmado pela imagem do autor',review_note='v6 tinha cabeça exagerada; v7 edição proporcional em avaliação.')
chart['scope']='Direção facial corrigida para C/Tirante por imagem do autor; corpo jovem v7 em avaliação após reduzir cabeça. Bebê/criança preservadas, adulto antigo rejeitado.'
(D/'chart.json').write_text(json.dumps(chart,ensure_ascii=False,indent=2),encoding='utf-8')
p=D/'index.html';page=p.read_text(encoding='utf-8');newart=Path(os.path.relpath(P/'concept.png',D)).as_posix()
if oldart:page=page.replace(oldart,newart)
page=page.replace('Rosto B / corpo v5 em avaliação','Rosto C / proporção v7 em avaliação').replace('Direção facial B escolhida. Corpo v5 em avaliação','Direção facial corrigida para C/Tirante. Cabeça reduzida na v7, em avaliação').replace('uma anatomia para a cabeça B','cabeça C e proporções').replace('Tramino · cabeça B e corpo','Tramino · cabeça C e proporção')
p.write_text(page,encoding='utf-8')
sheet=Image.new('RGB',(1800,1400),'#faf7f0');draw=ImageDraw.Draw(sheet);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',24)
for k,n in enumerate(chart['nodes']):
 with Image.open(D/n['art']) as im:t=ImageOps.contain(im.convert('RGB'),(850,590));x=k%2*900;y=k//2*700;sheet.paste(t,(x+(900-t.width)//2,y+75+(590-t.height)//2))
 status='Histórico REJEITADO' if n['decision_status']=='rejected' else 'Preservado' if n['stage']<3 else 'Rosto C / v7 em avaliação';draw.text((x+20,y+15),n['name']+' · '+status,font=font,fill='#282443')
sheet.save(D/'familia.png')
note='\n\n## Correção de seleção e proporção — C/Tirante\n\nAutor esclareceu por imagem que escolheu a cabeça índigo/marfim (C), não o focinho longo (B). V5 foi baseada em interpretação equivocada. Novo corpo v6 teve cabeça exagerada; v7 aplica redução proporcional pedida, em avaliação. Esta decisão supera os registros anteriores de seleção B.\n'
p=D/'CHART.md';text=p.read_text(encoding='utf-8')
if '## Correção de seleção e proporção' not in text:p.write_text(text+note,encoding='utf-8')
print('Seleção corrigida para C, histórico preservado e corpo v7 registrado.')
exec(compile((D/'aplicar_cavaleiro_adulto_v3.py').read_text(encoding='utf-8'),str(D/'aplicar_cavaleiro_adulto_v3.py'),'exec'),{'__file__':str(D/'aplicar_cavaleiro_adulto_v3.py')})
