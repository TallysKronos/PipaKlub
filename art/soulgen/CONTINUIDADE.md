# Pausa da conversão de Pipamons — 25/10/2026

Herravento foi aprovado no arquivo `herravento-cacador-das-rajadas.soulgen.json`. A revisão 2 preserva integralmente partes, profundidades, transformações, pivôs, animações e assets do arquivo enviado. A revisão aprovada está em `keys/herravento/approved-layout.json`; o projeto portátil e as fontes ficam em `keys/herravento/color-rig-v2/`.

A fila foi pausada por solicitação do responsável para retomar a migração Godot/Steam na PIP-60. Não gerar a próxima criatura automaticamente durante esse trabalho.

## Retomar daqui

Próximo: **Platofolha**, depois **Celofita**, **Riovela** e **Javali de Biscoito**. São quatro pendentes da Dex; 32 dos 36 têm rig. Conceitos fora da Dex não aprovados continuam fora desta contagem. Consultar `pendentes/inventario.json` e as fichas antes de retomar.

Padrão: identidade/anatomia da própria espécie, acabamento Carcará, três quartos à direita, papel fosco com dobras/varetas/nós, sem encaixes ocos. Manter proporção das fontes nas novas montagens. Expressões alteram somente janelas registradas do rosto. Depois de edição do usuário, preservar todas as medidas e animações exatamente como enviadas, incluindo inversões e camadas.

Soulgen local: porta 5240, preset `herravento`. Servidor: `node tools/soulgen-studio/server.mjs`. Exportar PNGs e projeto portátil não integra automaticamente ao atlas do jogo nem ao Godot.

## Nova frente

PIP-60: https://linear.app/pipaklub/issue/PIP-60/migrar-pipaklub-para-steam-com-campanha-offline-e-online-opcional

Responsável escolheu seguir pelo Godot. Campanha offline e online opcional. O protótipo atual de Veredas ilustradas ainda não contém a campanha, Oficina, combate ou save completo.
