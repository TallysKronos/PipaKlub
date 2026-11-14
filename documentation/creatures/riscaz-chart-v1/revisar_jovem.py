from pathlib import Path
import json,shutil,hashlib
from PIL import Image
D=Path(__file__).resolve().parent;R=D.parents[2]
old=R/'art/creatures/riscaz-family-v1/riscavela/concept-v1';new=old.with_name('concept-v2');new.mkdir(exist_ok=True)
src=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f/exec-089f9ec5-e087-4837-8edb-be13c6177d58.png')
shutil.copy2(src,new/'concept.png')
brief='''# Riscavela — jovem ratazanoso, revisão 2

Direção explícita do autor: rejeitou jovem anterior e pediu aspecto mais ratazanoso.
Mudanças: corpo baixo e robusto, dorso arqueado, pescoço recolhido, focinho longo, duas orelhas pequenas arredondadas (uma entalhada), bigodes simples e quatro patas de dedos alongados.
Herança: carvão, creme, verde, dois incisivos de papel, vela única de vareta, duas fitas desiguais conectadas ao nó traseiro. Guardas iniciais antecipam adulto, sem elmo ou balista completos.
45% criatura, 45% pipa viva, 10% acabamento seletivo pixel/2D mangá. Nome e relações são propostas; não se alteram regras do jogo, base autoral ou rig. Arte nova em avaliação.
'''
(new/'brief.md').write_text(brief,encoding='utf-8')
(new/'revisao.md').write_text('# Conferência\n\nQuatro apoios visíveis, dois incisivos, orelhas menores de roedor, focinho alongado e corpo arqueado. Duas fitas contínuas e uma vela. A leitura de coelho/cervídeo da v1 foi removida. Cores amplas, contorno limpo e sombras cel; ilustração de concept, não pixel art técnico nem peças de rig. Aguardando aprovação visual.\n',encoding='utf-8')
p=json.loads((D/'prompts.json').read_text(encoding='utf-8'));p['riscavela']=(new/'prompt.txt').read_text(encoding='utf-8');(D/'prompts.json').write_text(json.dumps(p,ensure_ascii=False,indent=2),encoding='utf-8')
# Keep the reproducible gallery builder on the current revision, preserving v1.
b=D/'build.py';s=b.read_text(encoding='utf-8').replace("'Quadrúpede esguio com quatro patas, vela única e proteções iniciais nos apoios dianteiros.'","'Ratazana baixa e robusta, dorso arqueado, focinho longo, orelhas pequenas e quatro patas de dedos alongados.'").replace("'exec-ed82b90e-9b9e-4509-ae3a-a99dbe22e0d2.png'","'exec-089f9ec5-e087-4837-8edb-be13c6177d58.png'").replace("/id/'concept-v1';folder.mkdir","/id/('concept-v2' if id=='riscavela' else 'concept-v1');folder.mkdir").replace('Quatro patas distintas, face viva e dois incisivos, uma vela, duas fitas inteiras. Guardas iniciais sem copiar a armadura adulta. Silhueta mais alta e esguia que a criança. A referência de acabamento não transfere anatomia de coelho.','Quatro patas distintas com dedos longos, face de ratazana, dois incisivos, duas orelhas pequenas, uma vela e duas fitas inteiras. Corpo baixo e robusto, dorso arqueado e focinho comprido; substitui leitura de coelho/cervídeo rejeitada pelo autor.').replace('jovem ganha quatro apoios longos e proteção inicial','jovem ganha corpo robusto de ratazana, apoios baixos e proteção inicial')
b.write_text(s,encoding='utf-8')
exec(compile(s,str(b),'exec'),{'__file__':str(b),'__name__':'__main__'})
(new/'brief.md').write_text(brief,encoding='utf-8')
mfile=new/'manifest.json';m=json.loads(mfile.read_text(encoding='utf-8'));m['references']=['art/soulgen/keys/riscaz/cutout-rig-v1/preview.png','art/creatures/riscaz-family-v1/riscavela/concept-v1/concept.png'];m['revision_reason']='Autor rejeitou jovem v1 e pediu aspecto mais ratazanoso.';mfile.write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
om=old/'manifest.json';m=json.loads(om.read_text(encoding='utf-8'));m.update(decision_status='rejected',decision_note='Autor: nao gostei da evolução jovem faça um aspecto mais ratazanoso.');om.write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
(R/'art/creatures/riscaz-family-v1/DECISOES.md').write_text('# Decisões\n\n2026-11-04: autor rejeitou jovem concept-v1 e pediu aspecto ratazanoso. Revisão concept-v2 é candidata atual, em avaliação. Original preservado. Bebê não foi alterado; adulto mantém aprovação anterior.\n',encoding='utf-8')
