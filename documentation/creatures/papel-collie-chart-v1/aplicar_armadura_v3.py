from pathlib import Path
from PIL import Image,ImageOps,ImageDraw,ImageFont
import json,hashlib,shutil,os
D=Path(__file__).resolve().parent;R=D.parents[2];A=R/'art/creatures/alvacordo-family-v1/alvacordo';P=A/'concept-v3'
source=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f/exec-50878a78-15e8-47d4-b31e-beda77ef8f95.png')
shutil.copy2(source,P/'concept.png')
(P/'brief.md').write_text('# Alvacordo — armadura v3\n\n## Pedido do autor\n“Gostei muito do que vejo”, mas substituir a pelagem do peitoral para baixo por placas para facilitar reprodução, estudando a armadura de Dukemon. Aprovação parcial da identidade anterior, com revisão do corpo.\n\n## Construção proposta\nPeitoral marfim com inserto petróleo em cunha; duas placas abdominais; cintura petróleo; duas abas de proteção da anca; coxas de superfícies lisas; uma joelheira por perna; caneleiras longas; tornozelos livres e pés caninos protegidos. Ombreiras escuras e cotovelos articulados. Gola, três fitas do pequeno manto e cauda mantêm papel. Armações curvas dos antebraços, face, cores e rabiola preservadas como identidade.\n\nDukemon foi observado em arte oficial local apenas como estudo de placas grandes e intervalos de articulação. A imagem externa não foi input da geração. Sem copiar símbolos, armas, elmo ou paleta. Nome, elemento, obtenção e mecânicas continuam propostas/desconhecidos.\n',encoding='utf-8')
(P/'revisao.md').write_text('# Conferência\n\nNova imagem inspecionada: cabeça e gola conservadas; duas mãos, duas pernas, dois pés caninos e uma cauda completa. As superfícies pontiagudas repetidas do tronco e pernas foram substituídas por peitoral, duas placas abdominais, abas de quadril, joelheiras e caneleiras. Juntas escuras distinguem os segmentos. Armações dos antebraços e rabiola única mantidas; não reapareceram flâmulas no punho.\n\nLimites: uma vista não valida todos os encaixes de articulação; parte da raiz da cauda está oclusa. Pequenas mudanças de proporção da edição generativa, incluindo ombros mais cheios e pés protegidos. São propostas, não preservação exata de pixels. Há suaves sombras residuais. Não é rig, pixel art em grade ou animação. Nova armadura em avaliação pelo autor.\n',encoding='utf-8')
with Image.open(P/'concept.png') as im:size=list(im.size);mode=im.mode
(P/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen built-in',source=str(source),sha256=hashlib.sha256((P/'concept.png').read_bytes()).hexdigest(),dimensions=size,mode=mode,alpha=False,prompt='prompt.txt',reference_role='Own Alvacordo v2 edit target; external Dukemon art studied only',external_generation_inputs=False,decision_status='proposed',production_status='concept',implementation_status='not_integrated'),ensure_ascii=False,indent=2),encoding='utf-8')
mp=A/'concept-v2/manifest.json';m=json.loads(mp.read_text(encoding='utf-8'));m.update(decision_note='Identidade recebida positivamente; autor solicitou revisão do corpo em armadura. V2 preservada como histórico, sem aprovação integral da pelagem.');mp.write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
p=D/'chart.json';c=json.loads(p.read_text(encoding='utf-8'))
for n in c['nodes']:
 if n['id']=='alvacordo':
  n.update(art=Path(os.path.relpath(P/'concept.png',D)).as_posix(),brief=Path(os.path.relpath(P/'brief.md',D)).as_posix(),identity='Guardião canino bípede, armadura lisa do peitoral para baixo, gola de papel e armações recurvas nos antebraços.',decision_status='proposed',revision='concept-v3')
p.write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf-8')
p=D/'index.html';t=p.read_text(encoding='utf-8').replace('alvacordo/concept-v2/','alvacordo/concept-v3/').replace('Alvacordo · Adulto</h2>','Alvacordo · Adulto — armadura v3</h2>');p.write_text(t,encoding='utf-8')
p=D/'CHART.md';t=p.read_text(encoding='utf-8');note='\n\n## Revisão adulta v3 — placas de armadura\nAutor gostou da família e solicitou simplificar a reprodução da adulta: placas do peitoral para baixo em vez de pelagem repetida. Arte externa Dukemon inspecionada apenas para estudo de articulação, não input. Nova adulta v3 em avaliação. Identidade facial, armações, cores e rabiola continuam; concepts anteriores preservados.\n'
if '## Revisão adulta v3' not in t:p.write_text(t+note,encoding='utf-8')
sheet=Image.new('RGB',(1800,1500),'#f4f3ee');dr=ImageDraw.Draw(sheet);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',28)
for i,n in enumerate(c['nodes']):
 x=i%2*900;y=i//2*750
 with Image.open(D/n['art']) as im:tile=ImageOps.contain(im.convert('RGB'),(850,640));sheet.paste(tile,(x+(900-tile.width)//2,y+75+(640-tile.height)//2))
 dr.text((x+24,y+20),n['name']+' · '+n['maturity']+(' — armadura v3' if n['id']=='alvacordo' else ' (proposta)'),font=font,fill='#173c40')
sheet.save(D/'familia.png')
print('Armadura v3 salva e chart atualizado; versões anteriores preservadas.')
if (D/'aplicar_armadura_v4.py').exists():
 import runpy
 runpy.run_path(str(D/'aplicar_armadura_v4.py'))
