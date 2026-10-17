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
- Espaço: atacar um cruzamento válido entre as linhas. Segurar repete a puxada a cada 0,65 s; cada tentativa custa 12 de energia, inclusive se errar. Um alvo por puxada.
- A mira fica verde quando a sua linha cruza a faixa tracejada inimiga. Acertos comuns tiram 18 de durabilidade; a faixa central dourada tira 24. As linhas precisam formar um ângulo de pelo menos 11,54°; contato perto do chão ou da ponta não vale. A parte atacante precisa estar entre 35% e 95% de sua linha, e a faixa vulnerável entre 30% e 85% da linha inimiga (frações medidas desde o chão).
- Q / E: habilidade da pipa equipada. Custa 25 de energia e recarrega em 7 s. Na Ágil, Q desloca 96 px para esquerda e E para direita.
- Soltar ataque recupera 18 de energia/s; segurando, 6/s. A durabilidade começa em 100 e só é restaurada ao reaparecer.
- Cada corte vale 100 pontos. A pipa cortada retorna após 3 segundos.
- Ao entrar e ao reaparecer, a pipa fica protegida por 2,5 s (anel tracejado branco). Atacar encerra a proteção.
- Acertos, dano, cortes e reaparecimento aparecem na arena: números flutuantes, "ACERTOU!", pipa caindo e faixa central. Os bots miram por um instante antes de puxar.
- No celular: direcional, ATACAR e SK ← / SK → na arena.

| Tipo | Pipa | Habilidade |
| --- | --- | --- |
| Precisa | Carcará (laranja) | Por 2 s, próximo acerto recebe +8 de desgaste |
| Ágil | Mata verde | Dash lateral de 96 px |
| Guardiã | Azulão | Reduz desgaste recebido em 60% por 1,5 s |
| Técnica | Raio de sol | Por 2,5 s, amplia a faixa inimiga atingível para 15%–92% |

Os tipos são derivados do modelo equipado (cor do catálogo), validado pelo servidor para jogadores autenticados. Não há mudança de inventário nem migração de banco nesta atualização. Cortes simultâneos são calculados antes de aplicar as mortes; empates de autoria usam dano e ID estável. Os bots procuram cruzamentos e usam habilidades.

O balanceamento inicial mantém a mesma velocidade e durabilidade para todos os tipos. `combat.test.mjs` cobre geometria, tentativas sem acerto, recargas, dano simultâneo, habilidades e previsão de dash sob atraso.

## Multiplayer

Crie a sala e compartilhe o convite. Os participantes entram usando o código de seis caracteres. Até oito jogadores participam da mesma simulação. No servidor Node/Render, uma conexão WebSocket transmite atualizações a 30 Hz e envia comandos assim que mudam, com manutenção a cada 50 ms. O cliente prevê o movimento da própria pipa imediatamente, corrige diferenças suavemente e interpola os adversários. O servidor controla dano, energia, pontuação e reentrada. Uma conexão HTTP de compatibilidade é usada automaticamente se WebSocket estiver indisponível (inclusive no Worker do Sites). O ping continua representando a viagem de ida e volta ao servidor; a previsão local evita esperar por ela para mover a pipa. Sessões ausentes por 15 segundos saem da sala.

## GitHub Pages

O GitHub Pages publica a pasta `docs/` da branch `main`. Essa versão roda o treino com bots integralmente no navegador. O Pages não executa o servidor Node.js/Worker nem o banco de dados, portanto as salas online ficam disponíveis na versão com backend.

Após alterar o jogo, execute `npm run build:pages` e envie a pasta `docs/` atualizada ao GitHub. O arquivo `.nojekyll` preserva a publicação estática direta.

## Fluidez em aparelhos mais lentos

O cenário é desenhado em uma imagem reutilizada a cada quadro. O placar e os avisos só alteram o DOM quando seu conteúdo muda. Celulares começam no modo leve, com menor resolução de desenho e sem sombras nas pipas. O botão ◐ da arena permite alternar esse modo; em modo automático, duas medições consecutivas abaixo de 40 fps ativam os efeitos leves. O contador na arena mostra a taxa de quadros do aparelho, separada do ping da conexão.

