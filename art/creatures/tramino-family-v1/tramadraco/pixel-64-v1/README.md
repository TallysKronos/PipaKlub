# Tramadraco — piloto pixel art 64×64

Interpretação desenhada em pixels no Aseprite, a partir do concept-v3 aprovado. Não é redução automática do concept. Rosto protegido pelo elmo de dragão e viseira fechada; armadura índigo/marfim, cristal de pipa âmbar, bordas douradas, capa rasgada e espada com rabiola.

## Escopo

- Canvas nativo: 64×64 px; uma vista três-quartos voltada à direita.
- 8 frames de **idle**, ciclo de 1.200 ms, tag `idle-se`.
- 11 camadas: capa, duas pernas, torso, dois braços, ombreira próxima, helmet, cristal, espada e rabiola da espada.
- Luz superior esquerda, paleta limitada a 14 cores e transparência binária.
- Preview ampliado 6× por nearest-neighbor. Não integrado ao jogo.

A cabeça mantém olhos estreitos e viseira. Foram simplificadas as pequenas subdivisões da armadura, a espessura da espada e os rasgos menores da capa. O formato integral da capa e as bordas largas sobrevivem; costuras e microfacetas não cabem nessa escala.

## Arquivos

- `tramadraco-64.aseprite`: fonte editável.
- `tramadraco-64.png`: pose nativa 64×64.
- `preview-6x.png` / `preview-6x.gif`: leitura ampliada.
- `tramadraco-idle.png` / `.json`: spritesheet e atlas com tempos.
- `validacao.json`: medição de dimensões, cores, alpha e frames.
- `PixelSpec.json`: partes desenhadas e direção do piloto.

Caminhada e demais direções ainda não produzidas. A revisão deste piloto não representa aprovação visual pelo autor nem validação de pivô/collision no jogo.
