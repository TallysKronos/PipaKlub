from pathlib import Path
from PIL import Image,ImageOps,ImageDraw,ImageFont
import json,hashlib,shutil,os
D=Path(__file__).resolve().parent;R=D.parents[2];A=R/'art/creatures/alvacordo-family-v1/alvacordo';P=A/'concept-v4'
source=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f/exec-a402bc13-9b3d-44a2-9337-59ee4b988bdf.png')
shutil.copy2(source,P/'concept.png')
(P/'brief.md').write_text('# Alvacordo — armadura v4\n\nAutor considerou a armadura v3 básica e apontou leitura interrompida do braço esquerdo. Pediu estudar Dukemon e Beelzebumon.\n\n## Direção proposta\nPeitoral de pipa com janela petróleo, moldura de vareta dourada e tirantes vermelhos ligando dois hubs. Ombreiras e abas de quadril em dois volumes grandes, bordas relevadas e juntas escuras, nervuras nas caneleiras e fechos vermelhos. Contraste entre placas e regiões flexíveis, sem voltar a cobrir pernas de pelos. Armações deslocadas para fora dos antebraços e conectadas por suportes visíveis. Braço esquerdo, à direita da imagem, aberto e com mão abaixo da armação. Cabeça canina, gola, paleta e rabiola preservadas.\n\n## Pesquisa\nArtes oficiais Dukemon e Beelzebumon abertas e observadas. Dukemon: hierarquia de volumes rígidos e articulação; Beelzebumon: intervalos flexíveis, tiras e contraste entre materiais. Interpretação visual aplicada, sem copiar armas, elmos, roupas, símbolos ou lore. Apenas Alvacordo v3 entrou na geração.\n',encoding='utf-8')
(P/'revisao.md').write_text('# Conferência visual\n\nDois braços completos visíveis. No esquerdo (direita da imagem), ombro, braço, cotovelo, antebraço, punho e mão formam uma sequência contínua; armação fica na lateral, com dois suportes. Mão deixa de flutuar dentro da armação. Peitoral, ombreiras, quadril e pernas ganharam formas e detalhes próprios, mantendo regiões amplas. Uma cauda/rabiola, duas pernas e dois pés caninos.\n\nLimites: dedos em perspectiva exigem padronização numa prancha técnica; mecanismo e alcance dos suportes não foram testados em rig. Há sombreamento suave residual. Uma imagem não comprova funcionamento mecânico, pixel art de grade ou animação. V4 proposta, não aprovada automaticamente. V3 preservada como revisão solicitada.\n',encoding='utf-8')
with Image.open(P/'concept.png') as im:size=list(im.size);mode=im.mode
(P/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen built-in',source=str(source),sha256=hashlib.sha256((P/'concept.png').read_bytes()).hexdigest(),dimensions=size,mode=mode,alpha=False,prompt='prompt.txt',reference_role='Own Alvacordo v3 edit target; external art studied only',external_generation_inputs=False,decision_status='proposed',production_status='concept',implementation_status='not_integrated'),ensure_ascii=False,indent=2),encoding='utf-8')
mp=A/'concept-v3/manifest.json';m=json.loads(mp.read_text(encoding='utf-8'));m.update(decision_status='superseded',decision_note='Autor pediu armadura menos básica e braço esquerdo legível.');mp.write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
p=D/'chart.json';c=json.loads(p.read_text(encoding='utf-8'))
for n in c['nodes']:
 if n['id']=='alvacordo':n.update(art=Path(os.path.relpath(P/'concept.png',D)).as_posix(),brief=Path(os.path.relpath(P/'brief.md',D)).as_posix(),identity='Guardião canino com peitoral-pipa de tirantes, armadura de placas relevadas, braços completos e armações montadas lateralmente.',decision_status='proposed',revision='concept-v4')
p.write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf-8')
p=D/'index.html';t=p.read_text(encoding='utf-8').replace('alvacordo/concept-v3/','alvacordo/concept-v4/').replace('armadura v3','armadura v4');p.write_text(t,encoding='utf-8')
p=D/'CHART.md';t=p.read_text(encoding='utf-8');note='\n\n## Revisão adulta v4 — identidade da armadura e braço\nAutor apontou armadura básica e braço esquerdo desaparecido. V4 reposiciona armações na lateral dos antebraços, expõe os dois braços completos e cria peitoral-pipa com tirantes, placas com nervuras e fechos. Dukemon e Beelzebumon estudados visualmente, sem uso como inputs. Nova arte em avaliação.\n'
if '## Revisão adulta v4' not in t:p.write_text(t+note,encoding='utf-8')
p=D/'fontes.json';sources=json.loads(p.read_text(encoding='utf-8'))
for slug,title,local in [('dukemon','Gallantmon / Dukemon','../../../art/benchmarks/royal-knights-2026-11-03/referencias/dukemon.jpg'),('beelzebumon','Beelzemon / Beelzebumon','referencias/beelzebumon.jpg')]:
 if not any(s.get('title')==title for s in sources):sources.append(dict(title=title,url=f'https://digimon.net/reference_en/detail.php?directory_name={slug}',entity='Bandai / Digimon Web',access='2026-11-04',local_art=local,interpretation='Estudo visual de volumes rígidos, intervalos articulares e contraste de materiais; não copiar designs.',proposed_use='Revisão da armadura Alvacordo v4; sem input externo de geração'))
p.write_text(json.dumps(sources,ensure_ascii=False,indent=2),encoding='utf-8')
sheet=Image.new('RGB',(1800,1500),'#f4f3ee');dr=ImageDraw.Draw(sheet);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',28)
for i,n in enumerate(c['nodes']):
 x=i%2*900;y=i//2*750
 with Image.open(D/n['art']) as im:tile=ImageOps.contain(im.convert('RGB'),(850,640));sheet.paste(tile,(x+(900-tile.width)//2,y+75+(640-tile.height)//2))
 dr.text((x+24,y+20),n['name']+' · '+n['maturity']+(' — armadura v4' if n['id']=='alvacordo' else ' (proposta)'),font=font,fill='#173c40')
sheet.save(D/'familia.png')
print('V4 salva; chart e comparativo atualizados.')
if (D/'aprovar_alvacordo_v4.py').exists():
 import runpy
 runpy.run_path(str(D/'aprovar_alvacordo_v4.py'))
