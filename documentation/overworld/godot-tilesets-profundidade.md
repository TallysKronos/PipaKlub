# TileSets do Godot e profundidade nos mapas

Estudo de *Using TileSets* e *Using TileMaps* (docs.godotengine.org, versão stable) e das referências das classes `TileSet`, `TileData` e `TileMapLayer`, lidos a partir da fonte oficial (`godotengine/godot-docs`). Este documento cruza o que a engine oferece com a forma como montamos os mapas hoje.

## 1. O que a documentação diz

### TileSet

- `tile_shape = TILE_SHAPE_ISOMETRIC`: losango. A referência avisa: *"Isometric TileSet works best if all sibling TileMapLayers and their parent inheriting from Node2D have Y-sort enabled."*
- `tile_layout = TILE_LAYOUT_DIAMOND_DOWN`: o eixo horizontal desce para a direita e o vertical desce para a esquerda. É o nosso `u`/`v`.
- `tile_size` é o losango lógico (64×32). A textura do tile (`texture_region_size`) pode ser **maior** que o losango. É assim que um tile ganha altura: parede, barranco ou árvore ocupam 64×96 ou mais, e apenas a base fica na célula.
- `uv_clipping` impede o tile de desenhar fora da própria região do atlas. `use_texture_padding` adiciona 1 px transparente em volta para evitar sangramento com filtro.
- Um TileSet aceita **atlas** (imagens) e **coleções de cenas** (nós inteiros como tile). As cenas custam mais: a documentação recomenda usá-las só quando necessário.

### Propriedades por tile (`TileData`)

| Propriedade | O que faz | Por que importa para a profundidade |
| --- | --- | --- |
| `texture_origin` | desloca o ponto onde o tile é desenhado | sobe a arte alta (parede, copa) a partir da base da célula |
| `y_sort_origin` | ponto vertical usado na ordenação por Y | define a linha do "pé" do tile, onde ele passa a ficar na frente do Kael |
| `z_index` | ordem relativa dentro da camada | camadas fixas por cima ou por baixo (sombra no chão, telhado) |
| `modulate`, `material` | cor e shader por tile | sombreamento, variação, água animada |
| `flip_h`, `flip_v`, `transpose` | espelha e gira | uma face serve para os dois lados (`u` e `v`) |
| `probability` | peso no sorteio entre variantes | quebra a repetição do chão |
| `terrain_set`, `terrain` e peering bits | participação no autotile | transições pintadas na arte, não calculadas |

### Camadas (`TileMapLayer`)

- **Uma camada guarda um tile por célula.** Para sobrepor (chão + detalhe + parede + objeto) são necessárias várias camadas. A documentação recomenda separar fundo e frente.
- `y_sort_enabled` (do CanvasItem) mais `y_sort_origin` da camada: *"This Y-sort origin value is added to each tile's Y-sort origin value. This allows, for example, to fake a different height level."* Cada nível de altura vira uma camada com `y_sort_origin = nível × 64`.
- `x_draw_order_reversed` inverte a ordem no eixo X quando a ordenação por Y está ligada. Serve para tiles que se sobrepõem lateralmente.
- `rendering_quadrant_size` agrupa tiles em lotes para desenhar mais rápido, mas é ignorado em camada com ordenação por Y, que agrupa por linha.
- A navegação embutida no TileMap é limitada. A documentação recomenda gerar uma `NavigationRegion2D` e avisa que malhas de navegação 2D não podem ser empilhadas. Nosso AStar próprio, ligado ao modelo da planta, continua sendo o caminho certo.

### Terrenos (autotile)

- Terrenos ficam dentro de conjuntos de terreno. O modo do conjunto define o que precisa casar:
  - **Match Corners and Sides**: 8 vizinhos, equivale ao bitmask 3×3 (blob de 47 encaixes);
  - **Match Corners**: 4 cantos, equivale ao 2×2 (16 encaixes por par de materiais);
  - **Match Sides**: só os lados.
- Cada tile declara o terreno do centro e um **peering bit** por vizinho. O valor `-1` quer dizer "vazio".
- O mesmo tile pode ter terrenos diferentes nos cantos. Isso permite **transições entre terrenos** (grama → terra, por exemplo) desenhadas na própria arte.
- Modos de pintura: **Connect** liga ao que já está em volta; **Path** liga só ao traço atual, o que permite duas estradas vizinhas sem se fundirem.
- Por código, a camada oferece `set_cells_terrain_connect` e `set_cells_terrain_path`. São as mesmas regras, e o importador pode usá-las.

### Outros recursos úteis

