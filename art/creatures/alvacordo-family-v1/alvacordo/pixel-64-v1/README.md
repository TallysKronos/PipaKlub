# Alvacordo — pixel art 64×64

Interpretação desenhada em grids de pixels no Aseprite a partir do `concept-v4` aprovado; não é redução automática da arte. Prioridades: focinho canino, gola branca, placas marfim, painéis petróleo, janela de pipa no peito, tirantes vermelhos e arcos montados nos antebraços com suportes dourados visíveis.

## Entrega

- `alvacordo-64.aseprite`: fonte 64×64 em 16 camadas editáveis.
- `alvacordo-64.png`: pose nativa.
- `preview-6x.png` e `preview-6x.gif`: ampliação inteira por nearest-neighbor.
- `alvacordo-idle.png` / `.json`: 8 frames, tag `idle-so`, ciclo de 1.200 ms.
- `PixelSpec.json`: grids das partes, paleta e detalhes dos suportes.
- `validacao.json`: medição das exportações.

A estrutura sob as placas permanece contínua nos oito frames. Peito e gola respiram com 1 px de deslocamento; braços, arcos, cordas e suportes seguem a mesma chave de movimento, com atraso em relação ao torso. Pés mantidos no chão. A rabiola tem oscilação pequena independente.

Microfacetas, dedos separados e nervuras finas foram simplificados para não gerar ruído em 64×64. Uma direção e idle; caminhada, outras direções e integração ao jogo não realizadas. Aprovação do autor pendente.
