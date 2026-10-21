# Parque dos Ventos, progressão e classes — 21/10/2026

## Entrega

O parque é uma área opcional após o primeiro voo, acessível pela Rua dos Ventos ou por Jogar → Exploração e campanha. Há duas telas editáveis no Tiled: Trilha Clara e Clareira. Ambas usam o kit de terreno, vegetação e banco já existente, com colisões nos troncos, profundidade e entradas automáticas. Não foram geradas novas ilustrações nesta etapa.

Caminhar no gramado acumula entre 1.900 e 2.900 unidades de percurso para um encontro. Parado, nos caminhos de terra, em menus ou em carregamento, não acumula. Há uma proteção inicial e de 12 segundos ao retornar. A placa e o objetivo na HUD explicam os habitats. Os mapas ficam em `assets/world/park-v1/`; `scripts/build-park-content.mjs` é o gerador de autoria, não deve ser executado sobre edições manuais sem revisão.

## Progressão

- Tamer: níveis 1–100, limiar `20*(nível−1) + 3*(nível−1)²`, máximo 31.383 XP.
- Pipamon: níveis 1–50, curva existente preservada, máximo 25.970 XP.
- XP de combate do tamer: 20% do XP efetivamente recebido pelo parceiro, arredondado para baixo. Parceiro no máximo não gera XP de combate para o tamer.
- Descoberta inédita: 5 XP do tamer; primeira invocação de cada espécie: 20 XP. Estes bônus são únicos por conta e não repetem com reset do save. O nascimento de Rabbito entra no mesmo registro por espécie.
- Skills de tamer são futuras. Esta entrega não concede pontos nem promete habilidades já utilizáveis.
- O limite diário antigo de 2.000 XP do Pipamon foi removido para eventos verificados. Os limites individuais e a idempotência continuam.

A migração mantém `xp` legado para compatibilidade e introduz `tamer_xp`, inicialmente copiado com teto de 31.383. Os níveis visíveis são recalculados pela nova curva. Contas existentes recebem marcos zerados de espécies já vistas/possuídas para evitar recompensas retroativas repetidas. O balanceamento da curva e dos valores iniciais é uma hipótese de protótipo, a validar com sessões de jogo.

## Encontros e recompensas

Cada encontro é uma partida solo online de uma vitória. O servidor escolhe espécie, nível e sorteio de rabiola uma única vez. Antes do primeiro drop, aparecem Carcará ou Mata Verde. Depois: Carcará 50%, Mata Verde 35%, Raio 15%. Níveis 1–3 na trilha e 2–4 na clareira.

Vitória: 20 XP do parceiro na trilha, 30 na clareira ou contra Raio. A primeira vitória garante a rabiola da espécie; depois, 25% de chance, com garantia na oitava vitória após sete sem drop. Fuga, derrota e abandono não concedem XP de combate nem rabiola. Descobrir uma espécie continua sendo um evento próprio, mesmo que o jogador fuja depois.

Fuga por F, pelo botão ou pelo menu de pausa. Derrota retorna ao apoio da trilha; fuga/vitória preservam o lugar. Não se perde parceiro ou item. A rabiola é um consumível normal, utilizável no sistema de invocação existente.

Só o servidor pode registrar e liquidar encontros; clientes podem consultar seus recibos e abandonar seus próprios encontros. Conta, parceiro e partida são associados no PostgreSQL. Há um encontro pendente por conta e intervalo mínimo de 20 segundos entre criações. Retomada conserva o mesmo encontro e sorteio; sem a credencial local da sala, pode-se encerrá-lo sem recompensa. Salas sem conexão ativa são encerradas após o prazo existente de 15 segundos. O outbox persiste e tenta novamente resultados pendentes. Reiniciar a campanha invalida encontros pendentes antigos. Histórico técnico fica em `wild_runs`; o recibo aparece na conclusão da batalha.

## Classes do Rabbito

Clube → Classes do Rabbito abre o ateliê no professor. Apenas instâncias próprias de Rabbito podem ser especializadas. Nível 15 libera a escolha; 35 libera aprimoramento. O banco bloqueia mudanças em partida, troca ou ritual ativo. Versão do parceiro impede confirmação de uma tela desatualizada.

| Caminho | Classe | Aprimoramento |
|---|---|---|
| Velocista | +8% velocidade, +4% regeneração, −5% linha | Rastro dos Ventos: +16% velocidade, +8% regeneração, −5% linha |
| Condutor | +4% ataque, +8% regeneração, −5% velocidade | Mestre dos Fios: +8% ataque, +16% regeneração, −5% velocidade |

Reespecialização gratuita conserva nome, XP, nível, identidade e o aprimoramento já conquistado. As diferenças visuais iniciais são rastros ciano ou anéis dourados sobre a arte atual, com respeito à redução de movimento. Formas/sprites próprios, classes de outras espécies e skills exclusivas ficam para aprovação artística e de balanceamento posterior.

## Instalação e validação

Aplicar migrações 019, 020, **021_tamers_and_classes.sql** e **022_wild_encounters.sql**, nessa ordem, antes de publicar o servidor correspondente. As duas últimas são migrações únicas, transacionais. Fazer backup e validar em ambiente de homologação. O adaptador local instala as ausentes na ordem correta; nenhuma alteração foi aplicada ao Supabase ou ao Render nesta entrega.

`rpg.test.mjs` executa todas as migrações em PostgreSQL embarcado e verifica limites, especialização, preservação de nome/XP, controle de versão, acesso entre contas, bloqueio em partida, permissões, recibos imutáveis, primeiro drop, garantia após sete falhas, ausência de recompensas em fuga/derrota/abandono, teto de XP e invalidação após reset. A suíte completa passou com 321 testes. Auditoria no navegador confirmou entrada no parque, caminhada com obstáculos, encontro aleatório, fuga com recibo de zero XP e retorno ao parque.

Antes de lançamento: ajustar ritmo de encontros/XP com playtests; criar fauna e paisagismo próprios; validar dificuldade do parque nos níveis 1–50; testar uma sessão longa de progressão e instabilidade real de conexão. Os mapas atuais são uma primeira área funcional, não o acabamento artístico final de Steam.
