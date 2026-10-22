# Candidata da demo publicada — 21/10/2026

## Publicação confirmada

- Commit de aplicação: `556266b237f0e958664142b8cb019efda9e04806` — `Integrate five-area Morro campaign and audited street demo`.
- `origin/main` confirmado nesse commit. Inclui também `ed3432e`, que trouxe a rua e os interiores.
- Render: serviço `pipaklub`, estado Live, deploy automático de 1m18s.
- URL: https://pipaklub.onrender.com/.
- CI: [Demo validation aprovado](https://github.com/TallysKronos/PipaKlub/actions/runs/39606545796), incluindo builds, pacote da abertura e suíte completa.
- Verificação local anterior: 297 testes e 20 verificações direcionadas finais aprovados.

A publicação não incluiu os quatro arquivos locais da migração desktop, os materiais de criação artística pendentes ou consultas SQL de diagnóstico. Não houve aplicação de migrações ou alteração de credenciais em produção.

## Transporte e partida online no Render

`scripts/audit-demo-online.mjs --url=https://pipaklub.onrender.com --live`: **20 critérios aprovados em 72 segundos**. Verificados serviço, configuração de contas, isolamento de visitantes, recusa de origem estrangeira e captura sem conta, convite, sigilo de chaves, movimento entre duas conexões, substituição de conexão, retomada, saída e expiração HTTP/WebSocket após 62 segundos sem atividade.

`scripts/smoke-demo-release.mjs --url=https://pipaklub.onrender.com --live`: **partida de três rodadas concluída em 26 segundos**, com retomada dos dois jogadores e entrada dos dois na mesma revanche.

Esses scripts usam visitantes em salas próprias, não concedem XP à conta do proprietário e encerram suas salas ao final. Duas conexões no mesmo executor/rede não comprovam a experiência em dois aparelhos e redes independentes.

Logs locais: `tmp/demo-candidate-live-online.log` e `tmp/demo-candidate-live-match.log`.

## Arquivos e sessão

Onze PNGs usados pelos dez cenários novos (cinco da rua/interiores e cinco áreas do Morro, contando a camada adicional da praça) foram baixados dos URLs públicos da aplicação e comparados por SHA-256 com os arquivos locais. Todos coincidiram. Log: `tmp/demo-candidate-live-assets.log`.

A sessão existente foi restaurada após recarregar a página publicada. A coleção continuou com 33 criaturas, Nevagume equipada no nível 5 e 338 moedas. O progresso do Morro já era de cinco encontros vencidos antes desta publicação. Não foi redefinido para simular uma conta nova.

O navegador percorreu o acesso padrão da cidade à Praça da Chegada e as passagens físicas para Escadaria da Sombra, Laje dos Ventos, Mirante da Caixa-d’água e Parque dos Ventos, usando esse progresso confirmado. Evidências locais em `art/ui-reviews/demo-candidate-live-2026-10-21/`. Viewport observado: 1166 × 884; painel Render: 1151 × 873.

A interação com a saída do Parque abriu “O Morro do Sol conhece seu nome”, com os destinos online, invocador, revisita e “Continuar explorando”. A sessão ficou aberta nessa tela. A consulta final ao console do navegador não retornou erros. Evidência: `06-encerramento.png`.

## Limites do aceite

- O responsável informou não possuir uma conta de teste nova. Portanto, a concessão inicial de Rabbito, os cinco desbloqueios conquistados pela primeira vez e o login manual após sair **não foram validados com um cadastro novo em produção**. A abertura e o primeiro voo completos foram testados localmente com conta fictícia; isso não substitui esse aceite.
- A conta existente já tinha vencido os cinco encontros. Percorrer suas passagens não equivale a vencer cinco novas batalhas nem conferir novas recompensas.
- Permanecem o playtest com pessoas sem orientação, celular real, controle físico, computador modesto e dois aparelhos/redes independentes.
- A candidata ainda usa a identidade visual anterior. A nova start screen de Soulmonsters Chronicles: Fios do Destino é uma entrega posterior.

Este relatório registra a validação em produção localmente, após o commit da candidata. As evidências desta etapa ainda não fazem parte daquele commit.
