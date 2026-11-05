"""Salva concepts sem alterar pixels e atualiza apenas documentação do chart."""
from pathlib import Path
import json,hashlib,shutil,html
from PIL import Image

B=Path(__file__).resolve().parent
F=B.parent
ROOT=F.parents[2]
GENERATED=Path('C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f')
rows=json.loads((B/'fontes.json').read_text(encoding='utf-8'))
for r in rows:
    source=GENERATED/r['source']; target=F/r['id']/'concept-pipa-v3'/'concept.png'
    assert source.is_file()
    shutil.copy2(source,target)
    with Image.open(target) as im: im.verify()
    with Image.open(target) as im:
        r.update(file=target.relative_to(F).as_posix(),size=list(im.size),mode=im.mode,alpha=im.getchannel('A').getextrema() if 'A' in im.getbands() else None)
    r.update(sha256=hashlib.sha256(target.read_bytes()).hexdigest(),tool='image_gen integrada',status='concept em avaliação; sem rig ou integração',prompt='prompt.txt')
    # A fonte de geometria B/C é a folha já existente; adultos usam o respectivo jovem gerado.
    r['generation_references']=['art/soulgen/keys/azulao/color-rig-v2/concept.png','art/creatures/azulao-family-v1/azultor/rosto-adulto-v3/concept.png']
    if r['id'] in ['azulineo','azulume']:r['generation_references'].append('art/soulgen/campaign-redesigns-v1/azulfazo/concept-v1/opcoes.png')
    if r['id']=='azuligero':
        r['generation_references'].append('art/creatures/azulao-family-v1/azulineo/concept-pipa-v3/concept.png')
        r['correction_reference']='rascunho-proximo-do-jovem.png';r['effective_prompt']='prompt-correcao.txt'
    elif r['id']=='azulaculo':r['generation_references'].append('art/creatures/azulao-family-v1/azulume/concept-pipa-v3/concept.png')
    for ref in r['generation_references']:assert (ROOT/ref).is_file(),ref
    r['review']='../../lote-pipa-v3/REVISAO.md'
    (target.parent/'manifest.json').write_text(json.dumps(r,ensure_ascii=False,indent=2),encoding='utf-8')
(B/'manifest.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8')

def card(name,stage,src,folder,status):
    assert (B/src).is_file(),src
    return f'<article><small>{html.escape(stage)}</small><h2>{html.escape(name)}</h2><a href="{src}"><img loading="lazy" src="{src}" alt="Concept de {html.escape(name)}"></a><p>{html.escape(status)}</p><a href="{folder}/brief.md">Brief</a> · <a href="{folder}/prompt.txt">Prompt</a></article>'
cards=[]
for r in rows:
    cards.append(card(r['name'],r['stage'],'../'+r['file'],'../'+r['id']+'/concept-pipa-v3','Nova proposta em avaliação'))
cards.append(card('Azultor','IV · adulto · ataque','../azultor/rosto-adulto-v3/concept.png','../azultor/rosto-adulto-v3','Corpo e asas aprovados; face adulta apresentada para avaliação'))
style='''*{box-sizing:border-box}body{margin:0;background:#f4f0e7;color:#142b3c;font:17px/1.65 system-ui}main{max-width:1500px;margin:auto;padding:clamp(20px,4vw,54px)}h1{font-size:clamp(32px,4vw,56px);line-height:1.1}h2{margin:8px 0}nav{display:flex;flex-wrap:wrap;gap:20px;margin:25px 0}a{color:#075d7b}a:focus-visible{outline:3px solid #c24b24;outline-offset:4px}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:28px}article{background:#fffdf8;padding:24px;border-top:5px solid #216b83;min-width:0}img{display:block;width:100%;height:400px;object-fit:contain;background:#e7ebeb}small{font-weight:700}p{max-width:85ch}@media(max-width:760px){.grid{grid-template-columns:1fr}img{height:300px}}'''
page=f'''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Família do Azulão — evoluções de pipa viva</title><style>{style}</style><main><h1>Evoluções de pipa viva</h1><p>45% criatura · 45% pipa · 10% acabamento pixel/2D mangá. Novos concepts do bebê, dos jovens e dos adultos. Maturidade orienta corpo e rosto; as rotas têm construções distintas.</p><nav><a href="../../../../documentation/creatures/azulao-chart-v1/index.html">Chart completo</a><a href="REVISAO.md">Revisão e limites</a><a href="manifest.json">Arquivos e origem</a><a href="../index.html">Histórico de pranchas</a></nav><p>Azulão e Azulfazo existentes mantidos no chart. Monção e Alísio são configurações e não novos estágios. Concepts em avaliação, sem integração ou certificado de pixel art técnico.</p><section class="grid">{''.join(cards)}</section></main></html>'''
(B/'index.html').write_text(page,encoding='utf-8')

