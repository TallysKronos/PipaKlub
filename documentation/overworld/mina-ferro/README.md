# Mina de ferro — A/B/C/D

Prévia independente baseada no kit da gruta seca cavernas-v3, com fundo preto. IDs mina-ferro-a/b/c/d. A: pátio de carga. B: entroncamento ferroviário. C: frentes de extração. D: grande veio com circuito de retorno. Nomes descritivos de trabalho, sem integração narrativa.

Abrir godot/scenes/overworld_preview.tscn e selecionar a área, ou usar --area=mina-ferro-a --art-preview. Setas/WASD/clique para andar, E para interagir. KRONASTA_GEOMETRIA=1 ativa a conferência chapada. Gerador: node tools/mapa-studio/desenhar-mina-ferro.mjs. Testes: node --test tools/mapa-studio/mina-ferro.test.mjs tools/mapa-studio/model.test.mjs. Percurso Godot usa tests/industrial_map_checks.gd com INDUSTRIAL_AREA=mina-ferro-a (ou b/c/d); o nome do teste é histórico.

Fontes Tiled em art/overworld/mapas; consumidor mine_structures.gd; dados compilados em godot/assets/overworld/maps. Kit, prompts e QA em art/overworld/kits/mina-ferro-v1. Manifesto junto dos PNGs de execução. O cenário usa seis novos sprites principais, seis formações e três superfícies reaproveitadas, além dos módulos ferroviários e pórticos nativos.

Capturas: captures/<parte>/geometria, arte e arte-terreno, planos em planos/. Verificador: node tools/mapa-studio/verificar-capturas-mina-ferro.mjs. Relatório com limites em relatorios/entrega.md. Carrinhos estacionados e equipamentos são cenário; não há sistema de mineração ou veículo controlável nesta entrega.

Apresentação atual das bordas: consulte correcao-borda/README.md e antes-depois.png. Essa revisão corrige paredes soltas no corte da frente e possui capturas mais recentes que o conjunto original em captures/.
