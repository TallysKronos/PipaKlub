from pathlib import Path
import json,hashlib
from PIL import Image
F=Path(__file__).resolve().parent
p=F/'concept.png'; im=Image.open(p)
(F/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen',source='exec-d0b5e901-6e88-46bd-93e6-1d2c135511c5.png',sha256=hashlib.sha256(p.read_bytes()).hexdigest(),dimensions=list(im.size),mode=im.mode,alpha='A' in im.getbands(),prompt='prompt.txt',own_reference_inputs=['anaconda-retrato-family-v1/anaconda-cavaleiro/concept-v1/concept.png: acabamento apenas'],external_references='Três artes oficiais estudadas; nenhuma usada como input. Ver ESTUDO.md.',decision_status='proposed',production_status='concept',integration_status='not_integrated'),ensure_ascii=False,indent=2),encoding='utf-8')
