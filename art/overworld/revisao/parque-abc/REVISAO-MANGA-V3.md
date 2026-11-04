# Pisos, riacho e pontes — revisão v3

Solicitação: corrigir pisos genéricos, falta de profundidade da água no mapa B e ponte fora da linguagem mangá 2D.

## Arte aplicada

- Grama, terra, mato, bosque e piso: cores chapadas com pequenas marcas desenhadas em uma folha contínua de 512×256. Não usam mais as pinturas raster da revisão anterior. Os detalhes mantêm a escala no mundo, sem repetir uma moldura em cada célula.
- Transições: regiões curvas nos cantos, preservando os mesmos pontos de contato entre células. Corrigida a escolha de atlas que aceitava um par de materiais sem conter o material do piso, causando faixas e cores incorretas. A família v3 usa polígonos preenchidos, evitando bordas raster transparentes entre tiles.
- Água: superfície 18 px abaixo da cota visual da margem, com faces de terra expostas, linha escura de contato, dois tons de corrente e traços claros discretos. A altura dos pisos de caminhada e a navegação permanecem idênticas. O recuo é visual e representa o leito não caminhável.
- Pontes: duas peças inteiras de 3×5 células, desenhadas em SVG nativo 288×180, com contorno escuro, três tons de madeira, pregos, tábuas e cordas curvas. Tabuleiro e cordas são elementos separados para ordenar o personagem entre eles. Não há um tabuleiro repetido por célula nem escala não uniforme.
- Rampas: mesma cor e marcas da terra, sem esticar um recorte com bordas raster.

Os barrancos maiores e demais objetos são os assets existentes; esta revisão não os converteu para a nova família. O resultado ainda depende de aprovação visual.

## Evidências

- `clareira-do-papel-escala-jogo.png`: visão geral próxima, 1280×720.
- `clareira-do-papel-riacho-manga.png`: personagem e parceiro sobre o tabuleiro, câmera 1,5×.
- `clareira-do-papel-ponte-3x.png`: margem, espessura do deck e água em detalhe.
- `antes-manga-v3.png`: prancha da versão anterior, preservada para comparação.

14 capturas reais da Godot, não composições geradas para substituir o jogo. A cena continua sendo a prévia independente das plantas, sem abrir saves reais.

## Conferência

`parque_surfaces_checks.gd`: 125 verificações, zero falhas. Confere água rebaixada, margens presentes, duas pontes inteiras em escala nativa e passagens dos dois lados. O auditor regional continua sem falhas geométricas, com os avisos anteriores sobre ritmo e integração narrativa. A inspeção visual inclui o personagem apoiado na ponte.

## Reprodução e origem

Arte vetorial original editável: `tools/overworld/build_parque_manga.py`. Manifesto em `art/overworld/kits/parque/manga-v3/MANIFESTO.json`; cópia consumida em `godot/assets/overworld/kits/parque/manga-v3/`.

Para reconstruir o conjunto inteiro, executar por último `build_parque_manga.py` após os importadores antigos, que preservam a revisão anterior. Em seguida, importar recursos na Godot e executar o capturador `godot/tools/parque_abc_capture.gd` com renderizador. `tools/overworld/check_parque_review.py` confere os tamanhos próprios dos tiles, das folhas de detalhe e da ponte, além da igualdade entre fonte e runtime.

Sem push nesta revisão.
