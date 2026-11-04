# Terra e pedra — transição natural

Implementado nas cenas reutilizáveis seca e inundada, incluindo as variantes com vento. Sem integração à campanha, sem alterações de colisão, navegação ou saves.

O piso agora usa uma superfície opaca única, com máscara de caminho em coordenadas locais isométricas. A ponta é arredondada e assimétrica; duas escalas de ruído estático quebram o contorno e deixam bolsões de pedra nos ombros. A faixa central permanece contínua. A interpolação é curta para preservar a leitura gráfica em 2D; não há animação da máscara, brilho ou sombra falsa.

`godot/scripts/overworld/cave_ground.gd` cria o material compartilhado; `cave_ground_blend.gdshader` expõe largura, centro, início, fim, irregularidade e largura de mistura em células. Mover a cena inteira não muda a fase da textura ou o desenho da borda.

Na gruta inundada, o material é aplicado sobre o mesmo piso superior recortado pelo contorno medido do poço. Não existe um polígono retangular de terra sobreposto. Água inferior, faces da margem e espuma mantêm a geometria e a ordem de desenho anteriores. Na seca, o mesmo material ocupa o losango de sustentação.

Revisão em capturas nativas 1280×720 das duas cenas, detalhe ampliado da ponta e margem, captura geométrica do poço e recaptura do ciclo de vento de oito segundos. Nenhuma suíte de gameplay executada.

## Pesquisa e adaptação

- [Godot — funções de shader, smoothstep](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shader_functions.html): interpolação curta de limiar.
- [Victor Karp — Cheap Godot terrain shader](https://victorkarp.com/godot-terrain-shader/): princípio de quebrar uma máscara uniforme com ruído. Implementação própria adaptada para materiais de piso 2D, não cópia do shader de terreno 3D.
- [Godot — Terrain Sets](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html#creating-terrain-sets-autotiling): alternativa para futuros mapas de tiles. Esta entrega usa a máscara no piso da montagem visual; não cria uma nova coleção de autotiles de transição.
