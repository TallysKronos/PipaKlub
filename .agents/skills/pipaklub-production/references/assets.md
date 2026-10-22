# Assets na engine atual

## Antes de produzir

Leia as seções aplicáveis de `MANUAL-DE-ASSETS.md`. Use o personagem e o kit aprovados como referência; nome de anime sozinho não define a direção. A linguagem é papel vivo, dobras, varetas, nós e rabiolas com silhueta legível na escala de jogo.

Localize o manifesto/atlas e o consumidor em `src/art-client.js`, `src/menu-ui.js`, `src/dex-client.js` ou nos módulos de mundo pertinentes. Não imponha uma grade universal: dimensões, frames, orientação, pivô e tempo devem vir desse contrato.

## Aceitação por família

- **Sprites e chibis:** preserve volume, rosto, orientação e apoio entre frames. Examine a sequência animada, não só a prancha; cauda/rabiola deve continuar ancorada. Retratos e corpo inteiro têm recortes próprios.
- **Tiles e muros:** leia também `WORLD-ART-DIRECTION.md` e `HUD-KIT.md` apenas se houver interface. Compare repetição 3×3, trechos longos, quatro cantos e juntas entre eixos. Não repita tampas nos segmentos intermediários nem disfarce emendas com vegetação.
- **Objetos:** tronco toca a copa e o solo; banco enfrenta uma área utilizável; pivô de profundidade e colisão representam a base, não todo o PNG. Valide caminhos e zonas de interação no mapa real.
- **HUD:** mantenha pontas e ornamentos fixos em 3-slice e cantos em 9-slice. Nunca estique a imagem inteira para caber texto. Veja a referência de interface para conteúdo/foco.

Registre origem, identidade usada, uso, dimensões reais, frames, duração, pivô, alpha e evidências de revisão. O modelo externo `../create-game-assets/assets/asset-manifest.json` é um registro de produção, não substituto dos manifestos de runtime. Não invente autoria/licença dos arquivos legados.

## Ferramentas e limites

Da raiz do repo, os auxiliares importados ficam em:

```powershell
python .agents/skills/create-game-assets/scripts/asset_report.py assets/characters/overworld-v1/sr-assis.png --require-alpha --json
python .agents/skills/create-game-assets/scripts/build_preview_sheet.py assets/characters/overworld-v1/sr-assis.png assets/characters/overworld-v1/lia.png --out tmp/asset-review.png --columns 2
```

O primeiro verifica dimensões, cores e presença de canal alpha. Um canal existente pode estar totalmente opaco: examine `alpha_min`, `transparent_pixels` e bordas. Esses scripts não comprovam encaixes, continuidade anatômica ou estabilidade de animação. A prancha nearest-neighbor é diagnóstica; preserve o filtro de runtime definido para cada família.

Use `npm run audit:world` em mudanças do mundo e testes específicos (`world-structure.test.mjs`, `world-painted.test.mjs`, `quintal-modular.test.mjs`, `art.test.mjs`) conforme o consumidor afetado. Faça inspeção visual no jogo antes de dizer integrado/aprovado.
