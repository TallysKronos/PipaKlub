from pathlib import Path
import json, html, zipfile
from urllib.parse import urljoin
from PIL import Image

ROOT=Path(__file__).resolve().parent
REPO=ROOT.parents[2]
PDF=REPO/'output/pdf/pipaklub-benchmark-pokemon-digimon.pdf'
P='https://legends.arceus.pokemon.com/en-us/gameplay/'
D='https://www.bandainamcoent.com/news/digimon-story-time-stranger-what-you-need-to-know'
M='https://d1vtv52f4vjbmu.cloudfront.net/manuals/dwno/PS4-DWNO_manual_GBQS_WEB.pdf'
Z='https://legends.pokemon.com/en-us/gameplay'
figures=[]
def fig(file,title,category,source,observation,adaptation,limit='Captura oficial publicada; não é uma sessão de jogo executada nesta auditoria.'):
    figures.append(dict(file='capturas/'+file,title=title,category=category,source=source,observation=observation,adaptation=adaptation,limit=limit))
fig('poke-arceus-batalha-01.jpg','Arceus | Preparação e mira','Combate',P,'A mira ocupa o centro; os atalhos ficam nas bordas.','Reservar o centro para o cruzamento das linhas. Indicadores de alcance precisam aparecer junto do alvo, sem competir com o cenário.')
fig('poke-arceus-batalha-02.jpg','Arceus | Comandos de combate','Combate',P,'Vida e escolhas de ação ocupam regiões distintas, deixando o confronto visível.','Linha e energia junto do retrato; ações em um conjunto compacto. Não importar os turnos: o corte do PipaKlub depende de movimento contínuo.')
fig('poke-arceus-batalha-03.jpg','Arceus | Lista de técnicas','Combate',P,'A técnica em foco recebe destaque e os comandos de informação e retorno ficam no rodapé.','Mostrar custo, recarga e condição da rebicada selecionada. A ordem de turnos é específica desta referência, sem equivalente obrigatório no nosso jogo.')
fig('poke-arceus-pokedex-02.jpg','Arceus | Pesquisa na Pokédex','Coleção',P,'Lista de espécies e área de pesquisa formam duas regiões estáveis.','A Pipa Dex pode manter os rostos de um lado e o parceiro do outro; distribuir história, técnica e drops em páginas, evitando uma ficha longa.')
fig('poke-arceus-pokedex-03.jpg','Arceus | Progresso de pesquisa','Coleção',P,'A conclusão da pesquisa ganha um sinal próprio na ficha.','Separar espécie conhecida, exemplar obtido e parceiro equipado. O contorno de foco nunca deve ser a única indicação de propriedade.')
fig('poke-arceus-criacao-itens.jpg','Arceus | Criação de itens','Itens',P,'Grade, descrição e materiais têm áreas próprias.','Mochila com categorias, quantidade, descrição e ação contextual. Para rabiolas repetidas, agrupar visualmente sem perder a identidade dos exemplares quando ela importar.')
fig('digi-next-order-manual-09.png','Next Order | Menu Digivice','Menus',M+'#page=9','O manual mostra lista de destinos e informações dos parceiros simultaneamente.','Manter a lista do Caderno do pipeiro, acrescentando parceiro e contexto útil sem transformar cada opção em um painel decorativo.','Página 9 do manual oficial renderizada; caixas numeradas e explicações pertencem ao manual, não ao jogo.')
fig('digi-next-order-manual-15.png','Next Order | Guia de criaturas','Coleção',M+'#page=15','A página documenta grade de criaturas e ficha separada com navegação por páginas.','Retratos consistentes, posição lembrada e páginas de informação. Criaturas desconhecidas precisam de uma regra de revelação própria.','Página 15 do manual oficial renderizada; exemplos internos têm resolução menor que a página.')
fig('digi-next-order-manual-16.png','Next Order | Exploração e minimapa','Exploração',M+'#page=16','A cena de exploração usa informação periférica e um minimapa com símbolos distintos.','No Quintal, priorizar parceiro, missão e interação próxima. Exibir minimapa somente quando o percurso justificar; nunca usar apenas cor para diferenciar NPC e objetivo.','Página 16 do manual oficial, com chamadas editoriais numeradas.')
fig('digi-next-order-manual-18.png','Next Order | Itens e cuidado','Itens',M+'#page=18','O manual apresenta categorias e seleção de um item em contexto.','Organizar rabiolas e consumíveis por função, com alvo e consequência explícitos antes de usar. Mecânicas de fome e sono não fazem parte desta proposta.','Página 18 do manual oficial; não inferir comportamento não demonstrado pelas imagens.')
fig('digi-next-order-manual-20.png','Next Order | Ordens em batalha','Combate',M+'#page=20','Dados persistentes e menu de ordens temporário cumprem funções diferentes.','No online, ações rápidas permanecem acessíveis; menus de estudo devem informar se o mundo continua rodando. Não prometer pausa global numa sala multiplayer.','Página 20 do manual oficial; o menu radial é uma referência de organização, não uma decisão de implementação.')
fig('digi-next-order-manual-22.png','Next Order | Táticas e saída','Combate',M+'#page=22','Táticas e confirmação de fuga aparecem como etapas diferentes.','Separar continuar, configurar rebicada e abandonar partida. A confirmação de saída precisa explicar a consequência real do modo atual.','Página 22 do manual oficial, não uma tela de resultado de batalha.')
fig('digi-next-order-manual-30.png','Next Order | Comunicação com parceiro','Diálogo',M+'#page=30','A escolha de resposta preserva a presença das criaturas no cenário.','Retrato, nome e mensagem com uma ação principal clara. Em escolhas narrativas, usar uma lista legível e manter o parceiro presente.','Página 30 do manual oficial; não propõe importar sistemas de punição ou relacionamento.')
fig('digi-time-stranger-status-e-equipamento.jpg','Time Stranger | Ficha e equipamento','Coleção',D,'A criatura tem destaque e os atributos ficam agrupados em uma região funcional.','Dar escala ao Pipamon e resumir linha, energia e técnica primeiro. Deixar números avançados numa página de status.','Still oficial de apresentação de sistemas, com moldura e legenda promocionais externas à interface.')
fig('digi-time-stranger-habilidades-agente.jpg','Time Stranger | Habilidades','Progressão',D,'Categoria, nós de habilidade e explicação têm regiões distintas.','Para futuras skills de linha, mostrar requisito, custo, estado e efeito da escolha antes de confirmar. Não adicionar uma árvore apenas por semelhança visual.','Still oficial de apresentação; não foi testado com controle nesta auditoria.')
fig('digi-time-stranger-evolucao.jpg','Time Stranger | Progressão visual','Progressão',D,'Caminhos e opções de evolução são apresentados junto da criatura.','Os marcos 20/30/40/45/50 podem formar uma trilha de brilho com texto e ícone. Evolução de espécie não está sendo proposta.','Still promocional; esta referência não prova que o PipaKlub possua evolução.')
fig('poke-za-tempo-real-1.jpg','Z-A | Espaço do confronto','Contexto',Z,'Dois treinadores e seus parceiros estabelecem posições no cenário.','Usar como estudo espacial para batalhas em movimento; avaliar distâncias com o gameplay real do PipaKlub.','Imagem oficial com apresentação VS; não mostra uma HUD completa, recargas ou comportamento de controle.')

