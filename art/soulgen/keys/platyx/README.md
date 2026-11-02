# Platyx C — conversão spritelizada para Soulgen

Identidade recuperada de `origin/feature/retalho-bosque-d:art/characters/platyx/exploracao-v3/design-c.png`. A seleção C pelo dono está documentada no README da fonte. Cópia, decisão e hash em `art/soulgen/campaign-redesigns-v1/references/platyx-git/`. A/B e o conceito v2 são alternativas arquivadas, não identidade deste rig.

Conversão com image_gen nativo, mantendo o ornitorrinco-pipa tímido e medroso: cabeça teal larga em losango, olhos castanhos preocupados sobre creme, bico e pés ocres, corpo índigo/creme, braços dobrados junto ao rosto e cauda larga teal/índigo com nó, vareta e duas fitas. Carcará e Tufanocorte usados somente como acabamento: contorno escuro em degraus, sombras em blocos, sem ilustrar novamente em linha fina. Não é garantia de pixel art de grade única.

Sete peças independentes: torso, cabeça, dois braços, dois pés e cauda completa. Sem tubos ou cotos metálicos. Cada uma das três expressões alternativas contém a **cabeça inteira**, no mesmo canvas, não sobreposição só de boca/olhos. A maior área de cada rosto passa a verificação de opacidade em relação à normal. A cauda mantém nó e as duas fitas juntos, sem fio preso ao torso.

Seis ações propostas: respiro tímido, passinho cauteloso (`flight`, ID técnico, não voo canônico), coragem de bico/ataque, esconder o rosto/dano, alívio/vitória e derrota. Ataque em 0,68 s, sem definir dano ou habilidade canônica. Gestos curtos, receosos; não é agressividade de outro monstro aplicada ao Platyx. Movimento por recortes preserva desenho, não equivale ao ciclo de poses redesenhadas da referência anterior.

Abrir: `http://127.0.0.1:5241/?preset=platyx`, ou Projeto e biblioteca → Platyx C. Armazenamento próprio, sem sobrescrever drafts de outros personagens. Projeto portátil, prévia HTML independente, poses, atlas e validação em `cutout-rig-v1/`.

Validação técnica: sete partes, quatro cabeças completas, seis clipes, loops, marcador de impacto, dimensões dos PNGs, fim de derrota, articulações amostradas pelo auditor, 133 frames a 12 fps sem corte nas bordas. Inspecionada prancha de repouso, movimento, ataque, dano e vitória sobre claro/escuro. Mãos, ombros e cauda precisam da avaliação interativa do dono antes da aprovação artística. Não integrado ao jogo, sem mudança de espécie, atributos, aquisição ou história.

Fontes geradas e prompt mantidos, identidade original do Git intacta. `prepare.py` extrai componentes existentes e registra cabeças; `build-rig.mjs` monta e exporta. Depois de uma importação aprovada, o build reexporta o projeto do dono sem resetar encaixes por padrão.
