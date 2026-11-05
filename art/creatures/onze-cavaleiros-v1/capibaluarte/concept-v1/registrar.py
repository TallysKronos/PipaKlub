from pathlib import Path
import json,shutil,hashlib
from PIL import Image
D=Path(__file__).resolve().parent;R=D.parents[4]
src=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f/exec-58cb5139-f4f9-4b05-bad6-923995c8b76a.png');shutil.copy2(src,D/'concept.png')
with Image.open(D/'concept.png') as im:m=dict(id='capibaluarte',name='Capibaluarte',family='capivara-boia',decision_status='proposed',production_status='concept',implementation='não integrado',tool='image_gen.imagegen',source=str(src),width=im.width,height=im.height,mode=im.mode,alpha='A'in im.getbands(),sha256=hashlib.sha256((D/'concept.png').read_bytes()).hexdigest(),prompt='prompt.txt',brief='brief.md',review='revisao.md',sources='fontes.json',references=[dict(path='art/creatures/capivara-boia/child-manga-v3/concept.png',role='identidade própria atual'),dict(path='art/creatures/onze-cavaleiros-v1/yaguarion/concept-v2/concept.png',role='acabamento de cavaleiro aprovado')],external_images_used_for_generation=False,technical_pixel_art=False)
(D/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
(D.parent/'DECISOES.md').write_text('# Capibaluarte\n\n2026-11-04: cavaleiro aquático solicitado, com estudo estrutural de Craniamon e MegaGargomon. Nome e design propostos, em avaliação. Marévia natural preservada; escolha de rota e requisitos não definidos. Nenhuma integração.\n',encoding='utf-8')
doc=R/'documentation/creatures/capivara-boia-chart-v1/CHART.md'
note='\n## Proposta adicional de cavaleiro\nEm 2026-11-04, o autor pediu um cavaleiro com estudo estrutural de Craniamon e MegaGargomon. [Capibaluarte — concept-v1](../../../art/creatures/onze-cavaleiros-v1/capibaluarte/concept-v1/concept.png) é candidato em avaliação. Marévia preservada; não se definiu substituição, rota ou obtenção.\n'
if doc.is_file():
 s=doc.read_text(encoding='utf-8')
 if '## Proposta adicional de cavaleiro' not in s:doc.write_text(s+note,encoding='utf-8')
print('Capibaluarte salvo, imagem verificada e proposta documentada.')