local=[
('pipaklub-menu.png','PipaKlub | Menu principal','Menus','A tipografia, o fio e a pipa de foco já criam identidade. Na conta de teste sem parceiro equipado, aparece o avatar em destaque.','Preservar esta direção. Quando houver parceiro, mostrá-lo com nome e nível; informar o estado vazio sem dar aparência de erro.'),
('pipaklub-dex.png','PipaKlub | Dex em 720p','Coleção','A grade de rostos e a criatura inteira funcionam. A ficha possui rolagem própria; a história começa abaixo da área imediatamente visível.','Dividir o detalhe em Visão geral / História / Técnica / Drops, mantendo nome, retrato e rodapé fixos. O scroll interno deve ser alcançável por controle.'),
('pipaklub-parceiros-720.png','PipaKlub | Parceiros em 720p','Coleção','Dois retratos ocupam uma coluna larga; a área de detalhe mostra só parte dos status. O parceiro ocupa uma fração pequena da vitrine.','Redimensionar a vitrine pelo tamanho visual da criatura, sem cortar rabiola. Resumir dados principais antes de texto longo; permitir navegar pelos detalhes sem mouse.'),
('pipaklub-parceiros-1080.png','PipaKlub | Parceiros em 1080p','Coleção','A mesma coleção foi capturada em 1920 x 1080 para comparação de composição.','Definir limites de largura e densidade para que o espaço extra melhore a leitura. Uma captura em 1080p não substitui testes de escala do sistema ou TV.'),
('pipaklub-mochila.png','PipaKlub | Mochila em 720p','Itens','Cinco rabiolas ficam visíveis. Há dois cartões de Mata verde e a ação disponível leva ao invocador.','Acrescentar categorias e quantidade quando a coleção crescer; detalhe à direita e consequência da ação. Não criar botão Usar se essa ação não existe no fluxo.'),
('pipaklub-mochila-1080.png','PipaKlub | Mochila em 1080p','Itens','O painel foi observado também na segunda resolução, usando o mesmo banco de teste.','Validar 0, 1, 33 e muitas unidades; inventário curto não comprova que paginação, foco e desempenho funcionem com grandes coleções.'),
('pipaklub-missoes.png','PipaKlub | Missões','Exploração','O painel apresenta próximo objetivo e três trilhas. Ao abrir, a árvore de acessibilidade informou foco na página, sem ação focada.','P1: colocar foco inicial no objetivo ou ação principal; restaurá-lo ao fechar. Evitar que o diálogo narrativo atrás dispute atenção com a missão.'),
('pipaklub-abertura.png','PipaKlub | Abertura narrativa','Diálogo','A transmissão fica acima da faixa de fala; Continuar tem destaque e Continuar depois permanece disponível.','Preservar separação entre cena e leitura. Testar falas longas, tamanho da fonte, redução de movimento e escolhas sem mouse.'),
('pipaklub-combate.png','PipaKlub | HUD no fim de uma rodada de treino','Combate','A captura ocorreu no fim de uma rodada: dados nas bordas, resultado no centro e ações à direita. Textos da ficha são pequenos frente à moldura.','Priorizar linha, energia e disponibilidade da técnica. Usar avisos centrais breves e não sobrepor o ponto de corte durante a ação. Este print não comprova alinhamento ou latência.'),
('pipaklub-pausa.png','PipaKlub | Pausa do treino','Menus','O rótulo Duplo toque aparece cortado na faixa de rebicadas em 1280 x 720. Continuar recebe foco visível.','P1: trocar a faixa por seleção paginada com setas e nome completo ou usar uma lista. Manter o foco visível ao alternar e explicar a pausa conforme o modo.')]
for file,title,cat,obs,adapt in local:
    fig(file,title,cat,'PipaKlub local | HEAD 7183063 | 20/10/2026',obs,adapt,'Captura própria em navegador; conta Ana Local e banco PGlite isolado. Teclado/mouse, sem validação de controle físico. '+('1920 x 1080.' if '1080' in file else '1280 x 720.'))

