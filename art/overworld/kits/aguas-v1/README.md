# Águas vivas — biblioteca v1

Biblioteca visual para Soulmonsters, em isometria 64×32. Altura de um nível: 64 px. As pinturas foram geradas com IA e depois normalizadas, projetadas e articuladas por shaders. Os mapas da campanha não foram alterados.

## Conteúdo

- 6 materiais de piso: lago claro, lago profundo, rio claro, rio escuro, corredeira e água de brejo.
- 47 recortes de margem por material: centros, bordas, cantos externos/internos, passagens estreitas e junções. São **282 projeções de 6 pinturas**, não 282 pinturas independentes.
- 2 pinturas de queda: cortina suave e forte.
- 4 efeitos com alpha real: espuma de lábio, respingo de base, anel de ondulação e redemoinho.
- 6 TileSets, 6 ShaderMaterials e 16 cenas reutilizáveis: 6 corpos de água, curva e bifurcação, 4 cachoeiras U/V de um/dois níveis, 4 efeitos.
- Fontes, prompts e metadados preservados em `fontes/`. `library.json` descreve os arquivos e o ciclo.

## Usar no Godot

Abra uma cena em `godot/scenes/overworld/water/` e instancie no cenário. Os scripts são `@tool`: a água aparece também no editor. Após mudar propriedades, use o botão **Atualizar água/cachoeira/efeito** no Inspector.

Para desenhar um formato livre, use um TileMapLayer com `assets/overworld/kits/aguas-v1/tilesets/<material>.tres` e atribua ao campo **Material** o `materials/<material>.tres` correspondente. Pinte com o terreno de lados e cantos. O TileSet mostra uma versão estática colorida mesmo sem shader; atribuir o material ativa o movimento. Não misture os atlas de 47 células com os antigos atlas de 55 células.

O material compartilha a fase no espaço do mundo, evitando um reinício da textura a cada tile. O atlas `masks/shore-atlas.png` é uma máscara técnica: R identifica apenas a espuma das margens; A delimita a área molhada. A máscara fica parada enquanto a pintura se move por dentro. Não exiba esse atlas como arte de piso.

### Parâmetros

`water_id`: pintura do piso. `layout`: lago, rio reto, curva, bifurcação ou retângulo aberto. `patch_size`: tamanho da área em células. Os modelos de rio/curva usam uma largura padrão de três células numa área 8×8; para outras larguras ou formas, pinte seu TileMapLayer.

`flow_direction`: velocidade e direção em UV da pintura. `(0,0)` produz ondulação sem transporte; `(0,1)` segue V+; `(1,0)` segue U+; valores negativos invertem a corrente; `(0,2)` acelera a corredeira. A corrente é um efeito visual uniforme por trecho, sem simulação hidráulica de curva/bifurcação. Separe os trechos caso queira controlar suas direções individualmente.

`preview_time=-1` usa o tempo do shader. `set_animation_time(segundos)` permite congelar ou dirigir todos os materiais com o relógio do jogo, inclusive durante pausa. As prévias usam ciclo de quatro segundos e deslocamentos inteiros para fechar o loop. As cenas usam materiais próprios, permitindo relógios e direções diferentes por instância.

### Encaixar uma cachoeira

A origem de `water_patch.gd` é o **centro da célula (0,0)**, compensando o deslocamento interno do TileMap isométrico. U=(32,16), V=(-32,16). O formato `rectangle` usa centros completos até a aresta, apropriado para a saída aberta sobre uma queda; os demais formatos recuam a margem para deixar a transição com o terreno.

Na cachoeira a origem é o primeiro ponto do lábio. A face V percorre `(32,16)` por célula; a U percorre `(-32,16)`. A base está exatamente `drop_levels*64` px abaixo de cada ponto do lábio. Não escale a altura da queda para disfarçar um desnível incorreto: configure `drop_levels`.

Exemplo da galeria: platô 4×4 centrado na célula (0,0). Um canal 2×4 em V recebe offset `(32,16)`; seu lábio começa em `(-96,64)`, tem largura de duas células e usa face V. Um canal 4×2 em U recebe offset `(-32,16)`; o lábio começa em `(96,64)` e usa face U. São as mesmas posições das capturas. O poço inferior fica antes das paredes na ordem de desenho; o canal acima delas; a cortina e os emissores por último. Espuma é efeito separado, não tampa para esconder erro de geometria.

As quatro cenas de cachoeira contêm a cortina e os dois efeitos. O terreno, o canal de cima, o poço e as colisões pertencem ao mapa que receber a peça. A galeria mostra os encaixes com o kit `terrenos-v1`, que já existe neste repositório. O ZIP de água não duplica essa biblioteca de terreno.

## Revisão visual e animação

`documentation/overworld/aguas-v1/` contém catálogo, quatro capturas nativas 1280×720, detalhes das quedas, duas animações em GIF/WebP e relatórios de preparação/loop. As capturas foram feitas no Godot, com relógio fixado a 12 amostras/s; o movimento em execução usa a taxa normal do renderer. Não são GIFs de uma ilustração conceito.

Para regenerar as pinturas normalizadas e os recortes: `python tools/overworld/build_water_library.py`. Em seguida importe o projeto e execute `godot --path godot --script res://tools/water_library_preview.gd`. Para deixar a galeria em movimento use `-- --live` ou `-- --live-falls`; feche a janela para sair. Esse fluxo não carrega campanha, conta, inventário nem saves.

A revisão cobre os materiais, encaixes e renderização da galeria. Colisões, bloqueio da margem, nado, travessia, áudio e aplicação aos mapas não fazem parte desta entrega. Nenhuma suíte de testes de gameplay foi executada.

## Fontes técnicas consultadas

- [Godot — CanvasItem shaders, UV e TIME](https://docs.godotengine.org/en/latest/tutorials/shaders/shader_reference/canvas_item_shader.html)
- [Godot — CanvasItem e repetição de textura](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html)
- [Godot — criação de TileSets e terrenos](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html)
- [Tiled — conjuntos de terreno, cantos e lados](https://doc.mapeditor.org/en/stable/manual/terrain/)
