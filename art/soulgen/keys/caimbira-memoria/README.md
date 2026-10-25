# Caimbira · Vigia das Marés Esquecidas

Jacaré baixo de papel creme e verde-escuro, vista em três quartos à direita, vela de bambu e nós laranja. Anatomia baseada exclusivamente no atlas original do Caimbira; linguagem de papel baseada no Carcará. Fonte gerada com ImageGen, prompt em PROMPT.md.

Oito peças independentes: torso, cabeça, vela, quatro patas e cauda. Raízes sólidas sobrepostas, proporções das fontes preservadas. Sem alterações no atlas do jogo.

Cinco ações: idle (vigia), flight (nado nas correntes), skill (bote), hurt e victory. Expressões registradas apenas na janela dos olhos; alpha e restante da cabeça preservados.

Abrir em http://127.0.0.1:5240/?preset=caimbira-memoria . Projeto portátil em color-rig-v2/caimbira-memoria.portable.soulgen.json.

Reconstrução: prepare.py e build.mjs. Recortes e registro em color-rig-v2/registration.json; prévias em review.png e review-full.png. Exportação com 116 quadros e zero pixels nas bordas. Treze testes passaram, incluindo proporções, pivôs em movimento, fechamento dos ciclos, expressões e carregamento HTTP.

Revisão 2: arquivo aprovado do usuário incorporado integralmente, preservando peças, camadas e animações.
