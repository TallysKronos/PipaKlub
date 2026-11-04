# Região submersa — A/B/C

Prévia independente em três trechos conectados, 56×48 células e três pisos exploráveis por parte. A: Recife de entrada. B: Jardim de algas. C: Fenda abissal. Nomes funcionais, sem nova revelação, chefe ou ligação de campanha.

Abra godot/scenes/overworld_preview.tscn e selecione submerso-a/b/c, ou use --area=submerso-a --art-preview. Setas/WASD/clique para andar no leito e E para interagir. KRONASTA_GEOMETRIA=1 mostra a geometria chapada. SUBMERSO_CAPTURE=1 congela caústicas, algas e bolhas; use 0 para ver movimento.

Gerador: node tools/mapa-studio/desenhar-submerso.mjs. Fontes Tiled em art/overworld/mapas; runtime em godot/assets/overworld/maps. O conjunto reutiliza os auxiliares comprovados da geleira e tem gerador independente, peças e apresentação próprios. Testes: node --test tools/mapa-studio/submerso.test.mjs tools/mapa-studio/model.test.mjs. Percurso: godot/tests/industrial_map_checks.gd com INDUSTRIAL_AREA=submerso-a/b/c (nome histórico do teste compartilhado).

Kit submerso-v2: coral ramificado, algas largas, espirão basáltico e colônia coralina. Fontes, prompts, QA e prancha em art/overworld/kits/submerso-v2; manifesto e PNGs de execução em godot/assets/overworld/kits/submerso-v2. A biblioteca submerso-v1 anterior permanece intacta. Basalto e rocha solta da gruta foram reaproveitados com tintura de água.

A região é explorada pelo chão submerso. Toda a cena recebe apresentação aquática; não se trata de um lago pintado no mapa. Rampas, colisões e relevo usam a mesma superfície de apoio do personagem. Nove itens de prévia, três escondidos, encontros opcionais e fenda com dois caminhos. Nado livre, oxigênio, concessão online e integração narrativa não foram implementados.

Capturas atuais em captures/<parte>/{geometria,arte,arte-terreno}; planos em planos/. Verificar dimensões/inventário/hashes: node tools/mapa-studio/verificar-capturas-submerso.mjs. Animação em motion/. Relatório completo em relatorios/entrega.md. Branch local codex/mapa-submerso, sem push nesta tarefa.
