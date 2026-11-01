# Gelo — A/B/C/D

Prévia independente em quatro partes conectadas, com fundo preto e arte mangá/cartoon 2D. A: Clareira nevada. B: Lago congelado. C: Desfiladeiro de cristal. D: Coroa da geleira. Nomes funcionais, sem introduzir história ou chefe canônico.

Abra godot/scenes/overworld_preview.tscn e selecione gelo-a/b/c/d, ou passe --area=gelo-a --art-preview. Setas/WASD/clique para andar; E para interagir. KRONASTA_GEOMETRIA=1 ativa a versão chapada. Gerador: node tools/mapa-studio/desenhar-gelo.mjs. Testes próprios: node --test tools/mapa-studio/gelo.test.mjs tools/mapa-studio/model.test.mjs. Teste de percurso: godot/tests/industrial_map_checks.gd com INDUSTRIAL_AREA=gelo-a (ou b/c/d); o nome é histórico.

Fontes Tiled em art/overworld/mapas; mapas compilados em godot/assets/overworld/maps; consumidor ice_structures.gd e shader ice_ground.gdshader. Kit gelo-v1 possui cinco peças e uma superfície novas, fontes integrais, prompts, manifesto, QA e pranchas. Pegadas, fissuras e estacas são desenho nativo.

Cada parte tem três itens (um escondido), rampas v- e circulação livre sobre o terreno suportado. B é gelo totalmente sólido e caminhável; C tem fenda real; D possui dois acessos independentes ao patamar final. Não há escorregamento, clima com dano, chefe, mineração ou concessão de recompensas online.

Capturas geométricas, com arte e sem peças em captures/<parte>/. Planos em planos/; verificador: node tools/mapa-studio/verificar-capturas-gelo.mjs. Relatório e limitações em relatorios/entrega.md. Branch local codex/mapa-gelo, sem push nesta tarefa.
