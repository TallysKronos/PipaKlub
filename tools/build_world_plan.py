"""Build a reviewable world proposal; never writes gameplay or map files."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'art/overworld/mundo'
OUT.mkdir(parents=True, exist_ok=True)
areas, edges = [], []

def area(id, name, trajectory, biome, gate, purpose, encounters, size, status='PROPOSTA'):
    areas.append(dict(id=id, nome=name, trajetoria=trajectory, bioma=biome,
                      libera_apos=gate, funcao=purpose, encontros=encounters,
                      tamanho=size, estado=status))

def edge(a, b, gate='livre após acesso às duas áreas', kind='PROPOSTA'):
    edges.append(dict(de=a, para=b, condicao=gate, estado=kind, bidirecional=True))

existing = [
 ('rua-dos-ventos','Rua dos Ventos','ambas','Bairro inicial','primeira criação com Assis','Base de preparação; portas de casa, ateliê e loja','não','44×33'),
 ('morro-praca-da-chegada','Praça da Chegada','1','Morro do Sol','acesso ao Morro','Entrada do circuito; Zeca','não','24×16'),
 ('morro-escadaria-da-sombra','Escadaria da Sombra','1','Morro do Sol','acesso ao Morro','Bia; pausa e subida','não','24×16'),
 ('morro-laje-dos-ventos','Laje dos Ventos','1','Morro do Sol','acesso ao Morro','Juninho e Lia; treino de leitura do vento','não','24×16'),
 ('morro-mirante-da-caixa-dagua','Mirante da Caixa-d’água','1','Morro do Sol','acesso ao Morro','Tião; antecipar visualmente o parque','não','24×16'),
 ('morro-parque-dos-ventos','Parque dos Ventos · Morro','1','Morro do Sol','acesso ao Morro; duelo de Mikka conforme qualificação','Fecho do bairro 1; marco do coreto','não','24×16'),
 ('jardim-das-pipas','Jardim das Pipas','ambas','Parque dos Ventos','início da missão de Nina; sem exigir três bairros','Ouvir Nina, estabelecer o vínculo com Carcará e seguir rastros','sim, somente no mato','40×32'),
 ('clareira-do-papel','Clareira do Papel','ambas','Parque dos Ventos','seguir a busca de Nina','Escolha entre trilha segura e exploração; descanso antes das Veredas','sim, somente no mato','24×16'),
 ('veredas-do-encanamento','Veredas do Encanamento','ambas','Vereda e arenito','busca de Nina; acesso profundo separado após bairro 3','Lacertubo, recuperação de Carcará e primeira entrada vedada das Ruínas','sim, somente no mato','50×32'),
]
for row in existing:
    values=list(row)
    path=ROOT/'art/overworld/mapas'/f'{row[0]}.tmj'
    if path.exists():
        current=json.loads(path.read_text(encoding='utf-8-sig'))
        values[-1]=f'{current["width"]}×{current["height"]}'
    area(*values, status='EXISTENTE; papel futuro em proposta')

# Read the actual Tiled exits, resolving game-scene IDs without rewriting them.
maps = []
for file in sorted((ROOT/'art/overworld/mapas').glob('*.tmj')):
    m = json.loads(file.read_text(encoding='utf-8-sig'))
    props = {p['name']: p.get('value') for p in m.get('properties', [])}
    maps.append((file.stem, m, props))
scene_to_area = {p['cena_jogo']: id for id, m, p in maps if p.get('cena_jogo')}
raw_exits = []
for id, m, props in maps:
    for layer in m.get('layers', []):
        for obj in layer.get('objects', []):
            if obj.get('type') == 'saida':
                dest = next((p['value'] for p in obj.get('properties', []) if p['name']=='destino'), None)
                raw_exits.append(dict(origem=id, destino_cena=dest, destino_area=scene_to_area.get(dest)))

for a,b in zip([r[0] for r in existing[1:6]], [r[0] for r in existing[2:6]]):
    edge(a,b,kind='SAÍDAS TMJ NOS DOIS SENTIDOS')
edge('rua-dos-ventos','morro-praca-da-chegada','conexão via cidade; falta saída direta na Rua')
edge('rua-dos-ventos','jardim-das-pipas','missão de Nina; retorno TMJ ao quintal existe, ida ainda depende do jogo')
edge('jardim-das-pipas','clareira-do-papel',kind='SAÍDAS TMJ NOS DOIS SENTIDOS')
edge('clareira-do-papel','veredas-do-encanamento',kind='SAÍDAS TMJ NOS DOIS SENTIDOS')

districts = [
 (2,'beira-mar','Beira-Mar','Cais, restinga e vila de pescadores','Farol baixo','azul-petróleo e areia'),
 (3,'campanarios','Campanários','Colina histórica e jardins de igreja','Torre dos sinos','ocre e creme'),
 (4,'feira-das-fitas','Feira das Fitas','Mercado aberto e pomares de quintal','Cobertura de feira','coral e verde-folha'),
 (5,'vila-das-oficinas','Vila das Oficinas','Vila operária e galpões artesanais','Chaminé desativada','tijolo e azul-gasto'),
 (6,'canais-da-argila','Canais da Argila','Olarias e canais rasos de barro','Roda de água','terracota e turquesa'),
 (7,'lagoa-do-junco','Lagoa do Junco','Lagoa e palafitas baixas','Passarela da lagoa','verde-junco e lilás'),
 (8,'serra-do-apito','Serra do Apito','Serra de mata atlântica e nascentes','Pedra assobiadora','verde-escuro e pedra-fria'),
 (9,'buritizal','Buritizal','Cerrado e vereda de buritis','Buriti solitário','terra-vermelha e amarelo-palha'),
 (10,'pedra-bordada','Pedra Bordada','Escarpa de arenito e casario de bordadeiras','Arco de arenito','areia e vermelho-tecido'),
 (11,'alto-dos-varais','Alto dos Varais','Morro urbano denso e lajes comunitárias','Reservatório pintado','creme e tecido-multicor'),
 (12,'nascente-do-vento','Nascente do Vento','Cabeceira do rio e campo de altitude','Crista do Primeiro Vento','azul-claro e verde-seco'),
]
previous = 'morro-parque-dos-ventos'
for n, slug, name, biome, landmark, palette in districts:
    gate = f'vitória permanente no bairro {n-1}'
    hub, streets, arena_id, route = [f'{slug}-{s}' for s in ('eixo','ruas','arena','travessia')]
    area(hub, f'{name} · eixo central','ambas',biome,gate,
         f'Entrada segura, descanso e primeiro capanga; marco: {landmark}','não','40×32')
    area(streets, f'{name} · ruas','1',biome,gate,
         'Outros três capangas, laço opcional com baú e retorno curto ao eixo','não','48×40')
    area(arena_id, f'{name} · arena','1',biome,
         gate+'; desafio do campeão após quatro qualificações',
         'Campeão ainda sem nome aprovado; arena no ponto simbólico','não','32×28')
    area(route, f'{name} · travessia natural','ambas',biome,
         f'vitória no bairro {n}; retorno preservado após abertura',
         'Ligação ao próximo bairro, mato contornável e atalho de retorno','sim, somente no mato','48×36')
    edge(previous,hub,gate)
    edge(hub,streets)
    edge(streets,arena_id,'duelo exige quatro qualificações; passeio não concede vitória')
    edge(hub,route,f'vitória no bairro {n}')
    previous=route

area('galeria-dos-apitos','Galeria dos Apitos','2','Ruínas rasas de arenito','bairro 3 + missão inicial de Nina concluída',
     'Investigar danos além do pátio; Grampo evidencia o contraste entre preservar e arrancar','sim, somente no mato exterior','40×32')
area('caverna-do-mural','Caverna do Mural','2','Caverna de arenito e canais','bairro 4; acesso pela galeria',
     'Tyler mostra o primeiro laço; reação da Rabiola Antiga, sem explicar o Elo','não; conflito roteirizado separado','48×40')
area('caminho-dos-canais-antigos','Caminho dos Canais Antigos','2','Ruínas e nascente','bairro 11',
     'Preparação, descanso e vista do coração; equipamento arrancado antecipa ocupação','sim, somente no mato','48×36')
area('coracao-das-ruinas','Coração das Ruínas','2','Canais, arenito e câmara do ovo','bairro 11 para investigar; Rato só após bairro 12',
     'Bando invade; união da família; confronto com Rato respeita a ordem final','não; confrontos roteirizados','64×56')
area('santuario-do-lendario','Santuário do Lendário','ambas','Ruína aberta e cabeceira de rio','12 bairros + Rato derrotado',
     'Teste do lendário; identidade e espécie não definidas','não; duelo do lendário','48×40')
area('estadio-do-championship','Estádio do Championship','1','Equipamento público e praça de acesso','12 bairros + Rato + lendário, nessa ordem',
     'Final com Jamile; arquibancada reúne família, professor e Tyler','não','64×48')
edge('veredas-do-encanamento','galeria-dos-apitos','bairro 3 + missão de Nina concluída')
edge('galeria-dos-apitos','caverna-do-mural','bairro 4')
edge('caverna-do-mural','caminho-dos-canais-antigos','bairro 11; passagem antes visível, fechada')
edge('caminho-dos-canais-antigos','coracao-das-ruinas','bairro 11; Rato exige bairro 12')
edge('alto-dos-varais-eixo','caminho-dos-canais-antigos','bairro 11; reabre caminho familiar às Ruínas')
edge('coracao-das-ruinas','santuario-do-lendario','12 bairros + Rato derrotado')
edge('nascente-do-vento-travessia','santuario-do-lendario','12 bairros + Rato derrotado')
edge('nascente-do-vento-eixo','estadio-do-championship','12 bairros + Rato + lendário')
edge('canais-da-argila-eixo','rua-dos-ventos','atalho após bairro 6; não antecipa o acesso ao bairro')
edge('pedra-bordada-eixo','rua-dos-ventos','atalho após bairro 10; não abre laboratório antes do evento')

for row in areas:
    row['conecta_com'] = [e['para'] if e['de']==row['id'] else e['de']
                         for e in edges if row['id'] in (e['de'],e['para'])]
ids = {a['id'] for a in areas}
assert len(ids)==len(areas)
assert all(e['de'] in ids and e['para'] in ids for e in edges)
reached={'rua-dos-ventos'}
while True:
    new=reached|{e['para'] for e in edges if e['de'] in reached}|{e['de'] for e in edges if e['para'] in reached}
    if new==reached: break
    reached=new
assert reached==ids, 'A proposta contém área isolada'

plan=dict(estado='PROPOSTA — AGUARDA APROVAÇÃO', data='2026-10-29',
          fonte_historia='origin/claude/historia@18dec6b87808a45ec23853ff4eb526c37a331b9a',
          areas=areas, conexoes=edges, saidas_tmj_lidas=raw_exits)
(OUT/'mapa-mundi.proposta.json').write_text(json.dumps(plan,ensure_ascii=False,indent=2),encoding='utf-8')

intro='''# Mapa-múndi — Soulmonsters: Elo das Ruínas

**Fase 0 · PROPOSTA PARA APROVAÇÃO · 29/10/2026**

Este é um plano espacial, não um mapa já implementado. Nenhuma planta, regra, save ou asset do jogo foi alterado. Nomes, ordem dos bairros novos, biomas, portões e dimensões estimadas são propostas. IDs existentes permanecem intactos. As conexões atuais foram lidas dos TMJ; ligações novas têm estado explícito no JSON anexo.

**Atualização regional:** a Fase 0 foi sucedida pelo lote de plantas do Parque A/B/C em `art/overworld/briefs/parque-dos-ventos-abc.md`. As dimensões existentes da tabela são lidas das plantas atuais. A nova regra de regiões com pelo menos três partes está em `art/overworld/REGIOES-E-PARTES.md`; o desdobramento de Caverna, Coração e demais regiões futuras ainda exige revisão do mapa-múndi. A frase anterior descreve o escopo original da Fase 0, não nega as alterações de planta posteriores.

## Decisão mais recente do criador

“Preservar a missão mas deixar ela mais profunda também.” Nina e Lacertubo continuam na primeira excursão da demo, antes de exigir três bairros concluídos. A missão recebe preparação emocional, rastros e escolhas de exploração. Conteúdo profundo das Ruínas abre depois. Os acontecimentos novos descritos abaixo são propostas de execução dessa decisão, não falas ou eventos já aprovados.

## Fontes e divergências

- História consultada sem merge: `origin/claude/historia`, commit `18dec6b87808a45ec23853ff4eb526c37a331b9a`, arquivo `documentation/historia/BIBLIA-DA-HISTORIA.md` (v1). Seus rótulos Decidido/Canônico/Proposta permanecem válidos; a estrutura dos capítulos é proposta.
- Contratos locais: AGENTS.md, continuidade-terreno-isometrico.md, ESPECIFICACAO-MAPAS.md, INVENTARIO-CODEX.md, estilo/README.md, WORLD-ART-DIRECTION.md e WORLD-EXPLORATION.md. O roteiro de Tyler continua marcado como proposta de one-shot; o mural não prova sozinho uma cosmologia definitiva.
- A bíblia sugere Jardim/Clareira/Veredas após bairros 1/2/3. A decisão acima prevalece: acesso inicial preservado; cenas tardias e passagens profundas ficam separadas do primeiro percurso. Nada disso foi aplicado ao jogo nesta entrega.
- Guia `documentation/overworld/godot-tilesets-profundidade.md` e os kits extensos existem na branch de história, mas não nesta árvore de trabalho. Aqui há kits `comum` e `morro`; os demais exigem integração e conferência antes de serem considerados disponíveis. O guia remoto foi consultado, sem alterar o motor.
- Inventário gerado lista nove áreas; há também `veredas-piloto.tmj`, sem `cena_jogo`. É laboratório de validação, não décima área de campanha. Não foi apagado nem renomeado.
- Documentos antigos citam campanha conectada e mapas como imagem única. A decisão posterior de Godot com campanha offline e a produção modular prevalecem. A linguagem é mangá 2D, cores planas e uma sombra por material; não maquete 3D.
- Beira-Mar e Campanários já existem como Trilhas/identidades legadas (designs.json e CAMPANHA-CIDADE.md). Propõe-se aproveitá-las nos bairros 2/3; isso não migra nem renomeia os IDs das Trilhas, nem confirma seus campeões nesta expansão.

## Leitura do mundo

Uma espinha urbana avança pelos 12 bairros. O parque é um ramo acessível cedo que vai ganhando profundidade, com voltas por atalhos. Bairro não precisa virar um corredor: eixo seguro, ruas em laço, arena lateral e travessia natural compõem cada conjunto. O diagrama é topológico; posições não fixam distância nem orientação geográfica final.

```mermaid
flowchart LR
  R[Rua dos Ventos] --- M[B1 Morro do Sol]
  M -->|Mikka| B2[B2 Beira-Mar]
  B2 --> B3[B3 Campanários]
  B3 --> B4[B4 Feira das Fitas]
  B4 --> B5[B5 Vila das Oficinas]
  B5 --> B6[B6 Canais da Argila]
  B6 --> B7[B7 Lagoa do Junco]
  B7 --> B8[B8 Serra do Apito]
  B8 --> B9[B9 Buritizal]
  B9 --> B10[B10 Pedra Bordada]
  B10 --> B11[B11 Alto dos Varais]
  B11 --> B12[B12 Nascente do Vento]
  R --- J[Jardim das Pipas]
  J --- C[Clareira do Papel]
  C --- V[Veredas: Nina e Lacertubo]
  V -->|B3| G[Galeria dos Apitos]
  G -->|B4| CM[Caverna do Mural]
  CM -->|B11| CC[Caminho dos Canais Antigos]
  B11 -->|atalho após vitória| CC
  CC --- H[Coração: investigação B11]
  H -->|B12 e Rato derrotado| S[Santuário do Lendário]
  B12 -->|Rato derrotado| S
  S -->|lendário derrotado| E[Estádio: Jamile]
  B6 -. atalho de retorno .-> R
  B10 -. atalho de retorno .-> R
```

Setas urbanas exigem vencer o campeão anterior, não simplesmente chegar à área. O combate de Rato ocorre somente depois dos 12 bairros, embora a investigação do Coração possa abrir no 11. Retornos são bidirecionais após abertura. Arestas completas, condições e IDs estão no JSON; cada conjunto urbano se expande em eixo, ruas, arena e travessia na tabela.

## Catálogo de áreas

Trajetória 1 = campeonato; 2 = família/Ruínas. “Encontros” significa encontro aleatório: **somente no mato**. Duelos de capangas, campeões, boss e eventos não são encontros aleatórios. Praças, descansos, Nina e rampas de transição são seguros. Dimensões são células 64×32; cada arquivo fica abaixo de 96×96.

'''
table='| id | nome | trajetória | bioma | libera_apos | conecta_com | função na história | encontros | tamanho estimado | estado |\n|---|---|---|---|---|---|---|---|---|---|\n'
for a in areas:
    values=[a['id'],a['nome'],a['trajetoria'],a['bioma'],a['libera_apos'],', '.join(a['conecta_com']),a['funcao'],a['encontros'],a['tamanho'],a['estado']]
    table+='| '+' | '.join(values)+' |\n'

extra='''
## Missão de Nina: proposta em duas profundidades

| Etapa | Local e experiência | O que muda / limite |
|---|---|---|
| Primeiro contato | Jardim: Nina num recuo seguro, com carretel danificado e o espaço vazio do parceiro. Ela conta o essencial; sem monólogo explicativo. | A busca nasce de uma pessoa, não de uma lista de marcadores. O significado do Carcará vem antes da recompensa. |
| Seguir o rastro | Clareira: primeiro vestígio no caminho e um segundo num desvio contornável; trilha principal de 3–5 células. | Dois caminhos se reencontram. Um leva a recurso de preparação, outro a pista. Nenhum item de missão exige encontro aleatório. |
| Preparação | Veredas: vista antecipada do pátio, bica/banco seguro e atalho que pode ser aberto pelo lado interno. | Jogador reconhece o objetivo e decide explorar um patamar com baú antes de entrar. Não há escalada inventada nem saltos. |
| Encontro | Lacertubo no pátio dos canos; a rabiola de Nina é distinguível da recompensa do boss. | Depois da vitória ele desaparece; o brilho no chão é a rabiola de Carcará de Nina. A própria rabiola de Lacertubo é recompensa separada, não substituta. Não reaparece como guardião de revanche. |
| Devolução | Retorno curto até Nina, sem novo labirinto; Carcará e a reação dela dão fecho emocional. | Entrega inicial e recompensa são únicas. Nenhum tamanho ou tipo novo de recompensa foi fixado neste plano. |
| Releitura após B1 | Retorno ao Jardim com Nina: rabiola recuperada e rastros de cerol permitem suspeitar de interferência humana. | A causa é investigada depois do resgate, não justifica culpar automaticamente Lacertubo. Revelação factual final depende de roteiro aprovado. |
| Releitura após B2 | Clareira: apresentação de Tyler e Rai, depois de um vislumbre anterior sem explicação da origem. | Mantém a apresentação proposta pela bíblia sem bloquear a Clareira inteira. Se houver vislumbre, não revelar laboratório, DNA ou Elo. |
| Abertura após B3 | Passagem além do pátio até Galeria dos Apitos: marcas de retirada e primeiro confronto com Grampo. | Lacertubo já não está lá. Ruínas profundas permanecem fechadas antes do portão; o primeiro resgate não se repete. |

Não transformar Nina em simples guia de tutorial. Proposta: ela toma parte na devolução e acompanha a inspeção segura do rastro, mas não recebe profissão, parentesco, habilidade ou arco final inventado. O resgate, a suspeita e a descoberta do responsável são momentos separados. A ligação causal entre Bando e a batalha de Nina aguarda roteiro; a bíblia afirma o cerol, mas não detalha como o confronto se deu.

## Portas dos interiores (não criar plantas aqui)

| Porta externa | Interior / gatilho proposto | Sigilo |
|---|---|---|
| Rua dos Ventos: casa de Kael | `kael-home` já referenciado; casa e quarto no Iso Studio | Confissão noturna após B8, proposta conservadora dentro da faixa B7–8 da bíblia; gatilho final por aprovar. |
| Rua dos Ventos: ateliê de Assis | `professor-home` já referenciado; oficina e criação | Arquivo após B6 (faixa B5–6), com foto da expedição. Porta interna não se confunde com saída de mapa. |
| Dentro do ateliê | Laboratório sob o ateliê, após B10 (faixa B9–10) | Sem visibilidade de cenário interno antes do portão. Acesso proposto após B10; nunca antes de B9. |
| Rua dos Ventos: loja | `kite-shop` já referenciado | Serviço existente; não criar interior novo nesta fase. |
| Eixo de cada bairro | Portas decorativas ou serviços somente após brief aprovado | Não prometer 12 casas exploráveis nem desenhar interiores sem escopo. |

## Marcos e identidade dos bairros — todos em proposta

'''
for n,slug,name,biome,landmark,palette in districts:
    extra+=f'- **B{n} · {name}:** {biome.lower()}; marco {landmark.lower()}; família {palette}. Um eixo de respiro, até 4–6 fachadas por enquadramento, ruas em laço e arena de {name}.\n'

extra+='''

## Ritmo, relevo e retorno

- Todo bairro: entrada segura → primeiro capanga → escolha de ruas → descanso → campeão. Qualificação dos quatro adversários é estado separado de caminhada. Os NPCs existentes do Morro são preservados; a adequação à regra de quatro qualificações não será feita removendo Juninho, Lia ou outro personagem.
- Toda travessia natural: dois níveis mínimos com rampa útil, dois caminhos que se reencontram, um desvio recompensado, um descanso e um atalho aberto do lado de dentro. Regiões amplas são divididas em arquivos, não comprimidas na câmera.
- Uma ponte física exige apoio nas duas margens; uma ligação no diagrama não autoriza ponte suspensa. Água obedece à cota. Cachoeira somente se houver poço e diferença de nível na planta.
- Nomes e marcos guiam a descoberta pelo cenário. Nada de sinalizar todos os lugares no minimapa. Mostrar portas das Ruínas antes de abri-las, sem permitir contato prematuro com gatilhos narrativos.
- Um marco principal por área e até dois secundários. Cerca de 60% aberto / 40% denso é meta visual proposta, não medição existente. Escala e largura só são aprovadas após movimento real na planta.
- Atalhos B6/B10 voltam à Rua e retornam apenas a destinos já abertos; não deixam um jogador entrar em bairro futuro pelo caminho inverso. A perda de um título não deve apagar vitórias históricas nem fechar passagem em torno do jogador.

## Ordem de produção depois da aprovação

1. Primeiro brief: aprofundamento da missão de Nina nas três áreas existentes. Não substituir suas plantas antes da revisão de escopo. Preservar resgate, desaparecimento do boss e separação dos dois drops.
2. Primeiro bairro novo: B2, com eixo/ruas/arena/travessia. Fazer a planta e conferir antes de conceito ou kit. Beira-Mar e Campanários requerem decisão sobre aproveitamento dos nomes e NPCs legados.
3. B3 e Galeria dos Apitos; depois B4 e Caverna do Mural. Seguir até B12 em lotes, com portas e cenas narrativas dos capítulos intermediários registradas no brief.
4. Fechar Rato → lendário → Jamile na ordem decidida. A câmara do ovo não explica nem resolve o fio de Tyler neste jogo.

## Pedidos ao integrador — não implementados aqui

- Resolver `libera_apos` e `trajetoria` para condições estáveis de campanha; não usar apenas o nome de bairro num save. Distinguir acesso físico, cena por visita, qualificação, conclusão histórica e título atual.
- Cenários novos e transições bidirecionais precisam de IDs de cena próprios e pontos de entrada persistíveis. `cidade` é um hub externo citado pelos TMJ, não uma planta encontrada nesta pasta.
- A Rua não tem saída TMJ direta para Morro/Jardim; há retornos desses ramos e ligações via fluxo do jogo. Manter isso visível como trabalho de integração, sem alegar conectividade de planta completa.
- Separar `nina_resgate`, `nina_devolucao`, investigação e abertura profunda; recompensa idempotente. O nome dos estados é sugestão, não alteração de schema.
- Remover o boss do mundo após derrota e deixar recompensa de missão coletável sem repetir combate. Compatibilizar saves da demo já concluídos antes de mudar portões; nunca bloquear ou apagar recompensa já obtida.
- Chão, rampas, obstáculos, ocupantes e ordenação devem compartilhar geometria. Rever o guia remoto de profundidade na integração, sem presumir que um novo kit já está instalado nesta branch.

## Conferência desta entrega

O gerador confere IDs únicos, destinos internos existentes e conexão de todas as áreas no grafo sem portões. Isso não prova ausência de bloqueios narrativos nem acessibilidade física. A progressão descrita acima precisa de simulação de eventos pelo integrador, especialmente retornos, derrotas e saves antigos.

Leitura das saídas TMJ preservada em `mapa-mundi.proposta.json`. Nenhum importador foi executado; nenhum `kit.json` foi reescrito; nenhuma suíte do jogo foi necessária para um documento. Capturas geométricas e teste com Kael pertencem à fase da planta e estão **pendentes**, não aprovados por este diagrama.

Arte de revisão: `MAPA-MUNDI-PREVIA.png` é um esquema de conexões, não conceito de cenário nem captura do jogo. A tabela e o JSON são a fonte completa; a imagem agrupa as subáreas urbanas para legibilidade.

## Decisões para a revisão do dono

1. Aprovar ou ajustar a espinha dos bairros, seus nomes/biomas e a reutilização de Beira-Mar/Campanários.
2. Revisar a proposta de aprofundamento de Nina: resgate cedo, pistas posteriores e abertura profunda em B3. O desejo de preservar e aprofundar já foi confirmado; essas etapas específicas ainda são proposta.
3. Confirmar os marcos dos arquivos/falas nos pares B5–6, B7–8 e B9–10. O plano usa provisoriamente B6/B8/B10, sem fixar novo cânone.

Nenhuma área nova será desenhada antes da aprovação deste mapa-múndi. Não há merge, push ou publicação nesta entrega.
'''
(OUT/'MAPA-MUNDI.md').write_text(intro+table+extra,encoding='utf-8')

# Review diagram, not game art. Fixed-layout labels stay separate from map data.
font_path=Path('C:/Windows/Fonts/segoeui.ttf')
font=ImageFont.truetype(str(font_path),22)
small=ImageFont.truetype(str(font_path),18)
title=ImageFont.truetype(str(font_path),40)
im=Image.new('RGB',(1800,1320),'#141e29')
d=ImageDraw.Draw(im)
d.text((50,30),'SOULMONSTERS · MAPA-MÚNDI',font=title,fill='#f4e9d2')
d.text((50,87),'FASE 0 / PROPOSTA · conexões esquemáticas, sem escala geográfica · 29/10/2026',font=font,fill='#2ec8e3')
names=['Morro do Sol']+[r[2] for r in districts]
positions={}
for i,name in enumerate(names):
    col=i%4; row=i//4
    x=50+col*435; y=175+row*150
    positions[i]=(x,y)
    d.rounded_rectangle((x,y,x+395,y+105),radius=9,fill='#22303f',outline='#ffc23d',width=3)
    d.text((x+14,y+10),f'B{i+1:02} · {name}',font=font,fill='#f4e9d2')
    d.text((x+14,y+52),'Existente' if i==0 else 'Eixo / ruas / arena / travessia',font=small,fill='#d8c9ac')
    if col<3:
        d.line((x+397,y+50,x+430,y+50),fill='#ffc23d',width=3)
        d.polygon([(x+430,y+50),(x+421,y+44),(x+421,y+56)],fill='#ffc23d')
    elif row<2:
        d.text((x+205,y+114),f'→ B{i+2:02} na linha abaixo',font=small,fill='#ffc23d')
d.text((50,635),'PARQUE ACESSÍVEL CEDO · NINA E LACERTUBO',font=font,fill='#2ec8e3')
park=['Rua dos Ventos','Jardim das Pipas','Clareira do Papel','Veredas / Lacertubo']
for i,name in enumerate(park):
    x=50+i*435
    d.rectangle((x,680,x+395,760),fill='#22303f',outline='#2ec8e3',width=3)
    d.text((x+12,701),name,font=font,fill='#f4e9d2')
    if i<3: d.line((x+396,720,x+430,720),fill='#2ec8e3',width=3)
d.text((50,790),'Resgate e devolução no início; investigação posterior sem repetir a missão ou a recompensa.',font=font,fill='#d8c9ac')
d.text((50,845),'PROFUNDIDADE LIBERADA PELO CAMPEONATO',font=font,fill='#2ec8e3')
deep=[('Galeria dos Apitos','B3 + resgate concluído'),('Caverna do Mural','B4 · encontro com Tyler'),('Coração das Ruínas','B11 investiga / B12 enfrenta Rato'),('Santuário → Estádio','12 bairros → Rato → lendário → final')]
for i,(name,gate) in enumerate(deep):
    x=50+i*435
    d.rectangle((x,890,x+395,1005),fill='#22303f',outline='#2ec8e3',width=3)
    d.text((x+12,905),name,font=font,fill='#f4e9d2')
    d.text((x+12,949),gate,font=small,fill='#d8c9ac')
    if i<3: d.line((x+396,945,x+430,945),fill='#2ec8e3',width=3)
d.text((50,1045),'VOLTA AO BAIRRO · atalhos propostos após B6 e B10; interiores permanecem no Iso Studio.',font=font,fill='#ffc23d')
d.text((50,1090),'Arquivo do ateliê: B6?  |  Confissão de Heleana: B8?  |  Laboratório: B10? — marcos por aprovar.',font=font,fill='#d8c9ac')
d.text((50,1150),f'{len(areas)} áreas no catálogo · {len(edges)} conexões · nove plantas existentes preservadas',font=font,fill='#f4e9d2')
d.text((50,1190),'A imagem resume conjuntos. IDs, condições e subáreas completos no documento e no JSON.',font=small,fill='#d8c9ac')
d.text((50,1240),'Sem plantas novas, alterações de gameplay, merge ou push. Nina preservada por decisão do criador.',font=small,fill='#2ec8e3')
im.save(OUT/'MAPA-MUNDI-PREVIA.png')
print(json.dumps(dict(areas=len(areas),conexoes=len(edges),destinos_resolvidos=True,grafo_conexo=True),ensure_ascii=False))
