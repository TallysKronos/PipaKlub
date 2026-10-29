# Estilo de pixel dos personagens (Soulmonsters)

Regras para desenhar e animar os personagens do overworld (48×64, mapa isométrico 2:1) no acabamento mangá + Splatoon. A seção "Fontes" lista a pesquisa que embasa estas regras. O que dá para medir, o `check` mede. O resto fica com quem revisa.

## Precisa treinar a ferramenta?

Não é preciso treinar um modelo. O pixelgen não gera imagem por IA: quem desenha é o agente, por operações. O "treino" que ele precisa tem três partes, e todas já estão no código:

1. **Regras escritas**: este arquivo e o `AGENTS.md`.
2. **Uma ficha por personagem** (`sheet`): altura, cabeças, linha dos pés, limite de cores e rampas obrigatórias. É ela que mantém o mesmo personagem igual nas 8 direções e em todos os movimentos.
3. **Conferências automáticas** (`check`): contorno, contraste com os chãos, proporção contra a ficha, pé que desliza e cores fora das rampas.

O que ainda falta é uma **biblioteca de poses aprovadas**: um personagem de referência com idle, walk e run nas 8 direções, aprovado pelo responsável, que os agentes copiam como gabarito. É o próximo passo útil, e depende de desenhar e aprovar o primeiro personagem completo.

## Proporção

- Figura de **52 a 56 px** de altura num quadro de 64, com os pés na linha 61 (2 px de margem embaixo).
- **2,5 cabeças** de altura: a cabeça tem cerca de 21 px. Fica entre o chibi (2 cabeças, rosto grande) e o RPG clássico (3 cabeças), e sobra espaço para olhos de mangá.
- Mãos e pés pequenos, de 2 a 3 px. Braço de ombro a mão com cerca de 10 px, perna de quadril a pé com cerca de 16 px.
- O mesmo personagem tem a **mesma cabeça (±1 px)** em todas as direções. Braço e perna só encurtam por perspectiva, nas vistas S e N e nas diagonais.

## Silhueta e contorno

- **A pose precisa ler só pela silhueta preta** (`render --silhouette`). Braços e pernas se separam do tronco. Se a silhueta preenche mais de ~75% da caixa, ela vira um bloco.
- **Contorno escuro em pelo menos 70% da borda**, com a cor `tinta`, que é um azul-escuro e não preto puro. Isso é o "traço de mangá".
- **Selout** (contorno seletivo) por dentro: onde uma parte encosta em outra, a borda usa o tom mais escuro da rampa da própria parte, não a tinta. Quando a parte de trás encosta na da frente, a linha interna fica com a cor da parte mais próxima de quem olha.
- **Linhas de 1 px sem pixel dobrado** nas quinas (a op `line` já faz isso). Degraus de diagonal regulares (1-1, 2-2, 2-1-2), sem degrau solto.
- Evite pixel isolado e "ruído": no 1× o detalhe some. Olho é 2×2 ou 1×2 com brilho de 1 px.

## Cor e luz

- **De 3 a 5 tons por material**, do escuro para o claro, numa rampa nomeada (`pele`, `cabelo`, `roupa`, `tinta`).
- **Hue shift**: o tom escuro puxa para frio (azul ou violeta) e o claro para quente (amarelo). Não basta escurecer a mesma cor. O preto puro só aparece em detalhe, nunca como sombra.
- **Brilho de Splatoon**: no máximo um brilho por material (cabelo, tênis, plástico), de 1 a 3 px, no tom mais claro. A cor de tinta do personagem (o acento) aparece em uma ou duas peças.
- **No máximo 16 cores por personagem**, contornos incluídos (`sheet --set cores=16`).
- **A luz vem de cima à esquerda.** Sombra embaixo e à direita, com **cel shading** em blocos de 2 a 3 tons, sem gradiente nem dithering na figura.
- **Proibido o pillow shading**, aquele em que a sombra contorna a forma por igual e o claro fica no centro.
- Nas vistas espelhadas (O, NO, SO) a luz troca de lado. Isso é aceitável no overworld. Nos personagens principais, redesenhe a sombra se ela incomodar.
- **Contraste com o chão**: a borda precisa se destacar na grama, na terra e na calçada (o `check` reprova). A noite dá aviso: use um realce de luz na borda de cima.

## Animação

Tempos de referência do jogo:

| Movimento | Quadros | Tempo | Estrutura |
| --- | --- | --- | --- |
| idle | 2 | 700 e 350 ms | respirar: tronco, cabeça e braços descem 1 px, pés parados |
| walk | 4 | 140/110/140/110 ms | contato, passagem (corpo sobe 1 px), contato espelhado, passagem |
| run | 6 | 6×90 ms | inclinado 1 px para a frente, passada maior, voo com o corpo 2 px acima |