- **Tiles alternativos**: o mesmo desenho com outra cor, outro material, `z_index` ou `y_sort_origin`, sem duplicar a imagem.
- **Espalhamento** (*scattering*) e **padrões** (*patterns*): detalhe que não se repete (tufos, pedrinhas) e conjuntos prontos (uma escada inteira, um muro com mureta).
- **Camadas de dados**: dados de jogo por tile (`encontro`, `som_de_passo`, `bloqueia`).

## 2. De onde vem a profundidade

1. **Altura de verdade na planta.** Um mapa sem desnível fica plano, por melhor que seja a arte. A profundidade começa no level design: patamares, barrancos, degraus, o chão de baixo aparecendo por trás.
2. **Tiles mais altos que o losango.** A face do barranco, a mureta e o tronco são arte vertical, ancorada na base com `texture_origin` e ordenada pelo pé com `y_sort_origin`. Hoje desenhamos essas faces como polígonos com textura esticada.
3. **Ordenação por Y em todas as camadas irmãs** (aviso da referência). Assim o Kael passa atrás da copa e na frente do tronco sem código especial.
4. **Uma camada por nível**, com `y_sort_origin` do nível. O que está no patamar de cima ordena como alto.
5. **Transições pintadas pelo autotile.** A borda grama/terra desenhada à mão em 47 ou 16 encaixes lê como relevo (rebordo, sombra na beira). Uma mistura por shader lê como mancha.
6. **Luz constante**: face sudeste clara, face sudoeste escura, topo mais claro que a face, sombra de contato no pé de tudo, chão de baixo um pouco mais escuro. Isso não vem da engine: vem da arte e do kit.

## 3. Como estamos hoje (`godot/scripts/overworld/view.gd`)

| Ponto | Hoje | Consequência |
| --- | --- | --- |
| Chão | um nó por célula (Polygon2D ou Sprite2D com shader de mistura) | sem autotile real; a transição é uma mancha; milhares de nós por área |
| `TileMapLayer` | criada por nível, mas só usada no modo rascunho | nenhuma das propriedades acima é aproveitada |
| Barranco e muro | polígono por face, com textura via UV | sem espessura, sem rebordo no topo, sem canto pintado; quando a textura estica, aparece a "caixa de papelão" |
| Ordenação | `y_sort_enabled` no nó pai e cálculo manual por objeto (`_place_actor`, `sort_point`, desvanecer quem cobre o Kael) | funciona, mas cada caso novo exige código |
| Desnível | Morro e Veredas têm nível 1; **Parque, Jardim e Clareira são planos** | a falta de profundidade mais visível |
| Biblioteca `terrenos-v1` | 24 pisos com blob de 47 encaixes, 12 paredes com faces, cantos e terminações, marcada `campaignIntegrated: false` | a arte certa para fazer isso pelo Godot já existe e não está ligada |

## 4. Proposta

1. **Planta com relevo no Parque.**
   - Jardim: coreto num terraço meio nível acima, com escadaria curta.
   - Clareira: elevação suave com mirante no fundo.
   - Veredas: um segundo patamar e a cachoeira descendo o barranco.
2. **TileSet gerado pelo importador** (`tools/import-overworld.mjs` → `godot/assets/overworld/tilesets/<bioma>.tres`):
   - atlas de piso de `terrenos-v1` com um conjunto de terreno em Match Corners and Sides (máscara de 47 já catalogada);
   - kits de bioma com 16 encaixes por par em Match Corners;
   - atlas de face de barranco e parede com `texture_origin` = altura da face e `y_sort_origin` = pé;
   - cantos externo e interno e terminações como tiles próprios;
   - variantes com `probability` para quebrar repetição.
3. **Camadas por área**, todas com ordenação por Y:
   - `Chao_N0`: piso no nível 0, pintado com `set_cells_terrain_connect`;
   - `Detalhe_N0`: tufos e pedrinhas por espalhamento, `z_index` baixo;
   - `Barranco`: faces e cantos;
   - `Chao_N1` e `Detalhe_N1`: o mesmo no nível 1, com `y_sort_origin = 64`;
   - `Objetos`: coleção de cenas para árvores, bancos, baús e NPCs, com o pé em `y_sort_origin`.
4. **A planta e o modelo continuam mandando** na navegação, nos eventos e na colisão. O TileSet só desenha. O teste `overworld_checks.gd` passa a verificar também que cada célula andável tem tile de chão e que cada desnível tem face e canto.
5. **Prova pequena antes de tudo:** o `veredas-piloto` (ponte, rampa e mirante) refeito assim, comparado lado a lado com a versão atual e em captura ampliada nas bocas de rampa e nos cantos, como pede o `AGENTS.md`.
