# Montanha — prévia independente A/B/C

Três mapas de 56×48, cotas absolutas de 0 a 6: Sopé (A), Encosta (B), Cume (C). A rota sobe em zigue-zague, com becos recompensados e retorno alternativo em C. Revisão 2: maciço contínuo com silhuetas diferentes em cada parte; a sustentação externa desce à cota -18, e as rochas bloqueadas sobem até a cota 7. O percurso mantém cotas de 0 a 6. Nomes descritivos de trabalho, sem integração narrativa ou recompensas online.

Abrir godot/scenes/overworld_preview.tscn e escolher kronasta-montanha-a, b ou c. Setas/WASD/clique para andar. KRONASTA_GEOMETRIA=1 mostra a blocagem. O gerador é tools/mapa-studio/desenhar-montanha.mjs; fontes Tiled em art/overworld/mapas/. O vocabulário de alturas é interno aos três mapas e preserva o tileset compartilhado.

Validação: node --test tools/mapa-studio/montanha.test.mjs tools/mapa-studio/model.test.mjs. Percurso Godot: tests/industrial_map_checks.gd com INDUSTRIAL_AREA=kronasta-montanha-a (ou b/c); o nome do teste é histórico, o teste usa a área selecionada. Capturas e respectivos planos estão nesta pasta; verificar-capturas-montanha.mjs confere nomes, dimensões e hashes.

Comparação antes/depois em comparacao/. Novos assets e prompts em art/overworld/kits/montanha-v1/README.md.

Consulte relatorios/entrega.md para evidências e limites.
