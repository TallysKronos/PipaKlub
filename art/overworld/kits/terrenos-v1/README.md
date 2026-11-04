# Biblioteca de pisos e paredes — Soulmonsters

36 materiais originais gerados e preparados em **1.512 peças modulares**. Esse número conta encaixes/recortes e variantes derivados das fontes, não 1.512 pinturas independentes.

| Família | Materiais | Peças por material | Total |
|---|---:|---:|---:|
| Pisos | 24 | 47 estados de borda/canto + 8 centros | 1.320 |
| Paredes | 12 | 8 faces/fases + 4 cantos + 4 terminações | 192 |

As famílias incluem gramados, terra, areia, cascalho, pedra, concreto, asfalto, bloquete, ladrilho, cerâmica, madeira e painéis de oficina/laboratório; paredes de reboco, tijolo, pedra, concreto, azulejo, madeira, painel técnico e barranco.

## Estudo que orientou o conjunto

A referência do usuário foi usada como **estrutura de encaixe**, sem copiar sua arte ou paleta. Um centro de preenchimento não recebe o contorno de uma ilha. Bordas abertas, cantos convexos, cantos côncavos, corredores e peças isoladas precisam de estados próprios.

- [Godot — Using TileSets](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html): atlas, terreno por cantos/lados e configuração isométrica.
- [Godot — TileSet](https://docs.godotengine.org/en/stable/classes/class_tileset.html): orientação Diamond Down e peering bits.
- [Tiled — Using Terrains](https://doc.mapeditor.org/en/stable/manual/terrain/): conjuntos de cantos/lados e conjunto misto reduzido de 47 peças.

Escolha técnica: blob de 47 estados para um material sobre ausência de terreno, em camada sobre um piso base. As diagonais só conectam quando ambos os lados adjacentes existem. Isso resolve junções de material; **não resolve alturas**. A sustentação de um patamar ou uma rampa continua vindo da geometria, conforme `documentation/continuidade-terreno-isometrico.md`.

## Arquivos

- `fontes/*.png`: pinturas originais; `fontes/geracao.json`: prompts, ferramenta e referências; `fontes/rascunhos`: versões substituídas.
- `superficies/*.png`: fontes periódicas 512×512 para UV contínuo.
- `pisos/<material>/blob-NNN.png`: máscaras isométricas 64×32, RGBA; fora do terreno há transparência, para mostrar o piso base.
- `pisos/<material>/centro-0..7.png`: losangos preenchidos, sem contorno de tile ou sombra pintada.
- `atlas/<material>.png`: 8 colunas, 7 linhas; os 47 estados ocupam linhas 0–5, os 8 centros a linha 6. A posição vazia final da linha 5 não é um tile.
- `paredes/<material>/`: faces U/V, cantos internos/externos e terminações com espessura. Altura física desenhada: 64 px; o PNG pode incluir a inclinação do topo e respiro.
- `library.json`: inventário, máscaras, atlas, fases, tamanhos e fontes.
- Runtime espelhado em `godot/assets/overworld/kits/terrenos-v1`.
- `godot/assets/overworld/kits/terrenos-v1/tilesets/*.tres`: **24 TileSets nativos**, prontos para atribuir a TileMapLayer.

## Usar no Godot

1. Atribua o `.tres` do material a uma `TileMapLayer`.
2. Use Terrains / Connect com terreno 0, conjunto 0. As relações de lados e cantos já estão gravadas. Não é preciso repintar os bits.
3. Coloque o piso base em uma camada inferior. O recorte do material superior mostra esse piso; os 47 estados não são uma transição pintada exclusivamente para grama/terra.
4. A galeria usa filtragem nearest na escala nativa para não introduzir frestas de filtragem. Para superfícies grandes com câmera em escala fracionária, prefira UV contínuo e revise a filtragem no mapa de destino.
5. Centros de pisos estruturados preservam a fase de juntas/tábuas; as alternativas têm variação discreta de material. Materiais naturais têm centros de textura mais variados com bordas compartilhadas.

Cada material tem seu próprio TileSet. Não misture os índices de terreno de arquivos diferentes num único Terrain Set sem definir as transições correspondentes. Use camadas separadas ou componha explicitamente um conjunto novo.

## Usar as paredes

Faces intermediárias não têm tampas verticais. Use `inicio` e `fim` apenas na terminação real do trecho. Cantos externos e internos têm projeções diferentes; não são o mesmo PNG renomeado. As fases 0–3 de cada face são **amostras consecutivas**, não alternativas aleatórias: respeite a ordem, ou use `superficies/` com UV contínuo na geometria do muro. A iluminação é aplicada por orientação da face.

As peças são uma biblioteca de revestimentos e exemplos geométricos. Não substituem o extrator de bordas/alturas do terreno. Não coloque uma face completa atravessando uma boca de rampa ou entre dois pisos da mesma altura. Colisão, navegação e ordenação de um mapa real ainda precisam de sua geometria compartilhada.

## Preparação e revisão

Arte criada com a ferramenta integrada `image_gen.imagegen`. Código posterior só faz normalização periódica, projeção UV, recorte por máscaras geométricas, variação discreta de material e empacotamento. Fontes preservadas. Dez materiais foram refeitos para eliminar contaminação da referência de pedra em cerâmicas, reboco e laboratório.

Gerar novamente: `python tools/overworld/build_terrain_library.py`. Depois importe o projeto no Godot e execute `godot --path godot --script res://tools/terrain_library_preview.gd` para exportar os TileSets e capturar a galeria. O script encerra ao terminar.

Revisão em `documentation/overworld/terrenos-v1`: mosaicos 8×8, recortes em L/vazados, 47 estados, faces longas, cantos e terminações. Há 36 capturas nativas 1280×720 e relatórios de preparação. Nenhuma suíte de testes foi executada; houve conferência geométrica, importação e revisão visual nativa.

**Ainda não aplicado nos mapas da campanha.** Aprovação artística final pendente do usuário. Não há alteração de colisão, salvamento, progressão ou mapas existentes.
