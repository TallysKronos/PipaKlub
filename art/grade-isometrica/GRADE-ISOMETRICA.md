# Grade isométrica do PipaKlub

Versão completa (com tabelas, modelos de pedido, manifesto e critérios de reprovação): [`especificacao.html`](especificacao.html).

Regra para cenários e móveis isométricos (casa e quarto do Kael, Parque dos Ventos e os próximos). Vale para quem desenha ou gera arte (GPT, Codex, artista) e para quem integra. Proposta de 23/10/2026; os itens com ⚑ precisam de aprovação.

## Por que o quarto saiu desalinhado

Diagnóstico da prova enviada, com a grade 2:1 sobreposta e as linhas de referência em vermelho: [`diagnostico.png`](diagnostico.png).

O piso e as paredes estão quase certos (26–27°, próximo da razão 2:1). Os problemas estão nos objetos:

1. **Cama:** o pé está mais achatado que 2:1 e a lateral mais íngreme. A cama foi girada em relação ao quarto.
2. **Guarda-roupa:** desenhado quase de frente; a borda do tampo é quase horizontal.
3. **Mesa:** câmera mais baixa, com a frente achatada. Também invade a linha da parede.
4. **Estante, TV e baú:** quase de frente. O baú flutua atrás da estante, sem contato com o piso.
5. **Janela:** desenhada de frente, em pé, em vez de deitada no plano da parede (as bordas horizontais deveriam seguir a inclinação da parede).
6. **Quadros:** idem, só que na parede direita.
7. **Abertura da escada e corrimão:** fora da grade, e o corrimão em outro ângulo.
8. **Medidas do quarto:** cerca de 10 × 7,4 células. Nenhuma medida fecha em células inteiras, nem as tábuas do piso.

Também há diferença de pixel entre as peças (o guarda-roupa e a estante parecem ampliados e borrados) e de espessura de contorno.

**Causa:** um gerador de imagem monta a cena inteira de uma vez e escolhe uma câmera para cada objeto. Não existe nele uma grade a respeitar. Pedir "isométrico" não basta: geradores costumam usar o isométrico verdadeiro (30°) ou perspectiva, e não o 2:1 dos jogos.

## A regra

1. **Uma projeção só: 2:1 (dimétrica, cerca de 26,57°).** Toda aresta "horizontal" no chão ou na parede anda 2 px na horizontal para cada 1 px na vertical. Arestas verticais ficam sempre verticais. Nada de 30°, ponto de fuga ou vista de frente.
2. **Célula de piso de 64 × 32 px** na escala nativa do cenário. **Uma célula de altura = 32 px ≈ 50 cm.** Tudo é medido em células.
3. **Medidas inteiras.** Cômodos, pegadas de móveis e aberturas usam células inteiras; meia célula só para objetos pequenos. Quarto do Kael proposto: 10 × 8 células e paredes de 5 (2,5 m). ⚑
4. **Pegada e âncora.** Cada objeto declara sua pegada (largura × profundidade em células) e sua altura. A **âncora** é o canto frontal da pegada (o ponto mais baixo na tela). Ela posiciona o PNG na grade e define a ordem de profundidade, como no `depthOrder` de `src/world-isometric.js`.
5. **Contato.** Móvel encostado na parede tem a face de trás exatamente na linha da parede, e os pés tocam o piso. Nada flutua, nada atravessa parede.
6. **Objetos de parede** (janela, porta, quadro, prateleira) são paralelogramos deitados no plano da parede: as bordas horizontais seguem a inclinação 2:1 daquela parede.
7. **Uma escala de pixel e uma luz.** Nenhuma peça é ampliada ou reduzida depois de pronta. Mesmo contorno (azul-escuro, `WORLD-ART-DIRECTION.md`) e mesma luz em tudo. ⚑ Proposta: luz da esquerda, face esquerda clara e face direita escura.
8. **Medidas de referência** (com Kael de 1,6 m ≈ 3,2 células, cerca de 102 px):

   | Objeto | Pegada | Altura |
   |---|---|---|
   | Cama de solteiro | 2 × 4 | 1 (cabeceira 2) |
   | Estante de TV | 3 × 1 | 1,3 |
   | Guarda-roupa | 2 × 1 | 4 |
   | Mesa de trabalho | 3 × 2 | 1,5 |
   | Porta | 2 de largura | 4 |
   | Janela | 2 × 1,5, com a base a 2 células do piso | — |

## Como produzir com IA sem perder a grade

O mais confiável é **montar por peças, não pedir a cena pronta.**

