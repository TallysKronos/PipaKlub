# Regiões de Kronasta: partes A, B e C

O primeiro jogo se passa na região de **Kronasta**. O mapa de Kronasta é a tela do mundo, no estilo da tela de mapa de Digimon World DS: a região inteira pintada, com cada lugar como um ícone ilustrado. Cada ícone leva a uma **região explorável**, como um bairro, o Parque dos Ventos ou as Ruínas.

## Regra principal [Decidido pelo criador]

**Toda região explorável tem pelo menos 3 partes: A, B e C.** Nenhuma região é um mapa único.

- Cada parte é um mapa próprio (`.tmj`). O jogador passa de A para B e de B para C por saídas.
- Uma região pode ter mais partes (D, E…). O mínimo é 3.
- Cada parte tem **itens espalhados** (seção 4).

Exemplo: o Parque dos Ventos não é um mapa só. O jogador entra no Parque A, segue para o Parque B e depois para o Parque C.

## 1. Papel de cada parte

| Parte | Papel | Bairro (trajetória 1) | Região natural ou das Ruínas (trajetória 2) |
| --- | --- | --- | --- |
| **A, a chegada** | Apresenta a região: o marco visual, o tom e o primeiro NPC. Tem saída para o mapa de Kronasta. | Entrada do bairro, a praça e os **capangas 1 e 2**. | Primeiros encontros leves e a primeira pista. |
| **B, o miolo** | Aprofunda: rotas alternativas, segredos, a maior parte dos encontros e um ponto de descanso. | **Capangas 3 e 4**, um descanso (banco, bica, lanchonete) e um segredo do bairro. | Desafio de travessia (relevo, água, mato alto), o segredo e a pista principal. |
| **C, o clímax** | Fecha a região: o confronto ou a revelação e a recompensa principal. | **Arena do campeão**, no ponto mais alto ou mais simbólico. | Chefe, guardião ou revelação da história, por exemplo o mural ou a câmara do ovo. |
| **D, E…** (opcionais) | Áreas secretas, atalhos, extensões que a história libera depois. | Quadra escondida, laje secreta. | Galerias que só abrem mais tarde. |

## 2. Ligações

- Ao entrar na região pelo mapa de Kronasta, o jogador sempre chega em **A**.
- Há saídas **A ↔ B ↔ C** nos dois sentidos.
- Depois de concluir C, abre um **atalho C → A** ou **C → mapa de Kronasta**, para a volta não ser repetitiva.
- Uma parte da trajetória 2 pode ficar trancada até um bairro ser vencido (`libera_apos`). Ela deve ser **vista** antes de ser liberada: portão, ponte caída, grade do Bando ou mato fechado.
- A saída entre partes fica numa borda clara: fim de trilha, portão, escadaria ou boca de caverna. Nunca no meio do mato.

## 3. Tamanho e ritmo

- Cada parte tem de **40×32 a 72×56 células**, e o limite técnico é 96×96 (`ESPECIFICACAO-MAPAS.md`).
- Atravessar uma parte pelo caminho principal leva de **1 a 3 minutos**. Explorar tudo, de 4 a 8 minutos.
- O relevo segue as regras contra o mapa chapado (seção 6): cada parte de região natural tem platôs e caminhos encaixados entre eles.

## 4. Itens espalhados

Itens entram na camada `eventos` com o tipo **`item`**:

| propriedade | valores | regra |
| --- | --- | --- |
| `item` | id do catálogo (ex.: `papel-seda`, `vareta-bambu`, `cola-reparo`, `rabiola-…`, `pista-caderno-heleana-3`) | Se precisar de um id novo, liste no relatório. Não invente efeitos. |
| `quantidade` | 1 ou mais | — |
| `visibilidade` | `visivel`, `brilho` (cintila no chão), `escondido` (atrás de peça, no fim de beco, no alto de platô) | — |
| `requer` | opcional: bairro, evento ou habilidade | Item atrás de portão da história |
| `trajetoria` | `1`, `2` ou `ambas` | Pistas da família e das Ruínas são `2` |

