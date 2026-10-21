# Save, bancos e navegação direta

## Comportamento

- Uma campanha atual por conta. História e resultados continuam sendo salvos automaticamente pelos serviços existentes.
- **Salvar jogo** registra mapa, posição e direção na conta; **Continuar save** retoma a posição com validação das colisões e dos desbloqueios atuais. Não restaura moedas ou itens de uma fotografia antiga.
- Menu → Opções → **Save e bancos**.
- **Banco do save: 30 indivíduos. Global da conta: 20 indivíduos**, separados. Repetidos ocupam espaços distintos. Transferir mantém o mesmo identificador, nome e XP; não cria cópias.
- A seleção de transferências é uma prévia. **Aplicar transferências** ou **Salvar jogo** confirma a operação no servidor. Fechar sem aplicar abandona a prévia.
- O global protege os indivíduos contra reinício da campanha. Não duplica nem altera propriedade: negociar ou perder uma pipa colecionável remove sua reserva global automaticamente.
- Quando o banco do save está cheio, receber outro Pipamon é bloqueado até transferir ou descartar uma cópia. Invocação e ingresso em Vale pipa verificam espaço antes de iniciar.
- O descarte exige selecionar a cópia e digitar **EXCLUIR PIPAMON**. A propriedade é removida; o registro histórico continua no PostgreSQL.
- Reinício exige **EXCLUIR SAVE**. Preserva os indivíduos escolhidos para o global e descarta todos os demais. Reinicia abertura, treino e desbloqueios. Preserva moedas, compras, itens, XP da conta, histórico e registros de prêmios únicos.
- Cada campanha permite um **novo Rabbito**. A concessão é única por geração da campanha, mesmo com repetição de pedidos ou outra aba.
- O registro de primeira vitória e as concessões de rabiolas permanecem. Reiniciar não repete bônus únicos. As recompensas normais de revisitar batalhas continuam.

## Movimento

Setas, WASD, direcional ou analógico esquerdo controlam Kael no chão autorizado do mapa. O movimento usa varredura dos pés, normalização diagonal e deslizamento junto às paredes, sem se prender às arestas do grafo usado pelo clique.

Portas e saídas têm setas azuis discretas e entram automaticamente ao avançar até a passagem. O retorno tem trava de reentrada até se afastar, evitando alternância infinita entre salas. Rivais continuam bloqueando saídas ainda não liberadas pelo servidor. Conversar e examinar usam E / A.

Menus, diálogos, carregamento, perda de foco e troca de conta suspendem a caminhada e limpam entradas pressionadas.

## Migração

Aplicar **019_campaign_saves.sql**, após 001–018, antes de publicar o servidor novo. O ambiente local aplica esta migração automaticamente; nenhum banco de produção é alterado por esse procedimento local.

Novas tabelas: player_campaign_saves, player_pipamon_storage, campaign_reward_history, campaign_story_births e campaign_kite_discards. Tabelas privadas, RLS ativada e acesso somente por funções autorizadas.

A migração permite proprietário nulo para indivíduos descartados, preservando referências históricas. Ajusta os gatilhos de avistamento, procedência de Souls e XP de partidas canceladas. A unicidade das Souls permanentes continua, exceto Rabbito, que pode ter uma cópia por campanha.

As mutações serializam no perfil e conferem revisão e inventário esperado. Partida, troca ou ritual ativos impedem alterações de save. Reinício marca resultados antigos ainda pendentes como cancelados, sem XP, prêmios ou desbloqueios tardios.

Contas anteriores não perdem Pipamons na migração. Coleções já acima de 30 aparecem integralmente e precisam organizar seus bancos antes de receber novos indivíduos; nada é descartado automaticamente.

## Validação

campaign.test.mjs cobre 30 + 20, propriedade, revisão, confirmação, reinício, novos Rabbito, descarte e bônus únicos. first-flight.test.mjs cobre controle direto, portas automáticas, trava de retorno e suspensão sob menus. A suíte completa também verifica economia, trocas, invocação, abertura e combate.
