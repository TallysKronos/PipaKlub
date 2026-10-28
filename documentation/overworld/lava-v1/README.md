# Rio de Brasa — lava flat 2D

Cena visual reutilizável Godot, isometria 64×32. Biblioteca local, ainda sem integração à campanha, colisão, dano, navegação ou salvamento.

## Arte e movimento

Basalto em quatro cores chapadas e lava em cinco, com fissuras seletivas, grandes faixas quentes e fragmentos escuros de crosta. Fontes geradas com imagegen integrado, prompts completos e origem em `art/overworld/kits/lava-v1/geracao.json`. Preparação determinística em `tools/overworld/build_lava_showcase.py`: projeção periódica das bordas, resolução 512×512 e normalização de paleta sem dithering. Não há bloom, brilho difuso, granulação ou filtros de tela inteira.

O shader desloca lentamente a pintura sobre a superfície inferior, com pulsação discreta de intensidade e ciclo fechado de oito segundos. `set_animation_time(t)` fixa a fase para auditoria, `-1` retoma o relógio da cena. `reduced_motion` fixa a lava em repouso; o contorno nunca se movimenta.

## Geometria e replicação

Um contorno medido de 50 pontos define o corte do chão, a superfície inferior e as faces das margens. A lava está 24 px abaixo do piso. O recorte produz duas margens superiores; o cortador ultrapassa minimamente os limites da montagem para evitar arestas coincidentes nas operações booleanas. As duas extremidades do rio são saídas abertas, sem uma face transversal funcionando como barragem.

A ordem de desenho é lava inferior → faces das margens → piso superior recortado → lábios e objetos. O piso próximo oculta as partes da superfície que devem ficar atrás da margem. A transição basalto/crosta usa `terrain_transition.gdshaderinc`, a mesma função de mistura irregular da caverna e da planície. É uma máscara de material sobre a geometria real, sem simular profundidade por sombra pintada.

Rochas reaproveitadas da biblioteca da caverna, com tonalidade própria no material de cada instância. A opção de cor do shader de contorno tem branco como padrão e preserva os consumidores anteriores.

## Abrir e revisar

Cena: `godot/scenes/overworld/lava/rio-de-brasa.tscn`.

Galeria: Godot `--path godot --script res://tools/lava_preview.gd -- --live`.

Prévia: `RIO-DE-BRASA.gif`; detalhe animado: `MARGEM-ANIMADA.webp`; captura nativa: `lava-1280x720.png`. `geometria-1280x720.png` mostra as cotas sem texturas e objetos; `sem-objetos-1280x720.png` permite revisar toda a margem. `auditoria.json` registra 96 quadros, fechamento do ciclo e diferença na área do solo superior.

Nenhuma suíte de gameplay executada. A auditoria cobre a montagem visual e a animação na captura nativa, não dano, travessia ou comportamento de um personagem.
