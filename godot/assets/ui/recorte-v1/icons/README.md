# Ícones Recorte · PIP-65

SVG 48×48, PNG 96×96 e variante com contorno externo de papel em `world/` (canvas 64×64, com 8 px transparentes adicionais para não cortar a borda). Originais do projeto; gerador reproduzível em `scripts/build-recorte-icons.mjs`, usando tokens da PIP-62. Não misturar com os antigos `campaign/ui-recorte/icon-*` ou `battle-ink/icon-*`.

`Hud.icon(id)` retorna o SVG; `Hud.icon(id, true)` retorna o PNG 96 para uso ampliado. `Hud.Icons.texture(id, true)` retorna a variante de mundo. Texto, foco e input são controles nativos.

Prancha de leitura: `../mockups/icones.png` e `godot/mockups/icones.png`. A busca na versão web confirmou quatro tipos em `src/engine.js`, usados pela Dex em `src/dex-client.js`: Precisa, Ágil, Guardiã e Técnica. Todos têm símbolos próprios. A referência da especificação a seis elementos não corresponde ao sistema implementado na web; não foram inventados elementos adicionais.
