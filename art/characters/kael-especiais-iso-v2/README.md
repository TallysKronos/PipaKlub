# Kael no overworld isométrico

O salto tem seis poses por direção e mantém os 820 ms do controle anterior. A altura do salto vem do mapa. A folha contém cinco vistas desenhadas e três espelhadas. O último quadro de cada linha usa a pose de repouso da direção correspondente.

O gesto de item mantém a virada direcional de 240 ms e a apresentação de 1.710 ms. O primeiro e o último quadro usam o repouso frontal. As mãos ficam livres para o item ou o aviso apresentado pela interface.

Na montaria, a folha sentada passa por uma redução na densidade do pixel para se aproximar do Kael a pé. A folha continua com os recortes e pivôs originais e o assento sudoeste foi movido na direção dos ombros do Dóber. Os ciclos de caminhada e corrida montada usam as animações já aprovadas.

Os PNGs de origem das ações ficam em `fontes/`. A partir da raiz do projeto, execute `pack.ps1` para montar as folhas de salto e item e `pack-mount.ps1` para regenerar a folha sentada. As capturas da revisão usam `godot/tools/kael_special_actions_review.gd`.

- [Salto em oito direções](salto.png)
- [Fases do gesto de item](item.png)
- [Montaria em oito direções](montaria.png)
- [Subida da escada](escada/stair-up-60.png) e [descida](escada/stair-down-60.png)
