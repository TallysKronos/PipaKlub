# Grama mangá — revisão 4

Extensão do piloto em 29/10/2026. A terra com pedrinhas da revisão 3 permanece; a grama ganha uma pintura original de tufos angulares, pequenas folhas e trevos em grupos espaçados. Grandes áreas ficam quase lisas. Não foram alterados barrancos, pontes ou calçadas nesta revisão.

A pintura é compartilhada em coordenadas do terreno, com período espelhado de 576 pixels, deslocamento próprio e mistura de 84%. Nenhuma célula reinicia o desenho; a máscara existente mantém os detalhes no material correto. O escurecimento de mato continua aplicado depois da pintura. A fonte contém diferentes agrupamentos; não há um tufo idêntico por losango.

Fonte: `godot/assets/overworld/terrain-pilot-v4/grama-manga.png`, RGB opaco 1254×1254. Original de imagegen copiado sem alterações, sem colisão, filtragem linear. Registro em `asset-source.json`.

[Comparação com a revisão 3](index.html), mesma câmera. Treze capturas nativas 1280×720, incluindo juntas ampliadas, pontes, rampa e diagnóstico sem textura. Relatório em `report.json` verifica preservação dos dados de mapa e posição ao alternar F6. Não é teste completo de jogabilidade.

Permanece isolado em `godot/tools/terrain_pilot_view.gd`, sem mudar o renderer da campanha ou saves. Para recriar capturas: Godot com `--path godot --script res://tools/terrain_pilot_capture.gd`. Acrescente `-- --live` para permanecer na prévia e alternar F6. Revisões anteriores preservadas.
