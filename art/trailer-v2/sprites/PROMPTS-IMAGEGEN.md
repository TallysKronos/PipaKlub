# Prompts usados no gerador integrado

Ferramenta: `image_gen.imagegen`, `transparent_background: true`. Cada entrada abaixo é uma chamada separada. Os originais estão preservados; não foi usado CLI/API externo.

## Vertim — primeira geração

Referência: `art/creatures/estratonte-family-v1/vertim/concept-v1/concept.png`.

```text
Use case: identity-preserve. Production overworld sprite reference sheet for Vertim. EDIT the attached approved Vertim concept into exactly TWO views side by side on real transparent background: LEFT front three-quarter facing southwest (toward bottom-left), RIGHT back three-quarter facing northwest (toward upper-left), same exact scale and floor baseline. Preserve the creature identity: cute lavender juvenile long-neck sauropod, green eyes, cream neck bands, mint green broad belly sail panel and shoulder triangles, dark navy straps, orange rope knots, small two-piece cream/mint diamond kite tassel tied to tail. Four feet, long neck, long tapered tail. Coherent chunky pixel art with clearly marked square blocks about 5-7 source pixels per block and dark outline 1 block wide, 3 shade levels per material. Each view fully visible, no clipping, generous transparent gap. The back view must reveal back anatomy rather than mirroring front face. No scenery, ground shadow, labels, text, frame, watermark. Landscape 1536x1024, keep original full resolution.
```

## Vertim — correção de orientação

Entrada de edição: primeira geração `exec-c8a3f2e5-8aa7-41ec-a7c8-1f62ad2d97c9.png`. Saída escolhida: `exec-04716009-5331-41a5-90a8-ff43d1395315.png`.

```text
Targeted correction to this two-view Vertim sheet. Keep LEFT front southwest sprite EXACTLY unchanged. Change ONLY the RIGHT sprite orientation into true REAR THREE-QUARTER NORTHWEST view: we look at its rump and the back of the long neck/head as it walks away toward upper-left. NO eye, NO nose, NO face visible on right. Four feet arranged around rear-facing body, tail toward viewer lower-right. Retain lavender/cream sauropod anatomy, green side panels, navy straps, orange knots and diamond tassels exactly. Same size/baseline, chunky pixel block style and real transparent background. No glow, background, shadow, text.
```

## Urso-polar jovem

Referência: `art/creatures/urso-polar-family-v1/urso-polar-young/concept-v1/concept.png`. Saída: `exec-cdbf00e4-ca9c-49fc-a324-39a3e73c5ae2.png`.

```text
Use case: identity-preserve. Production overworld TWO VIEW pixel sprite sheet of this exact Urso-polar young approved concept. Preserve its identity: strong ivory-white QUADRUPED polar bear with cyan eyes and navy forehead triangle, teal armored cape with tall navy red-lined collar, mustard bamboo edge trim, red rope knots at chest/shoulders/wrists, elongated teal-and-cream kite shield plates on BOTH forearms, navy diagonal bands, short tail ending in red rope and two cream/teal diamond kite tassels. On TRUE transparent background, exactly TWO complete separated views side-by-side: LEFT front three-quarter facing SOUTHWEST, looking toward lower-left and seeing chest/face. RIGHT rear three-quarter facing NORTHWEST, going toward upper-left, seeing BACK OF HEAD (no visible face or eyes) and back/cape/rump/rear feet foreground; this is a true back view, not mirrored front. Equal body scale and floor baseline in both. Chunky pixel art formed of clear square blocks with dark outline exactly one block, simple 3 tones per material. No antialias smooth illustration style. No shadow, scenery, labels, text, border, extra subjects, clipping. Landscape 1536x1024.
```

## Eremor — oito poses de rugido

Referência: `godot/assets/campaign/combat-eremor.png`. Saída original: `eremor-rugido-v1/geracao.png` (`exec-cc95e351-66b3-4435-b7c0-84957ec6fd0e.png`).

```text
Identity-preserving edit of the attached Eremor combat spritesheet. Produce a clean ROAR animation sheet, exactly 8 frames arranged FOUR COLUMNS by TWO ROWS on true transparent background. One Eremor per cell, same scale and anchored on same baseline in each cell, full body visible. Match the original top-left Eremor identity and pose: massive squat dark navy bear/sloth legendary, long ivory hooked foreclaws planted on ground, ivory face/arms bands with red chevrons, red eye markings, red rope chest knot, huge ivory/red kite fan panels along back supported by brown bamboo struts and red knots, navy-ivory-red fan tail. Faces left 3/4. No new anatomy or horns. Maintain exactly this design, NOT a dragon. Eight chronological poses: (1) neutral quiet, mouth shut; (2) deep inhale, chest lifts and head leans back, claws still planted; (3) neck extends upward and mouth opens halfway; (4) explosive roar, head tilted up-left and WIDE OPEN mouth with visible dark interior and small teeth; (5) sustained roar wide open mouth, neck at peak reach; (6) pulsing final roar, open jaws with slight recoil; (7) mouth starts closing and shoulders settle; (8) exhausted recoil, mouth shut and head lowers. The three open-roar poses MUST have visibly different jaw silhouettes, not merely colored mouths on a closed muzzle. Keep legs/feet and fan structure consistent. Clean crisp 2D game sprite rendering matching original; no red background fringe, no glow, no scenery, no ground shadow, no particles, no text/labels/numbers/borders. Each equal cell 350x313 logical target, final whole image landscape.
```

A onda de choque e a conversão de silhueta são operações nativas do Aseprite, sem prompt de geração adicional. Os prompts históricos dos quatro RAW reaproveitados não foram recuperados; a origem legada foi registrada sem inventar autoria ou licença.
