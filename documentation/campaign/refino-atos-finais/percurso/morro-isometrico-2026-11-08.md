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
