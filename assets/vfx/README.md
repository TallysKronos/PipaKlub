# Trade ceremony art

Generated using the built-in image generation tool. Original output preserved without image edits.

- `trade-celestial.png`: 1254 × 1254, true RGBA (alpha range 0–253), four equal 627 × 627 cells. Cyan comet at (0,0); gold comet at (627,0); encounter seal at (0,627); stardust cluster at (627,627). CSS uses 200% background size and corner positions, so no preprocessing is needed.
- `trade-sky.png`: 1672 × 941 RGB illustration, used as the ceremony background.

The atlas is requested only while `.is-flying` is active. The sky appears with the trade scene. Simple CSS lights remain available if either texture fails to load. Animations stop when the ceremony finishes; small viewports render half the trail particles. The source assets are served by an explicit allowlist and copied to both build outputs. No authentication or database change is required for this visual update.

## Final prompts

### Transparent VFX atlas

Use case: stylized-concept. Generate one production game VFX texture atlas on a truly transparent background, square 1024x1024, arranged as an exact 2 by 2 grid of equal 512x512 cells, no gutters or labels. Each asset centered within its cell and fully contained with generous transparent margins. Top left: a magical cyan-white comet head, tapered flowing wisps and tiny diamond particles, pointing upward, vertical symmetrical silhouette. Top right: a warm gold-white comet head with peach and lavender wisps and tiny diamond particles pointing upward. Bottom left: a spectacular magical celestial encounter sigil, a thin luminous elliptical ring with delicate ornate four-point stars and an intense white-gold center, teal and violet energy, seen front on. Bottom right: a cluster of varied small four-point sparkle stars and stardust, airy and separated, pale cyan gold lavender. Art direction: charming hand-painted 2D fantasy video-game effects, crisp readable shapes matching playful illustrated kite creatures, polished glowy translucent alpha edges, luminous but not washed out, no text, no letters, no checkerboard, no solid backdrop, no frame, no characters. Assets will be sampled by CSS grid cell cropping and animated in a kite trading ceremony.

### Celestial background

Use case: stylized-concept. Asset type: landscape background for a charming illustrated 2D fantasy kite game trading ceremony. A beautiful quiet celestial amphitheater above the clouds at night: deep navy and indigo velvet sky, subtle teal and lavender aurora ribbons around the left and right outer edges, distant tiny warm stars, faint delicate circular star-chart arcs, a softly illuminated curved cloud horizon along the very bottom. Soft hand painted polished game background with a little storybook texture. Wide landscape composition, completely empty dark center and upper center for two animated luminous kites and readable UI text. Sky occupies 85 percent; horizon only bottom 15 percent. Light concentrated near bottom corners, no large planets, no moon, no characters, no kites, no text, no logos, no frame, no UI. Magical and emotionally special, dreamy, restrained contrast, beautiful color depth.
