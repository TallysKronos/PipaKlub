# PIP-88 — escada de pedra e encontros do caminho

Correção da referência anotada em `before/referencia-anotada.png`.

## Causas e correções

1. A escada usava um sprite cinza com linhas escuras repetidas. Agora são oito
   degraus projetados com a pedra da calçada e faces de sustentação da família
   dos muros. Os lados e o fundo são fechados. A largura, a pegada e a subida de
   64 pixels continuam correspondendo à rampa do modelo. Não foi acrescentada
   colisão derivada da arte.
2. A mistura do piso usava a classificação dos quatro vértices do tile sem
   considerar a altura das superfícies vizinhas. A calçada da rampa inferior
   contaminava os canteiros superiores. A cobertura agora consulta os centros
   vizinhos na mesma altura física; nas rampas, calcula a altura no ponto.
3. A triangulação de um losango inteiro tornava as transições angulares. Só os
   trechos mistos recebem subdivisões, com amostragem contínua. Os interiores
   uniformes continuam sendo um único quadrilátero. Pontas e fins de caminho
   ganham curvas suaves, mantendo as UVs em coordenadas do mundo.
4. As duas quinas de canteiro na boca inferior da escada receberam um chanfro
   discreto de 0,18 célula. O recorte do topo, as extremidades das paredes e a
   nova face de fechamento usam os mesmos pontos. O corte é limitado a um canto
   de uma célula superior já bloqueada, sem modificar uma célula caminhável.

## Assets e consumidores

- `godot/scripts/overworld/view.gd`: cobertura do terreno, projeção dos degraus,
  suportes e fechamento dos chanfros. O modelo de navegação não foi editado.
- `tools/overworld/build_morro_stairs.py`: quatro PNGs/SVGs de escada derivados
  dos materiais aprovados, também espelhados no runtime. Preserva 96×112,
  pegadas 1×2 / 2×1, oito espelhos e subida 64. O gerador geral chama a nova
  família, e os manifestos identificam o renderer `projected-stone-steps`.
- Não houve geração adicional de materiais: foram reutilizadas as fontes
  ilustradas de piso e muro já aprovadas, com projeção e recorte geométricos.

## Conferência

Capturas nativas 1280×720 em `after/`: Praça da Chegada, Escadaria da Sombra,
Parque dos Ventos, detalhe dos encontros, Kael parado sobre os degraus e as
quatro orientações de escada isoladas. As versões vistas pelo lado alto também
têm o fundo fechado. `quatro-direcoes.png` reúne as quatro capturas.

A leitura da escada, o apoio de Kael, as extremidades e os fechamentos dos
chanfros foram inspecionados nas capturas. `validacao.json` registra dimensões,
espelhamento, ausência de pixels cinza neutros nos novos sprites e ausência de
erros no log nativo. Não foi repetida uma bateria de gameplay.

Os JSONs de mapa, o grafo de navegação, as colisões, os níveis e a interpolação
de altura do personagem continuam os existentes. Os chanfros alteram somente
a geometria desenhada nos cantos bloqueados identificados junto às rampas.

Esta entrega é local à cena de revisão Godot da PIP-88, sem publicação ou troca
automática dos mapas da campanha.

## Reprodução

```powershell
python tools/overworld/build_morro_stairs.py
godot --headless --editor --path godot --quit
godot --path godot --rendering-driver opengl3 --script res://tools/morro_wall_review.gd -- --stairs
```
