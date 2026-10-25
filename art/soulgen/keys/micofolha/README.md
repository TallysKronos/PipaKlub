# Micofolha · Mensageiro das Copas

Pequeno mico de papel alaranjado, rosto escuro, vela de folhas em creme/laranja/verde-petróleo, bambu, nós e rabiola enrolada. Vista em três quartos para a direita; face distante menor. Acabamento baseado no Carcará aprovado, preservando a identidade do atlas original.

## Entrega

Abra http://127.0.0.1:5240/?preset=micofolha. Oito peças: tronco, cabeça/juba, dois braços, duas pernas, vela e rabiola. Cada peça possui profundidade diferente e pivô próprio. Cinco ações com expressões registradas: Curioso nas copas (2,4 s), Salto de folha (1,2 s), Bote das copas (1,8 s; impacto 0,65 s), Susto nas folhas (1,2 s) e Festa do mensageiro (2,6 s). Ciclos fechados; ações únicas retornam ao neutro.

Projeto editável e portátil em color-rig-v2/. preview.html tem controles de ação, tempo, velocidade, fundo e miniatura. review.png mostra cinco poses nos fundos claro/escuro; review-full.png mostra os 116 quadros do atlas de estudo de 256 px, a 12 fps. A montagem usa 224 × 224 unidades lógicas, com fontes em resolução original e transparência.

## Origem e reprodução

Fonte ImageGen gerada em 25/10/2026, preservada em source.png, prompt e referências em prompts.json. prepare.py mede componentes conectados e recortes; as expressões são registradas somente na janela de olhos/sobrancelhas da cabeça canônica. Alpha e pixels fora da máscara ficam idênticos. Nenhuma anatomia ou olho foi desenhado por código. build.mjs monta articulações próprias e exporta as prévias usando o mesmo amostrador do editor.

Para reproduzir, execute prepare.py com Python/Pillow, depois build.mjs com Node e @napi-rs/canvas (SOULGEN_CANVAS_MODULE aceita o caminho externo). Conferir validation.json, articulações, extremos e expressões. Validação técnica não substitui aprovação artística do autor. Rig configurado no Soulgen; não altera sprites, atlas ou save do jogo. Publicação Git não incluída nesta entrega.

Aprovado pelo autor em 25/10/2026 após ajustes manuais de cabeça, braços e perna próxima. author-adjustments.json preserva as posições aprovadas e a identificação do arquivo recebido; build.mjs reaplica esses ajustes. Revisão de rig 2.
