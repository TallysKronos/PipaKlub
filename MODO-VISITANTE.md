# Jogar sem conta (modo visitante)

O menu inicial ganhou **Jogar sem conta**, logo abaixo de "Entrar na aventura". O mesmo botão aparece na janela de conta. Com um clique o jogador entra na aventura completa (abertura, mundo, Trilhas, oficina) sem e-mail e sem senha.

## Como funciona

- O servidor (`/account/guest`) cria um **usuário anônimo do Supabase**. O gatilho de cadastro que já existe (`pipa_player_signup`, migração 001) cria o perfil e a coleção do jogador como para qualquer conta. Por isso **não há migração nova**: todas as funções do jogo continuam identificando o jogador pela sessão.
- O apelido inicial é "Visitante 1234", e o jogador pode trocá-lo em Minha conta. A sessão usa os mesmos cookies HttpOnly das contas normais.
- **Salvar progresso:** em *Visitante → Salvar meu progresso*, o jogador informa um e-mail (`/account/guest-save`). O Supabase envia o link de confirmação. Depois de confirmar, ele cria a senha por "Esqueci minha senha". O progresso continua na mesma conta.
- **Limites do visitante:**
  - trocas com outros jogadores ficam bloqueadas até salvar com e-mail;
  - sair do modo visitante pede confirmação;
  - o progresso se perde se o navegador for limpo ou se o jogador passar 7 dias sem jogar (validade do cookie de renovação).
- **Abuso:** no máximo 4 visitantes novos a cada 15 minutos por IP, além do limite do próprio Supabase.

## Para ativar em produção

1. No painel do Supabase: **Authentication → Sign In / Providers → Allow anonymous sign-ins**, ligado. Sem isso o botão responde "O modo sem conta ainda não foi ativado no servidor. Código CONTA-VISITANTE." e nada quebra.
2. Recomendado: ativar o CAPTCHA de autenticação do Supabase e conferir o limite de cadastros anônimos por hora em *Rate Limits*.
3. Publicar o servidor desta revisão. Merge e deploy dependem de autorização explícita (PIP-49).
4. Limpeza (opcional, depois): visitantes que nunca salvaram acumulam linhas em `auth.users`. Vale agendar uma limpeza de anônimos sem atividade há mais de 30 dias, somente com autorização para operar no banco de produção.

## Teste local

`node scripts/local-trades.mjs` emula o login anônimo (porta 5194). Na tela inicial, **Jogar sem conta** entra direto na abertura do Kael. Testes: `node --test accounts.test.mjs`.

## Publicação de 24/10/2026

Por decisão do responsável, esta release mantém visitantes **desativados** em produção. O Supabase continua com login anônimo desligado. Sem `GUEST_PLAY_ENABLED=1` no servidor, `/account/config` informa `features.guest=false`, o cliente oculta os botões e `/account/guest` recusa novas sessões antes de acessar o provedor. Contas existentes continuam funcionando.

Para ativar futuramente, serão necessárias autorização para ligar o login anônimo no Supabase e a variável `GUEST_PLAY_ENABLED=1` no Render. O adaptador local habilita o recurso somente no banco isolado para testes.

Os novos starters e a hierarquia manual do Rabbito estão no Soulgen Studio e no Git; seus rigs ainda não substituem os atlas de combate/overworld do jogo.

Validação da integração: ambos os builds concluídos; 89 testes focados passaram e entrada visitante local retomou a mesma fala da campanha após recarregar. A suíte completa em sequência executou 487 testes: 485 passaram e permaneceram as duas falhas anteriores dos relatórios visuais (`avatar-player.test.mjs` e `home-layout.test.mjs`). Após adicionar a trava de publicação, os 15 testes de contas passaram, incluindo a recusa de novos visitantes sem chamar o provedor. Nenhum dado de produção foi migrado ou reiniciado nesta release.
