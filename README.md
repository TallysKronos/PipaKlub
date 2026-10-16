# Pipa Club

Jogo de cortar pipas para até 8 jogadores por sala, com simulação e placar controlados pelo servidor. Partidas de 3 minutos, quatro pipas, treino com bots e controles de toque.

## Executar

Requer Node.js 24+. A dependência `ws` fornece o transporte WebSocket no servidor.

```sh
npm ci
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

Crie a sala e compartilhe o convite. Os participantes entram usando o código de seis caracteres. Até oito jogadores participam da mesma simulação. No servidor Node/Render, uma conexão WebSocket transmite atualizações a 30 Hz e envia comandos assim que mudam, com manutenção a cada 50 ms. O cliente prevê o movimento da própria pipa imediatamente, corrige diferenças suavemente e interpola os adversários. O servidor controla dano, energia, pontuação e reentrada. Uma conexão HTTP de compatibilidade é usada automaticamente se WebSocket estiver indisponível (inclusive no Worker do Sites). O ping continua representando a viagem de ida e volta ao servidor; a previsão local evita esperar por ela para mover a pipa. Sessões ausentes por 15 segundos saem da sala.

## GitHub Pages

O GitHub Pages publica a pasta `docs/` da branch `main`. Essa versão roda o treino com bots integralmente no navegador. O Pages não executa o servidor Node.js/Worker nem o banco de dados, portanto as salas online ficam disponíveis na versão com backend.

Após alterar o jogo, execute `npm run build:pages` e envie a pasta `docs/` atualizada ao GitHub. O arquivo `.nojekyll` preserva a publicação estática direta.

## Hospedar o multiplayer gratuitamente no Render

O arquivo `render.yaml` configura um Web Service no plano **Free**, com jogo, API multiplayer e SQLite no mesmo processo. O repositório pode permanecer privado.

1. Entre em https://dashboard.render.com e conecte sua conta GitHub, concedendo acesso ao repositório `TallysKronos/PipaKlub`.
2. Crie um **Blueprint** e selecione esse repositório. O Render lê `render.yaml` e usa os comandos já configurados.
3. Confira que o serviço está no plano **Free** e conclua a criação. O Render fornece o endereço público `onrender.com` após a implantação.

O servidor gratuito pausa após 15 minutos de inatividade. O primeiro acesso após a pausa pode levar cerca de um minuto. As salas são temporárias e são perdidas se o serviço reiniciar ou for implantado novamente, pois o disco gratuito não é persistente. Não há cadastro ou ranking permanente nesta versão.

O servidor usa a porta fornecida em `PORT` e reconhece o HTTPS do proxy para validar corretamente a origem das requisições multiplayer.

Sites novos são publicados com acesso privado ao proprietário por padrão. Para convidar pessoas externas pela URL publicada, o proprietário precisa ajustar o acesso do Site. A publicação privada pode ser usada imediatamente pelo proprietário; o servidor local permite teste na rede.

## Arquivos

`src/index.html`: interface, canvas e cliente. `src/engine.js`: simulação compartilhada. `src/backend.js`: API e validação. `build.mjs`: incorpora todo o conteúdo em `worker/index.js` e gera `dist/server/index.js`. `dev.mjs`: servidor local com adaptador SQLite compatível com D1.
