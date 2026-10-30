# Pântano — prévia independente

Autorizado como região independente, sem chefe ou revelação. Três áreas no seletor: `kronasta-pantano-a` (Entrada alagada), `-b` (Curva dos cipós), `-c` (Clareira das raízes). Nomes descritivos de trabalho. Esta primeira versão compartilha a estrutura de travessia e aterros entre as partes, variando o canal; não representa três capítulos de campanha.

Abrir `godot/scenes/overworld_preview.tscn`, ou executar Godot com `--path godot res://scenes/overworld_preview.tscn -- --area=kronasta-pantano-a --art-preview`. Setas/WASD/clique para andar, E para interação. `KRONASTA_GEOMETRIA=1` mostra a blocagem.

Gerador: `node tools/mapa-studio/desenhar-pantano.mjs`. Node: `node --test tools/mapa-studio/pantano.test.mjs tools/mapa-studio/model.test.mjs`. Godot: `res://tests/pantano_water_checks.gd`; percurso de prévia reutiliza `res://tests/industrial_map_checks.gd` com `INDUSTRIAL_AREA=kronasta-pantano-a` (ou b/c), apesar do nome histórico do teste.

Capturas: `res://tools/bosque_region_capture.gd -- --area=<id> --plan=res://../documentation/overworld/pantano/planos/<id>.json --out=<pasta>`; `--terrain-only` retira o cenário móvel/vegetação para revisar juntas. `node tools/mapa-studio/verificar-capturas-pantano.mjs` confere tamanho, nomes e hashes.

Kit/fontes e prompt: `art/overworld/kits/pantano-v1/README.md`; manifesto `godot/assets/overworld/kits/pantano-v1/kit.json`. [Relatório e limites](relatorios/entrega.md).
