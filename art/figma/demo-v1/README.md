# PipaKlub no Figma - primeira versão

Arquivo: https://www.figma.com/design/KCvJbbcDt9E35umMjjXHVz/PipaKlub

Protótipo: https://www.figma.com/proto/KCvJbbcDt9E35umMjjXHVz/PipaKlub?node-id=15-2&starting-point-node-id=15%3A2&scaling=scale-down

## Organização

- 00 · Comece aqui: identidade, escopo, mapa de fluxo e limites.
- 01 · Sistema & assets: fundações, componentes e biblioteca visual.
- 02 · Demo navegável: 38 telas e estados com 113 ligações de navegação.

As telas de resultado e batalha repetidas por área preservam a continuidade do retorno. Não representam dez mecânicas diferentes. As duas abas de Visão geral já selecionadas não navegam para si mesmas. Os dois pontos de entrada são início e quintal.

## Sistema inicial

36 variáveis em duas coleções, seis estilos de texto e um estilo de elevação. Paleta proveniente de src/index.html; fontes Lilita One, Nunito e Pixelify Sans, disponíveis e verificadas no Figma. Um modo por coleção, sem inventar um tema escuro.

Componentes de botão (quatro variantes), campo (padrão/erro), painel, cartão de parceiro e medidor. Biblioteca de 40 componentes de imagem, incluindo 12 recortes de botão. Não são 40 personagens: há mapas, itens, ícones, arte da interface e imagens de apoio.

Botões usam pontas fixas de aproximadamente 37,93px na altura de 64px e centro repetível. Prova de larguras 160/256/420 confirmou que só o centro cresce. Painéis nativos de papel/borda não esticam o PNG da janela. Há Auto Layout nos grupos de conteúdo; cenários e overlays têm posição deliberada no canvas.

## Conteúdo do fluxo

Início, entrada, erro, recuperação, quarto de Kael, nascimento de Rabbito, professor, quintal, coleção, Dex, história, rabiola, mochila, missões, destinos, opções, sala casual, cinco mapas do Morro, passagem bloqueada/liberada, HUD ilustrativa de duelo, retorno de ataque, consulta de habilidade, resultados por contexto e final da demo.

O novo percurso do Morro foi desenhado como fluxo-alvo. Isso não ativa o piloto na versão publicada do jogo. O quintal usa a arte de identidade antiga e está explicitamente marcado para sincronização posterior com o mapa modular atual. A abertura está resumida; as falas completas e todos os checkpoints continuam no código do jogo.

## Verificação realizada

- Metadados de 38 telas/estados, com 113 rotas sem reação ausente ou destino inválido.
- Auditoria geométrica: nenhum texto, frame ou instância fora do container imediato nas telas verificadas. Isso não comprova acessibilidade ou todos os tamanhos de janela.
- Screenshots revisados de fundações, botões, capa, quintal, coleção/Dex, mapa e oito estados chave. Corrigido corte das abas por altura do Auto Layout e recorte vertical do centro dos botões.
- No navegador do protótipo: cliques reais de início para login e de login ilustrativo para abertura. Não houve digitação de credenciais. O modo scale-down foi confirmado para caber na janela.
- Imagens originais e atlas próprios enviados ao Figma; personagens recortados pelos manifestos. Não foram enviados os estudos de personagens de terceiros do benchmark.

## Limites

É uma base editável de design e um protótipo de navegação, não um motor de jogo dentro do Figma. Login, física, dano, estado online, XP e itens são simulados. Campos de acesso exibem texto de exemplo; opções são estados de apresentação. Nos duelos, as criaturas e valores são exemplos de HUD, não especificação final de cada rival. Ainda faltam adaptação mobile, outras resoluções, animação completa, controle físico e teste de acessibilidade.

state.json preserva IDs, destinos e referências das imagens para continuar sem duplicar o trabalho. helpers.js contém as funções utilizadas na composição. Os assets e builds do jogo não foram alterados por esta entrega. Não houve deploy.
