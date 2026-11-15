# Prompt da folha de itens

Ferramenta integrada ImageGen, geração nova com fundo transparente.

```text
Create a production game UI inventory icon sheet for Soulmonsters / PipaKlub, a modern Brazilian fantasy world with advanced everyday technology and physical kite crafting. Exactly SIX isolated colorful inventory objects in a perfectly regular THREE COLUMNS by TWO ROWS grid, identical cell size, each centered in its cell with at least 15% transparent padding. No text, numbers, borders, panels, ground, shadows on ground or UI.
Reading order left to right, top to bottom:
1. Modern repair kit: compact pearl white and navy hard-shell case with teal trim, a turquoise diamond kite emblem on lid, orange latch; slightly open to reveal a small adhesive roll and folded paper.
2. Kite paper: a neat fan stack of folded square tissue paper sheets in cyan, cream, coral and sunny yellow.
3. Kite frame rods: bundle of three slender warm bamboo rods with modern teal connector sleeves and an orange elastic strap, clear long silhouette.
4. Repair adhesive: small modern squeeze glue bottle with cream body, navy base, coral nozzle cap, teal diamond emblem.
5. Waxed line: a chunky deep navy spool wound with cream thread, teal end caps, a small loose curved thread end.
6. Currency: a modest stack of three gold coins, one upright front coin with engraved diamond kite emblem.
Art style matches polished hand-drawn JRPG menu item illustrations: strong clean dark navy outlines, large readable cel-shaded shapes with two or three tones per material, highlights from upper left, crisp edges, cheerful colors, silver and teal product design, subtle orange accents. These are menu illustrations intended to display at 80 to 180 pixels. No tiny pictorial texture, no gritty realism, no labels. Transparent background, consistent scale and angle, equal 3x2 grid. Landscape aspect 3:2.
```

A folha original foi preservada em itens-imagegen.png. O recorte determinístico usa três colunas e duas linhas, remove alfa menor que 0,9 e ajusta cada silhueta a 224 px dentro de um canvas de 256 × 256. A escala das ilustrações de HUD usa Lanczos. A arte não substitui os sprites de overworld.
