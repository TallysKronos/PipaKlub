# Tatutrama · Guardião das Dobras Antigas

Tatu de papel em vermelho, creme e carvão. A carapaça é a própria estrutura de pipa, com bambu, nós e borlas. Focinho afilado, quatro patas curtas com garras e rabiola segmentada enrolada. Sete peças editáveis com profundidades distintas e pivôs próprios. Vista oblíqua para a direita; face frontal do focinho visível, olho distante oculto pela projeção.

Soulgen: http://127.0.0.1:5240/?preset=tatutrama

Cinco ações: Vigia das dobras (2,4 s), Impulso rente ao chão (1,2 s), Investida da trama (1,8 s; impacto 0,66 s), Recolher sob a carapaça (1,2 s), Orgulho do guardião (2,6 s). Ciclos fechados, ações únicas retornam ao neutro e expressões mudam somente a janela dos olhos/sobrancelhas.

## Fonte e reprodução

ImageGen em 25/10/2026, usando o Tatutrama original e o Carcará aprovado como referências de identidade e acabamento. Fonte preservada em color-rig-v2/source.png, prompt em prompts.json. prepare.py mede recortes e registra expressões no alpha canônico, sem redesenhar anatomia por código. build.mjs monta o rig e gera projeto portátil, preview.html com controles/miniatura, review.png em dois fundos e review-full.png com todos os 116 quadros do atlas de estudo (12 fps, células de 256 px). Montagem lógica 248 × 224, imagens na resolução original.

Reprodução: Python/Pillow para prepare.py, Node com @napi-rs/canvas para build.mjs (SOULGEN_CANVAS_MODULE aceita instalação externa). Validação técnica em validation.json não equivale à aprovação visual do autor. Configurado no Soulgen; sprites, atlas e saves do jogo preservados. Aprovado pelo autor em 25/10/2026. Ajustes de patas e inversão horizontal da pata traseira próxima preservados em author-adjustments.json e reaplicados por build.mjs. Revisão de rig 2.