priorities=[
('P1','Pausa: rebicadas cortadas','Nome completo, foco visível e navegação por todas as seis opções em 720p e 1080p. Sem depender de arrastar horizontalmente com o mouse.'),
('P1','Missões: foco inicial','Abrir com foco em elemento útil; fechar retorna à opção Missões. Confirmar e cancelar não acionam o mundo atrás.'),
('P1','Coleção e Dex: informação em páginas','Visão geral mostra criatura, nível, estado de posse e técnica; história e drops em páginas próprias. Todas as páginas e a rolagem interna acessíveis sem cursor.'),
('P1','HUD de combate: legibilidade','Aumentar prioridade visual de linha e energia; manter cruzamento de linhas livre. Testar arena com quatro participantes, efeitos e avisos simultâneos.'),
('P2','Mochila: escala do inventário','Categorias, quantidades e detalhe contextual; testar vazia, uma unidade e muitas unidades. Agrupamento visual não deve alterar dados ou consumir exemplares incorretos.'),
('P2','Estados da coleção','Distinguir foco, consulta, obtido, equipado e indisponível usando forma, texto e ícone além da cor.'),
('P2','Diálogos e cenário atrás','Reduzir competição entre sobreposições. Uma camada interativa por vez, sem esconder informação necessária à decisão.'),
('P1 antes da liberação','Controle físico e jornada completa','PIP-46/PIP-48: testar abertura até Zeca, renomear sem teclado físico, reconexão, cancelamento, persistência e ausência de recompensa duplicada. Ainda pendente.')]

