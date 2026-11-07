from pathlib import Path
import json,shutil,hashlib
from PIL import Image,ImageOps,ImageDraw
D=Path(__file__).resolve().parent;R=D.parents[2]
A=R/'art/creatures/urso-polar-family-v1';F=A/'borealvo/concept-v2'
source=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f/exec-576459c1-cbf7-4d20-a58e-7f989230e938.png')
shutil.copy2(source,F/'concept.png')
shutil.copy2(F.parent/'concept-v1/brief.md',F/'brief.md')
(F/'revisao.md').write_text('# Cabeça v2\n\nPedido: focinho menos exagerado e pequenas deformações de pelagem, como dois picos nas bochechas, evitando cabeça lisa e genérica.\n\nObservado: focinho mais compacto, duas grandes pontas na bochecha visível e poucos recortes no topo. O alto ganhou três saliências principais, em vez das duas previstas. Olhar estreito e nariz escuro mantidos; sem juba ou microtextura de pelo. Corpo, manto, arma, bracelete e rabiola conservam a leitura da versão anterior, sem alegar identidade pixel a pixel fora da edição.\n\nProposta em conferência, sem aprovação. Histórico v1 preservado. Permanecem os limites de contagem de unhas descritos na V1; nenhuma produção técnica ou integração.\n',encoding='utf-8')
im=Image.open(F/'concept.png')
(F/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen',source=source.name,sha256=hashlib.sha256((F/'concept.png').read_bytes()).hexdigest(),dimensions=list(im.size),mode=im.mode,alpha='A' in im.getbands(),prompt='prompt.txt',own_reference_inputs=[dict(path='../concept-v1/concept.png',role='Alvo: edição dirigida da cabeça, preservando restante do design')],decision_status='proposed',production_status='concept',integration_status='not_integrated'),ensure_ascii=False,indent=2),encoding='utf-8')
chart=json.loads((D/'chart.json').read_text(encoding='utf-8'))
for n in chart['nodes']:
    if n['id']=='borealvo':n.update(art=n['art'].replace('concept-v1','concept-v2'),brief=n['brief'].replace('concept-v1','concept-v2'))
(D/'chart.json').write_text(json.dumps(chart,ensure_ascii=False,indent=2),encoding='utf-8')
sheet=Image.new('RGB',(2200,850),'white')
for i,n in enumerate(chart['nodes']):
    thumb=ImageOps.contain(Image.open(D/n['art']).convert('RGB'),(530,760));sheet.paste(thumb,(550*i+(550-thumb.width)//2,60+(760-thumb.height)//2))
    ImageDraw.Draw(sheet).text((550*i+18,20),['Bebe','Crianca','Jovem','Adulto v2'][i]+' / proposta',fill='black')
sheet.save(D/'familia.png')
comparison=Image.new('RGB',(1000,580),'white')
for i,path in enumerate([F.parent/'concept-v1/concept.png',F/'concept.png']):
    crop=Image.open(path).convert('RGB').crop((400,90,700,380))
    crop=ImageOps.contain(crop,(480,520));comparison.paste(crop,(500*i+(500-crop.width)//2,40))
    ImageDraw.Draw(comparison).text((500*i+20,15),['Antes / v1','Focinho e tufos / v2'][i],fill='black')
comparison.save(D/'cabeca-comparativo.png')
p=D/'index.html';p.write_text(p.read_text(encoding='utf-8').replace('borealvo/concept-v1','borealvo/concept-v2'),encoding='utf-8')
note='2026-11-04: autor solicitou focinho mais curto e detalhes pontuais na silhueta da cabeça. Adulto v2 corrige cabeça; demais formas preservadas. Aprovação pendente.'
for p in [D/'CHART.md',A/'DECISOES.md']:
    s=p.read_text(encoding='utf-8')
    if note not in s:p.write_text(s+'\n\n## Revisão da cabeça\n\n'+note+'\n',encoding='utf-8')
print('Adulto v2 salvo; chart e comparativo atualizados.')
if (D/'aprovar_adulto_v2.py').exists():
    import runpy
    runpy.run_path(str(D/'aprovar_adulto_v2.py'))
