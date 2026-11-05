from pathlib import Path
import json,hashlib,shutil
from PIL import Image
F=Path(__file__).resolve().parent
src=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f/exec-5eaa5fae-06a5-4d95-a7d2-a11acfa7996f.png');p=F/'concept.png';shutil.copy2(src,p);im=Image.open(p)
(F/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen',source=src.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),dimensions=list(im.size),mode=im.mode,alpha='A' in im.getbands(),prompt='prompt.txt',own_reference_inputs=['coruja-balanca/concept-v1/concept.png: acabamento e robustez; não identidade'],external_inputs=[],decision_status='proposed',production_status='concept',integration_status='not_integrated'),ensure_ascii=False,indent=2),encoding='utf-8')
