# Gambalhote — overworld diagonal v1

Duas poses estáticas de câmera elevada em ¾: frente SW e costas NW. Canvas 80×80 por vista, PNG transparente e fonte editável `gambalhote-overworld-diagonal.aseprite`. Os frames 1 e 2 representam vistas distintas, não um ciclo.

Identidade preservada do concept base aprovado: gambá bípede, face marfim, nariz telescópico de bambu com ponta rosa, peito-pipa, acentos coral/petróleo, cauda preênsil ligada ao quadril segurando uma cruzeta, dois fios nos pulsos. O Alvacordo aprovado definiu câmera, compactação e acabamento, sem transferir armadura ou anatomia.

## Produção

Geração de base com image_gen integrada, uma folha com duas vistas. Prompt completo em `prompt.txt`, original em `geracao.png`. Normalização no Aseprite MCP headless: recortes de mesmo tamanho, redução com a mesma escala para frente/costas, paleta própria de 24 cores, alpha binário e posicionamento em canvas. Recortes em `normalizacao.json`. Trata-se de adaptação de base gerada; não é desenho integral manual nem recuperação comprovada de grelha original.

O corpo ocupa menos altura que o conjunto completo, pois cauda e cruzeta se estendem acima da cabeça. Pivô proposto (40,65), ainda não validado no cenário. As costas têm sobreposições próprias, preservando a raiz da cauda e sem duplicar o peito-pipa na nuca/dorso.

## Entrega

- `frente-sw.png`, `costas-nw.png`: poses nativas transparentes.
- `gambalhote-overworld-diagonal.aseprite`: fonte com duas vistas.
- `prancha-native.png`, `preview-cinza-5x.png`: comparação das duas vistas em fundo cinza, nativa e ampliada.
- `prancha.aseprite`: montagem editável com fundo separado.
- `index.html`: comparador de resolução/fundos e downloads.
- `validacao.json`: medidas reais do PNG.

Não houve alteração de código, integração, commit ou push. Sprites anteriores e concepts preservados. As poses ainda precisam de aprovação visual do usuário e de teste no jogo antes de preparar idle/walk.
