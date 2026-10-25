# Primeira árvore separada

Uma árvore grande da trilha oeste foi convertida em objeto independente. O fundo e o sprite foram gerados com ImageGen a partir da referência aprovada. Prompts em `prompts.txt`; dimensões, origem, pivô e configuração em `manifest.json`.

`tree.png` preserva o original RGBA de geração (1374×1145, transparência real). `tree-game.png` é a versão normalizada na densidade de pixels do cenário (223×186), feita por `tools/normalize_tree.gd`; o original não é sobrescrito. A árvore é uma reconstrução baseada na referência, não uma extração pixel a pixel da silhueta antiga.

`ground-without-tree.png` contém o chão reconstruído. Como a geração também alterou partes de uma árvore vizinha, o jogo amostra apenas a região x=300..540, y=405..655 desse arquivo. Fora dela, usa a textura original. O shader `ground_patch.gdshader` serve ao fundo e aos recortes antigos próximos, evitando recolocar pedaços da árvore removida. A árvore vizinha acima mantém sua máscara e textura originais. Esses recortes antigos ainda precisam ser substituídos nas próximas etapas.

`scenes/illustrated_tree.tscn` é uma cena reutilizável com sprite de transparência real, pivô na base e collider nativo das raízes. O chão de navegação deriva o mesmo bloqueio de `separated_trees` em `routes-v2.json`. A antiga máscara `Copa oeste` e o obstáculo duplicado foram removidos. Não há mais recorte poligonal para a árvore central desta prova.

O contato é uma elipse de raios 45×14 px, centrada 7 px acima da base (420,635). A ordenação por profundidade usa essa base: Kael aparece na frente com pés abaixo dela e é encoberto pelo sprite quando está atrás. Copas não bloqueiam o deslocamento. A pequena marca de contato sob as raízes é uma elipse de baixa opacidade, sem luz volumétrica.

## Revisão

O botão **Árvore** leva Kael até o objeto. **F4** alterna a visibilidade da árvore para revelar o chão limpo; esse atalho visual de revisão mantém sua colisão. F3 continua mostrando pisos e obstáculos.

`--proof --tree-tour` gera cinco capturas nativas com câmera fixa: frente, trás, esquerda, direita e chão sem árvore. O teste principal verifica alpha, ausência da máscara antiga, presença do collider e acesso aos quatro lados, além das rotas anteriores do mapa. Capturas foram conferidas no renderer do Godot. Não equivalem a um playtest humano de todos os pixels do contorno.

Escopo: somente uma árvore substituída. O restante da vegetação continua no processo anterior. Ainda é um protótipo para validar a produção das próximas peças.
