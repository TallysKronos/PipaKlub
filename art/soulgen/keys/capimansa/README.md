# Capimansa · Companheira das Águas Calmas

Capivara de papel ocre/caramelo, focinho largo escuro, orelhas pequenas, quatro patas curtas, vela verde-petróleo e marfim com bambu, nós, remendos e folhas. Referência de identidade: atlas original da espécie. Acabamento: Carcará aprovado. Vista oblíqua para a direita, com face frontal do focinho visível; o olho distante fica oculto nesta projeção.

Soulgen: http://127.0.0.1:5240/?preset=capimansa

Oito peças editáveis, com profundidades distintas e pivôs próprios. Cinco ações: Brisa tranquila (2,4 s), Deslize sereno (1,2 s), Onda mansa (1,8 s, impacto 0,68 s), Recuo (1,2 s), Alegria tranquila (2,6 s). Ciclos fecham e ações únicas retornam ao neutro. Expressões só alteram olhos e sobrancelhas da cabeça canônica; silhueta, focinho, nariz e orelhas ficam preservados.

## Fontes e revisão

ImageGen, 25/10/2026. Fonte intacta em color-rig-v2/source.png; prompt e referências em prompts.json. prepare.py mede componentes, normaliza recortes e registra os olhos das variantes. build.mjs monta o rig, gera projeto portátil, preview.html com controles e miniatura, review.png com poses em fundos claro/escuro e review-full.png com todos os 116 quadros do atlas de estudo. Fontes em resolução original; montagem lógica 240 × 224 e atlas de estudo a 12 fps em células de 256 px.

Reprodução: Python/Pillow para prepare.py, Node com @napi-rs/canvas para build.mjs (SOULGEN_CANVAS_MODULE aceita instalação externa). Verificação técnica em validation.json; não substitui aprovação visual do autor. Rig configurado somente no Soulgen; atlas, sprites e saves do jogo preservados. Aprovado pelo autor em 25/10/2026 após ajustes manuais.

O arquivo recebido do autor ajusta posições, pivôs e camadas. author-adjustments.json preserva esses valores, o nome e o hash do arquivo; build.mjs os reaplica sem alterar imagens ou animações. Revisão de rig 2.
