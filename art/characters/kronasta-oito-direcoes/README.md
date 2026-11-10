# Sprites direcionais de Kronasta

As folhas têm oito células em duas linhas. A primeira segue S, SO, O e NO. A segunda segue N, NE, L e SE. Bambuzal, Beira-Canal, Feira e Cais usam células de 64 × 64 px e preservam a vista sudeste original. Centro, Lajes, Porto, Serra e Mirante usam células de 64 × 96 px com oito vistas redesenhadas a partir do sprite original, mantendo a altura visível e o apoio dos pés.

| Local | NPCs | Prévia |
|---|---:|---|
| Bambuzal | 5 | [Oito vistas](bambuzal/previa.png) |
| Beira-Canal | 5 | [Oito vistas](beira-canal/previa.png) |
| Feira | 6 | [Oito vistas](feira/previa.png) |
| Cais | 5 | [Oito vistas](cais/previa.png) |
| Centro | 6 | [Oito vistas](centro/previa.png) |
| Lajes | 5 | [Oito vistas](lajes/previa.png) |
| Porto | 5 | [Oito vistas](porto/previa.png) |
| Serra | 5 | [Oito vistas](serra/previa.png) |
| Mirante | 5 | [Oito vistas](mirante/previa.png) |
| Cenas especiais | 5 | [Oito vistas](cenas-especiais/previa.png) |

Os PNGs de origem ficam em `fontes/` dentro de cada pasta. No Godot, os sprites direcionais ficam em `godot/assets/npc-ds/<kit>/direcoes/`. O atlas compartilhado do Bambuzal e do Beira-Canal aponta para a folha de cada personagem. Nos demais bairros, a associação usa o mesmo nome do PNG individual.

Ao abrir a interação, o jogo calcula a direção de Kael no espaço projetado do mapa e seleciona a vista correspondente. `legacy_district_cast_review.gd` exercita os oito ângulos nos duelos dos primeiros bairros. `overworld_cast_review.gd` cobre o diálogo de Seu Lalau e os 26 NPCs de Centro, Lajes, Porto, Serra e Mirante em seus eventos de origem.

O lote de cenas especiais usa células de 64 × 96 px. Dona Cida, o produtor da Pipa TV, o guarda-parque Dito e o atendente do Estádio se viram ao interagir. Faye usa uma vista da folha nova no lobby e na arquibancada, conforme a montagem do elenco de cada rodada.
