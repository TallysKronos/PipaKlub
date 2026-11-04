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
| Clareira do Papel · B os caminhos do riacho (`clareira-do-papel`) | Parque dos Ventos | `park-clearing` | 64×48 | 0–1 | OK |
| Jardim das Pipas · A chegada (`jardim-das-pipas`) | Parque dos Ventos | `park-trail` | 60×44 | 0–1 | OK |
| Morro do Sol · Escadaria da Sombra (`morro-escadaria-da-sombra`) | Morro do Sol | `morro-area-2` | 24×16 | 0–1 | OK |
| Morro do Sol · Laje dos Ventos (`morro-laje-dos-ventos`) | Morro do Sol | `morro-area-3` | 24×16 | 0–1 | OK |
| Morro do Sol · Mirante da Caixa-d’água (`morro-mirante-da-caixa-dagua`) | Morro do Sol | `morro-area-4` | 24×16 | 0–1 | OK |
| Morro do Sol · Parque dos Ventos (`morro-parque-dos-ventos`) | Morro do Sol | `morro-area-5` | 24×16 | 0–0 | OK |
| Morro do Sol · Praça da Chegada (`morro-praca-da-chegada`) | Morro do Sol | `morro` | 24×16 | 0–1 | OK |
| Rua dos Ventos (`rua-dos-ventos`) | Bairro (Rua dos Ventos) | `quintal` | 44×33 | 0–0 | OK |
| Veredas do Encanamento · C o pátio dos canos (`veredas-do-encanamento`) | Parque dos Ventos | `park-veredas` | 64×48 | 0–1 | OK |

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

Áreas: Clareira do Papel · B os caminhos do riacho · Jardim das Pipas · A chegada · Veredas do Encanamento · C o pátio dos canos

**Chão (tiles 64×32, 4 variações lisas cada):**
- `grama` — Grama · 3788 células
- `bosque` — Mata fechada (bloqueio) (bloqueio: precisa ler como "não dá para passar") · 3297 células
- `terra` — Terra (trilha) · 1252 células
- `piso` — Piso de pedra · 366 células
- `mato` — Mato alto (encontros) · 35 células
- `ponte` — Ponte · 30 células
- `agua` — Água (bloqueio: precisa ler como "não dá para passar") · 16 células

**Transições (autotile de cantos, 16 peças por par):**
- bosque / grama · 933 bordas
- grama / terra · 786 bordas
- grama / piso · 150 bordas
- piso / terra · 74 bordas
- bosque / terra · 55 bordas
- grama / mato · 36 bordas
- ponte / terra · 16 bordas
- bosque / piso · 12 bordas
- agua / grama · 11 bordas
- mato / terra · 10 bordas
- agua / terra · 9 bordas
- grama / ponte · 8 bordas
- agua / ponte · 8 bordas
- mato / piso · 2 bordas

**Barrancos e muros de contenção:**
- 1 nível · face sudeste · 190 faces
- 1 nível · face sudoeste · 220 faces
- cantos externo e interno para cada altura usada; topo casando com o chão do nível de cima

**Rampas / escadas:** v- ×18, u- ×15 (tampo inclinado + cunhas laterais; no Morro e no Bairro, desenhar como **escadaria** de concreto)
**Pontes:** 30 células de tabuleiro, nos dois eixos, com cabeceiras

**Peças (Iso Studio, grade comum):**
- arvore (b) ×375
- arvore (a) ×347
- poste ×8
- arvore (florida) ×7
- bau ×7
- flores ×7
- banco 2x1 ×4
- vaso ×4
- lixeira ×4
- placa-mapa 2x1 ×2
- biruta ×2
- coreto 4x4 ×1
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
- muro-quintal (v+) ×76
- muro-quintal (u+) ×54
- muro-quintal (v-) ×48
- casa-morro (telha) 3x3 ×30
- casa-morro (laje) 3x3 ×27
- casa-morro (muro-chapisco) 3x3 ×25
- muro-quintal (u-) ×25
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

### Clareira do Papel · B os caminhos do riacho — `clareira-do-papel.tmj`

- Cena do jogo: `park-clearing` · 64×48 células · níveis 0–1 · conferência OK
- Chão: grama 1468, bosque 1049, terra 428, piso 62, ponte 30, mato 19, agua 16
- Peças: arvore (a) ×120, arvore (b) ×126, arvore (florida) ×3, banco 2x1 ×2, poste ×4, placa-mapa 2x1 ×1, vaso ×2, lixeira ×2
- Eventos: saida: Voltar ao Jardim das Pipas → park-trail · saida: Além da cidade · Veredas do Encanamento → park-veredas · interacao: Placa: habitats e encontros · interacao: Descansar no largo · interacao: Descansar no banco leste · interacao: Mapa do Parque dos Ventos · item: Papel de preparação · escondido · item: Linha de preparação · brilho · item: Papel de preparação · visivel · interacao: Rastro junto ao riacho