decisions=[
('Combate','Dados vitais nas bordas; leitura do cruzamento no centro. Efeito de skill deve comunicar alcance, janela e acerto.','Não copiar ordem de turnos ou menus que bloqueiem a leitura do adversário.'),
('Dex e coleção','Retratos consistentes + criatura grande + páginas de detalhe + ações no rodapé.','Não concentrar toda a história, XP, drops e seis atributos numa única coluna longa.'),
('Mochila','Categorias e quantidades; seleção revela descrição e ação disponível.','Não transformar cada unidade repetida num cartão grande sem necessidade.'),
('Exploração','Objetivo curto e interação próxima ao contexto. Parceiro presente no mundo.','Não manter cinco painéis grandes durante o passeio.'),
('Diálogo','Uma voz, uma mensagem e uma ação principal; escolhas em lista.','Não sobrepor diálogos narrativos e menus ativos com a mesma prioridade.'),
('Identidade','Papel vivo, bambu, nó, linha, vento e retratos dos Pipamons.','Não importar molduras tecnológicas, criaturas, logos ou sprites das franquias.')]

extra_notes={
'poke-arceus-pokedex-01':'Arte conceitual do caderno; não é tela funcional da Dex.',
'poke-arceus-mapa':'Cena narrativa com personagens; apesar do nome original do arquivo, não é mapa.',
'poke-arceus-loja':'Exterior de loja; sem menu de compra visível.',
'poke-arceus-loja-menu':'Exterior de oficina; apesar do nome do arquivo, não mostra menu.',
'poke-arceus-pastagem':'Entrada da pastagem; sem interface de equipe.',
'poke-arceus-equipe-pastagem':'Cena da pastagem; sem menu de gerenciamento.',
'digi-time-stranger-personalidade':'Montagem editorial de painéis; não tratar como uma única tela do jogo.',
'digi-time-stranger-fazenda':'Cena promocional da fazenda; sem HUD interativa.',
'digi-time-stranger-conversao':'Apresentação promocional de obtenção de criatura.',
'poke-za-tempo-real-2':'Cena espacial sem HUD completa; não evidencia recargas.'}

manifest=json.loads((ROOT/'fontes-parciais.json').read_text(encoding='utf-8'))
for item in manifest:
    item['sourceAsset']=urljoin(item['sourcePage'],item['sourceAsset'])
    item['note']=extra_notes.get(item['id'],'Ver análise e limitações na galeria.')
for f in figures:
    if not any(x['file']==f['file'] for x in manifest):
        manifest.append(dict(id=Path(f['file']).stem,file=f['file'],sourcePage=f['source'],kind=f['limit'],date='2026-10-20'))
for path in (ROOT/'capturas').glob('*'):
    if not any(x['file']=='capturas/'+path.name for x in manifest):
        manifest.append(dict(id=path.stem,file='capturas/'+path.name,sourcePage=M if 'manual' in path.name else (D if 'digimon' in path.name else P),kind='Página do manual oficial renderizada' if 'manual' in path.name else 'Print próprio do site oficial com contexto',date='2026-10-20'))
