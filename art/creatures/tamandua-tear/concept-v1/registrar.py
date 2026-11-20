from pathlib import Path
import json,hashlib,shutil
from PIL import Image
F=Path(__file__).resolve().parent
src=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f/exec-62e5cd35-abcc-4d78-9746-c2509fbbf79a.png');p=F/'concept.png';shutil.copy2(src,p);im=Image.open(p)
(F/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen',source=src.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),dimensions=list(im.size),mode=im.mode,alpha='A' in im.getbands(),prompt='prompt.txt',own_reference_inputs=['lince-de-cerco/concept-v1/concept.png: acabamento e solidez; não identidade'],external_inputs=[],decision_status='proposed',production_status='concept',integration_status='not_integrated'),ensure_ascii=False,indent=2),encoding='utf-8')
