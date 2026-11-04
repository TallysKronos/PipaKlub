# Mãe — caminhada v1

Fonte baseada na mãe aprovada em npc-ds-directions-v1. A edição foi feita no Aseprite headless, preservando a paleta de 32 cores e os pixels do rosto/roupas. As poses têm pernas e braços separados, passos alternados, elevação de um pé e 1 px de deslocamento do tronco nas passagens.

## Contrato

- Atlas de runtime: godot/assets/npc-ds/mae-walk.png, 256x768.
- Célula: 64x96. Quatro colunas de quadros, oito linhas de direções.
- Direções: s, sw, w, nw, n, ne, e, se.
- Durações: [150,120,150,120] ms (contato A, passagem A, contato B, passagem B), ciclo540ms.
- Pivô e escala iguais à base estática atual. A subida/descida e a revelação na escada continuam sendo controladas pelo jogo.
- Fonte editável: mae-walk.aseprite,32 frames, tags walk-s a walk-se, camadas corpo, braços e pernas + original oculto.
- mae-walk-atlas.aseprite contém a montagem do atlas de runtime. filmstrip.png contém a linha do tempo em faixa horizontal; mae-walk-atlas.png é a folha4x8 para inspeção.
- walk-se.gif é a prévia ampliada 4x da direção SE.

## Verificações

32 quadros, todos os pares adjacentes de um mesmo ciclo diferentes. Paleta original preservada, zero cores externas e zero alfa parcial nos quadros. Transparência do atlas conferida no Aseprite. O servidor disponível não expõe uma ferramenta validate; verificações equivalentes de cores/transparência foram feitas com read_pixels e revisão em filmstrip.

Compromisso: é um ciclo compacto de4 poses, com movimento discreto do tecido da saia longa. Não é um novo design da mãe nem uma geração por vídeo. O original estático não foi sobrescrito.
