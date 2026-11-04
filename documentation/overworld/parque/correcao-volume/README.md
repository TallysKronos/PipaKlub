# Correção: folhagem achatada e piso

O usuário rejeitou a composição v2: a folhagem de fundo parecia chão e o piso novo ficou pior. Causa técnica: a pintura top-down de copas foi amostrada por um shader em polígonos horizontais de terreno, sem altura, âncora ou ordenação própria.

## Alterações

- Retirar completamente `bosque-baixo.png` e `grama-calma.png` dos materiais consumidos. Fontes preservadas para histórico.
- Restaurar a grama a partir da fonte original `art/overworld/kits/bairro/fontes/pisos-v2/canteiro.png`; restaurar os tons anteriores de mato e bosque e retirar a mistura extra de cores/vinheta do shader. Terra e piso de concreto continuam nas fontes originais.
- Compor a borda com sprites verticais de arbustos, em nós ordenados por profundidade e com sombra de contato separada, somente nas células de bosque existentes.
- Manter a seleção reduzida de árvores da planta. Somente duas árvores de fundo por área são posicionadas explicitamente, sem a antiga população automática. Os elementos de fundo não adicionam colisão.

## Evidências

`antes/`: última composição rejeitada. `depois/`: seis capturas nativas a 1280×720 e uma no formato 1280×800. A importação e a renderização não registraram erro; não houve suíte de testes nem simulação de campanha. Isso não substitui aprovação visual do responsável ou teste físico em Steam Deck. Sem publicação.

Reprodução: `python tools/overworld/build_parque.py`, criação das cenas com `buildPieceScenes()` do importador e execução gráfica de `godot/tools/parque_capture.gd`.
