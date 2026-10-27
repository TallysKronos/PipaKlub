# Desenvolvimento do PipaKlub

Este projeto usa engine própria em JavaScript/Canvas 2D, interface DOM/CSS e servidor Node/WebSocket. Não introduza Godot, Unity, Phaser ou outro motor apenas porque um exemplo de skill o utiliza.

Para produção/revisão de assets, HUD/menus ou diagnóstico de desempenho, leia `.agents/skills/pipaklub-production/SKILL.md` e somente a referência da área solicitada. Ela conecta as três skills externas instaladas às regras e consumidores locais. Para mudanças fora dessas áreas, trabalhe normalmente.

A identidade e os contratos existentes estão em `MANUAL-DE-ASSETS.md`, `HUD-KIT.md`, `WORLD-ART-DIRECTION.md` e nos manifestos/renderizadores correspondentes. Orientações externas complementam esses contratos; não autorizam redesenho, troca de engine ou reestruturação ampla por conta própria. Instruções explícitas do usuário prevalecem.

Os arquivos externos e sua revisão estão registrados em `.agents/vendor/awesome-gamedev-agent-skills/source-lock.json`. Preserve licença e NOTICE ao redistribuí-los. A instalação de skills não autoriza deploy, alterações de banco ou download automático das demais skills citadas nos exemplos.

## Continuidade de terrenos e desníveis

Para criar ou corrigir pisos elevados, barrancos, rampas, pontes e conexões entre áreas, siga `documentation/continuidade-terreno-isometrico.md`. Derive sustentação e bordas da geometria e da altura, independentemente do material. Valide as conexões com cores simples antes das texturas e confira o resultado no jogo; não esconda defeitos de encaixe com vegetação.

Antes de entregar um layout, inspecione em captura nativa ampliada cada boca de rampa, canto interno/externo, lateral inclinada e encontro com patamar. Confira também sem personagem encobrindo a junta. Elimine faces que atravessam a rampa, tiras verticais aparentes sob a lateral, saliências isoladas e mudanças de escala/fase da textura entre faces. Laterais de rampas participam da ordenação de profundidade dos barrancos, não da camada de decalques do piso. Uma vista geral bonita não substitui essa revisão dos detalhes.