- Referência para o conceito: abra no Mapa Studio e use **Baixar referência para o Codex**.

### Jardim das Pipas · A chegada — `jardim-das-pipas.tmj`

- Cena do jogo: `park-trail` · 60×44 células · níveis 0–1 · conferência OK
- Chão: bosque 1174, grama 1012, terra 381, piso 73
- Peças: coreto 4x4 ×1, arvore (a) ×108, arvore (b) ×115, arvore (florida) ×3, banco 2x1 ×2, poste ×4, placa-mapa 2x1 ×1, vaso ×2, lixeira ×2, bau ×2
- Eventos: saida: Voltar à Rua dos Ventos → quintal · saida: Seguir para a Clareira → park-clearing · npc: Sr. Assis · encontros selvagens · interacao: Descansar no largo · interacao: Descansar no banco leste · interacao: Mapa do Parque dos Ventos · npc: Nina · interacao: Vestígio na trilha · releitura após o resgate · item: Papel de preparação · escondido · item: Linha de preparação · visivel · item: Papel de preparação · brilho

- Referência para o conceito: abra no Mapa Studio e use **Baixar referência para o Codex**.

### Morro do Sol · Escadaria da Sombra — `morro-escadaria-da-sombra.tmj`

- Cena do jogo: `morro-area-2` · 24×16 células · níveis 0–1 · conferência OK
- Chão: construcao 302, calcada 82
- Peças: arvore-grande 2x2 ×1, varal 2x2 ×1, casa-morro (telha) 3x3 ×6, casa-morro (laje) 3x3 ×3, casa-morro (muro-chapisco) 3x3 ×9, muro-quintal (v+) ×14, muro-quintal (u+) ×12, muro-quintal (v-) ×10, muro-quintal (u-) ×5
- Eventos: saida: Voltar para a Praça da Chegada → morro · saida: Seguir para a Laje dos Ventos → morro-area-3 · npc: Encontro do bairro · interacao: Passagem para a próxima área
- Zoneamento visual (sem alterar colisões): não se aplica
- Portas vinculadas às fachadas: não se aplica
- Referência para o conceito: abra no Mapa Studio e use **Baixar referência para o Codex**.

### Morro do Sol · Laje dos Ventos — `morro-laje-dos-ventos.tmj`

- Cena do jogo: `morro-area-3` · 24×16 células · níveis 0–1 · conferência OK
- Chão: construcao 284, piso 100
- Peças: varal 2x2 ×1, banca-pipas 2x2 ×1, casa-morro (telha) 3x3 ×6, casa-morro (laje) 3x3 ×10, casa-morro (muro-chapisco) 3x3 ×2, muro-quintal (v+) ×18, muro-quintal (v-) ×10, muro-quintal (u+) ×12, muro-quintal (u-) ×4
- Eventos: saida: Voltar para a Escadaria da Sombra → morro-area-2 · saida: Seguir para o Mirante da Caixa-d’água → morro-area-4 · npc: Encontro do bairro · interacao: Passagem para a próxima área
- Zoneamento visual (sem alterar colisões): não se aplica
- Portas vinculadas às fachadas: não se aplica
- Referência para o conceito: abra no Mapa Studio e use **Baixar referência para o Codex**.

### Morro do Sol · Mirante da Caixa-d’água — `morro-mirante-da-caixa-dagua.tmj`

- Cena do jogo: `morro-area-4` · 24×16 células · níveis 0–1 · conferência OK
- Chão: construcao 308, calcada 76
- Peças: caixa-dagua 2x2 ×1, mirante-guarda-corpo 2x2 ×1, casa-morro (telha) 3x3 ×7, casa-morro (laje) 3x3 ×6, casa-morro (muro-chapisco) 3x3 ×6, muro-quintal (v+) ×16, muro-quintal (v-) ×10, muro-quintal (u+) ×11, muro-quintal (u-) ×5
- Eventos: saida: Voltar para a Laje dos Ventos → morro-area-3 · saida: Seguir para o Parque dos Ventos → morro-area-5 · npc: Encontro do bairro · interacao: Passagem para a próxima área
- Zoneamento visual (sem alterar colisões): não se aplica
- Portas vinculadas às fachadas: não se aplica
- Referência para o conceito: abra no Mapa Studio e use **Baixar referência para o Codex**.

### Morro do Sol · Parque dos Ventos — `morro-parque-dos-ventos.tmj`

- Cena do jogo: `morro-area-5` · 24×16 células · níveis 0–0 · conferência OK
- Chão: construcao 272, grama 112
- Peças: arvore-grande 2x2 ×1, toldo-bandeirolas 2x2 ×1, casa-morro (telha) 3x3 ×5, casa-morro (laje) 3x3 ×4, casa-morro (muro-chapisco) 3x3 ×4, muro-quintal (v+) ×11, muro-quintal (u+) ×13, muro-quintal (v-) ×8, muro-quintal (u-) ×5
- Eventos: saida: Voltar para o Mirante da Caixa-d’água → morro-area-4 · saida: Sair para a cidade → cidade · npc: Encontro do bairro · interacao: Passagem para a próxima área
- Zoneamento visual (sem alterar colisões): não se aplica
- Portas vinculadas às fachadas: não se aplica
- Referência para o conceito: abra no Mapa Studio e use **Baixar referência para o Codex**.

