from pathlib import Path
import json,shutil,hashlib
from PIL import Image
D=Path(__file__).resolve().parent
src=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f/exec-0bb7c3ed-d9f9-486e-9457-c523bd5ecda2.png')
shutil.copy2(src,D/'concept.png')
with Image.open(D/'concept.png') as im:
 m=dict(id='yaguarion',name='Yaguarion',identity='yaguaru-memoria',decision_status='proposed',production_status='concept',implementation='não integrado',source=str(src),tool='image_gen.imagegen',width=im.width,height=im.height,mode=im.mode,sha256=hashlib.sha256((D/'concept.png').read_bytes()).hexdigest(),prompt='prompt.txt',brief='brief.md',review='revisao.md',references=[dict(path='art/soulgen/keys/yaguaru-memoria/color-rig-v2/preview.png',role='identidade atual do autor'),dict(path='art/creatures/onze-cavaleiros-v1/tricordio/concept-v4/concept.png',role='acabamento de cavaleiro aprovado')],external_images_used_for_generation=False,technical_pixel_art=False)
(D/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
print(f'Concept salvo e aberto: {im.width}x{im.height}; brief, prompt, revisão e manifesto presentes.')
