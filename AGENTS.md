# Desenvolvimento do PipaKlub

Este projeto usa engine própria em JavaScript/Canvas 2D, interface DOM/CSS e servidor Node/WebSocket. Não introduza Godot, Unity, Phaser ou outro motor apenas porque um exemplo de skill o utiliza.

Para produção/revisão de assets, HUD/menus ou diagnóstico de desempenho, leia `.agents/skills/pipaklub-production/SKILL.md` e somente a referência da área solicitada. Ela conecta as três skills externas instaladas às regras e consumidores locais. Para mudanças fora dessas áreas, trabalhe normalmente.

A identidade e os contratos existentes estão em `MANUAL-DE-ASSETS.md`, `HUD-KIT.md`, `WORLD-ART-DIRECTION.md` e nos manifestos/renderizadores correspondentes. Orientações externas complementam esses contratos; não autorizam redesenho, troca de engine ou reestruturação ampla por conta própria. Instruções explícitas do usuário prevalecem.

Os arquivos externos e sua revisão estão registrados em `.agents/vendor/awesome-gamedev-agent-skills/source-lock.json`. Preserve licença e NOTICE ao redistribuí-los. A instalação de skills não autoriza deploy, alterações de banco ou download automático das demais skills citadas nos exemplos.

## Mapas do overworld

Os mapas do overworld são construídos no Godot (`godot/`), por decisão do dono. Para criar, corrigir ou melhorar áreas exploráveis (planta, relevo, barrancos, muretas, rampas, escadas, pontes, vegetação, itens e eventos), leia `.agents/skills/soulmonsters-construtor-de-mapas/SKILL.md` e as referências que ela indicar. O agente do Codex para essa tarefa está em `.codex/agents/construtor-de-mapas.toml`.

## Continuidade de terrenos e desníveis

Para criar ou corrigir pisos elevados, barrancos, rampas, pontes e conexões entre áreas, siga `documentation/continuidade-terreno-isometrico.md`. Derive sustentação e bordas da geometria e da altura, independentemente do material. Valide as conexões com cores simples antes das texturas e confira o resultado no jogo; não esconda defeitos de encaixe com vegetação.

Antes de entregar um layout, inspecione em captura nativa ampliada cada boca de rampa, canto interno/externo, lateral inclinada e encontro com patamar. Confira também sem personagem encobrindo a junta. Elimine faces que atravessam a rampa, tiras verticais aparentes sob a lateral, saliências isoladas e mudanças de escala/fase da textura entre faces. Laterais de rampas participam da ordenação de profundidade dos barrancos, não da camada de decalques do piso. Uma vista geral bonita não substitui essa revisão dos detalhes.

## Margens, poços e cachoeiras

Áreas naturais que recebem cachoeiras devem ter um poço rebaixado com profundidade legível: recortar de fato o piso superior, fechar as faces da margem até a cota da água e apoiar o impacto nessa cota. Usar o mesmo contorno medido para o recorte, o barranco e a superfície inferior. O comprimento da queda inclui a diferença entre o solo e a água. Não entregar um retângulo de água como decalque sobre o piso, nem simular o volume apenas com borda escura ou sombra. Contornos naturais devem ser irregulares/arredondados; formas retangulares precisam corresponder a uma estrutura construída intencional.

Conferir a oclusão da margem próxima e a projeção do rebaixo dentro do terreno de sustentação. Água, laterais e espuma não podem vazar por baixo ou para fora da margem, nem cobrir o chão caminhável. Validar em captura nativa geral e ampliada, sem objetos encobrindo as juntas, mais uma versão geométrica simples. A regra vale para os novos assets e cenários Godot e para o renderer legado. Ver a seção "Margens e cotas de água" em `documentation/continuidade-terreno-isometrico.md`.
