# Trinca-brasas · Três Guardiões, um Coração

Um só corpo de papel carvão/laranja, três cabeças caninas com focinhos creme, quatro patas com garras, peitoral de pipa e rabiola trançada com três folhas de brasa. Vista oblíqua para a direita. Nove peças com profundidades distintas, cabeças articuladas separadamente e pivôs próprios.

Soulgen: http://127.0.0.1:5240/?preset=trinca-brasas

Cinco ações: Três sentinelas (2,4 s), Passada das brasas (1,2 s), Investida tripla (1,8 s; impacto 0,66 s), Recuo dos guardiões (1,2 s), Um só coração (2,6 s). Expressões de golpe e vitória nas três cabeças; dano na central com recuo corporal nas demais. Ciclos fechados e ações únicas retornam ao neutro.

ImageGen em 25/10/2026 com atlas original e acabamento Carcará. Fonte preservada em color-rig-v2/source.png, prompts em prompts.json. Tronco corrigido por ImageGen para fechar aberturas de encaixe. prepare.py mede componentes e registra variantes somente na janela dos olhos, com alpha e pixels externos idênticos. build.mjs gera projeto portátil, preview.html com controles/miniatura, review.png em dois fundos e review-full.png com os 116 quadros do atlas de estudo (12 fps, células 256 px). Montagem lógica 272 × 240; imagens preservam resolução original.

Reprodução: Python/Pillow para prepare.py; Node com @napi-rs/canvas para build.mjs (SOULGEN_CANVAS_MODULE pode indicar instalação externa). Validação técnica não substitui revisão artística. Configurado no Soulgen e aguardando avaliação do autor; sprites, atlas e saves do jogo preservados.

## Revisão 2: somente torso

A montagem recebida em trinca-brasas-tres-guardioes-um-coracao.soulgen.json está preservada em author-layout.json. Apenas a textura do torso foi substituída por uma pipa de papel normal com corrente e chave em formato de pipa. A fonte nova está em body-kite-source.png; prepare.py aplica apenas recorte alpha. Partes, pivôs, transformações e animações do autor ficam idênticos, exceto o retângulo de recorte da nova textura. A montagem do autor usa pivôs externos ao torso; os sockets normalizados anteriores foram removidos, sem redefinir os pivôs. Testes conferem preservação integral dos dados e limites das animações.

Revisão 3 aprovada pelo autor: versão final recebida no arquivo (1), com posições, pivôs, transformações e animações preservados em author-layout.json.
