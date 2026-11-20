# Laboratório do Sr. Assis · pixel art no overworld

O concept moderno fornecido pelo jogador orienta o teto curvo, o vidro azul,
a moldura laranja da porta e os equipamentos almáticos. O desenho foi
simplificado para a escala do overworld. O interior usa o corte isométrico
com duas paredes ao fundo para deixar a circulação visível.

## Como editar

- **fachada.aseprite** (304 × 280). Testeira, edifício e emblema em camadas.
  No PNG os vértices do apoio são `(13,190)`, `(143,255)`, `(291,181)`.
  Se alterar a fundação, atualize esses três pontos em
  `neighborhood_architecture.gd`.
- **interior.aseprite** (960 × 960). Exporte `Piso e paredes` como
  `estrutura.png` e `Móveis` como `moveis.png`. A estrutura está
  registrada na projeção 2:1 da sala; os móveis são recortados de acordo
  com as regiões e os pivôs de `professor_modern.gd`.
- Os PNGs vão para `godot/assets/campaign/professor-pixel-v2/`. O Godot
  usa nearest para manter os agrupamentos de pixels. Mantenha o ponto
  de apoio de cada peça ao redesenhar volume acima do chão.
- Pegadas, colisões e pontos de interação vêm da sala `professor` em
  `godot/assets/campaign/content.json`. O Godot ordena os móveis e os
  personagens por profundidade com essas pegadas. Alterações na planta
  exigem conferir o trajeto real e o alinhamento do sprite.

## Conferência

- 62 verificações do laboratório. Kael percorreu os cinco trajetos de
  ida e volta com o controlador de caminhada. Foram verificados 4.510
  pontos acessíveis e nenhum bolsão caminhável isolado. A oclusão foi
  conferida diante e atrás da mesa e da bancada.
- A fachada foi conferida na Vila. A cena interna foi capturada na
  campanha e também em vista geral, sem atores e em blocagem.
- A sala é o laboratório público. A câmara secreta da história e a
  atualização visual dos lotes vizinhos estão fora desta entrega.
