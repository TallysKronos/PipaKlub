# Etapa 1 — arco fechado da demo

31/10/2026. Integração local no Godot; não publicada.

O trecho termina na devolução da rabiola à Nina: abertura → professor/primeiro voo → oficina → Jardim → Clareira → Veredas → Lacertubo → recolher rabiola → retornar à Nina. Vencer o boss ou recolher o item, isoladamente, não conclui o trecho.

A entrega agora usa um diálogo de agradecimento antes da tela **Um fio de volta para casa**, no kit Recorte existente. A tela oferece continuar explorando, abrir o mapa de Kronasta ou voltar ao menu. Escape continua a exploração. O objetivo do parque deixa de pedir o resgate após a entrega. Não foram acrescentadas revelações da história nem recompensas de XP, dinheiro ou itens.

## Persistência e retomada

- A entrega consome o item e salva `ninaReturned` na mesma operação existente; exige missão aceita, vitória e posse da rabiola. Repetições não concedem nada.
- A conclusão é reconhecida também nos saves anteriores que já devolveram a rabiola. O checkpoint continua sendo a posição no mundo.
- Se o jogo fechar antes de escolher uma ação no encerramento, a tela reaparece ao carregar. A escolha salva `demoEndingSeen` com recibo `demo-ending-v1`; depois disso a jornada retoma normalmente.
- Se o salvamento falhar, não se avança a tela nem se publica o estado em memória. A rabiola permanece disponível quando a entrega falha.

## Verificação executada

Saves e preferências isolados em `tmp/playtest-humanlike/appdata`, sem usar jornadas reais.

- `campaign_checks.gd`: 206 verificações, incluindo abertura, primeiro voo/oficina, recompensas, boss e entrega.
- `park_journey_refinement_checks.gd`: 157 verificações de progressão, treinadores, combate, recuperação, quest e caminhos. O agente automatizado fez 12 vitórias selvagens e terminou os seis treinadores no nível 5; isso não comprova diversão ou uma partida humana até o nível 8. A dificuldade não foi reduzida nesta etapa.
- `demo_completion_checks.gd`: fluxo real da interação com Nina e confirmação do diálogo, encerramento, proteção contra entrega antecipada/remota, salvamento interrompido, conflito de revisão, ações do mapa/menu, Escape e retomada sem repetição. Também verifica foco e limites dos botões.
- `player_flow_checks.gd`: 7 verificações aprovadas; o runner ainda emite avisos de objetos/recursos em uso no encerramento do processo.

Capturas do renderer nativo em 1280×720 e 1920×1080, inspecionadas visualmente: [720p](ending-1280x720.png), [1080p](ending-1920x1080.png). As capturas usam uma jornada de teste próxima à conclusão. Esta etapa não equivale a um novo playtest humano completo nem fecha a preparação de distribuição da demo.