- **1 px de sobe e desce** por passo já dá peso ao personagem. Sem esse movimento ele parece colado no chão.
- **Braço oposto à perna**: a perna da frente avança e o braço da frente recua. Com o braço duro a caminhada fica robótica.
- **O pé apoiado não desliza.** Num ciclo no lugar, o pé no chão anda para trás na mesma velocidade em todos os quadros. O `check` avisa quando a diferença passa de 1 px. No idle ele não se mexe.
- **Vistas de frente e de costas (S, N)**: o pé que se afasta da câmera sobe 1 px e o que vem para a frente fica na linha de base. Nunca desça abaixo da base.
- **Diagonais**: metade do avanço vira profundidade (sobe ao se afastar).
- **Cabeça estável**: no máximo 1 px de deslocamento por quadro na caminhada. A cabeça não muda de forma entre quadros.

## Direções e reaproveitamento

- 8 direções: `S SO O NO N NE E SE`. Desenhe primeiro **S, E e N**, depois **SE e NE**. **O, SO e NO** saem por espelho e depois têm os detalhes assimétricos corrigidos.
- Mesma linha de pés, mesma altura e mesma cabeça em todas as direções. A ficha garante isso.
- Uma camada por parte: `Perna de trás`, `Perna da frente`, `Braço de trás`, `Tronco`, `Braço da frente`, `Cabeça` e `Cabelo`. É o que permite às receitas animarem sozinhas.

## Fontes

- Ciclo de 4 quadros (dois contatos e duas passagens), ordem 1-2-3-4-3-2 e arco de braços: [pixel art walk cycle animation (itch.io)](https://itch.io/blog/526535/pixel-art-walk-cycle-animation), [walk animation template (OpenGameArt)](https://opengameart.org/content/walk-animation-template), [walk cycle (PixelPad)](https://pixelpadpro.pages.dev/walk-cycle.html) e [How to Make a Run Cycle in Pixel Art](https://medium.com/@thomaspalef/how-to-make-a-run-cycle-in-pixel-art-e72fb9c0b812).
- Selout e contorno colorido: [pixel tutorial: selective outlines (itch.io)](https://itch.io/t/2422252/pixel-tutorial-selective-outlines) e [pixel art outlines part 2 (Lospec)](https://lospec.com/articles/pixel-art-outlines-part-2-using-color).
- Rampas e hue shift: [Pixelblog 1: Color Palettes (Slynyrd)](https://www.slynyrd.com/blog/2018/1/10/pixelblog-1-color-palettes), [Color Palettes (gamedev.net)](https://gamedev.net/tutorials/visual-arts/color-palettes-r4964), [Some insights about pixel art color ramps](https://lpc.opengameart.org/node/20643) e [Pixel Art fundamentals](https://caioraphael1.github.io/studies/Art/Pixel%20Art/Pixel%20Art-fundamentals.html).
- Pillow shading, banding, pixel dobrado e excesso de detalhe: [Pixel art mistakes (PixelPad)](https://pixelpadpro.pages.dev/pixel-art-mistakes.html), [Pixel art terms: pillow shading](https://3dbrendang.blogspot.com/2013/11/pixel-art-terms-linguo-techniques-part-2.html), [TU Delft: banding e pillow shading](https://repository.tudelft.nl/file/File_65d43acd-9779-4eab-999b-9bcd4f0a96a9) e [Pixel Art Tutorial (Android Arts)](https://www.androidarts.com/pixtut/pixelart.htm).
- Proporção em sprites pequenos (2 a 3 cabeças): [How to Draw Pixel Art Characters (Pixnote)](https://pixnote.net/en/learn/character), [Pixel-art people](https://blakecrosley.com/blog/pixel-art-characters-on-iphone) e [How to make Chrono Trigger sprites](https://sozai.app/transcript/make-chrono-trigger-sprites-pixel-art/).
- 8 direções, custo e 2:1 isométrico: [Isometric pixel art guide](https://www.sprite-ai.art/guides/isometric-pixel-art), [Pixelblog 55: Top Down Character Animation (Slynyrd)](https://slynyrd.com/blog/2025/3/24/pixelblog-55-top-down-character-animation) e [8-direction pixel character base](https://mediart.itch.io/8-direction-pixel-character-base).

Os sites slynyrd.com e lospec.com estão fora da rede liberada desta sessão. Por isso, das páginas deles só entrou o resumo da busca.
