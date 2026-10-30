# Parque e Veredas — correções da crítica visual

Revisão local de 29/10/2026. Aprovação estética ainda pertence ao usuário.

## Alterações

- **Pisos:** três pinturas raster novas, geradas com image_gen: grama de baixo
  contraste, terra compactada sem rachaduras grandes e barranco em camadas
  discretas. Fontes preservados em `art/overworld/kits/parque/pintura-v4/fontes`;
  materiais normalizados em 512×512 nas duas árvores de assets. Amostragem
  espelhada e fase mundial contínua evitam emendas entre células.
- **Coerência:** barrancos substituem a antiga alvenaria amarela muito
  contrastada. A textura de margem usa a mesma escala vertical dos barrancos.
  Pontes mantêm a pegada 3×11 e as passagens; madeira menos amarela, tinta
  mais fina, cordas discretas e pequenas variações internas nas tábuas.
- **Água:** dez células de água viram reentrâncias de grama no TMJ e no mapa
  compilado. O contorno contínuo deriva das células da água e dos trechos de
  ponte realmente sobre o leito. Topo, face e cota inferior compartilham o
  contorno; o plano inferior está 32 px abaixo. A parte visível é a interseção
  do leito projetado com a abertura superior, evitando vazamento pela frente.
  As pontas das pontes conservam apoio seco.
- **Transições:** curvas variam por vértice compartilhado; os pontos de encontro
  entre células continuam coincidentes. Áreas calmas dominam a pintura.
- **Vegetação:** árvores do Parque variam de escala com o pivô no solo;
  as que cobrem caminhos ficam menores. Copas e capim têm amarelos contidos.
  A moldura automática fora da floresta passa de 82% para 27% de ocupação;
  capim automático fica mais esparso. Árvores com colisão não foram apagadas.
- **Veredas:** os três módulos de encanamento passam a ocupar o fundo do pátio,
  com um coletor visual ligando-os; o centro permanece livre. Os objetos
  interativos e o boss mantêm suas posições e identificadores.
- **Ordenação:** pisos do Parque agora participam da ordenação das paredes e
  personagens. Isso remove traços de paredes de trás aparecendo nas rampas.
  As faces da água ficam abaixo do terreno superior.

## Conferência

- 18 capturas nativas do Parque, incluindo escala de jogo 1280×720, juntas
  ampliadas sem ocupantes, ponte e margens sem texturas/sprites.
- 10 capturas nativas da prova Kronasta em `forest/`.
- `parque_surfaces_checks.gd`: **544 verificações, zero falhas**. Inclui
  passagens, profundidade derivada da margem, triangulação, apoio seco e
  contenção da água dentro da abertura superior.
- `conferir-parque-abc.mjs`: **zero falhas**, alvos dos três mapas acessíveis.
  Os avisos existentes sobre condições de campanha e duração continuam
  registrados em `art/overworld/revisao/parque-abc/conferencia.json`.
- Capturas finais sem erros de script; aviso ambiental de cache de shader
  indisponível. Esta revisão não grava saves e não publica alterações.

## Reprodução

    python tools/overworld/build_parque_manga.py
    node tools/mapa-studio/refine-parque.mjs
    godot --path godot --script res://tools/material_recovery_capture.gd -- --out=<pasta-de-revisao>
    godot --path godot --script res://tools/kronasta_bosque_capture.gd -- --out=<pasta-de-revisao>/forest
    godot --headless --path godot --script res://tests/parque_surfaces_checks.gd
    node tools/mapa-studio/conferir-parque-abc.mjs

O gerador do kit preserva as pinturas-v4. O gerador dos mapas chama a função
de refinamento antes de compilar, para manter a margem e a composição ao
regenerar as plantas.

## Limite da integração

Aplicado aos mapas modulares novos Jardim, Clareira, Veredas e à prova
Kronasta. A campanha ainda usa consumidores e coordenadas separados; esta
revisão não substitui esses mapas nos saves nem implementa condições futuras
de progressão. Os conceitos anteriores e outros biomas foram preservados.
