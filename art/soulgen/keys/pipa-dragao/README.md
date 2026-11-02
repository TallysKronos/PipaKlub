# Pipa-Dragão — forma sobrecarregada

Conversão para o Soulgen da identidade químico B escolhida pelo autor, recuperada do Git. Fonte: `art/soulgen/campaign-redesigns-v1/references/pipa-dragao-git/prancha.png`; commit e hash no `source-lock.json` dessa pasta. Esta é a forma grande anterior ao desatar dos nós, não uma espécie nova. Preservados corpo pesado cinza-lilás manchado, espinhos escuros, peitoral ocre, tubos verdes no torso, equipamento dorsal e rabiola com amarrações.

Abrir: http://127.0.0.1:5241/?preset=pipa-dragao

Oito peças independentes: torso, cabeça, quatro membros, rabiola completa e conjunto dorsal. Quatro cabeças completas (normal, ataque, dano e vitória serena). Seis clipes técnicos: idle, deslocamento, investida, dano, vitória e derrota. Estes clipes não determinam comportamento, dano, atributos ou resultado do encontro roteirizado.

Arte gerada com image_gen em `cutout-rig-v1/source.png`; acabamento orientado pelo Carcará e pela desatada já aprovada. `prepare.py` apenas extrai componentes alpha e registra cabeças inteiras. `build-rig.mjs` monta pivôs e exporta revisão, atlas a 12 fps e projeto portátil. Não há bocas isoladas substituindo o rosto nem tubos cortados nas raízes dos membros. A braçadeira do membro próximo é fechada e pertence ao conceito original.

145 frames sem pixels tocando as bordas. Validação de estrutura, articulações e expressões; poses renderizadas inspecionadas em fundo claro/escuro. Aprovação artística e conferência interativa do movimento ainda pendentes. A forma desatada e suas edições do autor permanecem independentes. Sem alterações de runtime, história, menus ou encontros.
