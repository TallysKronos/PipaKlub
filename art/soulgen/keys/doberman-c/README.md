# Dóber de papel — recorte fiel para o Soulgen

[Abrir no Soulgen](http://127.0.0.1:5240/?preset=doberman-c). Nome provisório, identidade da opção C aprovada.

Versão ativa: **refined-rig-v3**. A revisão 2 permanece arquivada como referência. A imagem enviada pelo autor foi copiada para `source.png`; nenhuma peça foi redesenhada. A tentativa anterior de geração de peças foi rejeitada e não é carregada pelo preset nem pelo jogo.

## Refinamento 3

- Sete peças: torso, cabeça, quatro patas e uma rabiola completa. Fios, nós traseiros e ambas as folhas pertencem à rabiola; o pivô fica no nó do quadril. O trecho de fio que some sob o dorso acompanha a mesma peça. Os tirantes e nós do peito continuam no torso, pois fazem parte da armação.
- Cortes das patas traseiras reposicionados para devolver o flanco ao torso. Bordas das pernas não ficam mais soltas na camada do corpo.
- Limpeza registrada: 15.860 pixels de névoa/alpha fraco distante e 712 pixels de pequenos fragmentos desconectados do torso foram removidos. Os 364.730 pixels restantes mantêm seu RGBA da fonte. A revisão 3 não é apresentada como remontagem integral dos 381.302 pixels da revisão 2.
- Expressões novas de ataque, vitória e dano: geradas com imagegen e registradas somente nas janelas de olhos/boca da cabeça canônica. Alpha idêntico e todos os pixels externos às janelas idênticos. Orelhas, estalactites, nariz e pescoço permanecem na arte canônica.
- Skill usa fierce, vitória usa happy, dano/derrota usam hurt; repouso retorna a normal. Seis ações e 109 frames a 12 FPS.
- O preset arquiva a recuperação antiga no navegador antes de abrir a revisão 3. Recarregue a aba para receber a revisão atual. Salvar o projeto baixa uma cópia portátil; não aplica edição de arte ao jogo automaticamente.

Reprodução da revisão 3: slice-refined.mjs → register-expressions.mjs → build-refined.mjs → review-refined.mjs → tools/soulgen-studio/export-doberman-battle.mjs. A fonte de expressões e o prompt estão em refined-rig-v3/. Os renderizadores usam SOULGEN_CANVAS_MODULE ou @napi-rs/canvas.

Verificado: 12 testes Node de recortes/registro/rig/rotas/amostrador e 18 verificações nativas no Godot, sem falhas. Atlas de combate ativo: combat-doberman-c-soulgen-v3.png. A descrição abaixo registra a revisão 2 e suas limitações originais.

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

### Correção localizada do sorriso · rig 4

A felicidade agora combina os olhos felizes registrados com o sorriso fechado da cabeça canônica. Todos os pixels abaixo da janela dos olhos são os originais, incluindo boca, mandíbula e duas folhas faciais. Isso elimina o conflito da boca aberta com a folha posterior. Os PNGs de repouso, ataque e dano conservaram seus hashes. Cinco testes do preset passaram, incluindo a proteção dos pixels do focinho. O preset arquiva a recuperação antiga e carrega rigRevision 4; artRevision permanece 3. Atlas e prévias reexportados.
