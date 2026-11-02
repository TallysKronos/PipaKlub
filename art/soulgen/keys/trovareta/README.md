# Trovareta — Soulgen cutout v1

Primeira dos quatro guardiões, executada antes das demais conforme pedido do dono.

- Preset local: `http://127.0.0.1:5241/?preset=trovareta`.
- Oito peças: torso, cabeça, asa próxima/distante, pata próxima/distante, duas rabiolas inteiras com seus fios e nós.
- Expressões: neutra, ataque, dano e vitória. O alpha e os pixels externos à janela do olho são idênticos à cabeça canônica.
- Seis ações: repouso (2,8 s), voo (1,15 s), ataque (1,65 s, impacto 0,65 s), dano (0,8 s), vitória (2,2 s) e derrota (1,1 s).
- Projeto editável: `cutout-rig-v1/trovareta.soulgen.json`; cópia portátil com PNGs embutidos ao lado.
- Fontes, prompts, atlas de estudo de 123 frames e prévia independente preservados em `cutout-rig-v1/`.

## Reprodução

1. `python art/soulgen/keys/trovareta/slice.py` (Pillow).
2. `python art/soulgen/keys/trovareta/register-faces.py`.
3. `node art/soulgen/keys/trovareta/build-rig.mjs` com `@napi-rs/canvas` instalado ou `SOULGEN_CANVAS_MODULE` apontando para sua instalação.
4. `node --test art/soulgen/keys/trovareta/rig.test.mjs`.

Não há alteração de código/atlas do jogo. Os movimentos usam o sampler/renderizador real do Soulgen. Os pivôs estão medidos nas raízes; o relatório de encaixe acompanha pontos de articulação, não detecta sozinho fendas na pintura.

## Revisão feita

Inspeção das oito peças, composição montada, estados faciais e atlas com os seis movimentos. Corrigidos fragmentos da rabiola vizinha no recorte e posição do pescoço. Verificação de estrutura e juntas sem avisos; 123 frames exportados sem tocar a borda das células. Testes existentes de modelo, fluxo e servidor: 17 passaram.

O navegador automatizado não pôde ser operado: a ferramenta retornou “Local browser use is disabled in Work settings”. A integração de botão/preset foi conferida no código; reprodução visual em tempo real pelo navegador não foi declarada como testada. Fontes possuem alpha parcial e o renderer colorido mantém sua amostragem atual; não são sprites de grade nativa estrita.

Descargas elétricas e som de trovão não estão implementados neste rig. A ação de ataque contém preparação, batida e recuperação; efeitos podem ser adicionados separadamente, presos às pontas das asas, sem pintar raios permanentes no corpo.
