# Alvacordo 64×64 — limpeza pixel art

Correção nativa da pose-mestra v2 no Aseprite, solicitada pelo autor. Não houve nova geração, ampliação do canvas, blur ou filtro de nitidez. A geração original e o prompt permanecem em `../overworld-master-64-v2/`.

## Técnicas aplicadas

- Consolidação de tons intermediários para reduzir ruído e agrupamentos isolados.
- Gola organizada em massas maiores de luz e sombra, mantendo pontas e proporção.
- Olho âmbar separado da máscara escura, com contraste localizado.
- Pipa do peito organizada em losango de moldura dourada e planos petróleo.
- Cordas dos arcos reconstruídas como linhas contínuas de 1 px, com apoios dourados sobrepostos.
- Bordas de cor verificadas por grids e previews a 1× e 8×. Sem suavização.

135 pixels diferentes em relação ao nativo v2, cerca de 7,4% da massa opaca original; apenas seis pixels tiveram alpha alterado em encaixes locais. 12 cores opacas usadas, contra 15 antes. Paleta de trabalho mantém 17 slots (não eliminar slots à força; cores não usadas não aparecem no PNG). Pose e canvas preservados, um frame estático. Animação e integração não realizadas.

## Arquivos

- `alvacordo-master-64.aseprite`: fonte editável.
- `alvacordo-64.png`: nativo 64×64, transparência binária.
- `preview-8x.png`: ampliação nearest-neighbor.
- `a.png` / `b.png`: comparação antes/depois em 8×; `b` foi preferida pela revisão independente.
- `antes.aseprite`: snapshot da pose antes da limpeza.
- `validacao.json`: medições dos exports.
- `revisao.md`: resultado da comparação.

O trabalho permanece como proposta visual aguardando o autor.
