# Araruna · Asa das Lembranças

Novo rig em três quartos para a direita, baseado no atlas original da Araruna e na linguagem de papel do Carcará. Fonte gerada com ImageGen; prompt preservado em PROMPT.md. Sem alterações no atlas utilizado pelo jogo.

Seis peças editáveis: cabeça e peito, duas asas, duas garras e rabiola. Proporções das imagens preservadas. Expressões de ataque, dano e vitória aplicadas apenas na janela dos olhos, mantendo o alpha e o restante do corpo.

Cinco ações: idle, flight, skill, hurt e victory. Os ciclos fecham e as ações retornam à pose neutra. Exportação: 116 quadros, sem pixels nas bordas das células.

Abrir: http://127.0.0.1:5240/?preset=araruna-memoria

Projeto portátil: color-rig-v2/araruna-memoria.portable.soulgen.json. Reconstrução: prepare.py e build.mjs. Revisão visual em review.png e sequência completa em review-full.png.

Verificação: testes de pivôs, encaixes, proporções, expressões, limites em movimento, carregamento e exportação. Pendente aprovação visual do usuário no Soulgen.

A fonte gerada chega à borda inferior nas cópias de expressão; somente a área dos olhos dessas cópias é utilizada. O corpo canônico e as peças independentes possuem margem transparente na fonte.

Revisão 2: incorporado integralmente o arquivo aprovado `araruna-asa-das-lembrancas.soulgen.json`, preservando geometria, camadas e animações. Limites verificados pelo alpha real da exportação, pois cantos transparentes de peças giradas podem ultrapassar o quadro.