chartbase=ROOT/'documentation/creatures/azulao-chart-v1';cp=chartbase/'chart.json';c=json.loads(cp.read_text(encoding='utf-8'))
for r in rows:c['modelSheets'][r['id']]='../../../art/creatures/azulao-family-v1/'+r['file']
c['modelSheets']['azultor']='../../../art/creatures/azulao-family-v1/azultor/rosto-adulto-v3/concept.png'
c['visualBatchNote']='Lote pipa-v3: cinco concepts individuais com construção de pipa viva e maturidade proposta. Azultor tem corpo e asas aprovados na v2; face adulta v3 em avaliação. Sem substituir rigs existentes.'
descriptions={
 'azulim':('Filhote de pipa sem pernas, face ampla e curiosa, bico pequeno, asas curtas assimétricas e rabiola de nuvem.','A fase bebê testa equilíbrio com asas em ângulos diferentes; o rosto ainda não possui a estrutura severa do adulto.'),
 'azulineo':('Jovem ave-pipa alta de pescoço dobrado em sanfona, bico fino, duas asas estreitas, duas pernas longas e rabiola dupla azul/turquesa.','Corpo de papel com quilha fina e articulações apoiadas em varetas; a pose de passo lateral testa o reposicionamento da rota.'),
 'azulume':('Jovem ave-pipa compacta de face em conchas de papel, dois pés, duas asas curtas e três painéis sensoriais ligados por linha na cauda.','Olhos atentos e manipulação da linha explicam a investigação do vento; inteligência ainda é proposta de comportamento, não habilidade implementada.'),
 'azuligero':('Adulto de torso horizontal longo em células de papel conectadas, duas asas dianteiras, duas patas posteriores, bico fino e duas fitas de rabiola.','A forma alta juvenil se reorganiza em eixo horizontal de voo e flexão; não é apenas o jovem aumentado. Novo corpo permanece proposta em avaliação.'),
 'azulaculo':('Adulto de face poligonal larga e baixa, olhos âmbar, duas asas horizontais em leque, dois pés e três painéis sensoriais traseiros.','O corpo cresce lateralmente, reduz a proporção dos olhos e ganha forro ameixa e condução de linha no peito. Estratégia e construção novas em avaliação.'),
 'azultor':('Adulto hipogrifo de pipa viva: quatro patas, duas asas em leque, torso de papel tensionado e face poligonal com bico forte curvado.','O autor aprovou corpo e asas do piloto-pipa-v2; a face adulta v3 evolui o rosto-base com planos mais severos e projeção do bico. Face em avaliação.')
}
for n in c['nodes']:
    if n['id'] in descriptions:
        n['identity'],n['change']=descriptions[n['id']]
    if n['id'] in {r['id'] for r in rows}:
        n['mechanicStatus']='Concept de pipa viva v3 em avaliação, com maturidade proposta e referências próprias. Sem rig, animação ou integração; poderes e requisitos seguem propostas.'
    if n['id']=='azultor':n['mechanicStatus']='Adulto definido pelo autor. Corpo e asas de pipa viva v2 aprovados; face adulta v3 apresentada para avaliação. Sem rig ou integração.'
cp.write_text(json.dumps(c,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'concepts':len(rows),'arquivos_validados':True,'chart_atualizado':True},ensure_ascii=False))
