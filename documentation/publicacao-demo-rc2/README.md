# Publicação da demo-rc.2

Inclui `feature/ui-kit-consistente` (saves, salvamento automático, parque, classes, constelações, encontros selvagens, Soulgen) e `claude/demo-polimento` (revisão visual do fluxo). O `/health` passa a responder `release: "demo-rc.2"`.

A ordem importa: **o banco antes do servidor**. O Render publica a cada push na `main`; o servidor novo usa tabelas que só existem depois da 019–023.

1. **Verificar** — no SQL Editor do Supabase de produção, rode `1-verificar.sql`. Esperado: `m017_*` e `m018_*` = `true`; `m019`–`m023` = `false`.
   Se a 017 ou a 018 vier `false`, pare: aplique `supabase/migrations/017_kael_opening.sql` e `018_story_first_collection.sql` primeiro.
2. **Migrar** — rode `2-migracoes-019-023.sql` inteiro (as cinco migrações, na ordem, cada uma na sua transação). Se alguma falhar, pare aqui e não faça o merge.
3. **Conferir** — rode `1-verificar.sql` de novo. Esperado: tudo `true`.
4. **Publicar** — merge do PR na `main`. Aguardar o deploy do Render.
5. **Depois do deploy**:
   - `https://pipaklub.onrender.com/health` mostra `demo-rc.2`.
   - `node scripts/audit-demo-online.mjs --url=https://pipaklub.onrender.com --live` e `node scripts/smoke-demo-release.mjs --url=https://pipaklub.onrender.com --live` (salas de visitante; ambos encerram as próprias salas).
   - Na sua conta: entrar, salvar em Opções → Save e bancos, recarregar e continuar do mesmo lugar.

Reverter o servidor é voltar o deploy anterior no Render. As migrações não têm rollback automático: renomeiam funções e recriam invólucros com o mesmo nome e assinatura, mas o servidor demo-rc.1 rodando sobre o banco já migrado não foi testado. Faça o passo 2 só quando for seguir até o passo 4.
