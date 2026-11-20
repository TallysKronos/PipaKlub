"""Publica apenas documentação/concepts v2; não altera assets de jogo."""
import hashlib
import json
from pathlib import Path
from PIL import Image

DOC = Path(__file__).resolve().parent
ROOT = DOC.parents[2]
OLD = DOC.parent / 'rabbito-chart-v1'
ART = ROOT / 'art/creatures/rabbito-family-v1'
SPECS = {
    'rastro-dos-ventos': ('Jovem de corrida: corpo em seta diagonal, pés de impulsão longos e orelhas estreitas para trás.', 'Interceptar pelo salto', 'Pernas longas impulsionam; velas auriculares estreitas orientam a trajetória.'),
    'arauto-da-tempestade': ('Adulto bípede de impulsão leporina/canguru, peito em quilha e orelhas abertas em arco transversal.', 'Abrir caminho pelo salto', 'Patas traseiras potentes acumulam impulso; o arco auricular recebe o vento.'),
    'mestre-dos-fios': ('Condutor juvenil de corpo suspenso em gota e duas orelhas formando pinças de um losango aberto.', 'Redirecionar tensão', 'Patas manipulam a linha enquanto as bordas auriculares definem sua passagem.'),
    'tecelao-da-aurora': ('Adulto baixo e largo; torso de pipa-caixa e quatro apoios sustentam duas grandes velas auriculares em arco.', 'Ancorar uma travessia', 'Base ampla estabiliza a carga; os quatro apoios ficam livres e a rabiola nasce da traseira.'),
    'rabbitknight': ('Boxeador romano compacto: proteção contínua de boca, gola e peitoral em faixas; duas luvas enormes de punhos reforçados.', 'Aparar e contra-atacar com peso', 'Couraça segmentada protege boca e peito; luvas pesadas e base larga concentram o impacto.'),
}
data = json.loads((OLD / 'chart.json').read_text(encoding='utf-8'))
data['visual_revision'] = 'Conjunto integralmente aprovado visualmente: quatro concepts v2 e Rabbitknight romano v3.'
for node in data['nodes']:
    if node['id'] not in SPECS:
        continue
    ident = node['id']
    anatomy, action, mechanism = SPECS[ident]
    version = 3 if ident == 'rabbitknight' else 2
    folder = ART / ident / f'concept-v{version}'
    node.update(identity=anatomy, action=action, mechanism=mechanism,
                art=f'../../../art/creatures/rabbito-family-v1/{ident}/concept-v{version}/concept.png',
                brief=f'../../../art/creatures/rabbito-family-v1/{ident}/concept-v{version}/brief.md')
    node['decision_status'] = 'approved'
    node['approval_note'] = 'Autor: "aprovado, todos, esse estilo ficou maravilhoso". Aprovação visual do conjunto atual, sem certificar integração ou mecânicas.'
    prompt = folder / 'prompt.txt'
    image = folder / 'concept.png'
    if not image.exists() or not prompt.exists():
        raise FileNotFoundError(folder)
    brief = f'''# {node['name']} — concept v{version}

## Definido e observado
Rabbito é criação singular de Kael, animada pela Rabiola Antiga. A base e os rigs existentes permanecem intactos. Paleta creme/turquesa/dourado e rabiola de três laços conservam parentesco. Rabbitknight é boxe, sem continuação registrada; agora o autor determinou armadura romana de boca e peitoral e luvas maiores e pesadas.

## Proposta visual
{anatomy}
Verbo: {action}. Construção: {mechanism}
História interpretativa mantida: {node['story']}
Limitação proposta: {node['tradeoff']}

## Acabamento
Contorno marinho contínuo, massas amplas de cor, sombra cel simples e poucas dobras funcionais. O piloto Arauto v2 guia o acabamento, não impõe sua anatomia às outras rotas.

## Incógnitas e escopo
Graus, espécie definitiva, custos e obtenção continuam propostos. Não se inventa passado selvagem anterior à criação de Kael. Concept raster; não é sprite técnico, rig ou habilidade integrada. Aprovação visual do autor: “aprovado, todos, esse estilo ficou maravilhoso”.
'''
    (folder / 'brief.md').write_text(brief, encoding='utf-8')
    sources = json.loads((DOC / 'sources.json').read_text(encoding='utf-8'))
    with Image.open(image) as im:
        manifest = dict(id=ident, version=version, tool='image_gen.imagegen', source=sources[ident],
                        sha256=hashlib.sha256(image.read_bytes()).hexdigest(), width=im.width,
                        height=im.height, mode=im.mode, alpha='A' in im.getbands(), prompt='prompt.txt',
                        references=[{'path':'art/creatures/rabbito-family-v1/arauto-da-tempestade/concept-v2/concept.png','role':'Acabamento aceito pelo autor'},
                                    {'path':'art/soulgen/keys/rabbito/color-rig-v2/concept.png','role':'Identidade da família'}],
                        decision_status='approved', approval_note=node['approval_note'],
                        production_status='concept', implementation='não integrado', technical_pixel_art=False)
    if ident == 'arauto-da-tempestade':
        manifest['references'] = [
            {'path':'art/soulgen/keys/rabbito/color-rig-v2/concept.png', 'role':'Identidade'},
            {'path':'art/creatures/azulao-family-v1/azultor/rosto-adulto-v3/concept.png', 'role':'Acabamento'}]
    if ident == 'tecelao-da-aurora':
        manifest['correction'] = {'input':'tentativa-01.png', 'prompt':'prompt-correcao.txt', 'reason':'Remover corda e anéis que prendiam as patas dianteiras'}
    if ident == 'rabbitknight':
        manifest['references'] = [{'path':'art/creatures/rabbito-family-v1/rabbitknight/concept-v2/concept.png', 'role':'Alvo de edição: armadura e luvas'}]
    (folder / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
(DOC / 'chart.json').write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
page = (OLD / 'index.html').read_text(encoding='utf-8')
start = page.index('const data=') + len('const data=')
end = page.index(';const labels=', start)
page = page[:start] + json.dumps(data, ensure_ascii=False) + page[end:]
for ident in SPECS:
    version = 3 if ident == 'rabbitknight' else 2
    page = page.replace(f'{ident}/concept-v1/', f'{ident}/concept-v{version}/')
page = page.replace('Rabbito — caminhos do Elo', 'Rabbito — concepts limpos v2')
page = page.replace('ESTUDO AUTORAL · PROPOSTAS VISUAIS', 'CONCEPTS V2 · DIREÇÃO LIMPA')
page = page.replace('href="PESQUISA.md"', 'href="../rabbito-chart-v1/PESQUISA.md"')
page = page.replace('Concepts sem aprovação nova do autor.', 'Todos os concepts atuais aprovados visualmente pelo autor, incluindo Rabbitknight romano v3.')
page = page.replace('Identidade existente preservada; graus ainda propostos.', 'Concept aceito visualmente; graus e mecânicas ainda propostos.')
(DOC / 'index.html').write_text(page, encoding='utf-8')
# Montagem comparativa: apenas disposição/redução dos PNGs, sem pintura.
from PIL import ImageDraw, ImageFont, ImageOps
sheet = Image.new('RGB', (1440, 1060), 'white')
draw = ImageDraw.Draw(sheet)
try:
    font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 25)
except OSError:
    font = ImageFont.load_default()
for i, node in enumerate(data['nodes']):
    x, y = (i % 3) * 480, (i // 3) * 530
    with Image.open(DOC / node['art']) as im:
        rgba = im.convert('RGBA')
        white = Image.new('RGBA', rgba.size, 'white')
        white.alpha_composite(rgba)
        thumb = ImageOps.contain(white.convert('RGB'), (440, 465), Image.Resampling.LANCZOS)
    sheet.paste(thumb, (x + (480-thumb.width)//2, y + (470-thumb.height)//2))
    draw.text((x+22, y+486), node['name'], font=font, fill='#102b31')
sheet.save(DOC / 'familia-v2.png')
for node in data['nodes']:
    for field in ('art', 'brief'):
        if node.get(field) and not (DOC / node[field]).is_file():
            raise FileNotFoundError(node[field])
print(json.dumps({'nodes':len(data['nodes']), 'new_concepts':4, 'pilot':1, 'index':str(DOC/'index.html')}))