for item in manifest:
    path=ROOT/item['file']
    with Image.open(path) as im: item['dimensions']=list(im.size)
(ROOT/'fontes.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')

intro='Estudo visual para o PIP-50, com referências de Pokémon e Digimon e revisão do piloto local do PipaKlub. Capturas coletadas em 20/10/2026. O resultado orienta composição e interação; não é uma avaliação de desempenho, economia ou balanceamento.'
method='Foram consultadas páginas oficiais de Pokémon Legends: Arceus, Pokémon Legends: Z-A, materiais oficiais de Digimon Story Time Stranger e o manual de Digimon World: Next Order. As imagens das franquias são capturas publicadas pelos titulares ou páginas do manual, não sessões próprias dos jogos. As molduras promocionais e chamadas do manual permanecem identificadas. PipaKlub foi aberto num servidor local com banco de teste isolado, HEAD 7183063; os prints incluem 1280 x 720 e amostras de 1920 x 1080. Nenhuma conta ou banco de produção foi alterado.'
conclusion='A direção recomendada é um caderno de campo brasileiro: parceiro em destaque, rostos para navegar, papel e bambu como linguagem, tipografia legível e comandos consistentes. O piloto já tem identidade no menu principal. O maior ganho agora vem da hierarquia das informações e do contrato de navegação, antes de criar mais molduras.'
limits='O benchmark não verifica input lag, animações completas, acessibilidade das franquias ou navegação por controle físico. Os screenshots promocionais não comprovam estados ocultos, fluxos de erro ou regras de negócio. O teste local não conclui PIP-46, PIP-48 ou PIP-49; homologação, migração e implantação continuam trabalhos separados.'
md=['# PipaKlub - Benchmark de HUD e menus','',intro,'','## Recomendação','',conclusion,'','## Método e limites','',method,'',limits,'','## Decisões por sistema','']
for area,use,avoid in decisions: md+=['### '+area,'',use+' '+avoid,'']
md+=['## Ajustes priorizados no piloto','']
for p,title,accept in priorities: md+=['### '+p+' - '+title,'',accept,'']
md+=['## Diretrizes propostas para o nosso jogo','',
'- Base de composição: 16:9, com teste em 1280 x 720 e 1920 x 1080. Margem segura proposta: 32 px em 720p, ajustada após teste em TV.',
'- Texto de leitura: começar com 18-20 px em 720p; rótulos menores só para informação secundária. São propostas para PipaKlub, não medidas das referências.',
'- Uma ação primária por contexto; rodapé estável com confirmar, voltar, páginas e ações secundárias. Glifos seguem o dispositivo usado.',
'- Foco = pipa e fio + contorno; equipado = selo e texto; obtido = símbolo e texto; indisponível = requisito explícito. Não depender apenas de cores.',
'- Sprites preservam proporção e rabiola; ajustar pelo limite visual, sem ampliar uma moldura raster inteira. Containers continuam usando 9-slice.',
'- Leitura de ficha por abas: Visão geral, Status, Técnica, História e Drops conforme a tela. Não repetir páginas vazias ou ações que não existem.',
'- Recompensas, equipamento e uso de itens continuam confirmados pelo servidor; mudar a interface não altera essa autoridade.',
'- Redução de movimento desativa pulsos, deslocamentos e brilhos contínuos sem remover indicação de foco ou estado.',
'','## Capturas comentadas','']
for f in figures:
    md+=['### '+f['title'],'',f"![{f['title']}]({f['file']})",'',f['observation'],'','**Aplicação:** '+f['adaptation'],'','**Evidência:** '+f['limit'],'','**Fonte:** '+f['source'],'']
