# Hiponilo · Guardião do Rio Sagrado

Hipopótamo roxo de papel com pequenas presas, cobertura rosa/coral de bambu e rabiola turquesa. Vista oblíqua para a direita, focinho frontal visível. Oito peças articuladas com proporções originais e profundidades distintas. Montagem lógica 272 × 240.

Soulgen: http://127.0.0.1:5240/?preset=hiponilo

Cinco ações: Guarda do rio (2,4 s), Passada do guardião (1,2 s), Avanço da corrente (1,8 s; impacto 0,68 s), Recuo (1,2 s), Sossego do rio (2,6 s). Ciclos fechados, ações únicas retornam ao neutro. Variantes faciais mantêm alpha e pixels externos às janelas idênticos.

ImageGen, 25/10/2026. Identidade do atlas Hiponilo, acabamento Carcará aprovado. Fonte preservada em color-rig-v2/source.png e torso corrigido em body-core-source.png. Prompt completo em prompts.json. prepare.py mede recortes, registra expressões e normaliza o torso gerado sem patas duplicadas. build.mjs monta articulações próprias e gera projeto portátil, preview.html com controles/miniatura, review.png em dois fundos e review-full.png com todos os 116 quadros do atlas de estudo (12 fps/células 256 px). Fontes na resolução original; preserveSourceAspect rejeita esticamento.

Reprodução: Python/Pillow e Node com @napi-rs/canvas (SOULGEN_CANVAS_MODULE aceita instalação externa). Aguarda revisão do autor. Validação técnica não equivale a aprovação artística. Sprites, atlas e saves do jogo preservados.

Revisão 2 aprovada pelo autor: approved-layout.json preserva a montagem final recebida com posições, pivôs, transformações e animações. build.mjs reaplica os dados sem substituir seus ajustes. Referências antigas de encaixe não são impostas à montagem final.

As dimensões manuais aprovadas pelo autor prevalecem sobre a proporção inicial de montagem; o exportador mantém essas dimensões sem corrigi-las automaticamente.
