# Palafitas · normalização e revisão nativa

## Entrega

Cinco fontes preservadas e cinco PNGs normalizados em godot/assets/npc-ds/palafitas-v1/. Altura112px de conteúdo, um frame estático sudeste; filtro e escala seguem o contrato atual de NPC estático (84px no renderer). Empacotador reexecutável tools/package-palafitas-npcs.py remove pixels residuais fora do componente conectado do personagem, preservando antialias na borda; não usa recorte por cor. Relatório por fonte em art/characters/palafitas-overworld-v1/qa.json.

## Verificado

- Cinco saídas RGBA, alpha0–255, conteúdo sem corte, pivô inferior central registrado.
- Prévia112 sobre fundos claro e escuro inspecionada: máscara, cabelo, maquiagem e roupas legíveis; detalhe fino do rosto se perde naturalmente.
- Cinco capturas nativas1280×720 no Godot4.7.2/OpenGL, mapa Palafitas A. Mesmo ponto caminhável próximo a Kael, colocação pelo método real _place_actor para altura e ordenação. Sem personagem sobre parede ou suspenso na água nas capturas finais.
- Teste palafitas_walk_checks.gd:403 verificações,0 falhas, controlador programado (não controle físico).

## Não verificado / limites

Não há eventos definitivos de campeonato, duelos, retratos, caminhada ou rig novo. As capturas usam uma cena de QA sem save e não alteram mapa/campanha. Não foram testadas as cinco identidades em todas as posições/oclusões de A–C. Tamanho84px é o contrato legado, não uma altura individual calibrada por idade; posterior direção de escala pode distinguir Oruvo e Seyran. Kael atual é mais pixelado e estes NPCs têm desenho mais suave; normalizar resolução não resolve essa diferença de família artística. Sem alegar uniformidade estética final.

Reprodução: executar empacotador; importar projeto Godot; executar res://tests/palafitas_art_review.gd em modo gráfico. A primeira captura de desenvolvimento usou projeção sem elevação e foi descartada; o script agora reutiliza _place_actor. Avisos do ambiente: user://logs e cache de shader sem escrita; editor também não conseguiu salvar preferências. Capturas e testes concluídos, sem erro de script na revisão final.

Sem merge, push ou deploy nesta etapa.