### Morro do Sol · Praça da Chegada — `morro-praca-da-chegada.tmj`

- Cena do jogo: `morro` · 24×16 células · níveis 0–1 · conferência OK
- Chão: construcao 267, calcada 117
- Peças: portao 4x1 ×1, mesa-artesao 2x2 ×1, arvore (tronco-largo) ×1, banca-pipas 2x2 ×1, caixa-dagua 2x2 ×1, casa-morro (telha) 3x3 ×6, casa-morro (laje) 3x3 ×4, casa-morro (muro-chapisco) 3x3 ×4, muro-quintal (v+) ×17, muro-quintal (u-) ×6, muro-quintal (v-) ×10, muro-quintal (u+) ×6
- Eventos: saida: Voltar à Rua dos Ventos → quintal · saida: Seguir para a Escadaria da Sombra → morro-area-2 · npc: Zeca · interacao: Oficina de pipas · interacao: Subir a escadaria
- Zoneamento visual (sem alterar colisões): não se aplica
- Portas vinculadas às fachadas: não se aplica
- Referência para o conceito: abra no Mapa Studio e use **Baixar referência para o Codex**.

### Rua dos Ventos — `rua-dos-ventos.tmj`

- Cena do jogo: `quintal` · 44×33 células · níveis 0–0 · conferência OK
- Chão: canteiro 847, calcada 349, asfalto 200, construcao 40, terra 16
- Peças: casa-kael 4x4 ×1, casa-assis 4x3 ×1, loja-pipas 4x3 ×1, mural ×1, bancada-rua ×1, banco ×3
- Eventos: saida: Casa de Kael → kael-home · saida: Casa do Sr. Assis → professor-home · saida: Loja de pipas → kite-shop · saida: Explorar a cidade → cidade · interacao: Mural · amigos · interacao: Mural · trocas · interacao: Seus parceiros · interacao: Parque dos Ventos · exploração
- Zoneamento visual (sem alterar colisões): Fundos residenciais (fundo-de-casa) · Quintal de Kael (quintal) · Quintal do Sr. Assis (quintal) · Jardim da loja (jardim) · Praça e serviços (praca) · Trilha para o parque (saida-parque)
- Portas vinculadas às fachadas: Casa de Kael: (7,10), frente v+ · Casa do Sr. Assis: (21,10), frente v+ · Loja de pipas: (35,10), frente v+
- Referência para o conceito: abra no Mapa Studio e use **Baixar referência para o Codex**.

### Veredas do Encanamento · C o pátio dos canos — `veredas-do-encanamento.tmj`

- Cena do jogo: `park-veredas` · 64×48 células · níveis 0–1 · conferência OK
- Chão: grama 1308, bosque 1074, terra 443, piso 231, mato 16
- Peças: arvore (b) ×134, bau ×5, placa-mapa ×1, biruta ×2, banco ×1, pipa-presa ×1, flores ×7, arvore (a) ×119, arvore (florida) ×1
- Eventos: saida: Voltar à Clareira do Papel → park-clearing · npc: Lacertubo · guardião dos canos · interacao: Banco do pátio · interacao: Sinais no bosque · interacao: Mapa das Veredas · interacao: Papel rasgado entre as folhas · interacao: Canos marcados · interacao: Rabiola do Carcará de Nina · npc: Nina · item: Papel de preparação · escondido · item: Linha de preparação · visivel · item: Papel de preparação · brilho · saida: Retorno curto ao Jardim · após a vitória → park-trail

- Referência para o conceito: abra no Mapa Studio e use **Baixar referência para o Codex**.

## Pendências conhecidas das plantas importadas

- **Morro do Sol (5 áreas):** as plantas já contêm casas, marcos e traçados distintos. A PIP-81 aproxima varal, guarda-corpo e árvore grande dos espaços que identificam; a campanha antiga ainda não foi substituída pela prévia PIP-88.
- **Rua dos Ventos:** o material `canteiro` continua bloqueado. A camada `zonas` diferencia quintais, jardim da loja, fundos, praça e trilha; coordenadas das portas estão nas propriedades das casas. A PIP-84 produz a arte desses espaços.
- **Escadas:** somente a fileira marcada como rampa sobe um nível; o corredor restante é acesso plano. Escadaria com desenvolvimento maior exige mudar planta, altura e navegação em conjunto, sem esticar só o desenho.
- Interiores (quarto, sala, ateliê, loja) seguem no Iso Studio e não entram aqui.
