# Mapa de eventos sonoros V1

Pontos de conexão são propostas derivadas dos consumidores; nenhum evento está conectado automaticamente.

| Evento | Ação | Situação da ação | Arquivos | Conexão sugerida |
| --- | --- | --- | --- | --- |
| `ui.focus` | Mover foco | existing | 2 | godot/scripts/campaign/front_end.gd · _button / _pause_game / _resume_game / _show_settings |
| `ui.confirm` | Confirmar | existing | 2 | godot/scripts/campaign/front_end.gd · _button / _pause_game / _resume_game / _show_settings |
| `ui.cancel` | Voltar | existing | 2 | godot/scripts/campaign/front_end.gd · _button / _pause_game / _resume_game / _show_settings |
| `ui.open` | Abrir painel | existing | 1 | godot/scripts/campaign/front_end.gd · _button / _pause_game / _resume_game / _show_settings |
| `ui.close` | Fechar painel | existing | 1 | godot/scripts/campaign/front_end.gd · _button / _pause_game / _resume_game / _show_settings |
| `ui.deny` | Ação indisponível | existing | 1 | godot/scripts/campaign/front_end.gd · _button / _pause_game / _resume_game / _show_settings |
| `ui.tab` | Trocar aba | existing | 1 | godot/scripts/campaign/front_end.gd · _button / _pause_game / _resume_game / _show_settings |
| `ui.slider` | Ajustar opção | existing | 1 | godot/scripts/campaign/front_end.gd · _button / _pause_game / _resume_game / _show_settings |
| `ui.pause` | Pausar | existing | 1 | godot/scripts/campaign/front_end.gd · _button / _pause_game / _resume_game / _show_settings |
| `ui.resume` | Retomar | existing | 1 | godot/scripts/campaign/front_end.gd · _button / _pause_game / _resume_game / _show_settings |
| `ui.warning` | Confirmação destrutiva | existing | 1 | godot/scripts/campaign/front_end.gd · _button / _pause_game / _resume_game / _show_settings |
| `ui.map` | Abrir mapa | existing | 1 | godot/scripts/campaign/front_end.gd · _button / _pause_game / _resume_game / _show_settings |
| `dialogue.open` | Iniciar conversa | existing | 1 | godot/scripts/campaign/front_end.gd · _advance / _dialog / _confirmation |
| `dialogue.advance` | Avançar fala | existing | 1 | godot/scripts/campaign/front_end.gd · _advance / _dialog / _confirmation |
| `dialogue.choice` | Escolher resposta | existing | 1 | godot/scripts/campaign/front_end.gd · _advance / _dialog / _confirmation |
| `dialogue.end` | Encerrar conversa | existing | 1 | godot/scripts/campaign/front_end.gd · _advance / _dialog / _confirmation |
| `dialogue.blip` | Pulso de texto opcional | existing | 3 | godot/scripts/campaign/front_end.gd · _advance / _dialog / _confirmation |
| `progress.save_ok` | Gravação confirmada | existing | 1 | godot/scripts/campaign/progression.gd · discover / acquire / award; session.gd · commit_operation |
| `progress.save_error` | Falha ao gravar | existing | 1 | godot/scripts/campaign/progression.gd · discover / acquire / award; session.gd · commit_operation |
| `progress.objective` | Objetivo recebido | existing | 1 | godot/scripts/campaign/progression.gd · discover / acquire / award; session.gd · commit_operation |
| `progress.quest_complete` | Objetivo concluído | existing | 1 | godot/scripts/campaign/progression.gd · discover / acquire / award; session.gd · commit_operation |
| `progress.item` | Item recebido | existing | 2 | godot/scripts/campaign/progression.gd · discover / acquire / award; session.gd · commit_operation |
| `progress.coins` | Moedas recebidas | existing | 2 | godot/scripts/campaign/progression.gd · discover / acquire / award; session.gd · commit_operation |
| `progress.xp` | XP concedido | existing | 2 | godot/scripts/campaign/progression.gd · discover / acquire / award; session.gd · commit_operation |
| `progress.level_up` | Subiu de nível | existing | 1 | godot/scripts/campaign/progression.gd · discover / acquire / award; session.gd · commit_operation |
| `progress.discovery` | Espécie descoberta | existing | 1 | godot/scripts/campaign/progression.gd · discover / acquire / award; session.gd · commit_operation |
| `progress.area` | Área descoberta | existing | 1 | godot/scripts/campaign/progression.gd · discover / acquire / award; session.gd · commit_operation |
| `progress.tutorial` | Exercício concluído | existing | 1 | godot/scripts/campaign/progression.gd · discover / acquire / award; session.gd · commit_operation |
| `inventory.bag` | Abrir bolsa | existing | 1 | godot/scripts/campaign/front_end.gd · _show_bag / _show_collection / _show_tail_workshop; exploration.gd · equip / repair |
| `inventory.equip` | Equipar parceiro | existing | 1 | godot/scripts/campaign/front_end.gd · _show_bag / _show_collection / _show_tail_workshop; exploration.gd · equip / repair |
| `inventory.unequip` | Retirar equipamento | future | 1 | godot/scripts/campaign/front_end.gd · _show_bag / _show_collection / _show_tail_workshop; exploration.gd · equip / repair |
| `inventory.inspect` | Inspecionar parceiro | existing | 1 | godot/scripts/campaign/front_end.gd · _show_bag / _show_collection / _show_tail_workshop; exploration.gd · equip / repair |
| `inventory.repair_start` | Iniciar reparo | existing | 1 | godot/scripts/campaign/front_end.gd · _show_bag / _show_collection / _show_tail_workshop; exploration.gd · equip / repair |
| `inventory.repair_done` | Reparo concluído | existing | 1 | godot/scripts/campaign/front_end.gd · _show_bag / _show_collection / _show_tail_workshop; exploration.gd · equip / repair |
| `inventory.tail_restore` | Restaurar rabiola | existing | 1 | godot/scripts/campaign/front_end.gd · _show_bag / _show_collection / _show_tail_workshop; exploration.gd · equip / repair |
| `inventory.consume` | Usar consumível | future | 1 | godot/scripts/campaign/front_end.gd · _show_bag / _show_collection / _show_tail_workshop; exploration.gd · equip / repair |
| `world.step_stone` | Passo em pedra/calçada | existing | 5 | godot/scripts/campaign/room_view.gd · _process / _safe; park_view.gd · _physics_process / _interact; exploration.gd · chest / collect_tail; overworld/fruit_tree.gd · hit / fruit_landed |
| `world.step_soil` | Passo em terra | existing | 5 | godot/scripts/campaign/room_view.gd · _process / _safe; park_view.gd · _physics_process / _interact; exploration.gd · chest / collect_tail; overworld/fruit_tree.gd · hit / fruit_landed |
| `world.step_grass` | Passo em grama | existing | 5 | godot/scripts/campaign/room_view.gd · _process / _safe; park_view.gd · _physics_process / _interact; exploration.gd · chest / collect_tail; overworld/fruit_tree.gd · hit / fruit_landed |
| `world.step_wood` | Passo em madeira/escada | existing | 5 | godot/scripts/campaign/room_view.gd · _process / _safe; park_view.gd · _physics_process / _interact; exploration.gd · chest / collect_tail; overworld/fruit_tree.gd · hit / fruit_landed |
| `world.grass_rustle` | Atravessar matinho | existing | 3 | godot/scripts/campaign/room_view.gd · _process / _safe; park_view.gd · _physics_process / _interact; exploration.gd · chest / collect_tail; overworld/fruit_tree.gd · hit / fruit_landed |
| `world.door_open` | Abrir porta | existing | 2 | godot/scripts/campaign/room_view.gd · _process / _safe; park_view.gd · _physics_process / _interact; exploration.gd · chest / collect_tail; overworld/fruit_tree.gd · hit / fruit_landed |
| `world.door_close` | Fechar porta | existing | 2 | godot/scripts/campaign/room_view.gd · _process / _safe; park_view.gd · _physics_process / _interact; exploration.gd · chest / collect_tail; overworld/fruit_tree.gd · hit / fruit_landed |
| `world.stairs` | Contato no degrau | existing | 3 | godot/scripts/campaign/room_view.gd · _process / _safe; park_view.gd · _physics_process / _interact; exploration.gd · chest / collect_tail; overworld/fruit_tree.gd · hit / fruit_landed |
| `world.chest_open` | Abrir baú | existing | 2 | godot/scripts/campaign/room_view.gd · _process / _safe; park_view.gd · _physics_process / _interact; exploration.gd · chest / collect_tail; overworld/fruit_tree.gd · hit / fruit_landed |
| `world.tail_pickup` | Recolher rabiola | existing | 2 | godot/scripts/campaign/room_view.gd · _process / _safe; park_view.gd · _physics_process / _interact; exploration.gd · chest / collect_tail; overworld/fruit_tree.gd · hit / fruit_landed |
| `world.tree_hit` | Bater na árvore | existing | 3 | godot/scripts/campaign/room_view.gd · _process / _safe; park_view.gd · _physics_process / _interact; exploration.gd · chest / collect_tail; overworld/fruit_tree.gd · hit / fruit_landed |
| `world.canopy` | Balanço da copa | existing | 3 | godot/scripts/campaign/room_view.gd · _process / _safe; park_view.gd · _physics_process / _interact; exploration.gd · chest / collect_tail; overworld/fruit_tree.gd · hit / fruit_landed |
| `world.fruit_fall` | Fruto soltando | existing | 2 | godot/scripts/campaign/room_view.gd · _process / _safe; park_view.gd · _physics_process / _interact; exploration.gd · chest / collect_tail; overworld/fruit_tree.gd · hit / fruit_landed |
| `world.fruit_land` | Fruto no chão | existing | 3 | godot/scripts/campaign/room_view.gd · _process / _safe; park_view.gd · _physics_process / _interact; exploration.gd · chest / collect_tail; overworld/fruit_tree.gd · hit / fruit_landed |
| `world.transition` | Trocar de área | existing | 1 | godot/scripts/campaign/room_view.gd · _process / _safe; park_view.gd · _physics_process / _interact; exploration.gd · chest / collect_tail; overworld/fruit_tree.gd · hit / fruit_landed |
| `world.interact` | Interagir | existing | 1 | godot/scripts/campaign/room_view.gd · _process / _safe; park_view.gd · _physics_process / _interact; exploration.gd · chest / collect_tail; overworld/fruit_tree.gd · hit / fruit_landed |
| `world.splash` | Passo em água rasa | future | 3 | godot/scripts/campaign/room_view.gd · _process / _safe; park_view.gd · _physics_process / _interact; exploration.gd · chest / collect_tail; overworld/fruit_tree.gd · hit / fruit_landed |
| `workshop.select_tail` | Escolher rabiola | existing | 2 | godot/scripts/campaign/workshop_model.gd · place_rod / hold_knot / release_knot / cut_at / hold_soul / release_soul / _finish / _lose |
| `workshop.select_frame` | Escolher gabarito | existing | 2 | godot/scripts/campaign/workshop_model.gd · place_rod / hold_knot / release_knot / cut_at / hold_soul / release_soul / _finish / _lose |
| `workshop.rod_place` | Encaixar vareta | existing | 3 | godot/scripts/campaign/workshop_model.gd · place_rod / hold_knot / release_knot / cut_at / hold_soul / release_soul / _finish / _lose |
| `workshop.rod_fail` | Vareta fora do encaixe | existing | 2 | godot/scripts/campaign/workshop_model.gd · place_rod / hold_knot / release_knot / cut_at / hold_soul / release_soul / _finish / _lose |
| `workshop.knot_pull` | Tensionar nó | existing | 3 | godot/scripts/campaign/workshop_model.gd · place_rod / hold_knot / release_knot / cut_at / hold_soul / release_soul / _finish / _lose |
| `workshop.knot_good` | Nó correto | existing | 3 | godot/scripts/campaign/workshop_model.gd · place_rod / hold_knot / release_knot / cut_at / hold_soul / release_soul / _finish / _lose |
| `workshop.paper_cut` | Recortar papel | existing | 4 | godot/scripts/campaign/workshop_model.gd · place_rod / hold_knot / release_knot / cut_at / hold_soul / release_soul / _finish / _lose |
| `workshop.paper_tear` | Rasgar papel por erro | existing | 3 | godot/scripts/campaign/workshop_model.gd · place_rod / hold_knot / release_knot / cut_at / hold_soul / release_soul / _finish / _lose |
| `workshop.gust` | Rajada no teste | existing | 3 | godot/scripts/campaign/workshop_model.gd · place_rod / hold_knot / release_knot / cut_at / hold_soul / release_soul / _finish / _lose |
| `workshop.balance` | Retomar equilíbrio | existing | 2 | godot/scripts/campaign/workshop_model.gd · place_rod / hold_knot / release_knot / cut_at / hold_soul / release_soul / _finish / _lose |
| `workshop.soul_charge` | Carregar elo | existing | 1 | godot/scripts/campaign/workshop_model.gd · place_rod / hold_knot / release_knot / cut_at / hold_soul / release_soul / _finish / _lose |
| `workshop.stage_done` | Etapa concluída | existing | 1 | godot/scripts/campaign/workshop_model.gd · place_rod / hold_knot / release_knot / cut_at / hold_soul / release_soul / _finish / _lose |
| `workshop.birth` | Nascimento do parceiro | existing | 1 | godot/scripts/campaign/workshop_model.gd · place_rod / hold_knot / release_knot / cut_at / hold_soul / release_soul / _finish / _lose |
| `workshop.abort` | Cancelar montagem | existing | 1 | godot/scripts/campaign/workshop_model.gd · place_rod / hold_knot / release_knot / cut_at / hold_soul / release_soul / _finish / _lose |
| `workshop.restock` | Repor materiais | existing | 2 | godot/scripts/campaign/workshop_model.gd · place_rod / hold_knot / release_knot / cut_at / hold_soul / release_soul / _finish / _lose |
| `battle.encounter` | Encontro selvagem | existing | 1 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `battle.launch` | Lançar pipa | existing | 3 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `battle.round_start` | Início de rodada | existing | 1 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `battle.attack` | Ataque sem confirmar dano | existing | 4 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `battle.line_hit` | Acertou a linha | existing | 4 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `battle.hull_hit` | Dano na estrutura | existing | 4 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `battle.critical` | Acerto crítico | existing | 3 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `battle.line_snap` | Linha rompida | existing | 3 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `battle.hull_break` | Estrutura quebrada | existing | 3 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `battle.pull` | Puxão de linha | existing | 3 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `battle.dodge` | Esquiva ativada | existing | 3 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `battle.evade` | Golpe evitado | existing | 2 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `battle.guard` | Guarda de 0,5 s | existing | 2 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `battle.block` | Golpe bloqueado | existing | 3 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `battle.counter` | Janela de contra-ataque | existing | 2 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `battle.energy_ready` | Energia suficiente | existing | 1 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `battle.no_energy` | Sem energia | existing | 1 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `battle.cooldown_ready` | Recarga concluída | existing | 1 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `battle.signature_charge` | Preparação de assinatura | existing | 1 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `battle.signature_banner` | Entrada do banner | existing | 1 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `battle.signature_rabbito` | Rabbito · Pulo do Elo | existing | 2 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `battle.signature_nozinho` | Nozinho · proposta de nó de vento | legacy_or_proposed | 2 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `battle.signature_lacertubo` | Lacertubo · pressão tubular | existing | 2 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `battle.boss_intro` | Entrada do Lacertubo | existing | 1 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `battle.boss_phase` | Mudança de fase | existing | 1 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `battle.low_line` | Linha em estado crítico | existing | 1 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `battle.victory` | Vitória | existing | 1 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `battle.defeat` | Derrota | existing | 1 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `battle.flee` | Fuga concluída | existing | 1 | godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round |
| `creature.rabbito` | Chamado · Rabbito | existing | 3 | godot/scripts/campaign/encounter_view.gd · configure / _draw; workshop_birth_view.gd · nascimento |
| `creature.carcara` | Chamado · Carcará | existing | 3 | godot/scripts/campaign/encounter_view.gd · configure / _draw; workshop_birth_view.gd · nascimento |
| `creature.azulao` | Chamado · Azulão | existing | 3 | godot/scripts/campaign/encounter_view.gd · configure / _draw; workshop_birth_view.gd · nascimento |
| `creature.mata` | Chamado · Mata Verde | existing | 3 | godot/scripts/campaign/encounter_view.gd · configure / _draw; workshop_birth_view.gd · nascimento |
| `creature.raio` | Chamado · Raio de Sol | existing | 3 | godot/scripts/campaign/encounter_view.gd · configure / _draw; workshop_birth_view.gd · nascimento |
| `creature.lacertubo` | Chamado · Lacertubo | existing | 3 | godot/scripts/campaign/encounter_view.gd · configure / _draw; workshop_birth_view.gd · nascimento |
| `ambience.wind` | Vento de campo | showcase_or_campaign | 1 | godot/scripts/overworld/ · starter_neighborhood / cave_water / cave_waterfall / lava_showcase / pier_play; areas are not all campaign-enabled |
| `ambience.leaves` | Folhagem | showcase_or_campaign | 1 | godot/scripts/overworld/ · starter_neighborhood / cave_water / cave_waterfall / lava_showcase / pier_play; areas are not all campaign-enabled |
| `ambience.water` | Água corrente | showcase_or_campaign | 1 | godot/scripts/overworld/ · starter_neighborhood / cave_water / cave_waterfall / lava_showcase / pier_play; areas are not all campaign-enabled |
| `ambience.cave` | Ar de caverna | showcase_or_campaign | 1 | godot/scripts/overworld/ · starter_neighborhood / cave_water / cave_waterfall / lava_showcase / pier_play; areas are not all campaign-enabled |
| `ambience.lava` | Borbulhar vulcânico | showcase_or_campaign | 1 | godot/scripts/overworld/ · starter_neighborhood / cave_water / cave_waterfall / lava_showcase / pier_play; areas are not all campaign-enabled |
| `ambience.coast` | Água do cais | showcase_or_campaign | 1 | godot/scripts/overworld/ · starter_neighborhood / cave_water / cave_waterfall / lava_showcase / pier_play; areas are not all campaign-enabled |

## Texturas locais

Texturas complementares, pendentes de seleção e recorte por escuta.

- `texture.paper`: Papel e recortes.
- `texture.bamboo`: Varetas e madeira.
- `texture.leaves`: Folhagem ao vento.
- `texture.stream`: Riacho.
- `texture.coast`: Água sob o cais.
- `texture.cave`: Ar e goteiras de caverna.
