# Gelo — revisão de composição A/B/C/D

Quatro áreas conectadas no Godot, ampliadas para 56×48 células, com três pisos exploráveis cada. Fundo preto e arte mangá/cartoon 2D. A: clareira e bosques. B: bacia de gelo trincado. C: fenda contornada pelas duas margens e mirante dos cristais. D: coroa da geleira, com dois acessos independentes em cada mudança de andar. Nomes funcionais; região continua uma prévia independente sem ligação narrativa.

Abra godot/scenes/overworld_preview.tscn e selecione gelo-a/b/c/d, ou passe --area=gelo-a --art-preview. Setas/WASD/clique para andar, E para interagir. KRONASTA_GEOMETRIA=1 ativa a versão chapada. Regenerar: node tools/mapa-studio/desenhar-gelo.mjs. Testes próprios: node --test tools/mapa-studio/gelo.test.mjs tools/mapa-studio/model.test.mjs. Percurso Godot: tests/industrial_map_checks.gd com INDUSTRIAL_AREA=gelo-a (ou b/c/d), nome histórico do teste compartilhado.

131 pinheiros em massas com colisão no tronco e variação de escala/espelhamento. Três manchas de gelo por parte, com bordas de neve e fissuras contínuas entre tiles. As rampas de gelo usam a mesma altura no movimento e no desenho; há dez acessos de cinco faixas no conjunto. Doze itens, quatro escondidos, encontros contornáveis e andar superior sempre alcançável. O gelo é sólido: as rachaduras são arte, sem regra de quebra ou escorregamento.

Fontes Tiled em art/overworld/mapas; dados em godot/assets/overworld/maps; consumidor ice_structures.gd, shader ice_ground.gdshader e kit gelo-v1. As imagens originais do kit foram reutilizadas. Não há mudanças em campanha, saves, combate ou economia.

Capturas atuais em captures/<parte>/{geometria,arte,arte-terreno}; planos em planos/. Gerais anteriores e pranchas antes/depois em comparacao/. Inventário/dimensões/hashes: node tools/mapa-studio/verificar-capturas-gelo.mjs. Relatório atualizado em relatorios/entrega.md. Branch local codex/mapa-gelo, sem push nesta revisão.
