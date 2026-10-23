# Parque dos Ventos — família oblíqua 2:1

Estudo local de direção de arte e navegação, baseado nas três referências visuais enviadas em 22/10/2026. Elas orientam câmera elevada, leitura dos volumes, cores e densidade; nenhum personagem, cenário ou interface foi extraído delas.

## Direção escolhida

Parque de bairro brasileiro, coreto de telha terracota e madeira azul-petróleo, piso creme, caminhos de terra dourada, árvores verdes e flores coral. Luz no alto à esquerda. Chão contínuo, detalhes concentrados nos jardins. Copas e objetos verticais são sprites próprios para vista elevada; somente o plano do chão recebe a projeção. O movimento não desloca troncos ou bases de postes.

A projeção é dimétrica 2:1: `screenX=(x-y)*0.82`, `screenY=(x+y)*0.41`. Isso apresenta a geometria ortogonal existente em câmera diagonal. Não muda o formato Tiled aceito pela engine, coordenadas dos saves, missões, encontros ou concessão de itens.

## Entrega

- Dez PNGs normalizados, incluindo copa comum e copa com pipas para um único marco do mapa.
- Quatro projetos de rig: árvore, árvore do marco, biruta e bandeirolas. `*.soulgen.json` contém os PNGs incorporados e pode ser aberto pelo Soulgen Studio sem depender de caminhos do servidor.
- Clips `idle` de seis segundos, com começo/fim iguais. Copa: ±0,85°; tecido da biruta: ±2,5°; bandeirolas: escala vertical ±3,5%. Um relógio de vento comum mantém a direção coerente.
- Coreto, banco e flores estáticos. A copa/tronco e o tecido/mastro foram separados na geração, sem deformar o objeto inteiro.
- Escala lógica dos rigs: árvore 300×310, biruta 350×270, bandeirolas 320×130. Filtro linear de alta qualidade. PNGs com alpha; não são pixel art.
- Pivôs globais na base, pivôs de animação na junção da copa ou na fixação do tecido. Colisão continua na base dos objetos, não na silhueta da copa.

## Como revisar

Da raiz do repositório:

```sh
node scripts/preview-park-isometric.mjs
```

Abra `http://127.0.0.1:5241/`. Clique no chão ou use setas/WASD. Há percurso ao coreto, visão geral, pausa do vento e colisões visíveis. A prévia respeita `prefers-reduced-motion` e não acessa contas ou salva progresso.

Reconstrução determinística dos recortes e projetos:

```sh
python scripts/prepare-park-isometric.py
node scripts/build-park-wind-rigs.mjs
node --test world-isometric.test.mjs
```

Python requer Pillow. O script usa as fontes preservadas nesta pasta. `slices.json` registra recortes e dimensões; não confie em uma grade gerada sem conferir os limites. O recorte ignora alpha residual ≤16 apenas para localizar a caixa externa; preserva os pixels internos e adiciona margem transparente. A copa comum passa por ajuste proporcional com Lanczos.

## Origem e limites

`source-atlas.png`: geração original pelo image_gen integrado. `source-canopy-plain.png`: edição da copa para remover pipas e fitas; o atlas original permanece intacto. Os originais mantêm seus metadados. `prompts.json` registra os briefs de geração. Demais PNGs são recortes/normalizações locais dessas fontes, sem download de arte de terceiros.

Esta é uma prévia independente, não substitui o parque no jogo publicado. Kael usa seus sprites atuais em quatro direções: a direção visual é calculada após a projeção, mas ainda não há um novo conjunto de oito vistas. Antes da adoção no jogo: conferir pegadas e zonas de interação por objeto, integrar a câmera à troca de cenas e seguidores e validar HUD/mobile. Não foram medidos FPS nem desempenho em aparelhos reais.

Os avisos `flight/skill/hurt/victory ausente` do validador Soulgen vêm do perfil padrão de criaturas; estes props de cenário têm somente `idle`. Não são erros de rig.
