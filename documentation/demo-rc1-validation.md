# Publicação e validação da demo RC1

Validada em 20/10/2026. Candidata publicada, ainda dependente dos testes humanos abaixo.

- Commit: `a687f0e42d257f595287c023b7b7f7c4111fe8e3` em `main`.
- Jogo: https://pipaklub.onrender.com/
- Render: https://dashboard.render.com/web/srv-db99rqajnfac73bg4m40/deploys/dep-dbc10b95efls73b8uf90 — Deploy succeeded / Live.
- CI: https://github.com/TallysKronos/PipaKlub/actions/runs/39525408452 — success.
- Health público retornou `ok: true`, `release: demo-rc.1`, `demo: true`. Esse sinal não comprova entrega de e-mail ou disponibilidade do banco.

## Evidência executada

- Dois builds, validação ESM e 282 testes locais aprovados; builds e suíte também aprovados no CI Linux.
- Smoke local: dois visitantes, três vitórias, retomada de ambos e entrada na mesma revanche, em 25 segundos.
- Smoke no Render: mesmo fluxo aprovado em 29 segundos. Duas conexões WebSocket reais a partir deste computador; não equivale a dois aparelhos ou redes diferentes.
- Salas privadas casuais criadas pelo teste foram encerradas no bloco de limpeza. Nenhuma conta real, recompensa ou alteração direta de banco foi usada pelo smoke.
- [Confirmação visual do Render](../art/deployments/demo-rc1-2026-10-20/render-live.png).

## Ainda pendente

- Nova entrada manual após sair da conta no navegador do proprietário ainda não validada; não foi necessário encerrar uma sessão funcional para este teste.
- Entrega real de confirmação de novos cadastros ainda pendente. Proprietário confirmou recebimento da recuperação, alteração da senha e perfil conectado pelo fluxo atualizado.
- Partida entre dois aparelhos em redes distintas, incluindo queda curta, revanche e persistência dos resultados autenticados.
- Cinco jogadores novos, controle físico, celular e computador modesto, seguindo [o roteiro](demo-playtest.md).
- Recuperação da fila local após falha/redeploy e teste de carga não foram validados em produção.

Este relatório complementa o registro anterior de correções locais. Não declara a demo pronta para divulgação geral nem substitui os testes pendentes. O trabalho de desktop permaneceu separado e preservado no checkout.

## Atualização da recuperação de conta

Commit `339ed0a0712ebfdffcf2941397165b3192999f27` publicado no Render. Suíte de 285 testes aprovada localmente e no CI: https://github.com/TallysKronos/PipaKlub/actions/runs/39529752353.

Com autorização específica, foram consultados somente metadados da conta do proprietário. E-mail confirmado, sem exclusão/bloqueio e sem exigência de SSO; o hostname público registrado pelo Render corresponde ao projeto consultado. A consulta de auditoria limitada ao actor_id da própria conta não retornou linhas, o que não prova ausência de eventos. O proprietário também confirmou que a conta permaneceu conectada após recarregar a página no navegador usado por ele.

Após a troca de senha, o servidor agora autentica a mesma senha com o e-mail retornado pelo Supabase e exige coincidência entre o ID atualizado e o ID da sessão. O proprietário confirmou em teste real: “Conta conectada e perfil apareceu”. Isso valida o novo caminho de recuperação, não demonstra a causa exata da recusa anterior nem substitui testar uma nova entrada manual no navegador do proprietário.
