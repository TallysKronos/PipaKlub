# Retalho original — rig em revisão

**Revisão atual: [cutout-rig-v2/README.md](cutout-rig-v2/README.md).** O preset abre a v2 spritelizada com cabeças completas. O registro abaixo descreve somente a v1 preservada.

Identidade: opção A aprovada da antiga parceira de Heleana, registrada em `art/soulgen/campaign-redesigns-v1/retalho-decisoes.md`. Esta forma **não** é a Retalho mascarada/evoluída do roteiro atual. A escolha do dono pela original foi preservada, sem incorporar possessão ou trocar cronologia.

Arte de partes gerada com image_gen usando `retalho-original-reference.png` como identidade e `references/carcara.png` como referência de contorno. Duas gerações: primeira folha preservada em `source-inicial.png`, correção de margens em `source.png`. Sete partes: torso, cabeça, dois braços, duas pernas, rabiola completa incluindo nó/cordão. Quatro rostos (normal, ataque, dano, vitória). Somente janelas do rosto mudam; alpha e desenho externo da cabeça são idênticos para não deformar orelhas.

Seis ações propostas: vigília, passo suspenso, corte da vela, recuo, vitória, derrota. Impacto proposto do golpe em 0,72 s; sem habilidade ou dano canônico. 135 frames a 12 fps, atlas sem pixels cortados na borda. Validação técnica não é aprovação dos encaixes pelo dono. Pescoço, ombros, profundidade dos braços e registro das expressões ainda precisam da revisão interativa; não está integrado ao jogo.

Abrir: `http://127.0.0.1:5241/?preset=retalho-original`. Projeto portátil e prévia independente em `cutout-rig-v1/`. O preset tem armazenamento separado e não sobrescreve os quatro guardiões.

`prepare.py` apenas recorta e registra pixels existentes; `build-rig.mjs` monta e exporta. Não reconstrói arte por código. Originais aprovados e fontes geradas foram mantidos.
