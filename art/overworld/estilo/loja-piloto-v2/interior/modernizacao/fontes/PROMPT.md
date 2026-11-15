# Geração do estudo moderno

Ferramenta integrada ImageGen, com fundo transparente. A imagem gerada foi copiada para estudo-imagegen.png.

Entradas na ordem:

1. interior/remapeamento/blockout.png para câmera, volumes e distribuição.
2. interior/quadro-chave.png para conteúdo da loja.
3. art/professor-laboratorio-v2/interior/quadro-chave.png para materiais e identidade moderna.

Prompt integral:

```text
Use case: sketch-to-render. Create the finished PIXEL ART key frame of the Linha & Papel shop interior for the modern Brazilian fantasy game Soulmonsters / PipaKlub.
INPUT 1 is the APPROVED GEOMETRY BLOCKOUT: preserve its exact orthographic 2:1 isometric camera, room footprint, silhouette, furniture positions, heights and parallelism. All edges along u have screen rise/run +0.5, along v -0.5, verticals vertical. Remove ALL labels, letters, guide grid, Kael character, route guide line and captions. Retain the same empty room and seven furniture zones.
INPUT 2 is the PREVIOUS SHOP CONTENT reference, not its erroneous perspective: preserve the shop functions and identity, spools and reels, folded colored kite papers, kites, trading cards, two community tables with seating, wide windows, three kite wall displays, a glass front entrance.
INPUT 3 is the APPROVED LABORATORY STYLE reference: clean modern technology, teal and cream, orange accent, silver structure, actual crisp cel shaded pixel art. Same world.
Render the BLOCKOUT in final modern shop materials. A and B are sleek modular silver/cream shelving with charcoal supports, glass retaining lips, thin teal shelf edges, clearly separated large reels, papers and sealed kite-making materials. Shelves stay against the same back wall and ALL shelf tiers precisely parallel to the back wall on the 2:1 grid. C is a tall sleek glass-backed display of colorful physical diamond kites, same footprint. D is a low glass-topped island display of kite-making supplies, silver base, dark inset teal doors. E is modern service counter with angled compact POS touch screen, clear display glass and accessible open space behind it. F and G are TWO modern community tables, each with a dark navy inset digital play mat, subtle turquoise luminous boundaries, physical colorful trading cards and compact side benches, in the exact positions of the two approved table blocks. Add two broad windows on the back and left walls, views of green outside. Three tasteful physical framed kite emblems on the back wall. Glass double entrance in the cutaway FRONT LEFT wall at the marked entrance position, slim teal/silver posts, recessed dark doormat. Both front walls remain cut away for visibility.
Palette cream wall panels, muted teal accent wall, slate/navy equipment bases, light brushed silver, pale blue gray large floor tiles, small coral/orange details and colorful products. Readable clustered pixels, crisp stepped 1px dark colored outlines, 2-3 cel tones per material, top left light, no blur, no gradients, no painterly texture, no dithering. Technology is integrated into tangible everyday retail fixtures. No people, no robots, no floating screens, no science fiction tanks, no extra rooms, no inaccessible secret machinery, no signage text.
Full isolated cutaway room on a TRULY TRANSPARENT background, fully contained with generous margins, exact 2:1 camera, no cropping. Match the blockout proportions over the previous shop image. Target native room width 1024 pixels, wall height150px, adult human scale70px. All furniture parallel to the grid. Make an elegant cohesive finished environment.
```

A base foi normalizada para largura visível de 1024 px, canvas 1120 × 820, alpha binário e paleta mestra mais extensão, com nearest-neighbor. Removeram-se componentes externos à silhueta principal. O Aseprite recebeu a base RGB e uma camada de acabamento do símbolo do terminal. O arquivo editável contém essas duas camadas.
