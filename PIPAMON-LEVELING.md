# Níveis individuais dos Pipamons

O XP é da instância `player_kites.id`. Duplicatas da mesma espécie evoluem separadamente. Troca e captura mantêm o XP que já estava na pipa. O nível da conta do pipeiro e a dificuldade da IA continuam separados.

## Curva e brilho

Todos começam no nível 1, com zero XP individual. Não há conversão do XP antigo da conta. O máximo é 50 / 25.970 XP. O total necessário ao nível L é `40 × (L − 1) + 10 × (L − 1)²`.

| Nível | Efeito |
|---|---|
| 1–19 | Sem partículas de progressão |
| 20–29 | Prata |
| 30–39 | Ouro |
| 40–44 | Platina |
| 45–49 | Diamante |
| 50 | Aura, com brilho e aro adicional |

A interpretação de “acima do level 20” nesta versão é desbloquear no próprio nível 20. As partículas são estrelas vetoriais no canvas: até 16 por pipa, quatro no modo leve, três estáticas com movimento reduzido. Não criam temporizadores ou sprites adicionais. Também aparecem na prévia animada do inventário.

## Status no combate normal

| Status | Nível 1 | Nível 50 |
|---|---:|---:|
| Linha | 100 | 120 |
| Energia | 100 | 115 |
| Ataque | 100% | 112% |
| Defesa | 100% | 110% |
| Velocidade | 165 px/s | 178,2 px/s |
| Recuperação sem atacar | 18/s | 19,8/s |

Os valores crescem linearmente. Dano final usa `ataque do atacante / defesa do defensor`, além das regras atuais de geometria, crítico e proteção. Custos, recargas e janelas de ataque não mudam. Reset de rodada, respawn, previsão de movimento e barras usam os mesmos limites. O protótipo As Alturas continua independente.

O nível usado na sala vem de `reserve_player_match`, nunca de dados de entrada do navegador. Ele fica congelado até o próximo duelo; o ganho após o resultado não muda os status no meio da partida. Se uma captura trocar a pipa pela básica, o nível visual e os próximos limites passam a ser os da básica.

## Fontes de XP

- Corte entre contas: 25, respeitando o limite já existente de cinco cortes contra a mesma conta em 24 horas.
- Trilha: 120 na primeira vitória; 80 em vitória repetida; 20 em derrota confirmada.
- Desafio diário: 100 na primeira vitória elegível daquele dia, junto ao recibo existente das moedas.
- Treino local, visitante, importação de progresso e desistência sem resultado não dão XP individual.

Teto de 2.000 XP por conta por dia UTC, somando todas as instâncias. O teto de nível também limita o valor efetivamente creditado. Eventos repetidos não podem render XP novamente. O parceiro elegível é o registrado na entrada da partida; uma instância já perdida em Vale pipa não recebe crédito do antigo dono. A criatura recebida como captura não recebe o XP do atacante.

## Persistência e ativação

Aplicar `supabase/migrations/016_pipamon_leveling.sql` uma única vez, antes do deploy. A migração adiciona uma coluna de XP, referência da pipa em `match_players`, recibos privados de XP e gatilhos sobre os resultados confirmados atuais. Não modifica credenciais, não desbloqueia criaturas e não muda o XP da conta.

As rotinas de crédito não podem ser chamadas por jogadores nem pelo login restrito diretamente. São internas aos gatilhos executados pelas funções de liquidação existentes. RLS permanece ativa; o navegador recebe seu XP pela consulta de inventário já autorizada. Entradas antigas continuam com zero XP individual e todas as novas começam em 1.

Os testes executam as migrações em PostgreSQL/PGlite e verificam permissões, repetições, captura, curva, limites diário e máximo, status do motor e custo visual das partículas. A auditoria visual `/menu-audit` usa exemplos fictícios nos níveis 1, 20, 30, 40, 45 e 50, sem alterar contas.
