# Digimon World DS e Digimon World 2003 em regras de construção

Fontes: `documentation/benchmark-digimon-world-ds/README.md` (20 pranchas inspecionadas de 320
catalogadas), `documentation/benchmark-digimon-world-2003-exploracao-grind-2026-10-21.md` e as quatro
imagens de Digimon World DS que o dono enviou em 28/10/2026 (mapa-múndi, Data Forest, Beast Farm e
Default Farm). As pranchas não dão colisões, cotas exatas nem o grafo de saídas. Os números abaixo são
**metas nossas** derivadas da leitura, não medições do jogo original.

Estudamos composição e organização. Não copiamos desenho, textura, planta nem nome.

## 1. Mapa-múndi (ref. 1 do dono)

O que se vê: uma região inteira pintada como ilha, com cada lugar marcado por um ícone ilustrado e
caminhos entre eles. A região é um conjunto de lugares com identidade própria, não um mapa único.

Regra para nós:
- Kronasta tem a sua tela de mundo no mesmo espírito. Cada região do mapa-múndi é um ícone ilustrado
  com silhueta própria (morro, parque, vereda, ruínas).
- Cada região tem pelo menos 3 partes (A, B, C) ligadas em sequência e por um atalho de volta
  (`REGIOES-E-PARTES.md`).
- A saída de uma parte e a chegada na seguinte combinam em **direção, material do chão e cota**. Sair
  pela trilha de terra do fundo-direito chega na trilha de terra da frente-esquerda da próxima parte.

## 2. Data Forest (ref. 2 do dono; pranchas 1 a 4 do benchmark)

O que se vê:
- Blocos de terreno elevado (mesas) com topo de grama, **face de terra com veios** e uma borda de grama
  que dobra por cima da face. A base da face tem sombra no chão de baixo.
- Os caminhos passam **entre** os blocos. A altura organiza o espaço; não é enfeite.
- Copas em massa no alto dos blocos e nas bordas do mapa. Árvore solta é exceção.
- Áreas abertas alternam com estreitamentos; nas pranchas 2 a 4 a água organiza margens e travessias.
- O chão não é uma cor só: dois ou três verdes em manchas grandes, terra nas trilhas.

Regras para nós:
- Área natural com **≥ 40%** das células em nível 1 ou 2.
- Paredão com três partes sempre: face texturizada com estratos, borda de grama recortada no topo,
  sombra de contato no chão de baixo.
- Contorno de platô em trechos longos ao longo dos eixos isométricos, com cantos ocasionais. Borda
  diagonal em degraus de 1 célula serrilha e parece ameia: proibido (ver blocos de 2×2 na geometria).
- Mata em massas de 3 a 7 copas que se sobrepõem; no máximo 1 ou 2 árvores soltas por tela, cada uma
  com sombra.
- Um estreitamento a cada trecho aberto grande: o jogador sente que passou de um lugar para outro.

## 3. Beast Farm (ref. 3 do dono)

O que se vê: um terreno de topo plano cercado por barranco em quase todo o contorno, recintos bem
definidos por cerca e borda, e um acesso claro. A borda do terreno elevado é contínua e fechada; não há
canto aberto mostrando vazio.

Regras para nós:
- Platô habitado (fazenda, mirante, praça alta) tem contorno fechado: barranco em toda a borda exposta,
  mureta ou cerca onde há queda junto de área de uso.
- Recintos e canteiros têm limite construído contínuo, com cantos e pontas resolvidos (peça de canto e
  peça de ponta), sem buraco de uma célula que pareça passagem.
- O acesso ao platô é único e óbvio (rampa ou escada larga) e fica na face da frente.

## 4. Default Farm (ref. 4 do dono)

O que se vê: chão em vários tons e materiais (grama, terra batida, canteiros), objetos agrupados em
conjuntos funcionais, cercas e bordas que separam usos, e a moldura do mapa preenchida até a borda da
tela.

Regras para nós:
- Chão vivo: grama em 2 ou 3 tons com manchas orgânicas maiores que 4 células, terra marcando uso
  (trilha, porta, entorno de bica), tufos concentrados nas bordas de mata e de trilha.
- Objetos em grupos com função (banco + poste + lixeira; caixote + carrinho + ferramenta), nunca
  distribuídos um por célula.
- As últimas 4 a 7 células de cada lado são moldura (mata, paredão, água, casario) e a moldura continua
  além do limite do mapa até a câmera não alcançar o vazio.

## 5. Outras famílias do benchmark DS

| Família | Lição | Regra para nós |
| --- | --- | --- |
| Training Peak | patamares estreitos, paredes de rocha, escadas verticais visíveis; o topo tem espessura e base | toda subida conecta cotas explícitas e leva a algo (vista, atalho, item) |
| Chrome Mine, Drain Tunnel | o material conta a função: trilho, madeira estrutural, alvenaria, cano | cada bioma tem uma família de estruturas própria, não só outra cor de chão |
| Sheer Valley, Steamy Jungle, Packet Swamp, Mangrove Woods | silhueta antes do detalhe | reduza a captura a manchas: se duas áreas ficam iguais, mude a estrutura, não a textura |

Kit mínimo por família de terreno (benchmark DS, seção 2): centro, bordas nos quatro sentidos, cantos
internos e externos, topo/face/base de barranco, entrada e saída de rampa, margem, cabeceira de ponte.
Antes de usar uma família num mapa grande, monte uma sala de testes com trechos longos, curvas,
cruzamentos, cotas diferentes e objetos junto às bordas.

## 6. Digimon World 2003: o percurso

O que os guias e mapas documentam:
- Geografia funcional: cidade → ponte → parque (articulação) → entrada da floresta → floresta oeste e
  leste → hospedaria → lago → pradaria. Cada tela tem papel: passagem, serviço, combate, desvio.
- Bifurcações com recompensa; o jogador não atravessa telas só para uma luta obrigatória.
- Críticas de jogadores: retornos longos, caminhos confusos, encontros demais. Daí a procura por
  viagem rápida.

Regras para nós (tabela do benchmark, seção 3):

| Critério | Construção |
| --- | --- |
| Identidade | uma silhueta reconhecível por tela: árvore grande, caixa-d'água, coreto, arco das Ruínas |
| Caminho principal | material contrastante e largura de 3 a 5 células; a direção se lê sem placa |
| Desvio opcional | ramal de 2 células com motivo concreto no fim (item, espécie, vista, pista) |
| Risco espacial | mato de encontro fora da trilha obrigatória, ou contornável; trilha pavimentada não tem encontro |
| Descanso | um ponto seguro antes do trecho mais arriscado (banco, bica, sombra de árvore grande) |
| Circuito | depois do fim da parte, um atalho curto volta ao começo (portinhola, rampa, ponte consertada) |
| Profundidade | mais risco adiante, com chance de recuar antes de entrar |
| Continuidade | saída e chegada combinam em direção, piso e elevação |
| Colisão | toda passagem aparente é caminhável ou claramente bloqueada |
| Curiosidade | o que abre depois aparece antes: portão, ponte caída, outro lado do rio |

## 7. Medidas de partida (ajustar no playtest)

- Corredor mínimo: 2 células (Kael e o seguidor lado a lado). Caminho principal: 3 a 5.
- Parte de região: de 40×32 a 72×56 células (`REGIOES-E-PARTES.md`).
- Abertura × densidade: perto de 60% aberto e 40% denso em cada tela de jogo.
- Itens: pelo menos 3 por parte, pelo menos 1 escondido, todos alcançáveis.
- Zoom de exploração natural: 1.0.
