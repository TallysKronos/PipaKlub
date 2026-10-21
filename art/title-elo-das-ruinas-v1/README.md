# Soulmonsters: Elo das Ruínas — tela de abertura

**21/10/2026 · Integrada localmente, em revisão artística.**

O lendário Eremor é sugerido por velas, garras e pelo nó no peito. A imagem completa permanece nas sombras de um portal em ruínas. O título e os comandos são texto real, separados da arte.

## Arte e movimento

- `assets/title/elo-das-ruinas-v1/ruins.png`: cenário original opaco, 1672×941.
- `assets/title/elo-das-ruinas-v1/eremor-shadow.png`: presença de Eremor, 1536×1024 com alpha real, baseada no conceito existente.
- Duas camadas produzidas com image_gen integrada. Prompts integrais ao lado do manifesto em `assets/title/elo-das-ruinas-v1/prompts.json`. Pixels originais preservados.
- Câmera: deriva lenta de 36 s.
- Eremor: respiração ancorada na base em ciclo de 6 s, ondulação da ilustração por deslocamento SVG e pulsos independentes no olho e no nó do peito. Movimento procedural sobre o PNG aprovado; não são poses redesenhadas nem animação esquelética. A silhueta continua nas sombras.
- Névoa: duas camadas de gradientes animados a 24/34 s.
- Linha: pulso vetorial de 9 s, independente do PNG.
- Partículas esparsas e chamada Start com variação suave de opacidade.
- Pausa manual, pausa quando a página fica oculta e respeito a `prefers-reduced-motion`.

O lettering usa texto com Lilita One e Georgia; é uma composição para esta tela, não um novo logotipo oficial aprovado. A fonte web já utilizada pelo jogo tem fallback local de sistema.

## Entrada

Start aceita clique/toque, Enter, Espaço e botões padrão A/Start de controle. A tela usa um diálogo modal nativo para impedir cliques no jogo por baixo. O evento inicial é consumido, o comando é idempotente e o controle não atravessa a transição para iniciar outra ação.

O Start revela o fluxo já existente: visitante continua no menu; conta conectada continua na jornada/perfil carregado. A tela não faz login, não inicia partida e não altera coleção ou progresso. Ela é exibida uma vez por aba/origem, com armazenamento de apresentação em `sessionStorage`; `?title=1` permite rever e `?title=0` permite pular. Falha de armazenamento ou das imagens não bloqueia Start.

Convites `sala`, parâmetros de autenticação/recuperação, fragmentos de URL e rotas de auditoria passam direto. Navegadores sem suporte a diálogo modal nativo usam a entrada anterior. O render de arena e o controle global deixam de processar a apresentação enquanto a tela está aberta; não há nova engine ou dependência de animação.

## Verificação

- Worker e Pages gerados; os PNGs usam URLs com hash e passam pelo allowlist de assets.
- 42 testes direcionados aprovados: tela de título, navegação, piloto, abertura e primeiro voo. Incluem cancelamento de comandos, início único, fallback de arte/armazenamento, redução de movimento, gamepad simulado, rotas de recuperação e assets.
- Navegador: Enter abriu o menu sem iniciar treino; foco, pausa e retomada conferidos.
- Layout observado em 1280×720 diretamente e em iframes de 390×844 e 844×390, escalados visualmente pela página de revisão. Isso testa CSS em viewports reais de iframe, não um aparelho físico ou emulação de toque/controle.
- Redução de movimento e controle foram verificados por testes de contrato; não houve teste com controle físico.
- Ambiente local em porta 5230, banco PGlite isolado `.local/ruins-title-2026-10-21`; nenhum acesso ao Supabase de produção para esta revisão.

Evidências: `desktop-1280x720.png`, `mobile-390x844.png` e `landscape-844x390.png`. O ajuste final de legibilidade móvel está incluído na exportação e na prévia.

## Abrir e exportar

Com o servidor local do jogo em 5230: `http://127.0.0.1:5230/?title=1`.

`node scripts/preview-ruins-title.mjs` abre a revisão de três tamanhos em `http://127.0.0.1:5231/`, incorporando esse jogo em um iframe.

`node scripts/export-ruins-title.mjs` gera `output/soulmonsters-elo-das-ruinas-abertura.html`, com os PNGs, CSS e controlador embutidos. Pode ser aberto como arquivo local; as fontes web são opcionais e precisam de rede, com fallback disponível. Nessa exportação isolada, Start encerra a prévia e oferece rever; na integração do jogo, segue para o fluxo existente.

Código-fonte: `src/title-screen.js`, `src/title-screen-client.js`, `src/title-screen.css`. Integração nos dois builds, em `src/index.html`, `scripts/art-build.mjs` e `src/static-assets.js`.

Não foi publicado no Render nem commitado por esta tarefa. O menu após Start agora acompanha a identidade da abertura.

## Revisão do menu após Start

O menu compartilha cenário, Eremor animado, paleta e título com a abertura. Entrar na aventura encaminha ao login existente; treino, salas, regras e privacidade preservam seus controladores. Pipa Club continua sendo o clube dentro do mundo.

A animação do menu pausa enquanto título, partida ou jornada ocupam a tela. Pausa manual controla também a linha temporal SVG. Redução de movimento remove a deformação. Falha da imagem remove também os pontos luminosos. Fechar o login restaura o foco em Entrar na aventura.

Navegador: Start → menu → login → retorno com foco, acesso à folha de salas e entrada no treino com HUD normal. Layout observado em desktop e iframes de 390×844 e 844×390. A automação não conseguiu acionar controles dentro do iframe; a página de revisão recebeu o atalho Menu principal usando a rota normal ?title=0. Sem acesso à produção.

Evidências: menu-desktop.png, menu-mobile-390x844.png e menu-landscape-844x390.png. Os 42 testes passaram; log em tmp/ruins-menu-tests.log.
