# PIP-88 — acabamento dos muros

Os blocos cinza visíveis junto às escadas eram faces de contenção do terreno,
desenhadas com texturas de rascunho. Foram substituídas por pedra clara e reboco
creme, com novas fontes ilustradas na paleta do piso aprovado.

## Entrega

- Duas fontes `imagegen`, preservadas em `art/overworld/kits/morro/fontes/muros-v2`.
  A imagem do piso de pedra foi usada como referência de estilo e cor. Prompts,
  ferramenta e normalização constam em `proveniencia.json`.
- Superfícies periódicas 512×512, sem contornos nas extremidades dos módulos.
  O renderer conserva a fase da textura pela coordenada da parede e pela altura,
  em vez de reiniciar a pedra em cada face. Orientações recebem iluminação
  consistente, com acabamento superior claro e contato discreto na base.
- Trechos conectados com o mesmo intervalo de altura compartilham acabamento.
  Uma quina não muda de pedra para reboco só porque uma de suas faces está junto
  ao caminho. Componentes que encostam no caminho usam pedra; os demais, reboco.
- Também foram atualizadas as amostras antigas 32×80, os cantos 64×96 e as quatro
  peças de muro de quintal 64×96. As peças de quintal continuam ocultas onde a
  composição atual da PIP-88 já as ocultava; não foram acrescentados muros novos.
- Manifestos e assets correspondem entre `art/` e `godot/assets/`. O gerador geral
  chama a nova família, evitando restaurar o rascunho numa reconstrução futura.

## Verificação

Capturas nativas **1280×720** na Praça da Chegada, Escadaria da Sombra e Parque
dos Ventos, mais uma vista de perto dos muros. Inspeção visual das faces, quinas,
topos, bases e passagem da escada. Imagens em `after/`; comparação da Praça e do
Parque antes da alteração em `before/`. A prancha `modulos.png` mostra as duas
orientações e os cantos dos materiais.

`validacao.json` registra dimensões, espelhamento, bordas periódicas idênticas e
ausência de erros no log nativo final. Preservados os polígonos de sustentação,
alturas, posições dos apoios, aberturas das escadas e o modelo de navegação.
Não foram editados os JSONs de mapas, colisões, saves ou campanha; não foi rodada
uma nova bateria de gameplay.

Esta entrega é local à cena de revisão Godot da PIP-88. Não publica nem substitui
automaticamente os mapas da campanha. Escadas, portões e casas ainda usam suas
artes preexistentes.

Atualização posterior: as escadas e os encaixes do piso foram corrigidos em
[escadas e encontros](../escadas-encaixes/README.md), com capturas próprias.

## Reprodução

```powershell
python tools/overworld/build_morro_walls.py
godot --headless --editor --path godot --quit
godot --path godot --rendering-driver opengl3 --script res://tools/morro_wall_review.gd
python tools/overworld/build_morro_walls.py
```

O gerador usa Pillow e NumPy; apenas os PNGs exportados são consumidos no jogo.
