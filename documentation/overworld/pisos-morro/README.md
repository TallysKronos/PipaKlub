# PIP-88 — novos pisos do Morro

Esta revisão substitui a base visual do chão na cena Godot da PIP-88. A grama,
a calçada e o caminho de terra agora vêm de três superfícies ilustradas novas,
geradas para a mesma família. Não são decalques sobre o piso chapado anterior.

## Integração

- Fontes originais: `art/overworld/kits/morro/fontes/pisos-v2/`. Geração via
  `imagegen`, com prompts completos em `proveniencia.json`; arquivos originais
  preservados sem repintura. Sem uso de stock externo.
- Normalização: `tools/overworld/build_morro_floors.py`. Redimensionamento,
  correção técnica de continuidade nas bordas, projeção isométrica 2:1, recorte
  por centro do pixel e espelhamento entre `art/` e `godot/assets/`.
- Três materiais visíveis: grama de folhas pequenas, pedra clara com juntas
  irregulares e terra compactada. O identificador lógico `construcao` permanece
  reservado aos lotes bloqueados e continua aparecendo como quintal gramado.
- 32 amostras PNG 64×32, com SVGs que incorporam o raster correspondente, e
  96 estados de transição em seis pares. As duas famílias antigas com nomes
  invertidos também foram atualizadas para não deixar a paleta antiga no kit.
- Atlas de superfícies 1536×512. O renderer usa UVs contínuas em coordenadas
  `u/v` do mapa, com repetição a cada oito células em ambos os eixos. Isso evita
  reiniciar os desenhos das pedras e da grama a cada losango. As oito amostras
  por material são derivações de referência/compatibilidade; a cena utiliza a
  superfície contínua, com muito mais variação do que oito amostras isoladas.
- Os materiais nos vértices compartilhados definem o encontro entre grama,
  pedra e terra. Um material compartilhado desenha a mistura dentro do próprio
  piso, sem sobrepor cards de borda nem acrescentar colisão.
- A sombra do quintal continua separada em `_yard_shade()`, sem ser pintada nas
  novas fontes. Os sete decalques da entrega anterior continuam ativos.
- Os geradores antigos encaminham a reconstrução para a nova família quando
  as fontes estão presentes, evitando restaurar o chão antigo por acidente.

## Verificação visual e técnica

`before/` conserva as capturas com a grama anterior. `after/` contém as novas
capturas nativas de **Parque dos Ventos** e **Praça da Chegada**, em **1280×720**,
no Godot 4.7.2 oficial, Compatibility/OpenGL.

Também foram capturados quatro campos 8×8 no mesmo renderer: grama, pedra,
terra e um encontro dos três materiais. Cada campo foi verificado no zoom 1,4,
sem fundo para esconder falhas, totalizando **504.096 pixels internos, zero
frestas pretas**. As superfícies têm bordas periódicas idênticas; os PNGs dos
tiles têm 1.024 pixels opacos por losango, sem alpha parcial na aresta. Os
arquivos fonte/runtime correspondem byte a byte. O log nativo final não contém
erros de script ou shader. Evidências em `validacao.json` e `native-render.log`.

Não foi repetida uma bateria de gameplay: o modelo de mapa, os JSONs de áreas,
as colisões, os eventos e a navegação não foram editados nesta revisão visual.

## Reprodução

O gerador usa Python 3.10+, Pillow e NumPy, disponíveis no runtime de trabalho.
Essas dependências são apenas de produção dos assets; o jogo usa os PNGs exportados.

```powershell
python tools/overworld/build_morro_floors.py
godot --headless --editor --path godot --quit
godot --path godot --rendering-driver opengl3 --script res://tools/morro_floor_review.gd
python tools/overworld/build_morro_floors.py
```

Para explorar, abra `godot/scenes/overworld_preview.tscn` e ative a arte de revisão, ou
inicie a cena com `--art-preview`. Esta integração ainda é a cena de revisão da
PIP-88; não muda automaticamente os mapas da campanha nem os saves existentes.

Limites: casas, portões, muros e escadas são assets preexistentes. Este trabalho
substitui as superfícies de chão e seus encontros, sem redesenhar esses objetos.

Atualização posterior: o acabamento dos muros foi revisado separadamente em
[muros do Morro](../muros-morro/README.md), com capturas próprias.
