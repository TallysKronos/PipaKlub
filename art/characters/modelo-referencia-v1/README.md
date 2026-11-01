# Modelo de referência v1

Gabarito de proporção, sombra e tempo para os personagens do overworld (48×64). Todo o conteúdo é gerado pelos scripts do pixelgen. Para refazer:

```sh
node tools/pixelgen/examples/modelo-referencia.mjs art/characters/modelo-referencia-v1/modelo-base.pixelgen.json
node tools/pixelgen/examples/modelo-acoes.mjs art/characters/modelo-referencia-v1/modelo-acoes.pixelgen.json
```

| Arquivo | O que é |
| --- | --- |
| `modelo-base.pixelgen.json` | Vistas E e S com idle, walk e run, geradas pelas receitas |
| `modelo-acoes.pixelgen.json` | Vitória, derrota e nado nas 8 direções; escada vertical, subindo (`climb-N`) e descendo (`climbdown-N`) |
| `*-folha.png` + `*-atlas.json` | Folha para o jogo e as coordenadas de cada quadro e sequência |
| `pranchas/` | Uma linha por sequência, no cenário da ação: barranco com escada, água ou grama |
| `gifs/` | Animações no tempo real |

A escada e a água das pranchas só servem de cenário para conferir o encaixe. No jogo, elas vêm do mapa.
