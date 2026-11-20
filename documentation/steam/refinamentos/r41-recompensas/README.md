# R41 — recompensas reservadas e escolha de destino

05/11/2026. Base 7419176d. Produto Godot e perfil local.

## Fluxo entregue

- Operações de aquisição que adicionam criaturas passam a registrar o direito e sua identidade antes de confirmar a entrega. Se houver lugar, a criatura entra normalmente; sem lugar, fica em `pendingPartners`, sem ultrapassar 30 e sem perder seus atributos.
- A fila reaparece ao retomar o jogo e pode ser consultada em Pipamons e Banco e depósito. Mostra nome, arte existente, registro da instância, lotação e destinos disponíveis.
- Recompensa opcional: receber na campanha, guardar diretamente no depósito se houver vaga, abrir espaço com liberação confirmada de uma criatura elegível, recusar explicitamente ou receber depois. Ter 30/30 e 20/20 não apaga a reserva.
- Rabbito, Retalho e parceiros essenciais não oferecem recusa nem depósito direto. Podem ser recebidos após liberar uma vaga elegível. O parceiro ativo e os vinculados à história não podem ser usados como vítima da substituição.
- Uma reserva essencial impede prosseguir automaticamente ao trecho que depende dela; o jogador pode voltar ao menu mantendo a reserva. Se uma cópia antiga estiver numa batalha/oficina, a decisão é adiada até um ponto seguro. Escape/voltar na substituição retorna à fila, sem liberar ninguém; na fila segue a mesma regra do botão de saída.
- Liberar uma criatura e receber outra compartilham uma intenção recuperável: interrupção não deixa uma criatura liberada sem a recompensa correspondente. Confirmações começam em Cancelar e identificam o registro da recompensa.

## Identidade, rabiolas e retomada

`partner_rewards.gd` usa o registro de propriedade do perfil e indexa cada aquisição por campanha e operação de origem. Retomar uma cópia anterior ao nascimento e repetir a mesma operação reutiliza a identidade já conquistada, sem gerar uma segunda instância. Reserva resolvida, transferida, recusada ou liberada não reaparece ao carregar o arquivo antigo. Campanhas novas têm outro identificador e continuam podendo conquistar outro Rabbito.

A invocação usa o serviço existente da oficina. Sua rabiola já foi consumida ao iniciar; concluir com banco cheio grava a criatura reservada e o recibo, sem cobrar outra. Escolher destino ou recusar não devolve itens utilizados nem repete o ritual. Cancelar uma confirmação mantém os dois lados intactos.

O fluxo antigo “Retalho aceito, mas esperando vaga” é convertido para a reserva geral ao voltar à interação de acolhimento. Não há mais liberação e adoção em duas gravações independentes. Sua concessão continua sem conceder categoria da Liga. A identidade do parceiro e sua arte de batalha são verificadas no teste de confiança.

Parceiros de história recebem marca para não serem reinjetados quando uma cena os retira legitimamente da equipe, como a devolução de Retalho à mãe. A fila ainda pertence à campanha: excluir a campanha não move recompensas pendentes para o depósito global; desfazer a exclusão recupera o vínculo.

## Persistência e compatibilidade

Aquisições e decisões de recompensa, assim como transferências, **gravam um ponto de segurança mesmo com autosave desligado**. A configuração informa essa exceção. Outros avanços sem aquisição continuam seguindo a preferência de autosave.

O perfil passa à versão 2 na primeira operação nova. A versão 1 continua legível e suas criaturas permanecem preservadas; uma versão anterior do jogo poderá reconhecer o novo perfil como futuro e recusar acesso. Leituras JSON aceitam a representação numérica desserializada da versão. Uma regressão nesse ponto foi encontrada e corrigida antes da entrega.

O registro mantém uma intenção com a fotografia seguinte da campanha e depois conclui o recibo. Falhas de gravação antes do compromisso não publicam aquisição; falhas posteriores são retomadas ao reabrir. Se faltarem o perfil ou recibos necessários para justificar as instâncias de um save, o jogo preserva os arquivos e recusa usar um depósito vazio como substituto.

## Cobertura e limites

Nova suíte `pending_rewards_checks`: **110 checks, zero falhas**, com serviços reais de nascimento de Rabbito, acolhimento de Retalho e invocação pela oficina. O ritual usa o modelo e a fixture de eventos existente; não representa uma pessoa completando o minigame. Exercita 30/30, 20/20, recibos, nomes/IDs após rollback, destinos indisponíveis, substituição/recusa, falhas antes/entre/depois das gravações, reabertura, migração v1, perfil ausente e confirmações/voltar na interface. Se uma vaga abrir depois da tela, uma confirmação antiga de substituição é recusada sem liberar ninguém; o jogador pode receber na vaga livre.

O teste `retalho_trust_checks` foi atualizado para a nova transação e passou em **97 checks**; os resultados de combate continuam sendo fixtures. A liberação de áudio no encerramento agora é aguardada. Novos testes integram o runner e rejeitam vazamentos no encerramento.

Regressões executadas, sem falhas: resiliência 152; campanha 207; autosave/slots 55; exclusão/reinício 216; banco 113; título 350; ciclo de menu 55; feedback 35; recuperação de autosave 13; controles 44. Com as duas suítes acima, são **1.447 verificações em 12 suítes selecionadas**. A fila foi capturada e revisada no renderizador real; o runner completo de 25 suítes não foi executado.

Capturas Godot a 1280×720, OpenGL Compatibility/GTX 1650: [fila](pending.png), [escolha para abrir espaço](replacement.png).

Encontros selvagens atuais entregam rabiolas; **captura direta de criaturas ainda não está implementada**. A API genérica de concessão suporta a futura recompensa, mas o teste com origem de captura é uma fixture, não comprova uma mecânica jogável nova. Também não foram certificados históricos arbitrários de antes do registro de origem, todas as combinações de replay narrativo após liberar parceiros únicos, uso prolongado com bancos cheios, outros tamanhos/textos ampliados, controle físico, Steam/online, duas instâncias simultâneas, corte físico de energia, nova exportação ou CI remota. O runner completo não foi executado neste pacote.
