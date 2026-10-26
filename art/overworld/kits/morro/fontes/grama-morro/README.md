# Fontes dos decalques — PIP-88

Sete imagens geradas separadamente pela ferramenta `imagegen`, com fundo
transparente, em 26/10/2026. Originais preservados; não há stock externo.

Direção: RPG brasileiro acolhedor em 2D, vista elevada compatível com isometria
2:1, formas agrupadas e legíveis em 64×48, cel shading limpo, verdes de folha e
sálvia, detalhes pequenos creme/amarelo, contorno oliva discreto. Sem textura de
aquarela, ruído, sombra de quintal, texto, piso elevado ou cenário de fundo.

- `capim-alto-0..2.png`: três silhuetas de capim com folhas curvas assimétricas.
- `terra-batida-0..1.png`: duas manchas irregulares de terra clara e vegetação
  periférica, sem colisão.
- `trevo-flor-0..1.png`: dois agrupamentos baixos de trevos e flores miúdas.

O script `tools/overworld/build_morro_grass.py` registra os nomes originais das
gerações, remove halos de alpha baixo, recorta, redimensiona proporcionalmente e
ancora em canvas 64×48. Os PNGs finais ficam em `../../decalques/`; as fontes não
entram na exportação runtime.
