# Pipa Club

Jogo de cortar pipas para até 8 jogadores por sala, com simulação e placar controlados pelo servidor. Partidas de 3 minutos, quatro pipas, treino com bots e controles de toque.

## Executar

Requer Node.js 24+. Sem dependências externas.

```sh
npm run build
npm test
npm run dev
```

Abra http://localhost:5193. Para jogar em outro aparelho na mesma rede, use o IP do computador e a porta 5193. A instalação local persiste as salas em `.local/game.db`. O jogo publicado usa Cloudflare D1 (`DB`). As tabelas próprias são inicializadas por código, sem migrations do framework.

## Controles

- Setas ou WASD: movimento.
- Espaço: cortar, a até 128 unidades de outra pipa. Segure para causar dano; solte para recuperar energia.
- Cada corte vale 100 pontos. A pipa cortada retorna após 3 segundos.
- No celular: direcional e botão Cortar na arena.

## Multiplayer

Crie a sala e compartilhe o convite. Os participantes entram usando o código de seis caracteres. Até oito jogadores participam da mesma simulação, sincronizada por HTTP a cada 140 ms. O servidor limita os movimentos, controla dano, energia, pontuação e reentrada; versões concorrentes da sala são atualizadas com compare-and-swap no banco. O desempenho depende da latência da conexão. Sessões ausentes por 15 segundos saem da sala.

Sites novos são publicados com acesso privado ao proprietário por padrão. Para convidar pessoas externas pela URL publicada, o proprietário precisa ajustar o acesso do Site. A publicação privada pode ser usada imediatamente pelo proprietário; o servidor local permite teste na rede.

## Arquivos

`src/index.html`: interface, canvas e cliente. `src/engine.js`: simulação compartilhada. `src/backend.js`: API e validação. `build.mjs`: incorpora todo o conteúdo em `worker/index.js` e gera `dist/server/index.js`. `dev.mjs`: servidor local com adaptador SQLite compatível com D1.