**Mínimo por parte:** 3 itens, sendo pelo menos 1 `escondido` fora do caminho principal. A parte C tem mais a recompensa principal da região. Todo item precisa ser alcançável a partir da `entrada`, e a conferência reprova os que não são.

**O que espalhar:**
- materiais do ateliê, como papel, vareta e linha;
- consumíveis, como a cola de reparo;
- moedas;
- rabiolas raras, poucas;
- pistas da trajetória 2, como fotos, páginas do caderno da Heleana e fragmentos de mural.

Os becos sem saída são o lugar natural dos itens escondidos.

## 5. Nomes e propriedades

- Áreas novas: id `<regiao>-a`, `<regiao>-b`, `<regiao>-c` (ex.: `bairro-feira-a`). O nome visível é "<Região> · <nome da parte>".
- Propriedades do mapa no Tiled, além das já usadas (`nome`, `regras`, `cena_jogo`, `bioma`):
  - `regiao`: id da região, igual nas três partes;
  - `parte`: `A`, `B`, `C`, `D`…;
  - `libera_apos`: opcional;
  - `trajetoria`.
- As áreas que já existem **mantêm o id** (renomear quebra saves) e recebem só `regiao` e `parte`:

| Região | Parte | Área existente |
| --- | --- | --- |
| Morro do Sol (bairro 1) | A | `morro-praca-da-chegada` |
| | B | `morro-escadaria-da-sombra` |
| | C | `morro-laje-dos-ventos` |
| | D | `morro-mirante-da-caixa-dagua` |
| | E | `morro-parque-dos-ventos` (duelo da Mikka) |
| Parque dos Ventos | A | `jardim-das-pipas` |
| | B | `clareira-do-papel` |
| | C | `veredas-do-encanamento` (Lacertubo e a porta das Ruínas) |
| Rua dos Ventos (casa do Kael) | — | `rua-dos-ventos`: área de partida, fora da regra |

O Morro do Sol é o bairro tutorial e tem 5 partes, com um capanga por parte e a Mikka na última. Nos outros bairros, o campeão fica na última parte da região: C, ou D e E quando houver.

A Rua dos Ventos é a única exceção: é o ponto de partida da casa do Kael e não é uma região do mapa de Kronasta. Se ela crescer, ganha A, B e C como as outras.

## 6. Regras contra o mapa chapado

Valem em toda parte, com as referências de Digimon World DS que o criador aprovou (Data Forest e Beast Farm):

1. **Platôs:** pelo menos 40% da área natural fica em nível 1 ou 2. Os caminhos passam entre os blocos.
2. **Paredão com volume:** face com veios verticais, borda de grama dobrando por cima e sombra de contato no chão de baixo. Use o kit `terrenos-v1`.
3. **Árvores em massa:** bosques de 3 a 7 copas sobrepostas e muralhas de mata nas bordas e no alto dos platôs. No máximo 1 ou 2 árvores soltas por tela, e cada uma com sombra.
4. **Chão vivo:** grama em 2 ou 3 tons, com manchas grandes e orgânicas, marcas de terra e tufos concentrados nas bordas.
5. **Trilhas orgânicas:** bordas arredondadas, que alargam nos cruzamentos. Nada de retângulo em degrau.
6. **Moldura:** as últimas 4 a 6 células de cada mapa são preenchimento (mata, paredão ou água). A câmera nunca mostra o vazio.
7. **Câmera:** o zoom padrão mostra bastante mundo, em torno de 1,0. A arte é pensada para essa distância.

## 7. Conferência

Somam-se às regras de `ESPECIFICACAO-MAPAS.md`, seção 5:

| regra | nível |
| --- | --- |
| Região com menos de 3 partes | ERRO |
| Parte sem saída para a anterior ou para a seguinte | ERRO |
| Parte com menos de 3 itens, ou sem item escondido | AVISO |
| Item inalcançável a partir da entrada | ERRO |
| Área natural com menos de 40% em platô | AVISO |
| Árvore solta (sem vizinha a até 1 célula) acima de 2 por tela | AVISO |

Essas verificações ainda **não estão no Mapa Studio**. Até entrarem, o criador de mapas confere à mão e registra no relatório.
