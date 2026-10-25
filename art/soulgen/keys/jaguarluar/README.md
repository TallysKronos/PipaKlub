# Jaguarluar · A Sombra da Lua Cheia

Onça de papel ocre com rosetas, focinho creme, vela verde de bambu e rabiola enrolada com folhas. Oito peças em vista oblíqua para a direita: corpo, cabeça, vela, quatro patas e rabiola. Proporções dos recortes originais preservadas e profundidades distintas.

Soulgen: http://127.0.0.1:5240/?preset=jaguarluar

Cinco ações: Vigia ao luar (2,4 s), Passos de sombra (1,2 s), Bote da lua (1,8 s; impacto 0,68 s), Recuo (1,2 s), Alegria da mata (2,6 s). Ciclos fechados; ações únicas retornam ao neutro.

ImageGen em 25/10/2026. Identidade do atlas Jaguarluar e acabamento Carcará aprovado. Fonte de peças em color-rig-v2/source.png e expressões dedicadas da cabeça canônica em expressions-source.png, prompts em prompts.json. prepare.py mede componentes e registra olhos sem alterar alpha e pixels externos. build.mjs usa articulações próprias e gera projeto portátil, preview.html com controles/miniatura, review.png em dois fundos e review-full.png com os 116 quadros do atlas de estudo (12 fps/células 256 px). Montagem lógica 272 × 240, PNGs na resolução original.

Reprodução: Python/Pillow e Node com @napi-rs/canvas (SOULGEN_CANVAS_MODULE aceita instalação externa). Configurado no Soulgen, aguardando revisão visual do autor. Testes técnicos não representam aprovação artística. Atlas, sprites e saves do jogo preservados.

Revisão 2 aprovada pelo autor: approved-layout.json preserva posições, pivôs, dimensões, transformações e animações finais recebidas. Dimensões manuais prevalecem sobre a proporção inicial e os sockets anteriores, sem reposicionar suas peças. build.mjs reaplica os dados aprovados.
