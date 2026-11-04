# Tufanocorte — Soulgen cutout v1

Quarto e último guardião escolhido deste lote. Identidade: carneiro A da montanha, duas espirais de seda cortante, paleta jade/azul-marinho/marfim/ocre/coral e duas rabiolas.

Atualização aprovada pelo dono: recebido `tufanocorte-guardiao-da-montanha.soulgen.json`, preservado integralmente em `author-approved.portable.soulgen.json`. Incorporados cabeça, pivôs dos chifres e animações editadas. Revisão de rig 2; hash e normalizações em `author-import.json`. O build reexporta o projeto aprovado por padrão sem recalcular a montagem inicial.

Contrato de peças: torso limpo, cabeça, quatro patas com cascos fendidos, dois chifres completos com centros vazados e duas rabiolas completas. Chifres se articulam com a cabeça; rabiolas com o quadril. Não incorporar metade de um apêndice no torso para facilitar a montagem.

Direção de movimento: repouso firme e pequenas compensações na crina/cabeça; passo pesado contido; preparação do golpe recua e baixa a cabeça antes de avançar para a esquerda; dano e vitória recuperam postura; derrota sustenta a pose final. As espirais não giram continuamente como peças mecânicas.

Fontes e prompts preservados em `cutout-rig-v1/`. Produção local, sem integração em jogo. Acabamento híbrido de contorno Carcará, não uma garantia de grade nativa estrita de pixel art. Efeitos de vento/corte são uma camada posterior, não parte permanente da pintura dos membros.

## Entrega para revisão

- Soulgen: `http://127.0.0.1:5241/?preset=tufanocorte`.
- Dez peças, quatro rostos e seis ações. Projeto editável e cópia portátil em `cutout-rig-v1/`.
- Repouso 3,2 s; passo 1,6 s; investida 1,9 s (impacto em 0,8 s); dano 0,9 s; vitória 2,5 s; derrota 1,2 s.
- Atlas de estudo com 142 frames a 12 fps, sem tocar bordas; GIF de cada ação e prévia HTML independente.

Reprodução: `slice.py` e `register-faces.py` (Pillow, numpy e OpenCV), `build-rig.mjs` e `review-poses.mjs` (`@napi-rs/canvas` ou `SOULGEN_CANVAS_MODULE`), depois `node --test art/soulgen/keys/tufanocorte/rig.test.mjs`.

Revisados fontes, recortes, montagem, janelas faciais, fundos claro/escuro e extremos de movimento. Corrigido registro das expressões: cabeças ocupavam coordenadas diferentes das divisões iguais da folha. O chifre distante usa espelhamento visual em torno do próprio pivô para compor a silhueta de duas espirais, sem alterar seu PNG original. Os chifres acompanham a cabeça pelo parentesco; o fio da rabiola não fica preso na pintura do torso.

Navegador automatizado local indisponível nas configurações do app; não foi declarado playtest visual interativo. As fitas e espirais são partes inteiras articuladas, sem deformação por malha. Aprovação artística final da montagem e eventuais ajustes manuais ficam com o dono, como nas três criaturas anteriores.
