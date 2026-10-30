# Kael: idle e corrida

Implementado na campanha Godot da branch `codex/integracao-bosque-kronasta`.

## Arte e origem

- Repouso construído das oito referências aprovadas de Kael, com pernas fixas e respiração por camadas no Aseprite. A pose antiga era o primeiro quadro da caminhada, com uma perna em movimento.
- Corrida gerada com MiniMax H3 instalado localmente. Referências, prompts, graphs e identificadores em `references/`, `workflows/` e `jobs.json`; ciclos selecionados em `selections/`.
- A primeira execução NE falhou na leitura do modelo. A repetição gerou cenário e mudou para perfil; vídeo e seleção estão identificados como `rejected-background`, fora dos assets de runtime. A terceira execução mantém vista traseira e fundo limpo. O seletor agora rejeita bordas contaminadas e separa extrações pelo hash do vídeo.
- Grade nativa 64×96, pivô 32,94, 32 cores opacas já existentes e transparência binária. Um único recorte/escala por clipe conserva o voo. Nenhum ajuste de tamanho por quadro.
- Fonte Aseprite do idle com três camadas; corrida com correções localizadas nas botas de N, fases 6 e 7. Operações dessas correções em `aseprite/boot-fixes.json`.
- Revisão independente: idle 8/10; corrida inicial 7,5/10 com reparo obrigatório nas solas; corrida corrigida e NE 8/10, sem bloqueantes visuais. Isso não substitui aprovação do jogador.

## Comportamento

Idle anima ao parar, sem congelar um passo. Caminhar preserva a velocidade e os desenhos anteriores. Corrida usa oito poses distintas por direção, 640 ms por ciclo e deslocamento de 1,8×. Shift segurado, L3 ou botão do HUD; a tecla segue a configuração de esquiva sem mudar a esquiva de batalha. Reentrar em uma área preserva o remapeamento atual.

Os controladores reais de bosque/parque/morro, cidade e interiores recebem o multiplicador somente durante exploração manual. O caminho por clique também respeita o modo de corrida. Diálogos, pausas, escada vertical, item e salto mantêm suas regras. O seguidor aumenta a velocidade nos passos seguros já aceitos, sem atalhar obstáculos.

## Verificação

Com Godot 4.7.2 e dados locais isolados em `tmp/kael-test-appdata`, sem abrir saves do jogador:

- `locomotion_checks.gd`: 222 verificações, zero falhas, tanto headless quanto renderização nativa em 1280×720. Medição em 0,5 s: caminhada 1,500006 células, corrida 2,700005 células. Inclui paleta, alpha, 64 poses por ação, apoio do idle, mudança de estado, prioridade de escada, pausa, Shift, botão e L3 simulado.
- `locomotion_city_room_checks.gd`: 11 verificações, zero falhas. Movimento dos controladores reais de cidade e quarto, razão de velocidade, conversa e movimento de cutscene.
- `locomotion_traversal_checks.gd`: 72 destinos nas Veredas, 144 percursos, 36.900 passos de simulação, zero falhas. Rampas, pontes, apoio do jogador/seguidor e saída/retorno entre áreas, em corrida.
- `controls_checks.gd`: 44 verificações, zero falhas; `campaign_checks.gd`: 206, zero falhas.
- Pixelgen: seis testes de catálogo/rotas/save/autosave passaram; os projetos reais `kael-idle` e `kael-run` abrem e produzem previews no serviço do álbum.
- Importação das duas novas texturas pelo editor Godot concluída. O editor emitiu um diagnóstico de safe-save de preferências; os recursos foram importados e os testes nativos executaram.

`review/technical.json` e `manifest.json` registram o contrato. `review/idle-in-game.png` e `run-in-game.png` foram inspecionados em 1280×720; o botão cabe também nas verificações geométricas de 800×600 e 1920×1080. Estas duas últimas resoluções não são capturas nativas. GIFs `review/kael-idle.gif` e `kael-run.gif` apresentam a direção SE; fontes de prévia editáveis acompanham esses arquivos.

Controle físico e avaliação humana de fluidez não foram realizados. Não houve push nem alteração da curva de XP, encontros ou recompensas.
