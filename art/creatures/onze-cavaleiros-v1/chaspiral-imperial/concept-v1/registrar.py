from pathlib import Path
from PIL import Image
import shutil,json,hashlib
D=Path(__file__).resolve().parent
S=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f/exec-f1bc2e15-4ca7-4ac4-b401-13adc1a28265.png')
if not(D/'concept.png').exists():shutil.copy2(S,D/'concept.png')
with Image.open(D/'concept.png') as im:dimensions=list(im.size);mode=im.mode
(D/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen built-in',source=str(S),sha256=hashlib.sha256((D/'concept.png').read_bytes()).hexdigest(),dimensions=dimensions,mode=mode,reference_role='Own approved Chaspiral color-rig-v2 preview, ancestry and palette',external_generation_inputs=False,decision_status='proposed',production_status='concept',implementation_status='not_integrated',base_id='chaspiral',proposed_maturity='adult',stage=4,stage_status='proposed_mapping',final_name=None),ensure_ascii=False,indent=2),encoding='utf-8')
print('Concept e documentação salvos. Rig da Chaspiral preservado.')
