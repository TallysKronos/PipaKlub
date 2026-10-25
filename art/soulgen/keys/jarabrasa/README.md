# Jarabrasa · Sentinela das Brasas da Mata

Serpente de papel vermelho/creme com crista, corpo em S, leque estrutural de pipa em duas metades e rabiola bifurcada. Quatro peças proporcionais em vista oblíqua para a direita; sem patas. Profundidades distintas e pivôs próprios.

Soulgen: http://127.0.0.1:5240/?preset=jarabrasa

Cinco ações: Vigia das brasas (2,4 s), Ondulação da serpente (1,2 s), Bote de papel (1,8 s; impacto 0,66 s), Recuo da crista (1,2 s), Orgulho da serpente (2,6 s). Ciclos fechados, ações únicas retornam ao neutro. Expressões regeneradas na pose canônica, mantendo alpha e pixels fora dos olhos.

ImageGen em 25/10/2026 com referências do atlas original e acabamento Carcará aprovado. Fontes em color-rig-v2/source.png e expressions-source.png; prompts em prompts.json. prepare.py mede componentes e registra expressões. build.mjs usa proporções originais e gera projeto portátil, preview.html com controles/miniatura, review.png em dois fundos e review-full.png com 116 quadros do atlas de estudo (12 fps/células 256 px). Montagem lógica 256 × 240, imagens na resolução original.

Reprodução: Python/Pillow e Node com @napi-rs/canvas (SOULGEN_CANVAS_MODULE aceita instalação externa). Configurado no Soulgen, aguardando revisão visual do autor. Testes técnicos não equivalem à aprovação artística. Sprites, atlas e saves do jogo preservados.

Revisão 2: janela da rabiola ampliada conforme as dimensões reais da fonte (1312 × 1199). As duas pontas agora estão completas. prepare.py rejeita rabiola tocando os limites da janela de amostragem, evitando exportar recorte truncado.

Revisão 3 aprovada pelo autor: approved-layout.json preserva posições, pivôs, dimensões, transformações e animações finais. Esses ajustes prevalecem sobre a proporção inicial e as antigas referências de encaixe. build.mjs reaplica os dados exatos recebidos.
