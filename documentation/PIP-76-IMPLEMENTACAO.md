# PIP-76 · Menus de conteúdo

Implementação local sobre o visual aprovado na PIP-75. Mantidos os recortes, fontes e cores compartilhados. Não foi substituído o desenho aprovado por uma nova composição do ticket.

- Pausa: jogo congelado, véu, retícula a 8%, escada de 18 px, Mapa e Salvar jornada separados de Voltar ao menu. Voltar das páginas reconstrói a pausa e restaura o foco na ação de origem.
- Mapa: quadro amplo da geometria caminhável real da área e posição atual; sem marcadores de NPCs, baús ou saídas. Acesso pela pausa e pela ação remapeável de mapa durante exploração. É um mapa esquemático, não uma nova ilustração do bioma.
- Equipe: nomes longos com reticências e tooltip, condição e XP, destaque ciano do parceiro ativo e paginação conforme altura disponível.
- Mochila: páginas de itens inteiros calculadas pela altura útil; LB/RB e teclas remapeadas de guarda/puxão trocam categorias; vazio com ação; estados de carregamento (três losangos) e erro com repetição da leitura do snapshot. NOVO identifica tipos ainda não consultados nesta execução; esse indicador não altera o save.
- Configurações: abas Vídeo/Acessibilidade/Controles com LB/RB; valor do interruptor junto à opção; escala de texto 100/115/130% persistida nas preferências locais, com fallback seguro para arquivos antigos. Texto nativo, sem ampliar texturas ou bordas.
- Controles: captura e conflito na própria linha; Esc cancela, remapeamento válido preserva o foco na ação e Voltar retorna ao botão de Controles em Configurações.
- Estados reutilizáveis de lista em hud_list_state.gd. Listas locais são síncronas: não há espera artificial no fluxo normal para simular uma carga inexistente.
- Confirmações continuam com Cancelar inicial e navegação restrita à janela.

## Verificação

Dados e preferências isolados. Capturas em 1280×720, 1280×800, 1920×1080 e 2560×1080, em mockups/revisao/pip76.

O player_visual_audit.gd foi corrigido para verificar a validade de linhas após um reflow que pode substituí-las; ele continua medindo os cortes das linhas existentes. A decoração do botão de estado vazio não recria a rabiola durante reflow, evitando uma falha nativa observada no Godot.

Auditoria de pausa, bag-empty, bag-full, team-long, settings e controls: 24 combinações renderizadas, zero achados em tmp/player-audit-2026-10-26/pip76-verified2/measurements.json. Regressão de menus: 349 verificações sem falhas. Testes adicionais em res://tests/pip76_checks.gd validam mapa, gravação, retorno de foco, abas por eventos de controle, página sem corte, estados, preferência e conflito na linha.

Ainda não houve teste com controle físico nem exportação de executável desta revisão. Nenhuma alteração de status no Linear e nenhum envio desta revisão ao Git.

Aceite técnico final: pip76_checks.gd terminou com 82 verificações sem falhas; title_menu_checks.gd com 349. Nova execução final do player_visual_audit.gd após os últimos ajustes: 24 cenas renderizadas, zero achados e log de erros vazio, evidência em tmp/player-audit-2026-10-26/pip76-acceptance/measurements.json. Capturas finais em mockups/revisao/pip76.
