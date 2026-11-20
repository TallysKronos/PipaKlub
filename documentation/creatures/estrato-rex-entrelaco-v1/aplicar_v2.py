from pathlib import Path
from PIL import Image,ImageOps,ImageDraw,ImageFont
import json,hashlib,shutil,os
D=Path(__file__).resolve().parent;R=D.parents[2];P=R/'art/creatures/paleorix/concept-v2'
source=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f/exec-84dfb6d6-b281-4a22-a264-0993695b26a1.png');shutil.copy2(source,P/'concept.png')
(P/'brief.md').write_text('# Paleórix — segunda direção\n\nAutor pediu corpo magrelo como proporção de Omnimon e face geométrica no sentido de máscara angular, sem favorecer um dinossauro nem parecer robô.\n\nProposta: pernas longas, cintura estreita, peitoral pequeno e ombreiras contidas. Cabeça de máscara fóssil simétrica, olhos estreitos e viseira fechada sem focinho. Mandíbula de ruptura, escudo em braço vertebral, manto de papel e dois conjuntos de rabiolas mantêm a fusão. Silhueta esguia é alternativa à v1 robusta, preservada. Funções, duração, obtenção e estágio continuam propostas/desconhecidos.\n\nSomente v1 autoral entrou como input; referência externa de proporção foi observada, não usada na geração.\n',encoding='utf-8')
(P/'revisao.md').write_text('# Conferência\n\nDuas pernas longas, dois braços ligados ao torso, mão central da mandíbula e mão no punho vertebral legíveis. Cabeça com planos centrais, olhos estreitos e face fechada; sem focinho alongado de um dos parceiros. Ombros menores, cintura e peito estreitos, cauda mantém os dois conjuntos de flâmulas. Materiais orgânicos de osso/papel, sem pistões ou eletrônicos.\n\nLimites: viseira tem ponta alongada e prongas laterais pequenas; avaliar se a leitura desejada é alcançada. Ressonador é pequeno e menos evidente. Proporções novas exigem vistas de lado/costas e padronização de mãos. Não é rig, pixel art de grade ou integração. V2 em avaliação; v1 preservada.\n',encoding='utf-8')
with Image.open(P/'concept.png') as im:size=list(im.size);mode=im.mode
(P/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen built-in',source=str(source),sha256=hashlib.sha256((P/'concept.png').read_bytes()).hexdigest(),dimensions=size,mode=mode,alpha=False,prompt='prompt.txt',reference_role='Own Paleorix v1 for ancestry; external proportions studied only',external_generation_inputs=False,decision_status='proposed',production_status='concept',implementation_status='not_integrated'),ensure_ascii=False,indent=2),encoding='utf-8')
p=D/'chart.json';c=json.loads(p.read_text(encoding='utf-8'))
for n in c['nodes']:
 if n['id']=='paleorix':n.update(art=Path(os.path.relpath(P/'concept.png',D)).as_posix(),brief=Path(os.path.relpath(P/'brief.md',D)).as_posix(),identity='Guardião fóssil esguio, máscara angular fechada, mandíbula de ruptura e escudo vertebral.',revision='concept-v2')
p.write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf-8')
p=D/'index.html';t=p.read_text(encoding='utf-8').replace('paleorix/concept-v1/','paleorix/concept-v2/').replace('Entrelaço em avaliação; requisitos e mecânicas indefinidos.','Segunda direção esguia em avaliação; requisitos e mecânicas indefinidos.');p.write_text(t,encoding='utf-8')
note='\n\n## Segunda versão — direção esguia\nAutor pediu proporção magrela e rosto angular neutro entre os parceiros, sem aparência de robô. Criada v2 esguia com máscara fechada. V1 robusta preservada; v2 em avaliação, sem aprovação automática.\n'
for p in [D/'CHART.md',D/'ESTUDO.md']:
 t=p.read_text(encoding='utf-8')
 if '## Segunda versão' not in t:p.write_text(t+note,encoding='utf-8')
sheet=Image.new('RGB',(1800,1250),'#f4f1e9');dr=ImageDraw.Draw(sheet);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',30)
for i,v in enumerate(['concept-v1','concept-v2']):
 with Image.open(R/'art/creatures/paleorix'/v/'concept.png') as im:tile=ImageOps.contain(im.convert('RGB'),(850,1120));sheet.paste(tile,(i*900+(900-tile.width)//2,85+(1120-tile.height)//2))
 dr.text((i*900+24,20),'Paleórix '+('v1 · robusto' if i==0 else 'v2 · esguio (proposta)'),font=font,fill='#303750')
sheet.save(D/'versoes.png')
print('Paleórix v2 salvo; v1 preservada para comparação.')
if (D/'aprovar_v2.py').exists():
 import runpy
 runpy.run_path(str(D/'aprovar_v2.py'))
