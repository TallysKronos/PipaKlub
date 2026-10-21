# PipaKlub: candidata da demo

A demo contém abertura, primeiro voo, os cinco encontros do Morro do Sol e os modos online existentes. A política compartilhada de `src/trails.js`, aplicada pelo cliente e por `src/backend.js`, bloqueia bairros futuros sem apagar progresso antigo.

| Parte | Implementação | Fronteira de confiança |
|---|---|---|
| Jogo e HUD | Canvas e JavaScript em `src/index.html`; montados por `build.mjs` e `build-pages.mjs` | O navegador apresenta e envia comandos; não concede inventário nem vitórias de campanha |
| HTTP | Node 24, `dev.mjs`, backend gerado em `worker/index.js` | Valida origem, payload, sessão da sala e regras da demo |
| Partida | `src/engine.js`, `src/realtime.js`, SQLite local | Servidor decide cruzamentos, dano, rodadas e eventos |
| Contas | `src/accounts.js`, Supabase Auth e RPCs autenticadas | Sessões em cookies HttpOnly; identidade validada no provedor |
| Economia | PostgreSQL/Supabase, `src/game-database.js`, `src/progression.js` | Papel restrito `pipa_server`; operações autorizadas por funções, eventos idempotentes |
| Artes | Allowlist `src/static-assets.js` e configuração de `scripts/art-build.mjs` | Fontes e arquivos locais não são servidos por um diretório arbitrário |

Recarga online reutiliza a credencial privada da sala guardada apenas na aba e separada por conta. A conexão anterior cede o lugar à nova. Não é uma sessão de Supabase nem um mecanismo de transferência de propriedade.

Recuperação de senha usa um link do Supabase; seu bearer fica em memória após ser removido do fragmento da URL. O servidor encaminha a alteração ao provedor, que valida a autorização. Não há chave administrativa de Auth no cliente.

## Limites operacionais

- O serviço Free do Render pode dormir; o estado de salas e a fila local em SQLite não têm garantia de persistência entre reinícios/redeploys. Coleção e checkpoints confirmados ficam no PostgreSQL. Não declarar disponibilidade ou recuperação sem perdas com base somente no teste de recarga.
- `src/progression.js` expira duelos solo ociosos após cerca de 15 s; a janela de recuperação de salas multiplayer é de até 60 s. A demo não adiciona retomada automática de solo após recarga.
- Teste de produção com dois visitantes no mesmo executor não substitui redes físicas diferentes, carga, celular ou controle físico.
- Não há agentes de IA generativa ou webhooks de ferramentas embutidos; adversários são lógica do motor. Sem `automation.md`.

## Documentos relacionados

- [Fluxos e efeitos](flows.md)
- [Permissões](permissions.md)
- [Variáveis](variables.md)
- [Cobertura e lacunas](tests.md)
- [E-mails](emails.md)
- [Trabalho em segundo plano](cron.md)
- [Página pública](seo.md)
- [Roteiro de playtest e lançamento](demo-playtest.md)
- [Correções da jornada](../DEMO-CORRECOES-2026-10-20.md)
