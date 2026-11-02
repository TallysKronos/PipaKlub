# Rabiolava — Soulgen cutout v1

Segunda criatura do lote, após Trovareta aprovada pelo dono. Preserva a raia B, paleta magenta/azul-violeta e duas rabiolas incandescentes.

- Soulgen: `http://127.0.0.1:5241/?preset=rabiolava`.
- Seis partes: torso, cabeça, duas nadadeiras e duas rabiolas completas.
- Quatro rostos: neutro, ataque, dano e vitória. Janelas fixas nos olhos preservam todo o alpha e pixels fora dessas regiões.
- Seis ações: repouso 3,2 s; voo 1,6 s; golpe 1,85 s (impacto em 0,78 s); dano 0,9 s; vitória 2,5 s; derrota 1,2 s.
- Projeto editável e cópia portátil em `cutout-rig-v1/`. Atlas de estudo: 142 frames, 12 fps, sem contato com bordas das células.

## Reprodução

`slice.py` requer Pillow, numpy e OpenCV; `register-faces.py` requer Pillow. Rodar nessa ordem antes de `build-rig.mjs`, que requer `@napi-rs/canvas` ou `SOULGEN_CANVAS_MODULE`. Depois executar `node --test art/soulgen/keys/rabiolava/rig.test.mjs`. `review-poses.mjs` renderiza extremos maiores com o sampler real do editor.

As partes foram geradas a partir da identidade aprovada; as fontes e os prompts completos estão preservados. A extração mantém os pixels RGBA próximos da tinta de cada peça e remove apenas a névoa distante da geração. Não é grade nativa estrita de pixel art. O contorno segue o acabamento híbrido do Carcará; o renderer mantém sua amostragem atual.

O movimento é próprio de raia, com nadadeiras em batida contida, corpo liderando e rabiolas atrasadas em fases distintas. As fitas são peças inteiras articuladas na raiz: ainda não há deformação por malha ao longo da seda. Sem efeitos de lava implementados em batalha.

Revisão visual feita na montagem, expressões, fundo claro/escuro e extremos renderizados. O navegador automatizado continua indisponível nas configurações locais; não declarar playtest visual interativo. Não há integração com o jogo nem push desta criatura antes da revisão do dono.
