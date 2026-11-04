# Mãe animada e treino com foco visual

## Mãe

A fonte aprovada foi animada no Aseprite headless, preservando a paleta e as oito direções. Ciclo de quatro poses por direção: 150, 120, 150 e 120 ms. Fonte editável e prévia em `art/characters/mae-walk-v1/`; runtime em `godot/assets/npc-ds/mae-walk.png` (256×768).

`room_view` agora usa os estados reais de caminhada e escada para selecionar os quadros, voltando à pose parada ao terminar. O shader de recorte reconhece tanto o atlas estático de duas linhas quanto o animado de oito linhas. Assim, o recorte de entrada/saída da escada continua funcionando. Os trajetos e as falas não foram alterados.

Crítica independente: 7,5/10, sem bloqueios. Observação registrada: a saia longa deixa a alternância dos pés mais discreta nas diagonais. Subida e descida foram conferidas no jogo; capturas nesta pasta.

## Professor

- Escurecimento suave com aberturas nos alvos: parceiro, destino ou cruzamento, comando atual, instrução e pausa.
- Guia persistente até a ação ser concluída. Desaparece na pausa, na conclusão e nas cenas de recolher a pipa.
- Instruções curtas e específicas para cada ferramenta. Após ativar a habilidade, o destaque muda para o corte.
- Energia visível, sem o balão do professor cobrindo o cartão de status.
- Avançar aparece somente quando a tarefa termina, separado do balão.
- Passar o mouse pelo campo não movimenta mais o Pipamon: movimento por mouse exige clique ou arraste.
- No exercício de ferramentas, recargas curtas permitem repetir um erro sem esperar até vinte segundos. Isso se aplica ao tick do treino, sem alterar as regras de batalha, XP ou recompensas.

## Verificação

- `mother_walk_checks.gd`: 62 verificações, zero falhas. Direções, quatro quadros, repouso, dimensões, shader e subida/descida em execução.
- `tutorial_guidance_checks.gd`: 46 verificações, zero falhas. Persistência, input, alvos, texto por ferramenta e repetição rápida.
- `lesson_hud_checks.gd`: 520 verificações, zero falhas. Quatro resoluções, movimento normal/reduzido, pausa, margens e conclusão.
- `campaign_checks.gd`: 206 verificações, zero falhas.

Capturas nativas a 1280×720; `lesson-0.png` a `lesson-4.png`, `mae-subindo.png`, `mae-descendo.png`. Os testes são automatizados; não representam avaliação de diversão por jogadores novos.

O pacote interno em `godot/exports/demo-test-2026-10-31/` foi atualizado e executado fora do projeto. Carregou a caminhada da mãe e o treino com spotlight, com saída 0 e sem erros no log de execução. Evidências: `mae-pacote.png` e `tutorial-pacote.png`.
