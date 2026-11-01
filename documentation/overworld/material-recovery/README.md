# Recuperação dos materiais — 29/10/2026

## Git e preservação

Integrados `origin/codex/mapa-mundi` (9fa6ebff) e `origin/claude/mapa-prova`
(e02169eb). Merges locais d29d1fcf e 17c45e85. O trabalho local anterior foi
reaplicado; o stash de preservação foi mantido. Nenhum push nesta tarefa.

## Diagnóstico e correção

O kit Parque native-editable-manga-v3 desenhava cores quase uniformes com marcas
SVG em cinza. O shader extraía só a luminância dessas marcas. A água usava o
rio-claro antigo, com cáusticas muito contrastadas. O renderizador também
consultava surfaceShader e boundaryShrubs.files que o kit novo não fornece.

- Grama e terra reutilizam as pinturas aprovadas de planicie-v1; passeio usa
  bairro-inicial-v2/passeio-manga-v4. Nada foi repintado ou quantizado.
- O shader preserva as massas de cor originais e uma fase mundial contínua
  entre células, rampas e remendos de transição. Mato/bosque usam tons próprios.
- A prova Kronasta usa a mesma família de grama e terra, preservando seu mapa,
  máscaras de caminhos, alturas e ocupantes.
- O leito da Clareira está 32 px abaixo da superfície. As faces das margens
  conectam as mesmas arestas superiores aos vértices inferiores da água;
  os pisos da frente cobrem a água, as pontes ficam acima dela.
- Água ilustrada existente cavernas-v3/agua-linhas, em coordenadas mundiais
  sem achatar seus desenhos. Corrente contínua com ciclo de 32 segundos.
  A projeção dos outros consumidores do shader permanece como padrão.
- O gerador de geometrias chama parque_painted_materials.apply: regenerar
  pontes não substitui as pinturas aprovadas por marcas SVG.
- As chamadas opcionais de ambientação respeitam o contrato do kit atual.

## Validação

Capturas nativas OpenGL na RTX 5070, usando câmeras fixas e sem gravar campanha:

- `before/`: diagnóstico anterior à correção, inclusive falhas de contrato do kit.
- `after/`: 17 capturas, incluindo escala de jogo 1280×720, juntas ampliadas
  sem personagens e props, ponte e água nos tempos 0/8/32 s.
- `forest/`: 10 capturas da prova Kronasta, entrada, platôs e rampas.

`parque_surfaces_checks.gd`: **537 verificações, zero falhas**. Inclui passagem
nas duas pontes, água não caminhável, profundidade conforme kit, pinturas PNG
e tabuleiros no tamanho nativo. Capturas finais sem erros de script; apenas o
aviso ambiental de diretório de cache de shader indisponível.

Comparação das capturas de água: t=0 e t=32 com erro médio RGB máximo
0,0000033/255; t=8 apresenta movimento. `git diff --check` sem erros.

## Escopo

Aplicado ao renderizador modular dos mapas novos Jardim das Pipas, Clareira
do Papel e Veredas do Encanamento, e à prova Kronasta. A campanha possui um
consumidor separado (`park_landscape`/`veredas_modular_landscape`) que já usa
materiais aprovados. Esta tarefa não migra seus saves/coordenadas para os TMJ
novos nem declara as conexões de regiões futuras prontas. Muros, vegetação,
layout e desenhos das pontes foram preservados; a aprovação estética dessa
recuperação ainda é do usuário.

Reproduzir as capturas no Godot com renderer:

    godot --path godot --script res://tools/material_recovery_capture.gd

Reproduzir a verificação estrutural:

    godot --headless --path godot --script res://tests/parque_surfaces_checks.gd
