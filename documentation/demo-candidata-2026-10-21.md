# Candidata da demo — 21/10/2026

## Entrega

- Rua dos Ventos com sala e quarto de Kael, casa do professor e loja exploráveis.
- Morro do Sol em cinco áreas como caminho padrão da campanha, preservando os encontros e o progresso existentes.
- Passagens condicionadas a vitórias confirmadas da própria conta, retorno da batalha à mesma área e encerramento ligado à saída final.
- Correções do vaso sobre a escada, textos de destino e objetivo desatualizado após batalha.

Não inclui a migração desktop/Steam em andamento, os arquivos de criação artística, uma nova identidade de marca ou alterações de esquema do banco.

## Validação antes da publicação

- Suíte completa: 297 testes aprovados.
- Verificação final do percurso e troca de conta: 20 testes direcionados aprovados.
- Pacote existente de abertura 017/018: teste isolado aprovado, sem aplicação em produção nesta entrega.
- Builds Worker e Pages concluídos e artefato ESM validado. O Worker foi regenerado com o `build.mjs` versionado, sem depender dos ajustes locais de desktop.
- Abertura e cinco exercícios do primeiro voo percorridos no navegador local com conta fictícia. Duelo contra Zeca e retorno após derrota exercitados.
- Novo percurso padrão e bloqueio antes da vitória conferidos no navegador local. O teste automatizado das cinco passagens usa snapshots simulados; não representa cinco vitórias manuais em produção.

## Verificação após publicação

Confirmar o commit ativo no Render e no CI. Executar os testes limitados de salas visitantes com `scripts/audit-demo-online.mjs --url=https://pipaklub.onrender.com --live` e `scripts/smoke-demo-release.mjs --url=https://pipaklub.onrender.com --live`; ambos encerram suas próprias salas.

Conferir em conta autorizada a restauração da coleção, caminhada nas cinco áreas, treino/reprise, retorno e encerramento. Uma conta já concluída não valida a concessão inicial de Rabbito para um cadastro novo. A entrada manual após sair exige credenciais inseridas pelo responsável; preservar uma sessão funcional enquanto isso.

Dois clientes no mesmo executor validam transporte, partida e retomada; aparelhos e redes independentes continuam necessários antes de ampliar o playtest.

Relatórios de referência: [auditoria da rua](auditoria-rua-demo-2026-10-21.md) e [integração do Morro](integracao-morro-demo-2026-10-21.md).
