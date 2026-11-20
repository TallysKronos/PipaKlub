from pathlib import Path
import json,shutil,hashlib,os
from PIL import Image
D=Path(__file__).resolve().parent;R=D.parents[2];F=R/'art/creatures/capivara-boia-family-v1/capiboia-tececorrente';P=F/'concept-v2';P.mkdir(parents=True,exist_ok=True)
source=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f/exec-b9f86249-d206-4232-a9b4-2ca5789f622c.png')
if not(P/'concept.png').exists():shutil.copy2(source,P/'concept.png')
(P/'brief.md').write_text('# Adulto C — comportas vivas, revisão 2\n\nDefinido pelo autor: C é jovem; criar um adulto acima dela. Primeira versão adulta recusada, por falta de uma transformação significativa. Autor autorizou a reconstrução proposta com “faça”.\n\nProposta: encurtar torso e pescoço, alargar base e integrar os dois membros anteriores em membranas dobráveis. Uma abre passagem como comporta côncava, a outra fica recolhida em pregas. A jovem empurra água; este adulto propõe conduzi-la por abertura e recolhimento.\n\nHerança: focinho rombo, pequenas orelhas redondas, menta/marfim/petróleo, motivos de corrente e três abas na rabiola. Expressão mais contida e menor olho. Limitação proposta: precisa de apoio para manter a superfície aberta; deslocar e recolher exigem gestos distintos. Nome, habilidade e requisitos indefinidos.\n\nReferência visual de geração: apenas jovem C autoral. Benchmark externo orientou princípios, sem imagens de franquias no input. Adulto B e demais formas preservados.',encoding='utf-8')
(P/'revisao.md').write_text('# Conferência visual\n\nDois apoios posteriores e dois sistemas anteriores legíveis: um leque aberto com raiz próxima do ombro/cotovelo; o outro recolhido em três pregas no flanco. Não há mãos segurando remos. Três abas conectadas à rabiola. Pescoço e torso mais compactos; o foco visual deslocou-se do corpo longo para a superfície funcional.\n\nLimites: a raiz do membro aberto fica parcialmente ocluída pelo leque; precisam ser desenhadas vistas de perfil/costas e abertura para conferir amplitude e continuidade. As linhas d’água sugerem função, não demonstram simulação. Há sombreamento suave residual, sem grid pixel art validado. PNG RGB de fundo branco intencional.\n\nConcept proposto em avaliação, não aprovado automaticamente, sem rig/animação/integração. Versão 1 preservada como tentativa rejeitada pelo autor.',encoding='utf-8')
with Image.open(P/'concept.png') as im:dimensions=list(im.size);mode=im.mode
manifest=dict(tool='image_gen.imagegen built-in',source=str(source),sha256=hashlib.sha256((P/'concept.png').read_bytes()).hexdigest(),dimensions=dimensions,mode=mode,reference='Own young C, c-condutor/concept.png',external_generation_inputs=False,decision_status='proposed',production_status='concept',implementation_status='not_integrated',supersedes='concept-v1 as current candidate, original preserved')
(P/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
old=F/'concept-v1/manifest.json';m=json.loads(old.read_text(encoding='utf-8'));m.update(decision_status='rejected',decision_note='Autor: O B achei que ficou legal, mas o C ainda não gostei.');old.write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
chart=json.loads((D/'chart.json').read_text(encoding='utf-8'))
for n in chart['nodes']:
 if n['id']=='capiboia-tececorrente':
  n.update(art=Path(os.path.relpath(P/'concept.png',D)).as_posix(),brief=Path(os.path.relpath(P/'brief.md',D)).as_posix(),identity='Adulto compacto com membros-comporta de papel: um aberto em leque e outro recolhido em pregas.',story='O jovem empurra a água; o adulto abre passagem para ela.',decision_status='proposed',revision='concept-v2')
(D/'chart.json').write_text(json.dumps(chart,ensure_ascii=False,indent=2),encoding='utf-8')
note='\n\n## Adulto C — reconstrução v2\n\n2026-11-04: autor não gostou do adulto C v1 e autorizou reconstrução. Novo candidato v2 com corpo compacto e membranas-membro, uma aberta e outra recolhida. Em avaliação. Jovem C e adulto B preservados.\n'
for target in [D/'CHART.md',F.parent/'DECISOES.md']:
 t=target.read_text(encoding='utf-8')
 if '## Adulto C — reconstrução v2' not in t:target.write_text(t+note,encoding='utf-8')
exec(compile((D/'aplicar_alternativas_aprovadas.py').read_text(encoding='utf-8'),str(D/'aplicar_alternativas_aprovadas.py'),'exec'),{'__file__':str(D/'aplicar_alternativas_aprovadas.py')})
exec(compile((D/'aplicar_c_adulto_v3.py').read_text(encoding='utf-8'),str(D/'aplicar_c_adulto_v3.py'),'exec'),{'__file__':str(D/'aplicar_c_adulto_v3.py')})
