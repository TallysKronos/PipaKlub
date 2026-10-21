# Fluxos com dados ou efeitos externos

| Fluxo | Condição e sequência | Autorização e caso negado | Efeito |
|---|---|---|---|
| Cadastro/login | Navegador → `/account/signup` ou `/account/login` → Supabase Auth → conta por RPC | Origem, limites e formato; provedor valida credenciais/confirmacão | E-mail de confirmação quando necessário; cookies HttpOnly; inventário inicial depende das migrações |
| Recuperar senha | E-mail digitado → `/account/recover` → Supabase → caixa de entrada → retorno ao jogo → nova senha confirmada → `/account/reset-password` → provedor | Limite de envios; destino derivado do servidor; bearer obrigatório validado pelo provedor. ID de usuário no corpo não escolhe a conta | E-mail externo; atualização da senha pelo próprio jogador; cookies do navegador limpos após sucesso |
| Jornada | Conta → `/account/opening` e `/account/journey` → funções PostgreSQL | `auth.uid()`, sequência de checkpoint e escolha válida; outra conta/resposta atrasada não pode receber o resultado | Checkpoint, parceiro e nome; prática local sem prêmio econômico |
| Sala privada | Criar/entrar → reserva do parceiro se autenticado → SQLite → WebSocket | Credencial privada da sala; regras de casual/captura; visitante só entra no formato padrão; sala solo rejeita convidados | Participação, combate, eventos do servidor |
| Recarga online | Credencial da aba → `/api/resume` → mesmo jogador → novo socket | Não aceita chave ausente, pública ou de lugar já removido; cache da aba separado por conta | Renova presença e neutraliza comandos antigos; não cria outra reserva ou recompensa |
| Campanha | Preparar encontro → `/api/trail` → registro da tentativa → batalha → outbox → liquidação SQL | Demo rejeita bairro futuro antes da reserva; SQL valida desbloqueio e tentativa; cliente não registra uma vitória por conta própria | Moedas, XP do parceiro e rabiola de chefe confirmados no banco |
| Invocação | Ver rabiolas → ensaio opcional/primeiro → iniciar → tentar desenho → resposta | Sessão, propriedade da rabiola, receita e idempotência conferidas nas funções PostgreSQL | Ensaio só muda UI. Ritual real consome item; sucesso cria exemplar; abandono danifica rabiola |
| Feedback | Opções → formulário GitHub | Jogador escolhe abrir e enviar; nenhuma telemetria, credencial ou dump de estado é anexado automaticamente | Issue pública somente se o jogador enviar no GitHub |

Fontes: `src/accounts.js`, `src/backend.js`, `src/realtime.js`, `src/progression.js`, `src/summon-client.js` e migrações em `supabase/migrations/`. Testes correspondentes em [tests.md](tests.md).
