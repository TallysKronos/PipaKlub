# Quarto V4 · correção de linguagem anime

Revisão solicitada durante a entrega da V3: a animação deixou Kael cartoon demais. O retrato fornecido pelo usuário passa a ser referência principal direta do H3, em vez da prancha de corpo inteiro. A nova cena-base mantém rosto delicado, queixo mais fino, cabeça proporcional e corpo alongado. A atuação pedida é pequena e de boca fechada, sem sorriso largo, saltos ou deformação elástica.

Nova geração somente do plano do quarto. Locutor, pipeiros e batalha V2 preservados. Fluxo H3 local, 20 passos, 0,6 MP solicitado, 6 segundos solicitados, sem nós pagos; duração e raster reais serão registrados na exportação. Referências, workflow, job e prompts em `art/pipa-tv-cinematic-v4/`.

Montar com `tools/extend-pipa-tv-v3.py <quarto.mp4> --version v4`. A montagem V4 mantém o raster nativo do novo plano, adaptando o filme V2 sem distorcer proporções; exportação 1280×720 é redimensionada. O plano V3 rejeitado permanece preservado como fonte histórica.

O jogador continua pelo mesmo código de passagem automática para o quarto: reprodução única, pular, pausa e gravação atômica de conclusão da transmissão antes da fala de Kael. O retrato de diálogo selecionado permanece o novo Kael aprovado como alvo de traço; o sprite de exploração não foi redesenhado nesta tarefa.

Geração concluída no H3 local, job `104e8f27-13be-4a66-867b-4ceb5ab34606`. Fonte preservada em `art/pipa-tv-cinematic-v4/video-original/04-kael-anime/104e8f27_000.mp4`. Quadros de revisão em `kael-review.png`; metadados medidos da montagem em `montagem.json`.

Revisão visual: rosto mais fino e corpo esguio, enquadramento próximo que abre gradualmente para o quarto, piscar e movimento de cabeça. O H3 ainda abre brevemente o sorriso, apesar da instrução de boca fechada; não alegar aderência perfeita ao prompt. Preservou as cores, roupas, cabelo e fones. A tomada já começa com Kael junto à TV; não executou integralmente a aproximação inicial exclusiva da tela. A junção curta conecta a batalha anterior ao quarto.

Fonte nova: 1056×608, 24 fps, 6,58 segundos, com áudio. Filme completo: 25,84 segundos. MP4 de revisão e OGV do jogo exportados em 1280×720 com ajuste proporcional, sem alegação de geração HD nativa.

Recurso configurado em `opening_tv.gd`: `pipa-tv-abertura-v4.ogv`. Checagem estática de recursos: zero erros e quatro avisos preexistentes. Sem testes de gameplay ou publicação. O fluxo nativo de passagem ao quarto foi verificado estaticamente, mas não reproduzido de ponta a ponta nesta revisão.
