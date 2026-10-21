# Permissões

| Recurso/operação | Visitante | Conta autenticada | Servidor restrito |
|---|---|---|---|
| Treino local | Pode jogar; sem XP/itens | Pode jogar; sem prêmio econômico | Não concede prêmio |
| Sala casual padrão | Pode participar com credencial privada do lugar | Pode participar; coleção protegida | Simula combate; registra eventos entre contas |
| Vale pipa | Negado | Consentimento e exemplar elegível equipado | Reserva/liquida pela função SQL |
| Coleção, nome, equipamento, jornada | Negado | Somente dados da própria identidade validada por Supabase | Sem UPDATE arbitrário de tabelas pelo login do jogo |
| Troca/invocação | Negado | Propriedade e revisão/sessão conferidas nas funções | Não inventa operações fora da allowlist |
| Moedas/XP/vitórias | Não pode conceder | Não pode forjar resultado pelo navegador | Somente liquidação de evento/partida registrada |
| Bairro posterior ao Morro | Negado pela demo | Negado mesmo com progresso legado | Backend rejeita antes de criar a partida |
| Nova senha | Só com bearer de recuperação validado pelo provedor | Cookies de outra conta não escolhem o alvo | Usa chave publicável e bearer, sem API administrativa de Auth |

Identidade da conta vem do provedor; a identidade do lugar da partida vem da chave privada correspondente em SQLite. Uma não deve ser apresentada como a outra.

As migrações definem RLS e funções baseadas em `auth.uid()` para acesso de jogadores. Tabelas internas de economia não devem receber escrita direta do navegador. `002_restricted_server.sql` e as migrações seguintes concedem EXECUTE específico ao papel `pipa_server`; `src/game-database.js` mantém a allowlist e verifica privilégios na conexão.

Asserções negativas reais: `accounts.test.mjs`, `trades.test.mjs`, `summon.test.mjs`, `trails-audit.test.mjs`, `trail-rewards.test.mjs` e `test.mjs`. Essa matriz descreve o código e as migrações; não substitui conferir os privilégios do projeto de produção.