O movimento previsto aceita intervalos de até 100 ms por quadro para preservar a velocidade em aparelhos a 10–20 fps. O mesmo caminho de previsão atende tanto o criador quanto quem entra na sala.

## Hospedar o multiplayer gratuitamente no Render

O arquivo `render.yaml` configura um Web Service no plano **Free**, com jogo, API multiplayer e SQLite no mesmo processo. O repositório pode permanecer privado.

1. Entre em https://dashboard.render.com e conecte sua conta GitHub, concedendo acesso ao repositório `TallysKronos/PipaKlub`.
2. Crie um **Blueprint** e selecione esse repositório. O Render lê `render.yaml` e usa os comandos já configurados.
3. Confira que o serviço está no plano **Free** e conclua a criação. O Render fornece o endereço público `onrender.com` após a implantação.

O servidor gratuito pausa após 15 minutos de inatividade. O primeiro acesso após a pausa pode levar cerca de um minuto. As salas são temporárias e são perdidas se o serviço reiniciar ou for implantado novamente, pois o disco gratuito não é persistente. Contas, inventários e cortes confirmados são persistidos separadamente no Supabase.

O servidor usa a porta fornecida em `PORT` e reconhece o HTTPS do proxy para validar corretamente a origem das requisições multiplayer.

Sites novos são publicados com acesso privado ao proprietário por padrão. Para convidar pessoas externas pela URL publicada, o proprietário precisa ajustar o acesso do Site. A publicação privada pode ser usada imediatamente pelo proprietário; o servidor local permite teste na rede.

## Arquivos

`src/index.html`: interface, canvas e cliente. `src/engine.js`: simulação compartilhada. `src/backend.js`: API e validação. `build.mjs`: incorpora todo o conteúdo em `worker/index.js` e gera `dist/server/index.js`. `dev.mjs`: servidor local com adaptador SQLite compatível com D1.

## Contas e coleção — Supabase

1. Crie um projeto Supabase e execute `supabase/migrations/001_accounts_inventory.sql` uma única vez no SQL Editor. A migração é transacional e cria as tabelas do jogo, RLS, inventário inicial e funções de captura.
2. Execute `supabase/migrations/002_restricted_server.sql`. Ela cria `pipa_server` sem login e concede somente execução das quatro funções de partidas e recompensas. O proprietário deve definir uma senha exclusiva e habilitar Login com `ALTER ROLE pipa_server WITH LOGIN PASSWORD 'senha_exclusiva';`, por uma sessão administrativa do PostgreSQL. Essa senha não deve ser salva no Git nem enviada pelo chat. O painel Roles permite conferir os privilégios, mas não oferece campo de senha.
3. Configure no Render `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `PIPA_DB_HOST`, `PIPA_DB_PORT`, `PIPA_DB_USER` e `PIPA_DB_PASSWORD`. Use o host do pooler em modo Session (porta 5432) e usuário `pipa_server.PROJECT_REF`. Não use o usuário `postgres` nem chaves secretas de administração. A senha deve ficar apenas nas variáveis protegidas do servidor. A conexão verifica TLS; se o endpoint exigir CA própria, configure o PEM em `PIPA_DB_CA`.
4. Em Authentication → URL Configuration, defina Site URL como `https://pipaklub.onrender.com` e permita esse endereço como redirecionamento de confirmação.
5. Mantenha a confirmação de e-mail ativada. Para cadastros públicos, configure SMTP próprio; o remetente padrão do Supabase tem limites e restrições de destinatários. O jogo informa quando a confirmação está indisponível.
6. Execute `supabase/migrations/003_results_and_kite_history.sql` para habilitar resultados privados, os dez duelos mais recentes e a história das pipas. As migrações devem ser executadas na ordem numérica.

