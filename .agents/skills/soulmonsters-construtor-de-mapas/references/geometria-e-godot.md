# Geometria, estruturas e montagem no Godot

## 1. Grade, projeção e cotas

- Célula isométrica 64×32. `u` desce para a direita da tela, `v` desce para a esquerda.
- Tela: `x = (u − v)·32`, `y = (u + v)·16 − h·64`. **1 nível = 64 px** de parede.
- A câmera vê as faces `+u` (frente-direita) e `+v` (frente-esquerda). As faces `−u` e `−v` ficam de
  costas e não são desenhadas.
- Uma linha de visão anda `(+1, +1)` em planta e sobe `+0,5` nível por passo. Tudo o que fica nessa
  linha cai no mesmo pixel. É essa conta que decide o que esconde o quê; faça a conta antes de
  posicionar rampa, mureta ou árvore junto de desnível.
- Dados por célula (`godot/assets/overworld/maps/<area>.json`): `material`, `level`, e nas rampas
  `ramp` (`u+`, `u-`, `v+`, `v-`), `rampFrom`, `rampTo`. Altura num ponto: `map_model.gd`
  `surface_height` / `height_at`. Desenho, movimento e clique usam essa mesma altura.

## 2. Platôs e barrancos

Regras de forma:
- Decida a cota em **blocos de 2×2 células**, com contorno quase retangular (superelipse de expoente
  ~3 e ruído baixo). O barranco corre em trechos longos nos eixos `u` e `v`. Borda diagonal célula a
  célula vira ameia: refaça a forma.
- O caminho corta o platô em bloco inteiro (se uma célula do bloco é trilha, o bloco fica no chão).
  Assim a margem entre trilha e paredão sobra como faixa de grama, e o paredão não serrilha.
- Sem degrau solto: célula elevada precisa de pelo menos 2 vizinhas na mesma cota; platô de 1 célula
  vira chão. Nível 2 só em cima de nível 1.
- Bolsão caminhável sem acesso a partir da entrada vira mata ou paredão. Nada de plataforma solta.

Regras de acabamento (sempre as três juntas):
1. **Face:** só nas bordas expostas (`+u`/`+v` da célula mais alta), com a diferença real de cota,
   não até zero. Textura com estratos horizontais, UV contínuo por posição e altura (sem esticar uma
   imagem por célula). Face `+u` mais clara, face `+v` mais escura, pé da face escurecido.
2. **Borda de topo:** grama que dobra por cima da face, com recorte irregular de 4 a 11 px e uma linha
   de luz fina no alto.
3. **Sombra de contato:** faixa escura no chão de baixo, de ~0,5 célula, que esmaece. Desenhada logo
   depois desse chão na ordenação.

Cantos: topo, face e base compartilham os mesmos vértices. Canto interno e externo fecham sem buraco,
sem faixa dupla e sem linha terminando no vazio. Faces conectadas na mesma faixa de cota usam o mesmo
acabamento (`view.gd` `_wall_finishes`): um canto não alterna pedra e reboco.

## 3. Rampas (regra descoberta na prova do Bosque dos Ventos)

- **Toda rampa sobe para o fundo: `u-` ou `v-`.** Com rampa de 2 células (`rampa_comprimento` 2,
  inclinação 0,5 nível por célula), a rampa `u+`/`v+` tem a mesma inclinação da linha de visão: vira
  uma linha e some atrás do patamar. Com 1 célula ela fica de costas para a câmera. Recorte no platô não
  resolve.
- Logo, o acesso a um platô fica na **face da frente** dele (`+u` ou `+v`), e o ramal chega por baixo,
  subindo em direção ao fundo. Planeje a posição dos platôs pensando nisso: platô colado na moldura do
  sul ou do leste não tem face da frente livre.
- Pé da rampa em terra na mesma cota baixa, sem peça nem evento; chegada com 2 células de topo livre.
  Rampa com 2 células de largura no caminho principal.
- A face do barranco é recortada na boca. As laterais da rampa são cunhas que vão a zero no pé,
  ordenadas junto com os barrancos (não na camada de decalques).
- No chão, a rampa é terra inteira (máscara sem desfoque) e recebe tom de inclinação: mais clara
  quando sobe para o fundo.

## 4. Escadas

- Use quando o desnível não cabe em rampa ou quando o lugar pede construção (morro, bairro, Ruínas).
  `view.gd` já desenha escadas de pedra (`_draw_stone_stairs`: oito pisos e espelhos para 64 px, quatro
  direções, laterais junto ao terreno). Parametrize; não reinvente.
- Espelhos todos iguais (`Δh/N`), pisos todos iguais (`L/N`). O último espelho encontra o patamar
  superior sem piso duplicado. Mesma regra de direção visível das rampas: confira na captura que os
  degraus aparecem.
- Escada de mão (madeira vertical em barranco) é outro tipo de ligação, com movimento próprio. Se o
  mapa precisar, descreva o pedido de mecânica no relatório antes de desenhar.

## 5. Muretas e muros

Três tipos, com contratos diferentes:

