# Piloto jogável: margem do Mormaço em cel shading e pixels

Escopo autorizado: validar um trecho da margem com Kael, Mormaço, cachoeira e água animados antes de converter o mapa inteiro. Parte C do Pântano; a composição aprovada vem da cena Blender e do concept enviados pelo dono. Não há nova revelação, recompensa ou alteração de campanha.

```text
           patamares decorativos ── cachoeira ── mirante decorativo
                  escada             LAGO
                    │             Mormaço
       margem oeste └──── curva da margem ─── margem leste
            árvores       entrada do piloto       árvores
```

O marco é Mormaço no lago; a cachoeira é o marco secundário. A trilha inferior liga a entrada à margem esquerda e à direita, com estreitamentos junto às árvores e rochas. Os patamares e o mirante permanecem cenográficos neste piloto: não se presume navegação sobre níveis ainda não convertidos.

O terreno é renderizado em 3344 × 1882 e exibido a 1 pixel de textura por pixel de jogo no zoom 1.0. Kael usa o ator de produção de 70 px visíveis, sem ampliação. As árvores, cercas e pedras maiores são exportadas separadamente para ordenar a oclusão com o personagem. Navegação, recorte do lago e bloqueio dos patamares são derivados das mesmas coordenadas do Blender.

Este piloto é uma sala de validação do kit no projeto Godot consolidado. Não substitui os IDs, dados Tiled, regras de encontros ou gatilhos do mapa de campanha existente. As verificações regionais A/B/C e o audit do Mapa Studio se aplicam à futura conversão completa, não a esta cena isolada.

Critérios: andar de ida e volta pelas três margens, bloquear água e cercas, respeitar o contorno do solo, ordenar Kael atrás/na frente de copas, preservar sua escala e inspecionar a animação em render nativo. Prova em `art/overworld/pantano-mormaco-v2/jogavel-cel/`.
