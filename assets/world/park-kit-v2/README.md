# Parque dos Ventos — kit visual v2

Gerado com o **image_gen integrado**, em 21/10/2026. Originais preservados; os recortes são coordenadas do atlas, sem pintura, remoção de fundo ou reamostragem dos arquivos.

- `concept-v2.png`: direção visual do jardim completo; referência de composição, não é um fundo aplicado ao jogo.
- `park-atlas-v2.png`: RGBA 1536×1024. Árvore completa com pipa, árvore florida completa, gazebo e capim alto.
- `terrain-v2.png`: quatro materiais 768×512, repetidos pelo renderizador: gramado suave, terra, pedra clara e calçamento.
- `manifest.json`: recortes, apoios e registro das duas folhas. Só o parque usa as substituições de terreno; Morro e Rua mantêm seus kits.

## Montagem e edição

`assets/world/park-v1/park-trail.tmj` e `park-clearing.tmj` contêm os pisos, colisões, habitats, interações e transições no contrato Tiled existente. Os arquivos `.art.json` associam peças do kit aos objetos e às decorações. `scripts/build-park-content.mjs` gera ambos; não o execute sobre edições manuais sem revisar o diff.

O contrato atual do jogo usa camadas retangulares do Tiled e um atlas renderizado em tempo de jogo; ainda não importa camadas nativas de tile GID. Portanto, abrir somente o `.tmj` no Tiled mostra a geometria, e não toda a composição visual do atlas. A auditoria visual deve ser feita na prévia do jogo. Este trabalho mantém esse pipeline e não introduz um importador novo.

Árvores usam uma única peça inteira e um apoio nos pés. A colisão é apenas no tronco, com a copa ordenada em profundidade junto ao personagem. Não se deve voltar a compor estas árvores com os antigos sprites separados `trunk` e `canopy`.

Os encontros agora acontecem nos habitats visuais de capim alto. Gramado baixo e caminhos permitem circulação sem encontros. A regra de servidor, recompensas e limite de níveis não mudou.

## Prompts finais

### Composição

Create polished environment concept art for a Brazilian neighborhood creature collecting 2D chibi RPG, Parque dos Ventos. Landscape 3:2 composition, orthographic three quarter top down RPG view, no perspective horizon, no UI, no labels, no people. Match warm hand-painted crisp cartoon game environment: cream stone paths, terracotta tile gazebo, saturated leafy green foliage, golden sunlight from upper left, dark warm outlines like a cozy Brazilian hillside RPG. Entire playable map: entrance bottom left with short stone pillars and wooden gate, broad winding warm dirt path up toward the right exit, small welcoming rest plaza with terracotta roof gazebo upper left, wooden benches and small kite workshop sign, dense natural groupings of WHOLE trees with trunks visibly and physically attached to crowns, pink flowers. Clearly distinct patches of lush tall grass for random encounters on right and upper half, accessible off the safe path. Cohesive landscaping, irregular stone borders, leaf litter, rocks. Open central paths for walking, no giant empty lawn and no rows of identical trees. A tiny colorful paper kite caught in one tree. This is visual direction for a modular Tiled map to be built afterward, not a screenshot or collage. Make the complete area legible and beautiful, densely detailed at borders while keeping playable routes clear.

### Peças transparentes

Production game sprite atlas, transparent background, landscape 3:2 canvas divided into a STRICT invisible 2 by 2 uniform grid with wide empty transparent margins between four fully separate assets. No text, no frames, no ground tiles, no other pieces. Warm hand painted outlined 2D chibi Brazilian RPG environment, orthographic three quarter top-down view, sunlight upper left, cream/terracotta/leaf green palette. TOP LEFT CELL: ONE COMPLETE beautiful broad leafy tree, a single connected tree silhouette from leafy crown to visible branching brown trunk to roots, crown visibly connects to trunk, golden-green highlights, small colored paper kite caught in foliage. BOTTOM LEFT CELL: ONE COMPLETE alternate rounded pink flowering tree with green foliage, connected substantial trunk and roots, same scale and viewing angle. TOP RIGHT CELL: ONE COMPLETE small neighborhood park gazebo, warm terracotta tile roof, four wood posts, cream stone raised base with ONE shallow step at front, no people or furniture, entire silhouette fully visible. BOTTOM RIGHT CELL: ONE low organic cluster of tall lush grass with two tiny flowers and leaf tufts, a habitat patch with irregular edges, no visible dirt square. All four assets entirely inside their own cell and never overlap neighboring cell. Complete trees MUST include both canopy and trunk together, not separate component sprites. No baked rectangular background, genuine alpha transparency, subtle small contact shadow only. Clean game-ready silhouette, richly drawn but readable at small size.

### Terreno

Production environment terrain texture atlas for cozy hand-painted 2D Brazilian chibi RPG. Landscape 1536x1024 style 3:2, strict 2x2 equal quadrant grid, no gaps or frames or text. Each quadrant a fully filled flat top-down tileable material swatch, no objects, no perspective, no vignette, no gradients, no borders. TOP LEFT: soft low contrast warm sage green short lawn grass, mostly broad calm painted color shapes and very sparse tiny blades, NOT dense tiny repeated tuft pattern. TOP RIGHT: warm pale golden beige compacted dirt with subtle worn texture, just a few small pebbles, broad calm surfaces. BOTTOM LEFT: cream limestone plaza paving irregular medium sized rounded stone slabs with subtle warm seams, entirely covers quadrant. BOTTOM RIGHT: warm gray beige small rounded stone edging paving texture entirely covers quadrant. Painterly crisp cartoon matching Brazilian sunny hillside RPG, restrained surface detail to support vibrant trees and tiny characters, no flowers, no bushes, no trees. All four swatches should repeat without a dark seam. Even gentle lighting identical from edge to edge.
