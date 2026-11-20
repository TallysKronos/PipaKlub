from pathlib import Path
import json, shutil, hashlib
from PIL import Image, ImageOps, ImageDraw
R=Path(__file__).resolve().parents[3]
A=Path(__file__).resolve().parent
D=R/'documentation/creatures/cacaurama-chart-v2'
D.mkdir(parents=True,exist_ok=True)
P=json.loads((A/'geracao-v2.json').read_text(encoding='utf-8'))
G=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f')
nodes=[]
cards=[]
stories=['Fruto verde fechado; observa e se prende com pequenos ganchos.', 'Gomos crescem e os membros permitem explorar; primeiras pontas amarelas.', 'Fruto dourado; braços longos tensionam a linha com precisão paciente.']
for item,story in zip(P['items'],stories):
    F=A/item['id']/'concept-v2'; F.mkdir(parents=True,exist_ok=True)
    shutil.copy2(G/item['source'], F/'concept.png')
    (F/'prompt.txt').write_text(item['prompt'],encoding='utf-8')
    (F/'brief.md').write_text('# '+item['maturity']+' — proposta\n\nDefinido: amadurecimento do cacau guia as evoluções; preguiça apenas como inspiração.\n\nProposta: '+story+' Gomos são painéis tensionados; garras curvas e gesto carregam a inspiração animal.\n\nDesconhecidos: nomes finais, elemento, habilidades e lugar na campanha.\n',encoding='utf-8')
    (F/'revisao.md').write_text('# Conferência\n\nConcept proposto, sem aprovação. Fruto e rosto integrados; sem focinho, máscara facial ou pelagem de preguiça. Duas abas/ganchos no bebê; dois braços e duas pernas nos demais. Rabiola visível. A criança ganhou sorriso amplo e a rabiola sai do nó superior, ao contrário da cintura do jovem: diferenças a avaliar na próxima revisão. Contorno é ilustração raster, não pixel art técnico. Não recortado ou integrado.\n',encoding='utf-8')
    im=Image.open(F/'concept.png')
    manifest=dict(tool='image_gen.imagegen',source=item['source'],sha256=hashlib.sha256((F/'concept.png').read_bytes()).hexdigest(),dimensions=list(im.size),mode=im.mode,alpha='A' in im.getbands(),prompt='prompt.txt',own_reference_inputs=[],decision_status='proposed',production_status='concept',integration_status='not_integrated')
    (F/'manifest.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False),encoding='utf-8')
    rel=Path('../../../art/creatures/cacaurama-family-v1')/item['id']/'concept-v2'
    nodes.append(dict(id=item['id'],name=item['maturity']+' (nome pendente)',kind='stage',stage=item['stage'],maturity=item['maturity'],identity=story,story=story,decision_status='proposed',production_status='concept',art=(rel/'concept.png').as_posix(),brief=(rel/'brief.md').as_posix()))
    card=Image.new('RGB',(600,740),'white'); thumb=ImageOps.contain(im.convert('RGB'),(560,670)); card.paste(thumb,((600-thumb.width)//2,40+(670-thumb.height)//2)); ImageDraw.Draw(card).text((24,16),item['maturity']+' / proposta',fill='black'); cards.append(card)
F=A/'cacaurama'/'concept-v2'; F.mkdir(parents=True,exist_ok=True)
(F/'prompt.txt').write_text(P['adultPrompt'],encoding='utf-8')
(F/'brief.md').write_text('# Adulto — proposta pendente de arte\n\nCasca madura aberta vira manto e proteções dos antebraços; sementes e polpa organizam um corpo mais estreito. Cabeça pequena de semente, garras curvas e gesto paciente. A abertura é transformação fantástica, não afirmação de que cacau maduro se abre naturalmente. Duas gerações bloqueadas na etapa de saída (categoria other); nenhum PNG adulto produzido.\n',encoding='utf-8')
nodes.append(dict(id='cacaurama',name='Adulto (nome pendente)',kind='stage',stage=4,maturity='Adulto',identity='Casca aberta revela anatomia de sementes e membranas.',story='Amadurecer permite abrir a proteção e tecer com alcance maior.',decision_status='proposed',production_status='brief',brief='../../../art/creatures/cacaurama-family-v1/cacaurama/concept-v2/brief.md'))
edges=[dict(**{'from':nodes[i]['id'],'to':nodes[i+1]['id']},kind='reweaving',reason=stories[i] if i<2 else 'Casca madura se abre na transformação fantástica; sementes organizam nova anatomia.',decision_status='proposed') for i in range(3)]
(D/'chart.json').write_text(json.dumps(dict(family_id='cacaurama',scope='Revisão de concepts; adulto ainda em brief; sem integração.',nodes=nodes,edges=edges),indent=2,ensure_ascii=False),encoding='utf-8')
sheet=Image.new('RGB',(1800,740),'white')
for i,c in enumerate(cards): sheet.paste(c,(600*i,0))
sheet.save(D/'comparativo.png')
(D/'CHART.md').write_text('# Cacau e preguiça — revisão 2\n\nSolicitação do autor: evoluções seguem amadurecimento do cacau, preguiça deixa de ser literal. Três concepts propostos: bebê fechado verde, criança com pontas amarelas, jovem dourado. Adulto em brief: casca aberta e sementes estruturais. Cores representam uma rota artística verde→amarelo; variedades de cacau amadurecem em cores distintas. Nenhum nome final ou mecânica definidos.\n\nRevisão necessária: criança tem sorriso amplo e rabiola no topo; jovem tem rosto mais sóbrio e rabiola na cintura. Não são folhas técnicas ou rigs.\n',encoding='utf-8')
(D/'fontes.json').write_text(json.dumps([dict(url='https://www.kew.org/read-and-watch/caring-for-kews-chocolate',title='Caring for Kew’s chocolate trees',entity='Royal Botanic Gardens, Kew',fact='Sementes envoltas por polpa branca dentro do fruto.',interpretation='Polpa pode inspirar membranas e sementes articulações.',use='Anatomia proposta do adulto.'),dict(url='https://nationalzoo.si.edu/animals/news/why-are-sloths-so-slow-and-other-sloth-facts',title='Why are sloths so slow?',entity='Smithsonian National Zoo',fact='Movimento lento é característica estudada das preguiças.',interpretation='Transmitir paciência pelo gesto em vez de copiar rosto animal.',use='Braços, garras e postura; contagem de ganchos é proposta artística.')],indent=2,ensure_ascii=False),encoding='utf-8')
rejected=A/'cacaulento'/'concept-v1'
rejected.mkdir(parents=True,exist_ok=True)
shutil.copy2(G/'exec-b4895b89-8273-430a-b517-7783685b32d1.png',rejected/'concept.png')
(rejected/'revisao.md').write_text('# Rejeitado pelo autor\n\nPreguiça literal demais; evolução deve seguir amadurecimento do cacau. Preservado como histórico; não usar como direção atual.\n',encoding='utf-8')
(A/'DECISOES.md').write_text('# Decisões\n\nV1 rejeitada pelo autor: preguiça evidente demais. V2 em proposta: amadurecimento do cacau conduz anatomia, preguiça apenas em gesto e garras. Bebê/criança/jovem gerados; adulto pendente por dois bloqueios de saída da ferramenta. Nenhuma integração ou aprovação nova.\n',encoding='utf-8')
print(D)
