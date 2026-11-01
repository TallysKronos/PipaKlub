# Dóber de papel — recorte fiel para o Soulgen

[Abrir no Soulgen](http://127.0.0.1:5240/?preset=doberman-c). Nome provisório, identidade da opção C aprovada.

Versão ativa: **sliced-rig-v2**. A imagem enviada pelo autor foi copiada para `source.png`; nenhuma peça foi redesenhada. A tentativa anterior de geração de peças foi rejeitada e não é carregada pelo preset nem pelo jogo.

## Análise da imagem e recortes

A silhueta é alta e estreita, com duas orelhas de vela, focinho longo, estalactites faciais, peito losangular, quatro patas em planos distintos e duas velas de rabiola conectadas por linhas. O corpo inclinado e as patas afastadas já definem a perspectiva. Reposicionar as peças por proporções estimadas alterava essa construção; nesta versão cada recorte conserva suas coordenadas originais.

- **Cabeça e pescoço:** orelhas e face permanecem na mesma peça, evitando encurtamento, troca de lado e perda das estalactites. O corte inferior passa acima do losango; nós e tirantes pertencem ao corpo.
- **Tronco:** preserva peito, armação, linhas de ligação e os pixels que não pertencem às peças móveis. Não recebe círculos de articulação inventados.
- **Quatro patas:** separadas pelos contornos visíveis, com pivôs nas transições de ombro/quadril. A pata traseira distante tem apenas a porção exposta no desenho; não existe uma coxa completa escondida na fonte.
- **Duas velas da rabiola:** folhas separadas no ponto de encontro junto ao nó; a linha que volta ao dorso permanece no tronco. Os pontos de rotação das duas folhas são próximos, mas independentes.

São máscaras poligonais disjuntas, sem suavização adicional, repintura, alteração de cor, aumento das peças ou limpeza automática do alpha. A imagem original já contém franjas semitransparentes; foram preservadas, não apresentadas como alpha limpo.

`slices.json` registra os polígonos, retângulos e pivôs em pixels da fonte. `reassembled.png` recoloca as peças em suas coordenadas. Verificação por RGBA: **381.302 pixels visíveis, zero pixels alterados, zero ausentes e zero duplicados**. Essa verificação da remontagem não prova que existam superfícies ocultas para grandes rotações.

## Rig e movimento

Oito peças editáveis, seis ações: repouso, voo, habilidade, dano, vitória e derrota. 109 frames amostrados a 12 FPS. Movimentos locais contidos: cabeça até 2°, patas até 2°, rabiolas até 6°. O bote combina antecipação, avanço e recuperação pelo pivô global. Não simula uma corrida completa, pois exigiria reconstruir áreas que a fonte não mostra. A montagem neutra não altera o desenho. O arquivo portátil incorpora todos os PNGs.

A prévia `preview.html` permite alternar ações e velocidade; `animations.gif` mostra as seis ações. `parts-review.png` mostra os recortes. Atlas de combate Godot: `combat-doberman-c-soulgen-v2.png`, com fonte registrada em content.json. Repouso, deslocamento, ataque, dano, vitória e derrota usam os clipes; pausa congela o tempo e ações únicas não reiniciam por módulo de frame. Os sprites da montaria com Kael permanecem completos e independentes.

## Reproduzir

1. `node art/soulgen/keys/doberman-c/slice.mjs`
2. `node art/soulgen/keys/doberman-c/build-sliced.mjs`
3. `node art/soulgen/keys/doberman-c/review-sliced.mjs`
4. `node tools/soulgen-studio/export-doberman-battle.mjs`

Os passos de renderização usam @napi-rs/canvas; `SOULGEN_CANVAS_MODULE` pode indicar a instalação local. A exportação do atlas é explícita; baixar um projeto editado no Soulgen não sobrescreve o jogo automaticamente.

Validação: testes de fidelidade RGBA, dimensões, hierarquia, encaixes, projeto portátil, rotas e recuperação independente; 18 verificações nativas de equipe, HP e reprodução de ações. Aprovação artística do recorte e dos movimentos ainda cabe ao autor.
