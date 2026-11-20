from pathlib import Path
import json,shutil,hashlib
from PIL import Image
D=Path(__file__).resolve().parent
src=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f/exec-5e45cbf3-335a-48de-a338-9481678aeaad.png');shutil.copy2(src,D/'concept.png')
with Image.open(D/'concept.png') as im:
 m=dict(id='dobracula',name='Dobrácula',identity='doberman-c',decision_status='proposed',production_status='concept',implementation='não integrado',tool='image_gen.imagegen',source=str(src),width=im.width,height=im.height,mode=im.mode,alpha='A' in im.getbands(),sha256=hashlib.sha256((D/'concept.png').read_bytes()).hexdigest(),prompt='prompt.txt',brief='brief.md',review='revisao.md',sources='fontes.json',references=[dict(path='art/soulgen/keys/doberman-c/refined-rig-v3/preview.png',role='identidade autoral vigente'),dict(path='art/creatures/onze-cavaleiros-v1/yaguarion/concept-v2/concept.png',role='acabamento próprio aprovado')],external_images_used_for_generation=False,technical_pixel_art=False)
(D/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
print('Concept e procedência salvos, imagem aberta, dimensões '+str(m['width'])+'x'+str(m['height'])+'.')