md+=['## Próxima revisão jogável','',
'1. Corrigir corte das rebicadas e foco inicial de missões.',
'2. Aprovar uma ficha de parceiro em 720p com criatura maior, resumo e páginas de detalhe.',
'3. Testar o conjunto menu, diálogo, coleção e combate com controle físico. Registrar cada transição e retorno de foco.',
'4. Percorrer a abertura até o duelo de Zeca com conta nova; interromper e retomar em cada marco.',
'5. Somente após homologação de dados e plano de recuperação, preparar a liberação descrita no PIP-49.',
'','## Acervo e direitos','',
f"O acervo contém {len(manifest)} imagens, com dimensões e origem em fontes.json. A galeria destaca {len(figures)} figuras comentadas. Imagens complementares de cenário não são tratadas como evidência de HUD.",
'','Referências de Pokémon e Digimon pertencem aos respectivos titulares e ficam restritas a este estudo. Não foram inseridas nos assets de produção, na interface ou no pacote do jogo. Esta análise propõe padrões funcionais e uma execução visual original para PipaKlub.']
(ROOT/'BENCHMARK.md').write_text('\n'.join(md),encoding='utf-8')

esc=html.escape
cards=''
for f in figures:
    link=f'<a href="{esc(f["source"],quote=True)}" target="_blank" rel="noreferrer">Fonte oficial</a>' if f['source'].startswith('http') else esc(f['source'])
    cards+=f'<article data-category="{esc(f["category"])}"><header><small>{esc(f["category"])}</small><h2>{esc(f["title"])}</h2></header><a href="{f["file"]}" target="_blank"><img loading="lazy" src="{f["file"]}" alt="{esc(f["title"],quote=True)}"></a><p>{esc(f["observation"])}</p><p><b>Para PipaKlub:</b> {esc(f["adaptation"])}</p><p class="meta">{esc(f["limit"])}<br>{link}</p></article>'
options=''.join(f'<option>{esc(c)}</option>' for c in sorted(set(f['category'] for f in figures)))
priority=''.join(f'<li><b>{esc(p)} · {esc(t)}</b><p>{esc(a)}</p></li>' for p,t,a in priorities)
extra=''.join(f'<li><a href="{esc(x["file"])}">{esc(x["id"])}</a> - {esc(x.get("note",x.get("kind","")))}</li>' for x in manifest if not any(f['file']==x['file'] for f in figures))
page=f'''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>PipaKlub · Benchmark visual</title><style>
:root{{color-scheme:light;--ink:#153e39;--paper:#faf6e9;--line:#d3cbb9}}*{{box-sizing:border-box}}body{{margin:0;background:var(--paper);color:var(--ink);font:17px/1.6 system-ui,sans-serif}}main{{max-width:1220px;margin:auto;padding:48px 28px}}h1{{font-size:clamp(34px,5vw,60px);line-height:1.1;max-width:1000px}}h2{{line-height:1.25;font-size:23px}}.lead{{max-width:900px;font-size:21px}}a{{color:#855017}}.label,small{{text-transform:uppercase;letter-spacing:.12em;font-size:12px;font-weight:700}}section{{margin:44px 0}}.grid{{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px}}article{{background:white;border:1px solid var(--line);border-radius:10px;overflow:hidden}}article header,article p{{margin:0;padding:15px 22px}}article header{{border-bottom:1px solid var(--line)}}article img{{width:100%;height:auto;display:block;background:#e8e5dc}}.meta{{font-size:13px;color:#555;border-top:1px solid var(--line);overflow-wrap:anywhere}}select{{font:inherit;padding:12px;margin-left:12px;border:1px solid var(--line);border-radius:6px;background:white}}li{{margin:15px 0}}li p{{margin:4px 0}}details{{padding:20px;border:1px solid var(--line)}}[hidden]{{display:none!important}}@media(max-width:800px){{.grid{{grid-template-columns:1fr}}main{{padding:28px 18px}}}}@media print{{.grid{{display:block}}article{{break-inside:avoid;margin:20px 0}}select{{display:none}}}}
</style><main><p class="label">PIP-50 · Estudo visual · 20 outubro 2026</p><h1>Mais parceiro.<br>Mais céu. Menos ruído.</h1><p class="lead">{esc(conclusion)}</p><p>{esc(intro)}</p><p><a href="BENCHMARK.md">Relatório editável</a> · <a href="fontes.json">Manifesto de fontes</a></p><section><h2>Como ler o acervo</h2><p>{esc(method)}</p><p>{esc(limits)}</p></section><section><h2>O que corrigir primeiro</h2><ol>{priority}</ol></section><section><label for="filter">Capturas comentadas <select id="filter"><option value="">Todas as áreas</option>{options}</select></label><p>Clique na imagem para abrir o arquivo original. As capturas não foram redesenhadas ou geradas por IA.</p><div class="grid">{cards}</div></section><details><summary>Acervo complementar e limites de cada imagem</summary><ul>{extra}</ul></details><section><h2>Referência não é asset de produção</h2><p>As imagens das franquias pertencem aos respectivos titulares. Servem a este estudo; a proposta do PipaKlub mantém papel, bambu, nós, vento e personagens próprios.</p></section></main><script>document.getElementById('filter').addEventListener('change',function(){{document.querySelectorAll('article').forEach(e=>e.hidden=!!this.value&&e.dataset.category!==this.value)}})</script></html>'''
(ROOT/'index.html').write_text(page,encoding='utf-8')
(ROOT/'figuras.json').write_text(json.dumps(figures,ensure_ascii=False,indent=2),encoding='utf-8')

