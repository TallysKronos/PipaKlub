# Nina — overworld v2

Arte própria para o mapa, com identidade baseada no retrato existente e proporção chibi dos NPCs. Não substitui o retrato dos diálogos.

- `source.png`: geração original preservada; prompt em `prompt.txt`.
- `normalized-preview.png`: oito recortes normalizados para inspeção.
- Runtime: `assets/characters/nina-overworld-v2/manifest.json` e `overworld.png`.
- Quatro direções em repouso e uma pose de caminhada por direção. Não é um ciclo completo de caminhada.
- Células 192 × 192; altura opaca 144; apoio dos pés em (96, 180).
- Reprodução dos recortes: `node scripts/prepare-nina-overworld.mjs`.

Nina é estacionária no mapa e passa a se orientar para Kael. As poses de caminhada ficam disponíveis para uso futuro.
