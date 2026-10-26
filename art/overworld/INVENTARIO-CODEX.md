# Inventário para o Codex — mapas do overworld

Gerado por `node tools/mapa-studio/inventario.mjs` a partir das plantas em `art/overworld/mapas/`. Não edite à mão: ajuste as plantas no Tiled e rode de novo.
Regras de desenho, grade (64×32, 1 nível = 64 px de parede) e pedidos A (conceito) e B (kit) em [ESPECIFICACAO-MAPAS.md](ESPECIFICACAO-MAPAS.md). Estilo geral: anime 2D, contorno firme, cor em massas, a mesma luz alto-esquerda em todas as áreas.

## Como usar

1. **Kit do bioma primeiro** (seção por bioma abaixo): chão, transições, barrancos, rampas/escadas, pontes e peças. As peças vêm do Iso Studio na grade comum, para que árvore, banco e poste tenham a mesma escala em todas as áreas.
2. **Conceito de cada área** sobre a referência exportada pelo Mapa Studio (`<area>-referencia.png`), usando só peças do kit.
3. Uma peça que aparece em mais de um bioma (banco, poste, árvore, placa) é **desenhada uma vez** e recebe só variação de cor/material quando o bioma pedir.

## Resumo das áreas

| Área | Bioma | Cena do jogo | Tamanho | Níveis | Conferência |
| --- | --- | --- | --- | --- | --- |
| Parque dos Ventos · Clareira do Papel (`clareira-do-papel`) | Parque dos Ventos | `park-clearing` | 24×16 | 0–0 | OK |
| Parque dos Ventos · Jardim das Pipas (`jardim-das-pipas`) | Parque dos Ventos | `park-trail` | 24×16 | 0–0 | OK |
| Morro do Sol · Escadaria da Sombra (`morro-escadaria-da-sombra`) | Morro do Sol | `morro-area-2` | 24×16 | 0–1 | OK |
| Morro do Sol · Laje dos Ventos (`morro-laje-dos-ventos`) | Morro do Sol | `morro-area-3` | 24×16 | 0–1 | OK |
| Morro do Sol · Mirante da Caixa-d’água (`morro-mirante-da-caixa-dagua`) | Morro do Sol | `morro-area-4` | 24×16 | 0–1 | OK |
| Morro do Sol · Parque dos Ventos (`morro-parque-dos-ventos`) | Morro do Sol | `morro-area-5` | 24×16 | 0–0 | OK |
| Morro do Sol · Praça da Chegada (`morro-praca-da-chegada`) | Morro do Sol | `morro` | 24×16 | 0–1 | OK |
| Rua dos Ventos (`rua-dos-ventos`) | Bairro (Rua dos Ventos) | `quintal` | 44×33 | 0–0 | OK |
| Veredas do Encanamento (`veredas-do-encanamento`) | Veredas do Encanamento | `park-veredas` | 50×32 | 0–1 | OK |

## Bioma: Bairro (Rua dos Ventos)

Áreas: Rua dos Ventos

**Chão (tiles 64×32, 4 variações lisas cada):**
- `canteiro` — Canteiro / gramado (bloqueio) (bloqueio: precisa ler como "não dá para passar") · 847 células
- `calcada` — Calçada · 349 células
- `asfalto` — Asfalto · 200 células
- `construcao` — Construção / muro (bloqueio) (bloqueio: precisa ler como "não dá para passar") · 40 células
- `terra` — Terra (trilha) · 16 células

**Transições (autotile de cantos, 16 peças por par):**
- calcada / canteiro · 97 bordas
- asfalto / calcada · 80 bordas
- canteiro / construcao · 34 bordas
- canteiro / terra · 11 bordas
- calcada / construcao · 10 bordas
- asfalto / canteiro · 10 bordas
- calcada / terra · 5 bordas

**Barrancos e muros de contenção:**
- nenhum

**Rampas / escadas:** nenhuma
**Pontes:** nenhuma

**Peças (Iso Studio, grade comum):**
- banco ×3
- casa-kael 4x4 ×1
- casa-assis 4x3 ×1
- loja-pipas 4x3 ×1
- mural ×1
- bancada-rua ×1

## Bioma: Parque dos Ventos

Áreas: Parque dos Ventos · Clareira do Papel · Parque dos Ventos · Jardim das Pipas