1. **Casca do cômodo:** piso e paredes vazios, gerados sobre [`chapa-guia-vazia.png`](chapa-guia-vazia.png) ou desenhados por tiles de 64 × 32. Sem móveis.
2. **Cada móvel em um PNG transparente, separado.** O pedido leva a pegada e a altura da tabela e, como referência, a caixa do móvel recortada de [`chapa-guia.png`](chapa-guia.png). Assim o gerador copia o ângulo da caixa.
3. **A montagem é feita pelo jogo ou pelo Tiled**, colocando a âncora de cada peça na célula certa. Nunca numa imagem só, pintada pelo gerador. Isso também permite reaproveitar os móveis e ordenar a profundidade com o personagem andando entre eles.
4. **Conferência:** sobrepor a grade a cada peça e à cena montada ([`chapa_guia.py`](chapa_guia.py) gera as chapas). Reprovar quando uma aresta desviar mais de 1 px a cada 32 px da razão 2:1, quando a âncora estiver fora da célula ou quando houver objeto flutuando.

Se ainda quiser uma imagem única: mande a `chapa-guia.png` como referência de composição e peça para "manter exatamente as caixas, ângulos e posições da imagem de referência". Mesmo assim, confira por sobreposição; o gerador tende a girar peças.

### Modelo de pedido para o GPT (um móvel por vez)

> Pixel art de jogo, projeção dimétrica 2:1 (cada aresta horizontal sobe 1 px a cada 2 px; verticais retas; sem perspectiva, sem 30°). Um único objeto: **guarda-roupa de madeira com portas azul-petróleo**, pegada de 2 × 1 células, altura de 4 células, sendo cada célula do piso um losango de 64 × 32 px e cada célula de altura 32 px. Encaixe exatamente na caixa da imagem de referência: mesmo ângulo, mesma largura e mesma altura. Fundo transparente, sem sombra no chão, sem piso, sem outros objetos. Contorno azul-escuro de 1 px, luz vinda da esquerda (face esquerda clara, direita escura), paleta do jogo: reboco creme, terracota, azul-petróleo e madeira mel.

## Relação com o código ⚑

`src/world-isometric.js` projeta com `toIso = (x−y)·0,82 , (x+y)·0,41`. A razão é 2:1, mas um tile de 32 do mapa vira um losango de **52,48 × 26,24 px**, sem pixel inteiro, o que borra pixel art e não fecha com uma arte desenhada em 64 × 32. Duas saídas:

- **Recomendado:** mudar a projeção para `(x−y)·1 , (x+y)·0,5`. Um tile de 32 vira exatamente 64 × 32, e a arte nova segue esta regra. É preciso rever a escala do Parque dos Ventos, que hoje usa 0,82.
- Ou manter 0,82 e definir a célula da arte em 52 × 26. Isso é pior para pixel art.

As colisões continuam no mapa ortogonal do Tiled, como hoje. A grade de arte só define onde e como cada peça é desenhada.

## Ferramenta

O [Iso Studio](../../tools/iso-studio/README.md) (`npm run studio:iso`) gera a caixa de referência e o pedido de cada peça, encaixa o PNG gerado, confere as regras automaticamente e exporta a entrega com o manifesto.

## Fontes

- Razão 2:1 e tamanhos de tile: [Slynyrd, Pixelblog 41](https://slynyrd.com/blog/2022/11/28/pixelblog-41-isometric-pixel-art), [Sprite-AI](https://www.sprite-ai.art/guides/isometric-pixel-art), [Construct](https://www.construct.net/en/tutorials/creating-isometric-pixel-art-355/page-6), [Clip Studio, quarto isométrico em pixel art](https://tips.clip-studio.com/fr-fr/articles/4969?org=1).
- Pegada, âncora e profundidade: [Construct, ordem de objetos isométricos](https://construct.net/en/tutorials/isometric-games-object-layer-1321), [fórum do Tiled sobre profundidade](https://discourse.mapeditor.org/t/isometric-depth-sorting/736/2), [fórum do Godot sobre Y-sort](https://forum.godotengine.org/t/alternatives-to-y-sort-or-better-workflow-for-2d-depth-sorting-of-many-objects/133561).
- Tiled isométrico (altura do tile, alinhamento de objetos): [devlog do Tiled](https://thorbjorn.itch.io/tiled/devlog/120663/tinting-alignment-and-object-references), [fórum do Tiled](https://discourse.mapeditor.org/t/problem-aligning-tiles-in-an-isometric-map/989).
- IA com grade (referência de estrutura, ângulo fixo, isométrico verdadeiro × 2:1): [Scenario, tiles isométricos](https://www.scenario.com/blog/build-isometric-game-tiles-with-ai), [Layer](https://help.layer.ai/en/articles/12055377-how-to-forge-consistent-isometric-game-assets), [Scenario, esboço para assets](https://help.scenario.com/articles/4330764997-turning-sketches-into-cohesive-isometric-assets).