| Tipo | Onde | Contrato |
| --- | --- | --- |
| **Muro de arrimo** | barranco revestido em área construída (morro, bairro, Ruínas) | é a **face** do barranco com outro acabamento (chapisco, bloco, pedra; `wallSurfaces` do kit). Mesma geometria do barranco, mesma ordenação, cantos com as peças de canto interno/externo do kit (`kits/morro/muros/chapisco-*`) |
| **Mureta de borda (guarda-corpo)** | topo de laje, mirante, calçada alta, ponte: queda junto de área de uso | peça baixa (≈ 0,25 nível, 16 px) sobre a **aresta exposta** da célula alta, ordenada com a face dessa aresta. Contínua; abre só em boca de rampa, escada, ponte ou portão. Ponta com arremate. Não é necessária em barranco natural de mata |
| **Mureta livre / muro de divisa** | lote, quintal, canteiro, recinto | sequência de peças que bloqueiam (`bloqueia`, pegada correta), com peça de canto e de ponta. Nada de vão de 1 célula que pareça passagem; portão é peça explícita |

Regras comuns:
- Altura constante ao longo do trecho; acompanha a cota do chão onde se apoia.
- Nunca atravessa boca de rampa, cabeceira de ponte, porta ou saída.
- Se o pé de um muro some atrás de um piso mais alto à frente, a junta precisa fechar na captura
  ampliada; não cubra com arbusto.
- Mureta de borda não substitui o bloqueio: quem bloqueia é o desnível. Ela explica visualmente por que
  não se pula.

## 6. Pontes, água e poços

- Ponte: caminho, cabeceira e tabuleiro separados; madeira atravessa o vão e apoia em terra firme nas
  duas pontas; sombra acompanha a altura; atravessa sem degrau visual.
- Margem natural assimétrica e curva. Reta só em estrutura construída.
- Cachoeira exige poço rebaixado de verdade (recorte do piso, faces até a cota da água, impacto na
  água). Use `godot/scripts/overworld/cave_basin.gd` e as cotas medidas de `AGENTS.md`.

## 7. Profundidade e oclusão

- Tudo o que tem volume entra no nó ordenado por Y (`view.actors`). Na prova da floresta: cada célula
  de chão é um nó no vértice de cima `((u−v)·32, (u+v)·16 + 2)` e carrega as faces das suas arestas
  `+u`/`+v`; a sombra de base é um nó próprio logo depois do chão de baixo. Ator fica na projeção do
  chão sem altura; a arte sobe `h·64` (`view.gd` `_place_actor`).
- Platô na frente cobre o que está atrás dele, inclusive o Kael. Confira os dois sentidos.
- **Copa de árvore** sobe ~4 fileiras de tela acima do tronco e cobre o que fica atrás (`u−k`, `v−k`).
  Árvore até 2 fileiras atrás de chão caminhável vira arbusto; até 4, árvore baixa. Copas grandes que
  ainda cobrem o caminho entram em `view.occluders` e ficam transparentes sobre o Kael (a caixa usa a
  escala e o espelhamento do sprite).
- Peças grandes ordenam pelo canto da frente da pegada (`_place_actor` já compensa).

## 8. Vegetação e chão

- Mata em massa: moldura de 4 a 7 células com borda ruidosa, mais um anel de árvores além do limite do
  mapa (prova: 9 células), sem tapar as saídas.
- Chão por máscaras em baixa resolução, suavizadas: terra, mata (sombra sob copas), manchas e mato. O
  shader mistura dois verdes e a terra com borda orgânica (`godot/shaders/kronasta_ground.gdshader`).
  A textura usa a posição de tela, contínua entre células.
- Tufos de capim concentrados nas bordas de mata e trilha; raros no meio do gramado.

## 9. Arquivos e comandos

| O quê | Onde |
| --- | --- |
| Gerador da planta | `tools/mapa-studio/desenhar-<area>.mjs` (modelo: `desenhar-kronasta-bosque.mjs`) |
| Planta Tiled | `art/overworld/mapas/<area>.tmj` (tileset `art/overworld/tiles/rascunho.tsj`) |
| Conferência | `tools/mapa-studio/model.mjs`: `parseTiled`, `audit`, `verdict`, `reachable`, `canStep` |
| Compilação | `compile(raw, id)` de `tools/import-overworld.mjs` → `godot/assets/overworld/maps/<area>.json`; registrar em `maps/index.json` |
| Construtor do bioma | `godot/scripts/overworld/<bioma>.gd`, chamado por `view.gd` `load_area` (modelo: `kronasta_forest.gd`) |
| Modelo de movimento | `godot/scripts/overworld/map_model.gd` |
| Captura | `godot/tools/<area>_capture.gd` (modelo: `kronasta_bosque_capture.gd`, com `--out=` e `look`) |

- **Não rode `build()`** de `tools/import-overworld.mjs` à toa: ele reescreve todos os `kit.json`.
  Se rodar, reverta o que mudou em áreas que você não tocou.
- Godot 4.x, captura sem tela: `xvfb-run -a -s "-screen 0 1280x720x24" <godot> --path godot
  --rendering-driver opengl3 -s tools/<area>_capture.gd -- --out=<pasta>`. Use `timeout` e faça o
  script sair com erro quando a cena não monta; erro de parse deixa o Godot parado.
- Modo geométrico: o construtor lê uma variável de ambiente (a prova usa `KRONASTA_GEOMETRIA=1`) e troca
  a arte por cores chapadas. Todo construtor novo precisa desse modo.
- GDScript: tipe as variáveis quando o valor vem de `Dictionary`/`Array` (`var c: Vector2i = ...`);
  `:=` com valor sem tipo não compila.
- Testes: `godot/tests/overworld_checks.gd`, `godot/tests/morro_map_checks.gd`,
  `node --test tools/mapa-studio/model.test.mjs`. Testes de Godot reescrevem capturas e relatórios
  versionados (`documentation/overworld/reports/`, `mockups/`): reverta antes do commit.
