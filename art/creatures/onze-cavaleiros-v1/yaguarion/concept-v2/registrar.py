from pathlib import Path
import json,shutil,hashlib
from PIL import Image
D=Path(__file__).resolve().parent;old=D.with_name('concept-v1')
src=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f/exec-d086ec22-68b0-4130-8695-46a7fa53c852.png')
shutil.copy2(src,D/'concept.png')
brief=(old/'brief.md').read_text(encoding='utf-8')+'\n## Revisão 2 — solicitação atual\nO elmo deve ocultar testa e olhos humanoides, expondo só nariz e boca na abertura inferior. Esta decisão supera a abertura ampla da primeira proposta. Original preservado.\n'
(D/'brief.md').write_text(brief,encoding='utf-8')
m=json.loads((old/'manifest.json').read_text(encoding='utf-8'));m.update(source=str(src),decision_status='proposed',refinement_target='../concept-v1/concept.png',revision_reason='Elmo cobre região ocular humanoide; abertura inferior para nariz e boca.',sha256=hashlib.sha256((D/'concept.png').read_bytes()).hexdigest())
with Image.open(D/'concept.png') as im:m.update(width=im.width,height=im.height,mode=im.mode)
(D/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
(D.parent/'DECISOES.md').write_text('# Yaguarion\n\nVersão atual: concept-v2. Revisão solicitada para ocultar região superior humanoide sob o elmo de onça e expor nariz/boca. Em avaliação visual. concept-v1 preservado como histórico.\n',encoding='utf-8')
print('Revisão 2 salva; original preservado.')
