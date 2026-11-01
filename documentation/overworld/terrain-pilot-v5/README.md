# Barrancos e margens â€” revisÃ£o 5

Refinamento local de 29/10/2026 apÃ³s aprovaÃ§Ã£o da grama e da terra do piloto. Pintura original de solo em camadas largas, raÃ­zes pendentes curtas, fissuras seletivas e pequenas pedras embutidas. Os pisos da revisÃ£o 4 permanecem iguais.

## IntegraÃ§Ã£o

A vista opt-in aplica o novo acabamento Ã s faces compiladas dentro do retÃ¢ngulo experimental e Ã s paredes existentes da margem. Os vÃ©rtices, recortes, bocas de rampa, apoio das pontes e ordenaÃ§Ã£o de profundidade permanecem com o construtor original. NÃ£o foi acrescentada parede atravessando uma passagem nem alterada a cota da Ã¡gua.

A pintura acompanha coordenadas contÃ­nuas ao longo da face, com 384 pixels por faixa espelhada e 64 pixels por cota nos barrancos. NÃ£o reinicia em cada cÃ©lula. Faces adjacentes compartilham fase no canto. A sombra diferencia as orientaÃ§Ãµes; margens baixas usam a faixa de solo completa e reforÃ§o discreto de umidade junto Ã  base.

Fonte: `godot/assets/overworld/terrain-pilot-v5/barranco-manga-v2.png`, RGB opaco 2172Ã—724. Original imagegen copiado sem alteraÃ§Ãµes; filtragem linear com mipmaps, sem colisÃ£o. Shader e acabamento residem somente em `godot/tools/`.

## RevisÃ£o

[ComparaÃ§Ã£o na mesma cÃ¢mera com a revisÃ£o 4](index.html). Treze capturas nativas de 1280Ã—720: geral, sem objetos, rampa, pontes norte/sul, juntas ampliadas e cores chapadas. O relatÃ³rio registra preservaÃ§Ã£o dos dados de mapa e da posiÃ§Ã£o do personagem na alternÃ¢ncia F6. A revisÃ£o visual nÃ£o equivale a teste completo de jogabilidade.

Campanha, saves e renderer de produÃ§Ã£o permanecem inalterados. O arquivo `asset-source.json` registra a geraÃ§Ã£o. Para repetir a captura: Godot com `--path godot --script res://tools/terrain_pilot_capture.gd`. Acrescente `-- --live` para permanecer na prÃ©via.
