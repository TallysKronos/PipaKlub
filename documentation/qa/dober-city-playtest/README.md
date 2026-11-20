# Playtest visual do Dóber na cidade

Executado no Godot 4.7.2 com renderização Compatibility, janela de 1280 × 720 e um perfil de teste isolado.

O percurso usa os controles de movimento da campanha. Foram verificadas caminhada sudoeste, corrida, parada, subida e descida da rampa da Ladeira das Rabiolas. A interação foi conferida com Zeca na rua baixa e Assis na rua alta, incluindo a remoção do contorno ao sair do alcance.

O teste encontrou uma diferença de escala e apoio entre repouso e movimento. A calibração dos 16 ciclos foi corrigida e registrada em `art/characters/dober-overworld-iso/calibration.json`. A média da altura e do apoio dos quadros fica a até 1,5 px da pose parada na escala base. A variação de cada passada é preservada.

Resultados após a correção. Dezessete verificações no percurso e dezesseis ciclos na revisão de alinhamento, sem falhas. A inspeção das capturas foi feita na escala da tela.

- [Caminhada sudoeste](01-caminhada-sudoeste.png)
- [Corrida sudoeste](02-corrida-sudoeste.png)
- [Retorno ao repouso](03-repouso-sudoeste.png)
- [Subida da rampa](04-subida-rampa.png)
- [Contorno na rua baixa](05-contorno-zeca.png)
- [Contorno na rua alta](05-contorno-assis.png)

Repetir com `godot/tools/dober_city_playtest.gd` e `godot/tools/dober_alignment_review.gd` em modo gráfico. As evidências cobrem esse percurso e esses NPCs.
