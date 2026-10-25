# Flautrevo · Flautista dos Ventos Perdidos

Morcego de papel roxo/creme, focinho sem bico, orelhas dobradas, asas com varetas-flauta de bambu e rabiola azul-petróleo com sino. Vista oblíqua para a direita com olho distante menor. Quatro peças editáveis com pivôs próprios e profundidades distintas: corpo/rosto/orelhas, duas asas e rabiola.

Soulgen: http://127.0.0.1:5240/?preset=flautrevo

Cinco ações: Melodia na brisa (2,4 s), Voo do flautista (1,2 s), Sopro dos ventos (1,8 s, impacto 0,66 s), Nota interrompida (1,2 s), Reverência musical (2,6 s). Ciclos fecham; ações únicas retornam ao neutro. Expressões registradas somente na janela dos olhos/sobrancelhas, preservando alpha e demais pixels.

Fonte ImageGen de 25/10/2026 preservada em color-rig-v2/source.png; prompt em prompts.json. Referências: atlas original da espécie e acabamento Carcará aprovado. prepare.py mede e recorta componentes; build.mjs gera projeto portátil, preview.html com controles, review.png em dois fundos e review-full.png com todos os 116 quadros do atlas de estudo. Montagem 256 × 240, atlas de estudo 12 fps/células 256 px, fontes na resolução original.

Reprodução: Python/Pillow para prepare.py, Node com @napi-rs/canvas para build.mjs (SOULGEN_CANVAS_MODULE pode indicar instalação externa). Rig configurado no Soulgen, aguardando revisão visual do autor. Validação técnica não representa aprovação artística. Sprites, atlas e saves do jogo preservados.

## Revisão 2 — asas do autor

Montagem recebida em flautrevo-flautista-dos-ventos-perdidos.soulgen.json, preservada em author-layout.json. A asa pequena foi removida e substituída pela cópia horizontal da próxima. A cópia recebeu canal próprio em todas as cinco ações, com amplitude igual e sinal angular oposto, mantendo posições, pivôs e inversão do autor. O pivô da cópia está fora do retângulo do corpo, por isso o verificador de socket normalizado não se aplica a essa peça; os testes conferem geometria preservada e movimento espelhado em 121 amostras por ação. Revisão visual feita em poses renderizadas; não é integração ao jogo.

Revisão 3 aprovada pelo autor: posições e escalas individuais finais das duas asas importadas do arquivo (1), preservando as animações sincronizadas.
