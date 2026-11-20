from pathlib import Path
import json,hashlib,shutil
from PIL import Image
D=Path(__file__).resolve().parent
source=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f/exec-4963a3bb-7158-455f-bb19-26862f878148.png')
if not(D/'concept.png').exists():shutil.copy2(source,D/'concept.png')
with Image.open(D/'concept.png') as im:dimensions=list(im.size);mode=im.mode
(D/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen built-in',source=str(source),sha256=hashlib.sha256((D/'concept.png').read_bytes()).hexdigest(),dimensions=dimensions,mode=mode,references=[dict(path='../../capiboia-tececorrente/estudo-rosto-v1/concept.png',role='Own head anatomy, left closed-mouth face'),dict(path='../../capiboia-tececorrente/concept-v3/concept.png',role='Own ancestry/body identity, restructured for twohanded relic')],external_generation_inputs=False,decision_status='proposed',production_status='concept',implementation_status='not_integrated',kind='special_reweaving_proposal',stage=None,source_stage_unknown=True,item='Martelo de Ghinues',historical_owner='Ghinues, ancient golem; author-defined, no current appearance'),ensure_ascii=False,indent=2),encoding='utf-8')
note='\n\n## Remonta Especial pelo Martelo de Ghinues — proposta\n\n2026-11-04: autor definiu item raro de Ghinues, golem milenar que mantinha ambas as mãos no martelo/clava e não estará presente no jogo agora. Criado [concept completo](herdeiro-de-ghinues/concept-v1/concept.png) com rosto adulto revisado e postura bimanual. Nome, forma de origem e estágio indefinidos; nenhum vínculo mecânico no chart foi fixado. Em avaliação, sem integração.\n'
target=D.parents[1]/'DECISOES.md';text=target.read_text(encoding='utf-8')
if '## Remonta Especial pelo Martelo de Ghinues' not in text:target.write_text(text+note,encoding='utf-8')
print('Concept, prompt, brief, revisão e manifesto salvos; linha natural preservada.')