def make_pdf():
    from reportlab.pdfgen import canvas
    from reportlab.pdfbase import pdfmetrics
    from reportlab.pdfbase.ttfonts import TTFont
    from reportlab.platypus import Paragraph,Table,TableStyle
    from reportlab.lib.styles import ParagraphStyle
    from reportlab.lib.colors import HexColor,white
    from reportlab.lib.utils import ImageReader
    pdfmetrics.registerFont(TTFont('Arial','C:/Windows/Fonts/arial.ttf'))
    pdfmetrics.registerFont(TTFont('ArialB','C:/Windows/Fonts/arialbd.ttf'))
    W,H=842,595
    PDF.parent.mkdir(parents=True,exist_ok=True)
    c=canvas.Canvas(str(PDF),pagesize=(W,H))
    c.setTitle('PipaKlub - Benchmark de HUD e menus: Pokémon e Digimon')
    c.setAuthor('PipaKlub | Estudo de produto')
    n=0
    style=ParagraphStyle('body',fontName='Arial',fontSize=12,leading=18,textColor=HexColor('#153e39'))
    small=ParagraphStyle('small',parent=style,fontSize=9,leading=12)
    def para(text,x,y,w,st=style):
        p=Paragraph(esc(text),st);_,h=p.wrap(w,H);p.drawOn(c,x,y-h);return y-h-12
    def begin(title,label='BENCHMARK VISUAL'):
        nonlocal n
        n+=1;c.setFillColor(HexColor('#faf6e9'));c.rect(0,0,W,H,fill=1,stroke=0)
        c.setFillColor(HexColor('#153e39'));c.setFont('ArialB',9);c.drawString(36,H-30,'PIPAKLUB / '+label)
        c.setFont('ArialB',23);c.drawString(36,H-64,title)
        c.setStrokeColor(HexColor('#d3cbb9'));c.line(36,30,W-36,30)
        c.setFont('Arial',8);c.drawString(36,17,'20/10/2026 | Estudo de referências e piloto local | HEAD 7183063');c.drawRightString(W-36,17,str(n))
    def end():c.showPage()
    begin('HUD e menus: Pokémon + Digimon')
    y=H-110
    for t in [intro,conclusion,method,limits]: y=para(t,36,y,W-72)
    end()
    begin('Decisões para o PipaKlub')
    y=H-94
    for area,use,avoid in decisions:
        y=para(area.upper(),36,y,140,ParagraphStyle('s'+area,parent=style,fontName='ArialB',fontSize=11)) if False else y
        c.setFont('ArialB',11);c.drawString(36,y-12,area)
        y=para(use+' '+avoid,172,y,W-208,ParagraphStyle('dec',parent=style,fontSize=11,leading=15))-5
    end()
    for chunk,head in [(priorities[:4],'Prioridade: composição e navegação'),(priorities[4:],'Prioridade: escala e validação')]:
        begin(head);y=H-100
        for p,title,accept in chunk:
            y=para(p+' / '+title,36,y,W-72,ParagraphStyle('bold',parent=style,fontName='ArialB'))
            y=para(accept,36,y,W-72)-12
        end()
    for f in figures:
        begin(f['title'],f['category'].upper())
        path=ROOT/f['file'];im=Image.open(path);iw,ih=im.size
        maxw,maxh=W-72,330
        scale=min(maxw/iw,maxh/ih);dw,dh=iw*scale,ih*scale
        c.drawImage(ImageReader(im),36+(maxw-dw)/2,H-85-dh,width=dw,height=dh,mask='auto')
        y=H-85-dh-13
        y=para(f['observation']+' '+f['adaptation'],36,y,W-72,ParagraphStyle('caption',parent=style,fontSize=10.3,leading=14))
        y=para(f['limit'],36,y,W-72,small)
        # URLs are available as clickable labels to preserve readable layout.
        c.setFont('Arial',9);c.setFillColor(HexColor('#855017'))
        label='Fonte: '+('Pokémon - página oficial' if f['source']==P else 'Bandai Namco - apresentação oficial' if f['source']==D else 'Bandai Namco - manual oficial '+f['source'].split('#')[-1] if f['source'].startswith(M) else 'Pokémon Z-A - página oficial' if f['source']==Z else f['source'])
        c.drawString(36,max(44,y-2),label)
        if f['source'].startswith('http'):c.linkURL(f['source'],(36,max(42,y-4),W-36,max(55,y+9)),relative=0)
        end()
    begin('Fontes, limites e próximo passo')
    y=H-104
    for t in [f'Acervo: {len(manifest)} imagens. Galeria comentada: {len(figures)} figuras. Origem, dimensões e observações em fontes.json. Arquivos originais em capturas/.',
    'Próxima entrega recomendada: corrigir as abas da pausa e o foco de missões, então aprovar uma ficha de parceiro em 720p com páginas de detalhe. O menu principal atual deve ser preservado como base de identidade.',
    'A validação de controle físico e a jornada completa de conta nova continuam pendentes. Não houve implantação, comentário no Linear, alteração de conta real ou migração de produção nesta auditoria.',
    'Os prints locais são evidências de estados específicos. A captura de combate mostra fim de rodada de treino; não demonstra equilíbrio de skills ou desempenho online.',
    'As imagens de Pokémon e Digimon pertencem aos respectivos titulares. Não incorporar seus sprites, logos ou molduras no produto. Padrões funcionais devem receber execução visual original.']:y=para(t,36,y,W-72)
    for label,url in [('Pokémon Legends: Arceus',P),('Digimon Story Time Stranger',D),('Digimon World: Next Order - manual',M),('Pokémon Legends: Z-A',Z)]:
        c.setFont('Arial',10);c.setFillColor(HexColor('#855017'));c.drawString(36,y,label);c.linkURL(url,(36,y-3,600,y+12),relative=0);y-=22
    end();c.save()

if __name__=='__main__':
    import sys
    if '--pdf' in sys.argv:make_pdf()
    if (ROOT/'design-analises.json').exists():
        from build_character_study import build as build_character_study
        build_character_study(ROOT,PDF,with_pdf='--pdf' in sys.argv)
    if '--zip' in sys.argv:
        archive=REPO/'output/pipaklub-benchmark-pokemon-digimon.zip'
        with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
            for p in ROOT.rglob('*'):
                if p.is_file() and '__pycache__' not in str(p):z.write(p,'benchmark/'+str(p.relative_to(ROOT)))
            if PDF.exists():z.write(PDF,'benchmark/benchmark.pdf')
    print(json.dumps({'figures':len(figures),'images':len(manifest),'pdf':str(PDF)},ensure_ascii=False))
