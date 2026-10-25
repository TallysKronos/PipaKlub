# Guaravento · Vigia das Rajadas

Rig em três quartos, com acabamento artesanal baseado no Carcará aprovado. Oito peças: tronco, cabeça/juba, quatro pernas, vela e rabiola. Cinco ações com expressões: vigia ao vento, corrente de ar, rajada guardiã, recuo e orgulho do vigia.

Studio: http://127.0.0.1:5240/?preset=guaravento

Conceito e peças gerados com ImageGen em 25/10/2026, usando o Guaravento original e a direção do Carcará. Fontes preservadas em color-rig-v2/concept.png e source.png, prompts em prompts.json. prepare.py normaliza recortes e registra expressões sobre o alpha canônico. build.mjs gera projeto portátil, prévia HTML com controles, review.png (fundos claro/escuro), review-full.png (todos os quadros) e atlas de estudo de 116 quadros.

Reprodução: Python/Pillow para prepare.py; Node e @napi-rs/canvas para build.mjs (SOULGEN_CANVAS_MODULE aceita instalação externa). As validações técnicas não equivalem à aprovação visual do autor. Atlas do jogo preservado; integração ao jogo pendente.
