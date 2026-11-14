# Autotiling de Kronasta · 32×32

Grama/terra, pedra/terra, areia/grama e água/grama:47 máscaras canônicas ×3 variações. Atlas256×576,8 colunas e6 linhas por variação. A última célula de cada bloco fica vazia. kit.json descreve máscara e posição.

Cantos externos, internos, bordas, corredores e ilhas; diagonais só contam quando os dois lados correspondentes existem. Semeadura estável preserva a variação ao editar. Terra é a base das transições.

Topo, face e sombra dos penhascos são gerados a partir de uma única altura/pegada; earth.png e rock.png são texturas de parede em fase mundial. Rampas preservam as duas bocas.

O Studio usa os mesmos geradores deste kit. Exportar Godot inclui atlas, terreno montado e scripts nativos. Nenhum pixel das referências foi redistribuído ou traçado.

Revisão4: mais 27 pisos gerados, 31 conjuntos de terrenos pintáveis;  inclui os atlas de água e areia e os novos pisos;  geometria por campo dual compartilhado, independente do recorte de textura; chegada/saída das rampas fechadas; paredes de rocha64×64 com facetas irregulares. Use terrain-set.tres com este kit em res://autotile/. O volume é regenerado pelos scripts nativos da exportação do Studio.
