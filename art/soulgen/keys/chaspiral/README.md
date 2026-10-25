# Chaspiral · Atrasada para o Próximo Segundo

Criatura de papel com xícara no topo, cachos em espiral, asas rosa e verde-petróleo, varinha e rabiola de etiquetas com sino. Vista oblíqua para a direita. Seis peças com pivôs e profundidades próprios: corpo/rosto/xícara, duas asas, dois braços e rabiola. Todas preservam a proporção original dos recortes; preserveSourceAspect impede exportação de peças esticadas.

Soulgen: http://127.0.0.1:5240/?preset=chaspiral

Cinco ações: Pausa para o chá (2,4 s), Voo entre segundos (1,2 s), Espiral do instante (1,8 s, impacto 0,66 s), Segundo perdido (1,2 s), Hora de comemorar (2,6 s). Ambas as mãos possuem canais em todas as ações; ciclos fechados, ações únicas retornam ao neutro.

Fonte ImageGen de 25/10/2026 preservada em color-rig-v2/source.png, prompt em prompts.json. Referências: identidade do atlas Chaspiral e acabamento Carcará aprovado. prepare.py mede componentes e registra recortes dos olhos das variantes sobre a face canônica, preservando silhueta, boca, xícara e pixels fora das janelas. build.mjs gera projeto portátil, preview.html com controles/miniatura, review.png em dois fundos e review-full.png com os 116 quadros do atlas de estudo (12 fps/células de 256 px). Montagem lógica 256 × 240; imagens na resolução original.

Reprodução: Python/Pillow para prepare.py, Node com @napi-rs/canvas para build.mjs (SOULGEN_CANVAS_MODULE aceita instalação externa). Aguarda revisão visual do autor. Testes técnicos não equivalem à aprovação artística. Atlas, sprites e saves do jogo preservados.

Revisão 2: ataque e vitória regenerados diretamente sobre o corpo canônico em expressions-source-v2.png. Registro usa a mesma pose, sem importar trechos de asas/boca das poses montadas. Alpha e pixels fora das janelas dos olhos preservados.

Revisão 3 aprovada pelo autor: approved-layout.json preserva a montagem final recebida, com posições, pivôs, transformações e animações. build.mjs reaplica esses dados sem alterar a arte aprovada. Referências normalizadas de encaixe anteriores foram removidas para não impor os pivôs antigos à nova montagem.
