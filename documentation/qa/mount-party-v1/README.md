# Montaria no grupo — QA

Capturas nativas Godot 1280×720, save isolado. 01-team: parceiro real selecionado, retrato e ícone de capacidade ao lado. 02-battle: mesma instância de parceiro em batalha, arte própria, dano recebido. A pausa permite conferir a imagem; não faz parte da apresentação final.

Reprodução: Godot `--path godot --script res://tests/mount_party_ui_checks.gd`.

O teste também verifica desmontagem ao zerar HP e retirar o parceiro do grupo. `mount_quest_checks.gd` cobre 1 HP, apito sem parceiro, entrega atômica, reload, migração do prêmio antigo, encontro real e derrota persistida.

Revisão Soulgen: as capturas atuais usam a imagem recortada do autor e o atlas animado de 109 frames. A fixture agora verifica avanço de repouso, pausa, seleção de voo/ataque/dano/vitória/derrota e retenção do fim das ações únicas: 18 verificações sem falha.
