# Rabbito — piloto de caminhada em pixel art

Criado em 2026-11-04 como teste do estilo de spritesheet enviado pelo autor. A identidade do Rabbito vem de art/soulgen/keys/rabbito/color-rig-v2/concept.png. O sheet externo foi estudado como estrutura de ciclo e escala, sem copiar seus pixels.

## Entrega

- rabbito-walk.aseprite: documento nativo editável, 32×32, quatro frames, seis camadas.
- rabbito-walk.png + rabbito-walk.json: faixa horizontal 128×32 e atlas; sem trim.
- preview-1x.gif e preview-8x.gif: reprodução nativa e ampliada nearest-neighbor.
- PixelSpec.json: paleta, posições, simplificações e desenho em grades por camada.
- validacao.json: medidas reais, alpha binário, três desenhos únicos, tempos e hash.

Direção única de piloto SE/frente em três quartos. Ciclo apoio → passo A → apoio → passo B, 110/150/110/150ms. Frames 1 e 3 idênticos. Nove cores opacas efetivamente usadas; sem suavização ou alpha intermediário. Pivô proposto [17,31], não medido no jogo. Não definir velocidade de deslocamento por este teste: movimento em profundidade precisa de teste no renderer.

Pixels interpretados em grades no Aseprite, não reduzidos de uma ilustração grande. Orelhas longas, gola turquesa, corpo creme e rabiola dourada preservados. Facetas e pequenos remendos simplificados; não é o mesmo nível de detalhe do concept.

## Revisão

Crítico independente: v1 6,5/10, bloqueio de leitura dos passos. Ajuste localizado nas patas e separação delas. V2 7,5/10, bloqueio resolvido e nenhum bloqueante restante para esta direção. Permanecem limites de detalhamento de orelhas, corpo e rabiola nessa escala.

O servidor Aseprite disponível não expõe a ferramenta validate. Verificação mecânica foi feita pelos PNGs e atlas exportados: dimensões, cores, alpha, tempos e igualdade dos apoios. Não substitui teste in-game. Sem oito direções, corrida, salto, integração ou aprovação visual do autor. Assets existentes e rigs foram preservados.
