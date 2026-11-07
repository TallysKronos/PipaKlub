from pathlib import Path
import json, shutil, hashlib, html
from PIL import Image, ImageOps, ImageDraw
A=Path(__file__).resolve().parent
R=A.parents[2]
D=R/'documentation/creatures/cacaurama-preguica-chart-v1'
D.mkdir(parents=True,exist_ok=True)
G=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f')
items=json.loads((A/'ramo-preguica-geracao.json').read_text(encoding='utf-8'))
base=A/'cacau-baby/concept-v2'
nodes=[dict(id='cacau-baby',name='Bebê compartilhado',kind='stage',stage=1,maturity='Bebê',identity='Fruto verde fechado e ganchos pequenos.',story='Origem compartilhada com a rota mais vegetal.',decision_status='proposed',production_status='concept',art='../../../art/creatures/cacaurama-family-v1/cacau-baby/concept-v2/concept.png',brief='../../../art/creatures/cacaurama-family-v1/cacau-baby/concept-v2/brief.md')]
images=[('Bebe / base compartilhada',base/'concept.png')]
for item in items:
    F=A/item['id']/'concept-v1'; F.mkdir(parents=True,exist_ok=True)
    source=G/item['source'] if 'source' in item else next(G.glob(item['sourcePrefix']+'*.png'))
    shutil.copy2(source,F/'concept.png')
    (F/'prompt.txt').write_text(item['prompt'],encoding='utf-8')
    if item.get('fix'):
        (F/'prompt-correcao.txt').write_text(item['fix'],encoding='utf-8')
        shutil.copy2(G/'exec-34cddb31-afad-4553-ab53-89e66ce58b3e.png',F/'concept-antes-correcao.png')
    (F/'brief.md').write_text('# '+item['name']+' — ramo preguiça\n\nDefinido pelo autor: partir do mesmo bebê, desenvolver criança, jovem e adulto com maior presença da preguiça e manter traço.\n\nProposta: '+item['story']+'\n\nHerança: gomos, verde/amarelo, nós dourados, linha com dois terminais de semente. Preguiça incorporada no rosto, braços longos e garras curvas. Papel tensionado nos membros e casca sustentada por varetas. Especialidade proposta: sustentar, ancorar e conter. Limitação proposta: depende de apoio e tensão para movimentos amplos.\n\nNomes, elemento, obtenção e habilidades seguem indefinidos.\n',encoding='utf-8')
    review='Dois braços e duas pernas, mãos com duas garras visíveis, rosto pequeno, rabiola com fio e dois terminais. Acabamento 2D limpo e sem textura de pelagem realista. '
    if item['stage']==3: review+='Correção dirigida reduziu a mão apoiada de três para duas garras; original preservado. '
    if item['stage']==4: review+='Manto amplo e peitoral marfim mudam a anatomia; a linha segurada pela mão continua fora do enquadramento, enquanto a rabiola pessoal está completa. Pés com três dedos; família não é folha técnica multivista. '
    (F/'revisao.md').write_text('# Conferência\n\n'+review+'\n\nProposto, sem aprovação. Sem recortes, rig ou integração; ilustração não certificada como pixel art técnico.\n',encoding='utf-8')
    im=Image.open(F/'concept.png')
    (F/'manifest.json').write_text(json.dumps(dict(tool='image_gen.imagegen',source=source.name,sha256=hashlib.sha256((F/'concept.png').read_bytes()).hexdigest(),dimensions=list(im.size),mode=im.mode,alpha='A' in im.getbands(),prompt='prompt.txt',own_references=['cacau-baby/concept-v2/concept.png: identidade','preguicau-young: anatomia e acabamento, quando usado'],decision_status='proposed',production_status='concept',integration_status='not_integrated'),indent=2,ensure_ascii=False),encoding='utf-8')
    rel='../../../art/creatures/cacaurama-family-v1/'+item['id']+'/concept-v1/'
    nodes.append(dict(id=item['id'],name=item['name']+' (nome pendente)',kind='stage',stage=item['stage'],maturity=item['name'],identity=item['story'],story=item['story'],decision_status='proposed',production_status='concept',art=rel+'concept.png',brief=rel+'brief.md'))
    images.append((item['name']+' / proposta',F/'concept.png'))
edges=[dict(**{'from':nodes[i]['id'],'to':nodes[i+1]['id']},kind='reweaving',reason=nodes[i+1]['story'],decision_status='proposed') for i in range(3)]
(D/'chart.json').write_text(json.dumps(dict(family_id='cacaurama-preguica',scope='Ramo alternativo de concepts a partir do bebe existente; sem integração.',nodes=nodes,edges=edges),indent=2,ensure_ascii=False),encoding='utf-8')
sheet=Image.new('RGB',(2000,650),'white')
for i,(label,path) in enumerate(images):
    thumb=ImageOps.contain(Image.open(path).convert('RGB'),(480,570))
    sheet.paste(thumb,(500*i+(500-thumb.width)//2,50+(570-thumb.height)//2))
    ImageDraw.Draw(sheet).text((500*i+20,20),label,fill='black')
sheet.save(D/'familia.png')
(D/'CHART.md').write_text('# Cacau — ramo preguiça\n\nBebê compartilhado → criança que se desprende da casca → jovem apoiado nos braços → adulto guardião de ancoragem. Todos os destinos são propostas. A rota vegetal anterior permanece intacta. Nomes finais, elemento e regras não definidos.\n\nO amadurecimento verde→amarelo inspira a paleta; abrir a casca é transformação fantástica, não afirmação biológica. A rabiola continua sendo a portadora da alma. Sementes no peito são anatomia, não almas adicionais.\n\nO jovem foi corrigido para duas garras por mão. Adulto segura linha que sai da imagem; rabiola pessoal inteira. Ilustrações de concept, sem integração.\n',encoding='utf-8')
(D/'fontes.json').write_text(json.dumps([dict(url='https://nationalzoo.si.edu/animals/news/why-are-sloths-so-slow-and-other-sloth-facts',entity='Smithsonian National Zoo',title='Why are Sloths So Slow? And Other Sloth Facts',access='2026-11-04',fact='Membros longos e garras curvas permitem suspensão; há famílias de duas e três garras anteriores.',interpretation='Projetar alcance e sustentação em vez de apenas velocidade baixa.',application='Duas garras nas mãos, braços alongados, apoio e ancoragem. A anatomia fantástica não representa espécie real.')],indent=2,ensure_ascii=False),encoding='utf-8')
cards=''.join('<article><h2>'+html.escape(n['name'])+'</h2><img src="'+n['art']+'" alt="'+html.escape(n['identity'])+'"><p>'+html.escape(n['story'])+'</p><a href="'+n['brief']+'">Brief</a></article>' for n in nodes)
(D/'index.html').write_text('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>Cacau: ramo preguiça</title><style>body{font:18px system-ui;background:#faf8ee;color:#29281e;margin:40px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:28px}article{background:white;padding:20px;border:1px solid #d1c99e}img{width:100%;height:300px;object-fit:contain}a:focus{outline:3px solid #965300}</style><h1>Cacau: ramo preguiça</h1><p>Bebê compartilhado → criança → jovem → adulto. Concepts propostos; nomes pendentes.</p><main>'+cards+'</main></html>',encoding='utf-8')
print(D)
if (D/'aprovar.py').exists():
    import runpy
    runpy.run_path(str(D/'aprovar.py'))
