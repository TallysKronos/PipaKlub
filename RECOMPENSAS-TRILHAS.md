# Recompensas de Trilhas verificadas pelo servidor

## Entrega

As três Trilhas atuais passam a usar duelos individuais criados por `/api/trail`, com etapa, número de rodadas, adversários e dificuldade escolhidos pelo servidor. O cliente envia apenas movimentos, ataques, habilidades e esquiva. A conta autenticada e a coleção são validadas antes da entrada. Outros jogadores não podem entrar nessas salas.

O motor registra vitória ou derrota ao concluir a rodada decisiva. O servidor persiste o estado e mantém uma fila de entrega em SQLite. Moedas, estrelas, maestria, resultado e a primeira rabiola de cada chefe são gravados atomicamente no PostgreSQL. Solicitações repetidas devolvem o mesmo resultado; vitórias repetidas continuam pagando as moedas normais, sem outra rabiola do mesmo chefe.

Entregas:

| Chefe | Item | Modelo invocável |
| --- | --- | --- |
| Mikka | Rabiola de Raio de sol | raio |
| Lohan | Rabiola de Chaspiral | chaspiral |
| Kleie | Rabiola de Flautrevo | flautrevo |

O recebimento registra o avistamento necessário ao ritual. A rabiola entra no inventário online, não num inventário paralelo local. O resultado só mostra o prêmio confirmado pelo banco e libera “Ir ao invocador” após a confirmação. O mapa mostra se o item está pronto, em ritual, consumido, danificado ou descartado.

## Preservação e histórico

A migração mantém as moedas, estrelas e histórico já existentes na conta. Rabiolas apenas anotadas no progresso antigo não são convertidas automaticamente: vencer novamente o chefe numa partida verificada dá direito à primeira entrega online.

Novos envios do antigo mecanismo de resultados/importação do navegador são arquivados em `trail_operations` com prefixo `legacy-`. Eles não alteram carteira, desbloqueios ou inventário. Assim, adulterar o armazenamento local ou repetir operações antigas não gera moeda ou item online. O cliente encerra essas operações antigas sem apagar seu conteúdo arquivado no servidor e informa a mudança. A função que aplica progresso foi tornada privada.

As tabelas `trail_runs` e `trail_drop_claims` guardam os recibos. Jogadores não podem escrever nessas tabelas nem executar funções de registro/liquidação. Só o papel restrito `pipa_server` pode registrar partidas e informar seus resultados; as funções conferem conta, partida, etapa e limites de rodadas.

## Confiabilidade

A fila grava antes de enviar. Falha do banco mantém a entrega pendente com tentativas posteriores, inclusive após reiniciar o processo. Estados com rodada decisiva persistida são recuperados mesmo se o processo parou antes de enfileirar. A liberação/encerramento da partida aguarda o resultado pendente, sem perder a vitória ao sair. Uma sala solo abandonada sem conexão expira após 15 segundos e libera a conta sem inventar uma vitória. Reabrir a aplicação continua permitindo consultar as conquistas salvas no mapa.

Resultados recusam confirmação otimista: antes do banco, a interface indica que está conferindo/salvando. Falha de consulta oferece nova consulta. Respostas antigas não podem atualizar uma conta diferente ou um resultado já fechado.

## Instalação

1. Aplicar, em ordem, as migrações existentes até 013 e depois `014_verified_trail_rewards.sql` no Supabase pelo fluxo habitual.
2. Publicar a versão do servidor correspondente; ela requer as novas funções do papel restrito. Worker e Pages foram recompilados.
3. Preservar o arquivo SQLite de salas/fila no disco persistente do servidor. A recuperação depende desse arquivo em reinícios.
4. Não reverter para um servidor antigo com entregas de Trilhas ainda pendentes na fila. Antes de um rollback, preservar o SQLite e drenar a fila com a versão que entende eventos `trail`. Não apagar tabelas ou recibos como estratégia de rollback.

Nenhuma migração, merge ou publicação em produção foi executada nesta entrega.

## Auditoria local

O teste PostgreSQL cobre rejeição de premiação inventada, permissões, preservação histórica, catálogo, primeiro prêmio mesmo para vitórias antigas, concorrência, repetição de resultado, três chefes, derrota, rodadas inválidas, invocação, equipamento e item já consumido. Os testes do servidor verificam sala individual, parâmetros forjados, registro privado da rodada decisiva e recuperação da fila. Os testes de interface verificam espera pela confirmação, encaminhamento ao NPC e respostas atrasadas de outra conta.

No ambiente local, o Beto venceu Mikka por 3–1 em um duelo executado pelo motor do servidor. Um jogador automatizado de auditoria enviou somente entradas normais pelo mesmo protocolo dos jogadores; nenhum resultado, moeda, vida ou inventário foi alterado para produzir a vitória. O resultado confirmou 38 moedas e uma rabiola. Pelo Playwright, a rabiola recebida foi usada para invocar Raio de sol, que foi equipado e usado no treino. Após recarregar, a conta manteve moedas e equipamento; o mapa mostrou a rabiola já utilizada. Sem erros no console.

Validação final: 117 testes aprovados, build do servidor e da página concluído e verificação dos artefatos aprovada. A direção da campanha de 12 bairros está em CAMPANHA-CIDADE.md; essa expansão ainda não faz parte da implementação.
