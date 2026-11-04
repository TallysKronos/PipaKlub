# Correção conjunta — caminhada frontal

Oito poses foram extraídas do vídeo local `walk-s.mp4` e compostas numa
folha 4 × 2 com o mesmo recorte e escala. Frames originais 24, 28, 32, 36,
40, 44, 48 e 52; tempos e recortes em `extraction.json`.

Ferramenta artística: imagegen integrado, modo de edição. Alvo: `before-sheet.png`.
Referências: a montaria frontal aprovada, recortada sem redesenho de
`../sources/idle-eight.png`, e `../references/mount-edited-s.png` para Kael
e seu encaixe. Nenhum benchmark externo foi anexado.

Corrigidos em conjunto: duas orelhas altas com velas claras e dobras laranjas,
contornos, olhos, face e leitura das patas. A folha gerada foi mantida inteira
em `corrected-sheet-v1.png` e fatiada em oito PNGs RGBA de 384 × 512, sem
repintura programática dos pixels. A arte possui alpha real com bordas suaves.

`atlas.json` descreve a grade, os tempos e o pivô comum. `frames/` conserva
os recortes transparentes. `walk-front-corrected.gif` e `.mp4` são prévias
com fundo quadriculado; esse fundo não está pintado nos sprites.

A saída foi inspecionada em folha e sequência de poses. A recreação alterou
ligeiramente alguns desenhos e não garante equivalência exata de articulações
com o vídeo. O ciclo ainda requer aprovação visual do usuário; esta entrega
não integra nem substitui sprites no jogo. Não chamar esta sequência de pixel
art nativa: é ilustração raster 2D mangá com antialiasing.
