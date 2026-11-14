# Sprites de overworld v2 · conversão com o xprite-pixelate

12/11/2026. As folhas v1 (80×80) perderam detalhe porque foram reduzidas por redimensionamento
direto. O ImageGen desenha numa grade de pixels bem maior do que o sprite final:

| Criatura | Grade real da geração | Sprite v1 |
| --- | --- | --- |
| Farpim | 90×89 | 30×32 |
| Gambalhote adulto | 194×287 | 45×63 |

## Como funciona agora

`tools/sprites/converter-overworld.mjs` (dependências próprias: `cd tools/sprites && npm install`):

1. Separa as duas vistas da geração (frente SW à esquerda, costas NW à direita).
2. Recupera a grade real com o [xprite-pixelate](https://github.com/rhinoc/xprite-pixelate) (MIT).
3. Reduz para a altura final com o método `structure` e paleta de 20 cores.
4. Monta a folha 224×112 (células 112×112, apoio em (56, 100)) em
   `godot/assets/campaign/overworld-companions-v2/` e registra em `overworld-companions-v2.json`.

A altura v2 mantém o tamanho aprovado no jogo, na densidade de pixel do Kael:
`altura_v2 = altura_v1 × 1,25 / 0,952`. No jogo, `companion_follow.gd` usa a v2 quando ela existe
(escala do Kael, sem o `SIZE`) e a v1 nas demais. `KRONASTA_SPRITES_V1=1` força a v1, para comparar.

## Convertidas (8)

Farpim, Papisco, Velcão, Alvacordo e as quatro formas do Gambalhote: as únicas com a geração
original no repositório. O relatório fica em `tools/sprites/relatorio-v2.md`.

## Pedido ao Codex

As outras ~184 criaturas só têm no repositório a folha de 80 px já reduzida; o detalhe perdido não
volta a partir dela. Duas saídas, nesta ordem:

1. **Se as gerações originais ainda existirem na máquina do Codex** (a normalização registrou
   caminhos como `C:/Users/user/produto/.../overworld-diagonal-v1/geracao.png`): publicar cada uma
   em `art/creatures/<família>/<forma>/overworld-diagonal-v1/geracao.png`, junto com o
   `normalizacao.json` que tem os recortes das duas vistas. Eu acrescento ao `SOURCES` do conversor
   e rodo; não precisa gerar nada de novo.
2. **Se não existirem:** gerar de novo, com as duas vistas lado a lado num fundo transparente ou liso
   (frente 3/4 para sudoeste à esquerda, costas 3/4 para noroeste à direita), pixel art com blocos
   bem marcados, contorno escuro de 1 bloco e a mesma escala nas duas vistas. Não reduzir: entregar
   a geração como saiu. A redução e a grade ficam com o conversor.

Correções que valem para os dois casos: as costas da Capibaluarte precisam ter a mesma altura da
frente; o Rastro dos Ventos tem só quadros de corrida de perfil e precisa das duas vistas.

## Editar no Aseprite

Cada folha v2 tem um arquivo editável em `art/creatures/overworld-v2/<id>/<id>-overworld-v2.aseprite`
(gerado por `tools/sprites/aseprite-v2.mjs`, também chamado pelo conversor):

- quadro 1 = frente (sudoeste), quadro 2 = costas (noroeste), 112×112 cada;
- camada **Criatura** e a paleta das cores da criatura;
- recorte **chao** com o ponto de apoio em (56, 100): os pés ficam nessa linha.

Para levar a edição ao jogo: `File > Export Sprite Sheet`, **Sheet type: By Rows**, sem bordas nem
espaçamento, salvando por cima de `godot/assets/campaign/overworld-companions-v2/<id>.png`
(224×112). Pela linha de comando: `aseprite -b <id>-overworld-v2.aseprite --sheet <id>.png --sheet-type rows`.

Se rodar `converter-overworld.mjs` de novo para a mesma criatura, a folha e o .aseprite voltam a
ser gerados a partir da geração original: tire a criatura da lista `SOURCES` depois de retocá-la.
