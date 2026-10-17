# Ambiente local de trocas

Iniciar na pasta do repositório com `npm ci` e `npm run dev:trades`. Se as dependências e o build já estiverem prontos, basta `node scripts/local-trades.mjs`. Node 24 ou superior. Porta padrão 5194; pode ser alterada por `LOCAL_TRADE_PORT`.

Abrir as duas URLs no mesmo navegador:

- Ana: http://127.0.0.1:5194/local/ana
- Beto: http://localhost:5194/local/beto

Os nomes de host diferentes mantêm os cookies separados. Cada link conecta automaticamente sua conta fictícia. Abra “Minha conta” nas duas abas, crie um convite na Ana e entre com o código na aba do Beto. Ofereça uma colecionável de cada lado e confirme as duas ofertas. Altere uma oferta após a primeira confirmação para verificar que ambas as confirmações são apagadas. Use “Histórico de trocas” após concluir. Também é possível testar cancelamento, expiração após dez minutos e tentativa de entrada em partida durante negociação.

As contas começam com uma básica e três colecionáveis; Ana também recebe uma Soul de evento para testar a exclusão das ofertas. Trocas preservam a quantidade de pipas de cada jogador. Para login manual, use `ana@local.test` ou `beto@local.test`, senha fictícia `TesteLocal123!`. Cadastro não está disponível.

O adaptador local emula apenas autenticação e transporte das RPCs. Regras de troca, propriedade, permissões e transferência executam as seis migrações reais em PostgreSQL via PGlite. Salas e partidas usam o mesmo servidor de jogo e WebSocket. Não lê variáveis nem acessa serviços de produção. Escuta somente em 127.0.0.1 e rejeita outros nomes de host. Não publicar esse adaptador de autenticação; o servidor de produção não o importa.

Dados persistem em `.local/trade-demo/`, ignorada pelo Git. Após reiniciar, entre novamente pelos links. Para recomeçar com inventários novos, pare o servidor com Ctrl+C e renomeie essa pasta antes de iniciar novamente. Isso preserva os dados anteriores para recuperação.

Limite: PGlite usa uma instância local com transações serializadas. O ambiente testa o fluxo integrado, mas não substitui homologação de concorrência entre conexões PostgreSQL/Supabase independentes antes da produção.

## Invocação com o NPC

Em Minha conta, selecionar “Visitar o invocador” → “Invocar Pipamon”. Escolher um card dos avistados, selecionar uma rabiola compatível na preparação e usar “Usar rabiola → Ascendente”. Ana e Beto recebem cinco rabiolas fictícias, representando drops, compras e eventos. O servidor local instala as migrações 007 e 008 se ausentes, sem apagar as trocas existentes. Há avistamentos fictícios com e sem itens para testar os cadeados. As 33 artes reais de rabiolas foram integradas, mas nenhuma combinação alternativa está habilitada. Usar uma rabiola inicia um ritual com três tentativas; sair antes da conclusão a transforma em rabiola danificada, que só pode ser descartada. O feitiço pode ser consultado e desenhado com mouse, toque ou teclado. Não há loja ou cobrança real neste ambiente. Detalhes e pontos de integração em `SUMMONING.md`.