**Chão (tiles 64×32, 4 variações lisas cada):**
- `grama` — Grama · 284 células
- `bosque` — Mata fechada (bloqueio) (bloqueio: precisa ler como "não dá para passar") · 240 células
- `terra` — Terra (trilha) · 162 células
- `mato` — Mato alto (encontros) · 56 células
- `piso` — Piso de pedra · 26 células

**Transições (autotile de cantos, 16 peças por par):**
- bosque / grama · 130 bordas
- grama / terra · 112 bordas
- grama / mato · 58 bordas
- grama / piso · 18 bordas
- mato / terra · 18 bordas
- piso / terra · 10 bordas
- bosque / terra · 6 bordas
- mato / piso · 4 bordas

**Barrancos e muros de contenção:**
- nenhum

**Rampas / escadas:** nenhuma
**Pontes:** nenhuma

**Peças (Iso Studio, grade comum):**
- arvore (b) ×28
- arvore (a) ×12
- poste ×8
- arvore (florida) ×4
- banco 2x1 ×4
- vaso ×4
- lixeira ×4
- placa-mapa 2x1 ×2
- coreto 4x4 ×1

## Bioma: Veredas do Encanamento

Áreas: Veredas do Encanamento

**Chão (tiles 64×32, 4 variações lisas cada):**
- `bosque` — Mata fechada (bloqueio) (bloqueio: precisa ler como "não dá para passar") · 676 células
- `grama` — Grama · 493 células
- `terra` — Terra (trilha) · 241 células
- `mato` — Mato alto (encontros) · 78 células
- `piso` — Piso de pedra · 63 células
- `agua` — Água (bloqueio: precisa ler como "não dá para passar") · 37 células
- `ponte` — Ponte · 12 células

**Transições (autotile de cantos, 16 peças por par):**
- grama / terra · 186 bordas
- bosque / grama · 165 bordas
- grama / mato · 72 bordas
- bosque / piso · 29 bordas
- agua / grama · 28 bordas
- bosque / terra · 18 bordas
- agua / ponte · 12 bordas
- grama / piso · 9 bordas
- grama / ponte · 8 bordas
- piso / terra · 5 bordas
- agua / bosque · 4 bordas
- mato / terra · 3 bordas
- mato / piso · 3 bordas

**Barrancos e muros de contenção:**
- 1 nível · face sudeste · 23 faces
- 1 nível · face sudoeste · 41 faces
- cantos externo e interno para cada altura usada; topo casando com o chão do nível de cima

**Rampas / escadas:** v- ×9 (tampo inclinado + cunhas laterais; no Morro e no Bairro, desenhar como **escadaria** de concreto)
**Pontes:** 12 células de tabuleiro, nos dois eixos, com cabeceiras

**Peças (Iso Studio, grade comum):**
- arvore (b) ×16
- flores ×7
- bau ×5
- biruta ×2
- placa-mapa ×1
- banco ×1
- pipa-presa ×1

## Bioma: Morro do Sol

Áreas: Morro do Sol · Escadaria da Sombra · Morro do Sol · Laje dos Ventos · Morro do Sol · Mirante da Caixa-d’água · Morro do Sol · Parque dos Ventos · Morro do Sol · Praça da Chegada

**Chão (tiles 64×32, 4 variações lisas cada):**
- `construcao` — Construção / muro (bloqueio) (bloqueio: precisa ler como "não dá para passar") · 1433 células
- `calcada` — Calçada · 275 células
- `grama` — Grama · 112 células
- `piso` — Piso de pedra · 100 células

**Transições (autotile de cantos, 16 peças por par):**
- calcada / construcao · 193 bordas
- construcao / piso · 64 bordas
- construcao / grama · 57 bordas

**Barrancos e muros de contenção:**
- 1 nível · face sudeste · 29 faces
- 1 nível · face sudoeste · 87 faces
- cantos externo e interno para cada altura usada; topo casando com o chão do nível de cima

**Rampas / escadas:** v- ×9 (tampo inclinado + cunhas laterais; no Morro e no Bairro, desenhar como **escadaria** de concreto)
**Pontes:** nenhuma

