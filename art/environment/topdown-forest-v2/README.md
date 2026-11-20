# Árvores de Kronasta — arte gerada e fatiada

`source-tree.png` é a arte original gerada pelo image_gen integrado, preservada sem alterações. `prompt.txt` registra o pedido. A arte procedural anterior foi rejeitada e não é mais usada pelo editor.

`tree-64x96.png` adapta a arte à grade: escala por vizinho mais próximo, transparência binária e paleta de 32 cores sem dithering. Pivô [32,80]. `canopy.png` e `trunk.png` são recortes dessa mesma árvore; nenhuma folha foi recriada por fórmulas.

`trees.png` reúne 47 máscaras canônicas em quadros 64×96, 8 colunas e 6 linhas. As copas vizinhas são compostas em deslocamentos exatos de 32 px, em ordem de profundidade. O editor determina a conexão usando a ocupação e a altura de apoio. Há uma arte-base nesta revisão; futuras variedades precisam ser desenhadas/geradas como novas artes.

Regeneração: `python tools/plant-lab/build-tree-kit.py`. O recorte é intencional e autorizado pelo pedido do usuário para dividir a arte para autotiling. O PNG isolado consumido pela biblioteca também é atualizado em `topdown-plants-pixel-v1/arvore-kronasta.png`.
