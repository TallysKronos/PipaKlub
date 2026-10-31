# Correções do playtest — abertura e vila

Branch: `codex/integracao-bosque-kronasta`. Godot 4.7.2, Windows, renderizador Compatibility. Alterações locais sobre `9acf2fd8`.

O playtest pela interface percorreu a abertura, a entrega da rabiola, a criação/nome do Rabbito, a descida para a sala e a chegada à vila. Foi interrompido pelo usuário antes do professor. Os problemas abaixo foram observados nessa sessão; esta entrega corrige esses problemas e verifica os estados afetados com fixtures isoladas. Não representa aprovação do ciclo completo, combate ou progressão até nível 8.

| Problema observado | Correção |
| --- | --- |
| Mapa da vila era um retângulo vazio | Ruas, calçadas e escada derivadas das células reais, mescladas sem grade decorativa. Projeção compartilhada com o jogador. Identificação dos três locais públicos: casa, ateliê e loja. O minimapa recebe os mesmos caminhos. |
| Fala da Nina coberta pelo HUD | Vila usa o diálogo mangá compartilhado, com retrato, paginação e foco. HUD/minimapa ficam ocultos durante a conversa e voltam ao encerrá-la. Movimento bloqueado enquanto a fala está aberta. E continua funcionando para avançar. |
| Próxima ação obscura no quarto/sala | Dica persistente explica mesa, escada ou porta, com WASD/setas (ou analógico). Marcador aparece no ponto de interação. A dica de E aparece somente perto do alvo permitido pela etapa. |
| Escada exigia aproximação muito precisa | Alcance da interação ampliado de 110 para 150 nas coordenadas do quarto, incluindo a aproximação apoiada junto ao patamar. Colisão e geometria preservadas. |
| Botão de continuar próximo da borda | Reposicionamento após o cálculo de tamanho mínimo do container, com espaço para a ponta decorativa. |

## Validação

- `playtest_ui_regression.gd`: **70 verificações, zero falhas**, em viewports renderizados 1280×720 e 1920×1080. Inclui mapa, correspondência de ruas/calçadas/escada, distinção de gramado, posição do jogador, diálogo e restauração do HUD, bloqueio de movimento, comando E e abertura nas etapas 3, 11 e 13.
- `controls_checks.gd`: **44 verificações, zero falhas**.
- `campaign_checks.gd`: **206 verificações, zero falhas**.
- Capturas nativas em `fixes/`, sem montagem. Inspeção visual do mapa nas duas resoluções, diálogo da Nina e orientação do prólogo. Imagens de Nina usam uma fixture no ateliê; o texto foi reproduzido sem precisar repetir a campanha inteira.
- Saves e configurações em diretórios isolados de QA; save pessoal preservado.

Exemplos: [mapa corrigido](fixes/map-1280x720.png), [fala da Nina](fixes/nina-1280x720.png), [escada indicada](fixes/opening-11-1280x720.png), [objetivo da mesa](fixes/opening-3-1920x1080.png).

## Execução

O teste de interface exige renderização porque o carregamento da vila espera um frame desenhado; ele recusa execução headless explicitamente. Executar com `--script res://tests/playtest_ui_regression.gd -- --capture`, no projeto `godot/`. O teste carrega o front-end depois dos autoloads. Suites antigas que pre-carregam o front-end na inicialização apresentaram erro de resolução de `PixelgenSprites` em `--script`; não foram consideradas validação aprovada desta entrega.

A limitação inicial de teclas no controle remoto era da automação (código físico repetido), não um bloqueio do jogo. A avaliação de diversão do combate e do restante da campanha continua pendente do playtest completo.
