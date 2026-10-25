# Marulume · Mensageiro de Atlântida

Golfinho de papel azul/ciano/creme, focinho alongado, laço vermelho e peitoral de pipa com ondas. Quatro peças: corpo/rosto/peitoral, duas nadadeiras e cauda bifurcada. Vista oblíqua para a direita. Proporções originais preservadas, com verificação de esticamento.

Soulgen: http://127.0.0.1:5240/?preset=marulume

Cinco ações: À deriva (2,4 s), Nado nas correntes (1,2 s), Impulso da maré (1,8 s, impacto 0,66 s), Recuo na corrente (1,2 s), Salto de alegria (2,6 s). Cauda e nadadeiras possuem canais próprios; ciclos fechados e ações únicas retornam ao neutro. Expressões registradas somente na janela dos olhos, sem alterar alpha e demais pixels.

ImageGen em 25/10/2026 com identidade do atlas Marulume e acabamento Carcará aprovado. Fonte preservada em color-rig-v2/source.png; prompt em prompts.json. prepare.py mede componentes e registra as expressões. build.mjs monta pivôs próprios e gera projeto portátil, preview.html com controles e miniatura, review.png em dois fundos e review-full.png com os 116 quadros do atlas de estudo (12 fps/células 256 px). Montagem lógica 256 × 240, imagens na resolução original.

Reprodução: Python/Pillow e Node com @napi-rs/canvas (SOULGEN_CANVAS_MODULE aceita instalação externa). Aguarda avaliação do autor. Validação técnica não equivale à aprovação artística; atlas, sprites e saves do jogo preservados.

## Revisão 2: três faces corrigidas

Ataque, dano e vitória foram regenerados diretamente da peça canônica em expressions-source-v2.png. O registro usa coordenadas fixas de mesma pose e duas máscaras independentes para olhos/sobrancelhas, sem redimensionar recortes de poses diferentes. Alpha, focinho, sorriso, laço e todos os pixels externos às máscaras permanecem canônicos. As peças e animações foram preservadas.

Revisão 3 aprovada pelo autor: approved-layout.json preserva a montagem final e as animações recebidas. Dimensões manuais do autor prevalecem sobre a montagem proporcional inicial, sem reposicionar peças ou impor sockets antigos.
