# Areias do Vento

Cenário visual reutilizável Godot, isometria 64×32, fora da campanha. Sem colisões, movimentação de personagem, eventos, dano ou salvamento.

## Materiais e identidade

Areia clara em quatro cores, com grupos esparsos de marcas de vento e grandes áreas tranquilas. Arenito em planos de ocre e sombra terrosa, com contorno seletivo. Novas fontes feitas com imagegen integrado; prompts e origem em `art/overworld/kits/areia-v1/geracao.json`. Preparação determinística por `tools/overworld/build_sand_showcase.py`: correção periódica, resolução exata, paleta limitada e alpha/pivô do arenito. Originais preservados em `fontes/`.

Areia solta, terra compactada e pedra exposta usam a mesma mistura irregular `terrain_transition.gdshaderinc` das cenas anteriores. A terra da planície e a pedra da caverna foram reutilizadas com ajuste de cor no material. Não há pontilhado procedural, bloom ou sombras pintadas na textura da areia.

## Dunas e apoio

Malha 2D subdividida com 2.793 vértices e 5.376 triângulos, projetada a partir de coordenadas isométricas e um campo contínuo de altura. Duas elevações suaves, até aproximadamente 18 px, retornam a zero nos limites da montagem. Não existem faces verticais ou uma parede disfarçada de rampa.

As texturas usam as coordenadas originais das células, mantendo escala e fase ao subir a duna. O apoio dos objetos usa a mesma função de altura do chão. Três faixas discretas de iluminação destacam a inclinação real. `dune_height` ajusta a altura antes da instanciação; ainda não existe vínculo dessa altura com colisão ou navegação de gameplay.

O vento consiste em três traços curtos e discretos sobre a superfície, em ciclo de oito segundos. O chão e suas marcas permanecem estáticos. `reduced_motion` oculta os traços; `set_animation_time(t)` fixa a fase e `-1` retoma a animação.

## Abrir e revisar

Cena: `godot/scenes/overworld/sand/areias-do-vento.tscn`.
Galeria: Godot `--path godot --script res://tools/sand_preview.gd -- --live`.

Capturas nativas 1280×720: geral, sem objetos, máscaras, geometria e movimento reduzido. `geometria.json` registra as medidas do relevo; `auditoria.json` mede o fechamento do ciclo. Não foram executadas suítes de gameplay.

Prévia `AREIAS-DO-VENTO.gif`, detalhe `DETALHE-TRANSICAO.png`, pacote `areias-do-vento-godot.zip`.