O projeto publicado usa Brevo como SMTP no Supabase: host `smtp-relay.brevo.com`, porta `587`, login técnico exibido no painel SMTP da Brevo e uma chave exclusiva para o jogo. A chave fica somente no campo criptografado de senha do SMTP do Supabase; ela não vai para o Render, para este repositório nem para os jogadores. Use um remetente verificado. Sem domínio próprio, a Brevo pode substituir o domínio do remetente por `brevosend.com`. O limite inicial do Supabase com SMTP próprio é de 30 e-mails/hora; respeite também os limites atuais do plano da Brevo. A chave criada tem vencimento de um ano e a Brevo também expira chaves após 90 dias de inatividade. Para trocar a chave, atualize o campo SMTP Password no Supabase e teste a entrega antes de desativar a anterior.

O modelo de confirmação está em `supabase/templates/confirm-signup.html`, com assunto `Confirme sua conta no PipaKlub`, aplicado em Authentication → Emails → Confirm sign up. Ele mantém a variável `{{ .ConfirmationURL }}` do Supabase. A integração foi verificada com uma solicitação real de e-mail de acesso pelo Supabase e o evento `Delivered` nos registros transacionais da Brevo. Essa verificação confirma o transporte de e-mail; não substitui testar o cadastro e a confirmação de um novo jogador.

Ao terminar um duelo, a tela consulta os eventos confirmados da própria conta para mostrar XP, cortes entre contas, conquistas, perdas e adversários. O estado “salvo” só aparece após o encerramento confirmado no banco e sem cortes pendentes na fila local; valores parciais são identificados. Partidas HTTP sem WebSocket também têm o encerramento enfileirado ao consultar o resultado. É possível fechar a tela e reabrir um dos dez últimos duelos em Minha conta. Visitantes e treino recebem um resumo local, sem promessa de XP salvo. Na coleção, “Ver história” mostra até trinta mudanças de dono, com sala, data e apelidos preservados a partir desta atualização. Eventos anteriores recebem os apelidos atuais na migração. Somente o dono atual pode consultar a história de uma pipa; resultados de duelos só são acessíveis aos próprios participantes e não expõem identificadores dos outros jogadores.

Sem essas variáveis, contas e Vale pipa ficam desativados; o modo visitante casual e o treino continuam funcionando. Para executar localmente com um projeto configurado, copie `.env.example` para `.env`, preencha fora do Git e use `node --env-file=.env dev.mjs` após o build.

O cadastro concede uma pipa básica permanente e três colecionáveis. O inventário é criado uma única vez por conta. A pipa equipada e o apelido são validados pelo servidor; equipamento fica bloqueado durante a partida. A modalidade Casual preserva as pipas. Na modalidade Vale pipa, o convidado precisa aceitar explicitamente a regra de perda ao entrar. Uma captura transfere somente a pipa colecionável equipada, e o perdedor volta com a básica. Cada corte entre contas diferentes concede 25 XP, limitado aos primeiros cinco cortes contra a mesma conta em 24 horas. Nível: `1 + floor(sqrt(XP / 100))`.

Movimento e combate continuam no servidor WebSocket. Eventos de recompensa passam por uma fila local com repetição e identificadores idempotentes. A função PostgreSQL transfere a propriedade e grava XP na mesma transação. O banco confirmado é a fonte de verdade da coleção; uma animação de corte, sozinha, não confirma uma transferência. Como o disco gratuito é temporário, uma queda abrupta pode descartar eventos ainda não enviados ao Supabase. Saídas e encerramentos aguardam os cortes pendentes antes de liberar o equipamento.

Tokens de acesso e renovação ficam em cookies HttpOnly, Secure em HTTPS e SameSite=Lax, com prefixo `__Host-`. O servidor usa a chave pública para autenticação e o JWT do jogador para acessar seu próprio perfil/inventário via RLS. Para partidas e recompensas, a conexão PostgreSQL usa `pipa_server`, sem privilégios administrativos, sem bypass de RLS e sem leitura ou escrita direta nas tabelas do jogo. Somente quatro funções com validações internas são permitidas; o adaptador usa parâmetros e recusa outras operações. Uma credencial vazada ainda permitiria invocar essas funções, por isso ela continua sendo um segredo. Os testes executam as migrações em PostgreSQL local (PGlite) e verificam as permissões do papel restrito, propriedade, proteção contra escrita direta, idempotência e fila de recompensas.
