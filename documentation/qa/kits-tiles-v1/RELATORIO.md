# Kronasta — entrega dos kits de tiles v1

Base: `claude/unificacao`, commit `c0bf9107`. Branch: `codex/kits-tiles-v1`.

| Kit | Superfícies | Peças | Prancha |
| --- | ---: | ---: | --- |
| Morro do Sol, `morro-v2` | 5 pisos e 7 paredes | 6 | [morro-v2.png](morro-v2.png) |
| Cavernas de Cristal, `cavernas-cristal-v1` | 4 pisos e 2 paredes | 5 | [cavernas-cristal-v1.png](cavernas-cristal-v1.png) |
| Planícies, `planicies-v1` | 4 pisos e 1 parede | 6 | [planicies-v1.png](planicies-v1.png) |

Os três kits estão em `godot/assets/overworld/kits/`. A arte original foi refeita em 2D mangá nos três kits. Veja os [fontes, prompts e comandos de normalização](revisao-manga/README.md). Sem fotos, personagens ou arte reaproveitada de outros jogos. As texturas são chapadas em RGB; as peças têm alpha binário e são vistas em 2:1. Cada `library.json` registra o tamanho, a paleta efetiva e as diferenças nas bordas. Cada `kit.json` registra o PNG, o tamanho, a pegada nos eixos u/v, o apoio central em pixels e os quatro vértices projetados.

A escada ocupa 1×2, sobe em `v-` e tem oito espelhos de 8 px para uma cota de 64 px. O segmento de ponte segue o eixo u. `gato-de-luz` representa uma derivação de energia em poste, com caixa fechada e conduítes. As bases que integram as peças são pequenas fundações ou manchas de apoio; não têm sombra externa. A ponte e a escada deixam navegação, colisão e encontros com patamares para a montagem.

## O que passou

- 23 texturas RGB 512×512, cada uma com 4–6 cores, paleta igual ao manifesto e diferença **zero** nas duas bordas opostas. Nas paredes, a umidade escurece a região baixa e se dissolve perto da emenda vertical, para preservar o fechamento superior/inferior exigido.
- 17 PNGs RGBA com dimensões e pegadas verificadas, alpha binário, recorte com margem curta e nenhum pixel de halo branco detectado. A escada é conferida pela geometria declarada e pela prancha porque seu patamar superior está levantado.
- Inspeção visual de repetição 3×3 e peças a 1:1 sobre o piso de cada kit. A revisão 2D mangá passou nas três pranchas e no validador.

Validação reproduzível com Python e Pillow, na raiz:

```sh
python tools/validar-kit-tiles.py morro-v2 --prancha
python tools/validar-kit-tiles.py cavernas-cristal-v1 --prancha
python tools/validar-kit-tiles.py planicies-v1 --prancha
```

A saída completa está em [validacao.txt](validacao.txt). A checagem de halo detecta pixels muito claros e pouco saturados encostados em transparência; as pranchas ajudam a detectar problemas visuais além dessa regra.

## Revisar primeiro no mapa

| Textura | Risco em escala de jogo |
| --- | --- |
| `telha-barro` e `tijolo-aparente` | As fileiras são mais regulares e podem vibrar em movimento ou em zoom fracionário. |
| `cristal-chao` e `parede-cristal` | Os veios e facetas mais claros podem competir com efeitos e marcadores. Conferir especialmente nas áreas escuras. |
| `agua-gruta` | Pode parecer pedra polida se a luz do mapa baixar demais; a leitura depende também da margem e do shader. |
| `campo-flor` e `capim-alto` | Flores pequenas podem sumir no zoom afastado; a densidade do capim pode reduzir a separação da trilha. |
| `cimento-laje` | Conferir se as juntas continuam visíveis após a projeção e a iluminação. |

## Fora do escopo

Nenhum item da lista de arte ficou de fora. Não foram alterados mapas, geradores de mapa, scripts de jogo, `content.json` ou kits existentes. A verificação é de assets e de pranchas estáticas. O teste em mapa Godot, a navegação, a oclusão, o encontro da ponte com margens e a chegada da escada a ambos os patamares ficam para a integração.
