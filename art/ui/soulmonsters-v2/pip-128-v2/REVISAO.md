# PIP-128 — revisão artística 2

## Correção solicitada

O dono rejeitou a primeira entrega por falta de graça, toque 2D mangá, customização e direção artística: pareciam retângulos de cores básicas. A v1 permanece no histórico, mas não é uma direção aprovada nem base suficiente para seguir automaticamente à PIP-129.

A correção trabalha a construção ilustrada: silhueta, matéria, união, iconografia e composição. Não se limita a adicionar ruído, textura ou uma pipa no canto. As três novas pranchas mostram exploração, batalha e pausa com referências de traço autoral do projeto.

## Produção e arquivos

Ferramenta integrada `image_gen__imagegen`, três chamadas independentes. `A/B/C-prompt.txt` contêm os prompts exatos. `geracao.json` registra saídas originais e papéis das referências. As pranchas finais foram copiadas para esta pasta; não dependem da pasta de imagens geradas do Codex.

Alvo de edição: `fontes/A/B/C-layout.png`, montagens dos mocks antigos em três faixas, usadas para informar contextos e conteúdo. Referências de traço: `art/characters/parque-pipeiros-v2/references/kael-autoral.png` e `locutor-aprovado.png`, abertas e inspecionadas antes da geração. O locutor não foi inserido nas telas. Não foram usadas imagens de terceiros do benchmark como referência de geração.

## A — Seda viva

O suporte se torna uma peça de pipa: seda clara tensionada, segmentos coral e verde-mar, varetas com amarrações, bordas dobradas e reforços. Retrato e faixa pertencem à mesma construção. A pausa ganha o gesto de abrir um folio de montagem, com oito destinos e ícones ilustrados. Os comandos passam a ser pipas de formas distintas.

Avanço observado: detalhes de construção legíveis, customização dos ícones e parentesco entre telas. Risco: excesso de pontas/rabiolas nas pequenas faixas; textura de fibra e borda podem precisar ser reduzidas. Não transformar isso em pergaminho medieval ou caixa de bambu genérica.

## B — Mural de Kronasta

Placas pintadas e papel impresso definem chamadas e ações. A pausa toma a forma de um quadro comunitário com cartazes específicos para cada função; retrato, manchete e dados recebem hierarquias próprias. A seleção é uma peça amarela com desenho de pipa e marca gráfica, não apenas um contorno.

Avanço observado: relação mais imediata com bairro, oficina, cartaz e campeonato, além de contraste entre áreas impressas e áreas de consulta. Risco: rasgos, manchas e bandeiras em excesso podem deixar tudo com a mesma intensidade; explorar deve continuar mais calmo que competir. A vegetação e parte do cenário foram redesenhadas pelo modelo e não constituem proposta de mudança do mapa.

## C — Carretel e Elo

Carretel desenhado, linha passando por ilhoses, etiquetas de papel dobrado e um canto colorido dão matéria à conexão. O tempo se torna a face de uma bobina. Na pausa, os oito destinos se relacionam ao percurso, com uma grande peça de retrato/consulta.

Avanço observado: conexão e seleção fazem parte da ilustração; a silhueta não depende de caixas arredondadas com filete dourado. Risco: quantidade de cordas e carretéis pode competir com o foco. Não há um recurso numérico novo chamado Elo; a linguagem gráfica não inventa mana ou regra de vínculo.

## Traço e legibilidade

As saídas foram inspecionadas visualmente: contorno com espessura variável, áreas de cor organizada, sombras chapadas, retratos mangá e ícones customizados. Ainda há textura de papel e pequenas variações de desenho que precisam ser disciplinadas antes do kit de produção. Nenhuma prancha foi declarada perfeita ou aprovada pelo dono.

Esta revisão **não herda os resultados geométricos da v1**. A geração redesenhou partes dos cenários, poses, letras, indicadores e proporções, e algumas informações secundárias foram omitidas. A comparação agora é de direção artística, não de diferenças de pixels entre cenas idênticas. Os textos presentes orientam a composição, mas não são fonte confiável dos dados do jogo.

As pranchas são referências conceituais, não PNGs gigantes para montar a interface. Não há atlas modular, Theme novo, margens aprovadas, texto ampliado, navegação ou testes de input nesta revisão. Texto, barras e valores deverão voltar a ser nativos na implementação; ilustração será dividida em peças reutilizáveis. Exploração deve preservar o centro livre, e os ornamentos precisam caber nas margens nas quatro resoluções.

## Estado

PIP-128: propostas refeitas após a crítica; aguardam avaliação artística do dono. PIP-129 ainda não foi registrada. Nenhuma direção recebeu aprovação tácita da entrega antiga. Sem mudança no jogo, merge, push ou status no Linear.
