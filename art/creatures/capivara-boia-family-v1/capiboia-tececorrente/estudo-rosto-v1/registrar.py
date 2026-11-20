from pathlib import Path
import shutil,json,hashlib
from PIL import Image
D=Path(__file__).resolve().parent
S=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f/exec-431c4a18-7f99-43f9-94ff-e0bfd3555c1f.png')
shutil.copy2(S,D/'concept.png')
with Image.open(D/'concept.png') as im:dimensions=list(im.size);mode=im.mode
(D/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen built-in',source=str(S),sha256=hashlib.sha256((D/'concept.png').read_bytes()).hexdigest(),dimensions=dimensions,mode=mode,reference_role='Own adult C concept-v3 palette and identity, face reconstruction target',external_generation_inputs=False,decision_status='proposed',production_status='head_expression_study',implementation_status='not_integrated'),ensure_ascii=False,indent=2),encoding='utf-8')
print('Estudo facial salvo, com prompt e revisão.')