**Peças (Iso Studio, grade comum):**
- casa-morro (telha) 3x3 ×16
- casa-morro (laje) 3x3 ×13
- casa-morro (muro-chapisco) 3x3 ×11
- arvore-grande 2x2 ×2
- varal 2x2 ×2
- banca-pipas 2x2 ×2
- caixa-dagua 2x2 ×2
- mirante-guarda-corpo 2x2 ×1
- toldo-bandeirolas 2x2 ×1
- portao 4x1 ×1
- mesa-artesao 2x2 ×1
- arvore (tronco-largo) ×1

## Por área

### Parque dos Ventos · Clareira do Papel — `clareira-do-papel.tmj`

- Cena do jogo: `park-clearing` · 24×16 células · níveis 0–0 · conferência OK
- Chão: grama 148, bosque 120, terra 72, mato 31, piso 13
- Peças: arvore (a) ×6, arvore (b) ×13, arvore (florida) ×2, banco 2x1 ×2, poste ×4, placa-mapa 2x1 ×1, vaso ×2, lixeira ×2
- Eventos: saida: Voltar ao Jardim das Pipas → park-trail · saida: Além da cidade · Veredas do Encanamento → park-veredas · interacao: Placa: habitats e encontros · interacao: Descansar no largo · interacao: Descansar no banco leste · interacao: Mapa do Parque dos Ventos
- Referência para o conceito: abra no Mapa Studio e use **Baixar referência para o Codex**.

### Parque dos Ventos · Jardim das Pipas — `jardim-das-pipas.tmj`

- Cena do jogo: `park-trail` · 24×16 células · níveis 0–0 · conferência OK
- Chão: grama 136, bosque 120, terra 90, mato 25, piso 13
- Peças: coreto 4x4 ×1, arvore (a) ×6, arvore (b) ×15, arvore (florida) ×2, banco 2x1 ×2, poste ×4, placa-mapa 2x1 ×1, vaso ×2, lixeira ×2
- Eventos: saida: Voltar à Rua dos Ventos → quintal · saida: Seguir para a Clareira → park-clearing · npc: Sr. Assis · encontros selvagens · interacao: Descansar no largo · interacao: Descansar no banco leste · interacao: Mapa do Parque dos Ventos
- Referência para o conceito: abra no Mapa Studio e use **Baixar referência para o Codex**.

### Morro do Sol · Escadaria da Sombra — `morro-escadaria-da-sombra.tmj`

- Cena do jogo: `morro-area-2` · 24×16 células · níveis 0–1 · conferência OK
- Chão: construcao 302, calcada 82
- Peças: arvore-grande 2x2 ×1, varal 2x2 ×1, casa-morro (telha) 3x3 ×3, casa-morro (laje) 3x3 ×3, casa-morro (muro-chapisco) 3x3 ×2
- Eventos: saida: Voltar para a Praça da Chegada → morro · saida: Seguir para a Laje dos Ventos → morro-area-3 · npc: Encontro do bairro · interacao: Passagem para a próxima área
- Referência para o conceito: abra no Mapa Studio e use **Baixar referência para o Codex**.

### Morro do Sol · Laje dos Ventos — `morro-laje-dos-ventos.tmj`

- Cena do jogo: `morro-area-3` · 24×16 células · níveis 0–1 · conferência OK
- Chão: construcao 284, piso 100
- Peças: varal 2x2 ×1, banca-pipas 2x2 ×1, casa-morro (telha) 3x3 ×3, casa-morro (laje) 3x3 ×2, casa-morro (muro-chapisco) 3x3 ×2
- Eventos: saida: Voltar para a Escadaria da Sombra → morro-area-2 · saida: Seguir para o Mirante da Caixa-d’água → morro-area-4 · npc: Encontro do bairro · interacao: Passagem para a próxima área
- Referência para o conceito: abra no Mapa Studio e use **Baixar referência para o Codex**.

### Morro do Sol · Mirante da Caixa-d’água — `morro-mirante-da-caixa-dagua.tmj`

- Cena do jogo: `morro-area-4` · 24×16 células · níveis 0–1 · conferência OK
- Chão: construcao 308, calcada 76
- Peças: caixa-dagua 2x2 ×1, mirante-guarda-corpo 2x2 ×1, casa-morro (telha) 3x3 ×3, casa-morro (laje) 3x3 ×2, casa-morro (muro-chapisco) 3x3 ×2
- Eventos: saida: Voltar para a Laje dos Ventos → morro-area-3 · saida: Seguir para o Parque dos Ventos → morro-area-5 · npc: Encontro do bairro · interacao: Passagem para a próxima área
- Referência para o conceito: abra no Mapa Studio e use **Baixar referência para o Codex**.

