from pathlib import Path
import json,shutil,hashlib,os
from PIL import Image
D=Path(__file__).resolve().parent;R=D.parents[2]
B=R/'art/creatures/rabbito-family-v1/conde-da-ultima-hora'
P=B/'concept-v2';P.mkdir(parents=True,exist_ok=True)
data=json.loads((D/'producao-v2.json').read_text(encoding='utf-8'))
def write(p,t):p.write_text(t,encoding='utf-8')
def dump(p,v):write(p,json.dumps(v,ensure_ascii=False,indent=2)+'\n')
def rel(p,b):return os.path.relpath(p,b).replace('\\','/')
shutil.copy2(data['source'],P/'concept.png');write(P/'prompt.txt',data['prompt']+'\n')
review='Juba clara volumosa nasce nas bochechas/queixo e desce sobre o peitoral em grandes tufos, contrastando com armadura preta. Cintura estreita preservada. Face menor, olhos vermelhos estreitos e expressão severa, sem sorriso. Dois braços e duas pernas em postura ereta de comando; mão livre aberta e outra junto à guarda-relógio. Duas orelhas-pipa completas, capa preta/roxa para um lado e rabiola trançada com três laços para o outro. Espada contínua até a ponta, relógio legível. A empunhadura fica parcialmente oculta pela mão/guarda nesta vista; pegada e juntas exigem estudo posterior. Tufos da juba têm mais camadas que as 8–10 inicialmente pedidas, mantendo blocos de sombra limpos. Pontas superiores próximas da borda, completas.\n\nConcept inspecionado após geração, não rig, animação ou pixel art técnico. Nome e posição no chart ainda propostos.'
write(P/'brief.md','# Conde da Última Hora — revisão v2\n\n## Correção do autor\n\nVersão anterior considerada sem graça e pouco séria. Pedido: pelagem robusta saindo do queixo/peitoral e pose de imponência vampiresca, evocando Alucard.\n\n## Aplicação\n\nJuba de papel clara, cabeça baixa com olhos vermelhos estreitos, postura ereta, gesto de comando e espada baixa ao lado. A influência é de atitude e encenação; identidade, arma-relógio, orelhas-pipa e rabiola permanecem próprias. Adulto esbelto em armadura formal preta/roxa; sem associação automática ao Carretel Negro.\n\n## Conferência\n\n'+review+'\n')
write(P/'revisao.md','# Conferência v2\n\n'+review+'\n\nDesign proposto, aguardando avaliação do autor. Concept v1 preservado como histórico da direção criticada.\n')
manifest=json.loads((B/'concept-v1/manifest.json').read_text(encoding='utf-8'))
with Image.open(P/'concept.png') as im:manifest.update(width=im.width,height=im.height,mode=im.mode,alpha_extrema=im.getextrema()[-1] if im.mode=='RGBA' else None)
manifest.update(version=2,source=data['source'],sha256=hashlib.sha256((P/'concept.png').read_bytes()).hexdigest(),decision_status='proposed',reference='../concept-v1/concept.png',reference_role='Alvo próprio da revisão de juba, rosto e pose; imagem externa não anexada.')
dump(P/'manifest.json',manifest)
old=json.loads((B/'concept-v1/manifest.json').read_text(encoding='utf-8'));old.update(decision_status='superseded',critique='Autor: sem graça e pouco sério; pediu juba no queixo/peitoral e postura mais vampiresca.',superseded_by='../concept-v2/concept.png');dump(B/'concept-v1/manifest.json',old)
chart=json.loads((D/'chart.json').read_text(encoding='utf-8'))
chart['nodes'][0].update(art=rel(P/'concept.png',D),brief=rel(P/'brief.md',D),identity='Adulto vampiresco esbelto de juba clara no queixo/peitoral, olhos vermelhos estreitos, armadura preta/roxa e relógio-espada.')
dump(D/'chart.json',chart)
page=(D/'index.html').read_text(encoding='utf-8').replace('/concept-v1/','/concept-v2/').replace('armadura formal vampiresca, olhos vermelhos e relógio-espada.','juba robusta no queixo e peitoral, postura de comando, armadura formal vampiresca e relógio-espada.')
write(D/'index.html',page)
dump(D/'validacao-v2.json',dict(image_exists=True,chart_art_resolves=(D/chart['nodes'][0]['art']).resolve().exists(),sha256=manifest['sha256'],review=review))
print('Concept v2 salvo; v1 preservado; índice e chart apontam para a revisão.')
