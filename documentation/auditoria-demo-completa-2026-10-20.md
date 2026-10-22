# Auditoria da demo — 20/10/2026

## Resultado

Os bloqueios de abertura e de expiração das salas identificados nesta rodada foram corrigidos. A versão `14f8768051340d81178b34617b85b4b0107dbdd6` foi confirmada como Live no Render e aprovada no [CI](https://github.com/TallysKronos/PipaKlub/actions/runs/39534509583). Isso permite avançar para um playtest fechado; não equivale a aprovação para divulgação geral.

## Correções verificadas

### Abertura bloqueada pelo banco de produção

A conta conectava, mas a jornada exibia “O banco de contas ainda precisa ser configurado”. A consulta aprovada de cinco indicadores confirmou ausência de `player_opening` e `player_openings`. Após autorização específica, o pacote `output/sql/instalar-abertura-demo-017-018.sql` foi executado em uma transação no Supabase. Os cinco indicadores passaram a verdadeiros.

O pacote foi testado isoladamente com PostgreSQL/PGlite: preservação das coleções antigas, abertura concluída para legado, novo jogador sem coleção antes da história, concessão de um único Rabbito e recusa de reaplicação sem efeitos parciais. Não alterou senhas nem apagou dados.

A conta real voltou a carregar a jornada concluída e os destinos. Após a aplicação, a interface confirmou 33 pipas, Nevagume equipada no nível 5 e 338 moedas. Os cinco encontros do Morro continuavam vencidos.

### Sessões online expiradas e substituídas

Uma sala sem conexões deixava de avançar a simulação; o caminho WebSocket aceitava uma chave antiga sem conferir a idade da sessão. O servidor agora exige atividade inferior a 60 segundos antes de autenticar essa conexão.

Em produção, o fluxo de snapshots da conexão substituída parava, mas o evento de fechamento podia demorar a chegar. Foram adicionados avisos explícitos `session-expired` e `session-replaced`. O cliente limpa a retomada local e retorna ao menu sem enviar uma saída HTTP que removeria a sessão recém-aberta em outra aba.

Regressões locais e a auditoria final no Render confirmaram rejeição da sessão após 62 segundos e os dois avisos explícitos.

## Evidência automatizada

| Ambiente | Verificação | Resultado |
| --- | --- | --- |
| Local e CI | Suíte do jogo | 287 aprovados, nenhuma falha |
| Local e CI | Pacote SQL exato da abertura | 1 teste aprovado |
| Render, versão final | Auditoria de acesso e salas | 20 critérios aprovados em 72 s |
| Render, versão final | Partida casual de três rodadas, retomada dos dois jogadores e mesma revanche | Aprovada em 28 s |
| Local com PostgreSQL e provedor de identidade simulado | Jornada e economia por APIs reais | 12 critérios aprovados |

A auditoria online verificou acesso de visitante, recusa de alterações de perfil e captura sem conta, origem estrangeira, convites, sigilo das chaves nos snapshots, movimento compartilhado, recusa de HP/placar/classe forjados, neutralização de comandos antigos, substituição, reconexão, saída e expiração HTTP/WebSocket. Cinco amostras de RTT foram 139, 139, 139, 138 e 137 ms: mediana de 139 ms nesta rede e momento, não uma garantia de desempenho.

O teste autenticado local completou a abertura, preservou o parceiro, reservou equipamento durante a partida, finalizou três cortes, concedeu exatamente 75 XP ao jogador e ao parceiro equipado, confirmou ausência de recompensa duplicada em consultas repetidas, persistiu após nova entrada e liberou o equipamento. Usou identidades fictícias locais; não comprova o ledger de partidas autenticadas no Supabase de produção.

Logs locais em `tmp/`:

- `demo-complete-notices-tests.log`
- `demo-complete-live-notices-final.log`
- `demo-complete-match-notices-final.log`
- `demo-complete-economy-v2.log`

Scripts reproduzíveis: `scripts/audit-demo-online.mjs`, `scripts/smoke-demo-release.mjs`, `scripts/smoke-demo-economy.mjs` e `scripts/demo-opening-package.test.mjs`. As salas e conexões temporárias online foram encerradas na limpeza dos scripts. Os testes online usaram visitantes e não concederam recompensas à conta do proprietário.

## Revisão visual na conta real

- Jornada restaurada, encerramento da demo e retorno ao Morro do Sol.
- Bairros posteriores identificados como conteúdo futuro, sem entrada liberada.
- Coleção, animação de corpo inteiro, status e histórias acessíveis.
- PipaDex com 35 registros, retratos e seção de rabiolas; drops selvagens corretamente identificados como previstos.
- Ensaio de invocação concluído, sem iniciar ritual de consumo; a mochila permaneceu com uma rabiola de Raio de sol.
- Formulário de feedback aponta ao template do GitHub. Nenhuma mensagem foi publicada.

As imagens estão em `art/ui-reviews/demo-complete-2026-10-20/`, especialmente `05-jornada-restaurada.png`, `06-final-demo.png`, `07-limite-bairros.png`, `08-ensaio-sem-consumo.png` e `09-pipadex-drop-previsto.png`.

## Pendências e limites

1. **Texto inconsistente na PipaDex:** Carcará diz ser recebida no cadastro. A abertura atual concede Rabbito; ajustar a descrição para distinguir coleções antigas sem prometer uma fonte de aquisição inexistente. Não corrigido nesta rodada.
2. **Duas redes e aparelhos físicos:** a auditoria usou duas conexões reais, mas um único executor/rede. Validar partida autenticada, queda curta, revanche e recompensas em dois aparelhos e redes independentes.
3. **Novos jogadores:** cinco pessoas que nunca jogaram devem percorrer abertura e primeiro bairro sem orientação externa. O avanço automatizado da abertura por API não substitui esse teste de compreensão e navegação.
4. **Dispositivos:** celular, orientação, controle físico e computador modesto não foram validados nesta rodada. A tentativa de redimensionar o navegador não alterou suas dimensões efetivas; não contar como teste mobile.
5. **Autenticação:** o proprietário confirmou recuperação com entrada automática e sessão persistente após recarga. Nova entrada manual após logout e entrega de confirmação de novo cadastro continuam pendentes; a sessão funcional foi preservada.
6. **Operação:** carga, recuperação da fila de resultados após falha/redeploy e indisponibilidade prolongada não testadas em produção. `/health` é sinal de processo, não de disponibilidade integral do banco. Houve uma mensagem transitória de demora do serviço de contas durante a consulta ao invocador; causa não confirmada.

O trabalho local de desktop e os assets não relacionados foram preservados. A inspeção inicial de schema foi recusada pela revisão automática sob a autorização geral de teste; a consulta delimitada e a aplicação do pacote foram realizadas somente após as autorizações específicas posteriores do proprietário.