### Morro do Sol · Parque dos Ventos — `morro-parque-dos-ventos.tmj`

- Cena do jogo: `morro-area-5` · 24×16 células · níveis 0–0 · conferência OK
- Chão: construcao 272, grama 112
- Peças: arvore-grande 2x2 ×1, toldo-bandeirolas 2x2 ×1, casa-morro (telha) 3x3 ×3, casa-morro (laje) 3x3 ×3, casa-morro (muro-chapisco) 3x3 ×2
- Eventos: saida: Voltar para o Mirante da Caixa-d’água → morro-area-4 · saida: Sair para a cidade → cidade · npc: Encontro do bairro · interacao: Passagem para a próxima área
- Referência para o conceito: abra no Mapa Studio e use **Baixar referência para o Codex**.

### Morro do Sol · Praça da Chegada — `morro-praca-da-chegada.tmj`

- Cena do jogo: `morro` · 24×16 células · níveis 0–1 · conferência OK
- Chão: construcao 267, calcada 117
- Peças: portao 4x1 ×1, mesa-artesao 2x2 ×1, arvore (tronco-largo) ×1, banca-pipas 2x2 ×1, caixa-dagua 2x2 ×1, casa-morro (telha) 3x3 ×4, casa-morro (laje) 3x3 ×3, casa-morro (muro-chapisco) 3x3 ×3
- Eventos: saida: Voltar à Rua dos Ventos → quintal · saida: Seguir para a Escadaria da Sombra → morro-area-2 · npc: Zeca · interacao: Oficina de pipas · interacao: Subir a escadaria
- Referência para o conceito: abra no Mapa Studio e use **Baixar referência para o Codex**.

### Rua dos Ventos — `rua-dos-ventos.tmj`

- Cena do jogo: `quintal` · 44×33 células · níveis 0–0 · conferência OK
- Chão: canteiro 847, calcada 349, asfalto 200, construcao 40, terra 16
- Peças: casa-kael 4x4 ×1, casa-assis 4x3 ×1, loja-pipas 4x3 ×1, mural ×1, bancada-rua ×1, banco ×3
- Eventos: saida: Casa de Kael → kael-home · saida: Casa do Sr. Assis → professor-home · saida: Loja de pipas → kite-shop · saida: Explorar a cidade → cidade · interacao: Mural · amigos · interacao: Mural · trocas · interacao: Seus parceiros · interacao: Parque dos Ventos · exploração
- Referência para o conceito: abra no Mapa Studio e use **Baixar referência para o Codex**.

### Veredas do Encanamento — `veredas-do-encanamento.tmj`

- Cena do jogo: `park-veredas` · 50×32 células · níveis 0–1 · conferência OK
- Chão: bosque 676, grama 493, terra 241, mato 78, piso 63, agua 37, ponte 12
- Peças: arvore (b) ×16, bau ×5, placa-mapa ×1, biruta ×2, banco ×1, pipa-presa ×1, flores ×7
- Eventos: saida: Voltar à Clareira do Papel → park-clearing · npc: Lacertubo · guardião dos canos · interacao: Banco do pátio · interacao: Sinais no bosque · interacao: Mapa das Veredas · interacao: Papel rasgado entre as folhas · interacao: Canos marcados · interacao: Rabiola do Carcará de Nina · npc: Nina
- Referência para o conceito: abra no Mapa Studio e use **Baixar referência para o Codex**.

## Pendências conhecidas das plantas importadas

- **Morro do Sol (5 áreas):** no jogo atual o Morro é um corredor andável sobre uma ilustração pintada. A planta traz só o chão andável, a encosta (nível 1) e o resto como `construcao`. Antes do conceito, **vestir a planta** no Tiled com as peças do bairro (casas, lajes, muros, escadarias, caixa-d'água, varais, postes) usando a arte pintada atual como referência de conteúdo.
- **Rua dos Ventos:** gramados fora da calçada estão como `canteiro` (bloqueio). Decidir quais viram quintal, muro ou jardim.
- **Escadas:** a planta marca só a última fileira como rampa; o resto é o caminho de acesso. No jogo a subida é gradual.
- Interiores (quarto, sala, ateliê, loja) seguem no Iso Studio e não entram aqui.
