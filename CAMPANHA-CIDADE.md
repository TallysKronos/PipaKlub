# Campanha da cidade — direção aprovada

Status: desenho da próxima expansão. A entrega atual fecha a base de recompensas online das três Trilhas existentes; o mapa de 12 bairros e a disputa de títulos ainda não estão implementados.

## Decisões do criador

- Prioridade de plataforma: PC, com intenção de lançamento na Steam quando o jogo amadurecer.
- Campanha solo conectada à conta, com recompensas na economia online. “Offline” aqui não significa jogar sem internet.
- Uma cidade com 12 bairros. Cada bairro tem quatro capangas e um quinto adversário, o campeão: 60 batalhas de progressão básica.
- Vencer o campeão desbloqueia o bairro seguinte.
- Enquanto for campeão de um bairro, o jogador pode receber um desafio de NPC e deve defender o título.
- Perder a defesa torna aquele NPC campeão. O jogador precisa vencer os quatro capangas novamente antes de desafiá-lo para recuperar o título.
- Concluir os 12 bairros libera uma sequência final de batalhas para determinar o campeão da cidade. O tamanho e os integrantes dessa sequência ainda serão definidos.

## Modelo proposto para implementação

Separar o histórico permanente da história do estado atual de domínio. `bairro_concluido` e `bairro_desbloqueado` não são apagados ao perder uma defesa. O título atual, o NPC que ocupa a posição e a requalificação contra capangas são estados separados por conta. Cada jogador tem o estado de sua campanha solo; isso não cria um único título global compartilhado entre todos os jogadores.

Estados de um bairro: bloqueado → quatro capangas → campeão disponível → jogador campeão. Uma defesa vencida mantém o título. Uma defesa perdida registra o novo campeão e reinicia a qualificação dos quatro capangas, preservando recordes, itens recebidos e bairros já desbloqueados. O adversário do quinto encontro passa a ser o atual ocupante do título.

Os desafios devem ser criados pelo servidor e persistidos na conta, com um identificador idempotente. Proposta: apresentá-los ao retornar ao mapa, sem interromper um duelo ou ritual. A defesa pendente não desaparece ao recarregar. Fechar a aplicação não deve decidir uma derrota silenciosamente; deve haver retomada do desafio ou desistência explícita. Frequência, intervalo e critérios para um NPC desafiar ainda precisam de ajuste de game design.

A sequência municipal usa o histórico de conclusão dos 12 bairros. Proposta: perder depois um título de bairro não apaga o acesso à sequência final já conquistado. Isso evita zerar a história por uma defesa perdida.

## Recompensas e integridade

Reutilizar registro de partida, validação de combate, carteira e recibos da migração 014. Uma batalha deve registrar seu contexto imutável: progressão, defesa, reconquista ou final municipal. O resultado, a troca do título, a qualificação, os desbloqueios e as recompensas devem ser liquidados na mesma transação.

Uma primeira recompensa de bairro permanece única por conta, mesmo após perder e reconquistar o título. Não limpar `trail_drop_claims` ou consumir novamente o bônus de primeira conclusão para permitir a reconquista. Repetições e retomadas usam o identificador da mesma partida; importações do navegador não podem definir campeões nem criar recompensas.

## Próxima etapa de construção

1. Definir os 12 bairros e seus NPCs, aproveitando Mikka, Lohan e Kleie onde fizer sentido; não alterar IDs existentes sem migração explícita.
2. Criar estados por conta de campeão, ocupante do título, capangas de requalificação e desafios pendentes, com testes de concorrência, retomada e derrota.
3. Integrar um mapa da cidade com caminhos, campeões atuais e defesa pendente; foco em mouse, teclado e apresentação para PC.
4. Expandir o catálogo para 60 encontros e configurar a sequência municipal com nomes e quantidades aprovados.
5. Auditar o percurso: primeiro bairro → desbloqueio → defesa perdida → quatro capangas → reconquista sem prêmio duplicado → 12 conclusões → campeonato municipal.
