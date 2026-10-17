# Prompts e direção final

Modo utilizado: ferramenta integrada **image_gen**, com `transparent_background: true`. Não foi usado CLI/API próprio nem chave de API. Imagens de referência foram as próprias artes recém-geradas. Os arquivos foram copiados para o workspace sem alterar os pixels.

## Sr. Assis — poses

Use case: stylized-concept. Production sprite sheet for PipaKlub. Wide 1536x1024 transparent PNG, regular 4 columns by 2 rows, 8 equal cells. One full-body depiction of the same original Brazilian male professor aged 45 per cell. Clean-shaven, no beard/mustache; short black hair with white/gray temple streaks; brown eyes; aviator goggles on forehead; open white lab coat with clipped ID badge, blue polo, brown trousers and brown practical shoes. Consistent slight three-quarter orientation, scale and clothing. Style midway between polished 2D JRPG illustration and modern hi-bit pixel art: crisp stepped edges, dark navy outlines, clustered three-tone shading, no blur, gradients or 3D. Row1: neutral, wave, explain with open palm, point. Row2: hold kite string coil and point, think hand by chin, thumbs up, celebrate. No text, labels, scenery, grid or existing franchise characters.

## Sr. Assis — expressões

Identity-preserving expression atlas using the poses sheet as reference. Transparent 1536x1024, 4x2 grid, eight isolated heads with small neck only, no shoulders/hands. Same identity, age, gray temples, forehead goggles, orientation, hairstyle and rendering style. Row1: friendly neutral, speaking smile, closed-eye laugh, thoughtful eyebrow. Row2: surprised, worried, determined, proud wink. Change only expression, keeping head silhouette and scale as consistent as possible. No text/grid/background.

## Nozinho — desenho e animações

Original small floating spiritual kite-string creature, one chunky ivory/golden braided overhand knot, compact kite-like body, tiny rope loops, two short knotted arms and two frayed tail strings. Small teal spirit face in the knot, expressive amber eyes. No clothes/weapons; no existing franchise resemblance. Same 2D/hi-bit pixel-art hybrid as professor reference. Transparent square 4x4 atlas, sixteen frames, consistent identity and size. Row1 four-frame idle hover/blink; row2 four-frame greeting; row3 concentrate, charge, outward string snap, settle; row4 hurt, recover, closed-eye joy, open-eye joy. No labels/grid/scenery.

Ajuste final com a folha inicial como referência: preserve exact creature and all16poses/order; shrink every creature and effects to70% of current size within its own equal tile; center consistently and leave at least40px empty alpha padding to each tile edge, especially extended arms in row3; no crossing between cells or added characters. Requested canvas1536x1536; actual returned PNG1254x1254, recorded in atlas.

## Pipas almáticas — quatro criaturas

Original living spirit-kite creature atlas using professor only as rendering-style reference. Transparent square4x4 atlas; each row a distinct creature and four idle-hover/blink frames. Row1 Carcará: orange terracotta diamond kite, falcon eyes/beak, folded feather-wings, cream seam, orange knotted ribbon tail. Row2 Mata Verde: green leaf-manta diamond kite, visible leaf veins, centered cheerful face, leafy fins and cord tail with leaf tassel, no legs. Row3 Azulão: blue/cream rounded diamond shield kite of cloudlike paper panels, gentle eyes, side fins and blue braided tail with cloud tassel. Row4 Raio de Sol: golden yellow diamond lantern kite, amber eyes, folded zigzag side ribbons and two yellow tassel tails. Clear kite geometry, dark navy pixel-cluster contours, three-tone flat shading, no 3D or existing franchise likeness. One complete creature per tile, same size and central position within each row.

Ajuste final com a folha inicial como referência: preserve exact identities/colors and sixteen frames; scale each sprite including wings and full tails to75% inside its own cell; leave36px fully transparent padding on every side; four equal rows/columns, no labels or sprite overlap. Requested canvas1536x1536; actual returned PNG1254x1254, recorded in atlas.
