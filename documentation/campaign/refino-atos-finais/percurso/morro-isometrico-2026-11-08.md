# Morro do Sol no modelo isométrico (08/11/2026)

Até aqui o Morro do Sol (bairro 1, ato 1) era o único bairro com mapa pintado:
- 5 imagens de 1536×1024 vistas de cima (`godot/assets/campaign/morro/*.png`);
- colisão em retângulos;
- uma tela própria (`morro_view.gd`).

Por decisão do dono, o Morro foi refeito no mesmo sistema isométrico dos outros bairros.

## Áreas

Gerador: `tools/gerar-mapas-morro.py`. Compilação: `node tools/compilar-mapas.mjs kronasta-morro-a … kronasta-morro-e`.

| Cena de jogo | Mapa | Área | Rival | O que tem |
| --- | --- | --- | --- | --- |
| `morro` | `kronasta-morro-a` | Praça da Chegada | Zeca (morro-1) | Praça, oficina de pipas, patamar das casas, escadaria em dois lances |
| `morro-area-2` | `kronasta-morro-b` | Escadaria da Sombra | Bia (morro-2) | Becos, escadaria longa, a árvore da sombra |
| `morro-area-3` | `kronasta-morro-c` | Laje dos Ventos | Juninho e Lia (morro-3) | Laje grande, varais, laje alta com biruta |
| `morro-area-4` | `kronasta-morro-d` | Mirante da Caixa-d'água | Tião (morro-4) | Mirante, caixa-d'água no alto |
| `morro-area-5` | `kronasta-morro-e` | Praça da Campeã | Mikka (morro-5) | Gramado redondo com o ringue, coreto, saída para a cidade |

Casas do Morro: alvenaria pintada (rosa, creme, amarela, azul, verde), telhado de barro em
duas águas e caixa-d'água azul em metade delas (`district_architecture.gd`, estilo `morro`).
O calçamento é o de pedra clara do Centro.

## O que não mudou

- As cenas continuam `morro` e `morro-area-2…5`. Desafios, estrelas, recompensas, título e
  defesa de título usam as mesmas regras (`morro.gd`, `morro_rules.gd`, `district_rules.gd`).
- A batalha do Morro (`morro_battle_view.gd`) é a mesma.
- A subida para a próxima área só abre depois de vencer o desafio da área: o evento de saída
  tem `morroGate` e `park_checkpoint.gd` responde `morro_gate`.

## Integração

- `park_checkpoint.gd`: as 5 cenas entram em `MAPS`. Saves do mapa pintado (pixels, sem
  `space`) migram: perto do rival vão para o rival, senão para a chegada da área.
- `morro.gd`: `near_rival` aceita o mapa novo (células) e o antigo (pixels). A luta guarda o
  espaço do mapa e volta para ele.
- `front_end.gd`: o Morro abre pela mesma tela dos bairros (`_show_park`). O rival (evento
  `morroDuel`) chama `_morro_duel`.
- As entradas a partir da Rua dos Ventos já chegam na chegada da Praça.
- `morro_view.gd` e `assets/campaign/morro/maps.json` ficam no repositório. Testes antigos
  usam o mapa pintado, e ele também serve de referência e de miniatura do save.

Teste: `godot/tests/morro_iso_checks.gd` percorre as 5 áreas. Para cada uma confere:
- chegada, caminho até o rival e até a subida;
- portão fechado antes do desafio e aberto depois;
- luta e volta ao mapa;
- migração de saves antigos;
- saída final para a Rua dos Ventos.

## Versão 2 · mapas maiores e com mais andares (10/11/2026)

A pedido do dono, as cinco áreas foram refeitas em **64×56** (antes 48×40) e com **5 a 7
níveis** de terraços (antes 3). O gerador é o mesmo (`tools/gerar-mapas-morro.py`), agora com
um tileset de alturas próprio (níveis 0–7).

| Área | Níveis | Estrutura | Para explorar |
| --- | --- | --- | --- |
| A · Praça da Chegada | 5 | Praça, patamar das casas, dois terraços laterais que se reencontram na laje do meio, largo da caixa-d'água | Quintal escondido no meio, mirantes oeste e leste, beco da entrada |
| B · Escadaria da Sombra | 6 | Escadaria central longa com um patamar por nível | Subida leste alternativa, mirante oeste com o altar das pipas perdidas, viela das lavadeiras |
| C · Laje dos Ventos | 6 | Ziguezague: cada laje sobe pela ponta oposta da anterior | Atalho pelo meio, duas lajes altas do leste até a Laje do Vento |
| D · Mirante da Caixa-d'água | 7 | Zigurate: as subidas alternam entre o centro e as pontas | Plataforma da caixa-d'água no topo, mirantes oeste (luneta) e leste |
| E · Praça da Campeã | 5 | Escadaria larga em três lances até a arena de vinte fileiras | Dois jardins laterais, arquibancada com o mural dos campeões |

Cada área tem moradores com falas (Dora, Cauê, Celina, Nilo, Iara), placas de história, um
banco de descanso (recupera a equipe) e de 4 a 5 achados, a maioria em pontos sem saída.

Limite técnico: as escadas sobem só para o fundo da tela (v−), porque é a única direção que o
desenho de degraus cobre hoje. As rotas laterais são feitas deslocando as escadas de um nível
para o outro. Escadas laterais (u−) pedem mudança em três pontos do renderizador.

## Versão 3 · água, profundidade e assimetria (11/11/2026)

Crítica do dono à versão 2: faltava profundidade em alguns lugares, faltava cachoeira, havia
poucas áreas sem saída e os mapas estavam simétricos demais. O que mudou:

- **Córrego do Sol.** Cada área tem água: nascentes e tanques nos terraços altos, poços
  rebaixados com margem (a água fica um nível abaixo do chão, como pede
  `documentation/continuidade-terreno-isometrico.md`) e cachoeiras nas bordas.
- **Grotas.** Cortes até a cota 0 ao lado dos terraços, por onde a água desce. As quedas têm
  2 (A), 3 (B), 4 (C), 6 (D) e 1 (E) níveis.
- **Assimetria.** Nenhuma área é espelhada: em A o caminho sobe pelo leste e o oeste é um
  ramo sem saída de dois níveis; em B a grota fica a oeste e a rota alternativa a leste; em C
  a grota corta a laje grande e uma pinguela alta liga as metades; em D o leste virou um
  paredão; em E a arquibancada só sobe pelo oeste.
- **Sem saída.** De 3 a 5 por área (mirantes, quintais, lajes, poços), cada um com um achado
  ou uma placa.

No renderizador: `forest.stream` desenha água nas células de água sem os efeitos do porto;
`forest.waterFalls` e `forest.lavaFalls` desenham as quedas (`forest_structures.gd`,
`_falls`). O morro inteiro subiu um nível para a água caber na cota 0.
