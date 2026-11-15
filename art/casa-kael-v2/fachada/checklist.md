# Fachada — revisão do quadro-chave

15/11/2026. Etapa 2 para aprovação visual, ainda sem kit modular ou integração.

| ID | Conferência visual da fonte |
| --- | --- |
| F1 | [x] Corpo marfim, andar superior azul recuado e faixa coral. |
| F2 | [x] Coberturas planas escalonadas, platibandas e núcleo superior. |
| F3 | [x] Janela horizontal longa e esquadrias escuras. |
| F4 | [x] Varanda direita, painel azul perfurado, plantas e acesso. |
| F5 | [x] Porta azul sob marquise, apoiada em dois pilares. |
| F6 | [x] Janela térrea à direita, luminária e vasos. |
| F7 | [x] Jardim, árvores, flores, canteiros e muros baixos. |
| F8 | [x] Portão, caminho, caixa de correio e interfone. |
| F9 | [x] Bicicleta e equipamento solar na cobertura. |

## Evidências

- `quadro-chave.png` é a fonte de pintura, 1308 × 1202, produzida com ImageGen usando concept, blockout corrigido e loja aprovada como imagens de entrada. Prompt integral em `PROMPT.md`.
- `fontes/imagegen.png` preserva a saída original. `fontes/quadro-chave.aseprite` guarda a fonte aberta e salva em Aseprite 1.3.18.6, em modo headless. Uma camada RGB, sem alegação de retoque manual nesta entrega.
- `previa-com-kael.png` mostra a fonte ajustada somente para visualização junto ao recorte real de 70 px do Kael. O ajuste visual não comprova correspondência pixel a pixel ao blockout.
- `comparativo.png` reúne concept, candidata e captura atual. `jogo-atual.png` foi capturado da cena `res://scenes/overworld/neighborhood/bairro-jogavel.tscn` carregada isoladamente, sem saves de campanha.
- A captura e as pranchas são reproduzidas por `godot/tools/casa_kael_v2_pintura.gd`. Não houve alteração de assets de runtime, colisões ou fluxo de campanha.

## Revisão independente

O revisor de pixel art avaliou esta fonte com 9/10 e nenhum achado bloqueante para aprovação visual da etapa 2. Reconheceu a identidade, a projeção coerente e a separação entre entrada e varanda. Não aprovou automaticamente o kit ou a densidade final.

## Limites e próxima preparação

A fonte gerada tem fundo opaco, variação suave de fundo e mais cores que a paleta de cenário. Não é uma folha pronta para importação. A revisão automática `validate` citada pela skill não está exposta entre as ferramentas Aseprite desta sessão. Dimensões, camadas e modo RGB foram lidos por `sprite_info`, e a exportação foi conferida em PNG.

Antes de declarar os assets finais, fixar a correspondência da porta e dos pavimentos às medidas do blockout, limpar e agrupar os pixels na grade nativa, aplicar as rampas da ficha, remover o fundo e recortar os módulos com apoios e profundidade. As pequenas perfurações, folhas, flores, divisões do painel e raios da bicicleta exigem simplificação controlada. O guarda-corpo permanece vazado, não uma massa preta.

O solar ficou como um painel dividido em seis módulos e um reservatório cilíndrico. A porta da varanda recebeu vidro duplo. São detalhes desta candidata para revisão, mantendo o conteúdo obrigatório.

Pintura do térreo e do quarto ainda pendente. Esta entrega fecha a candidata da fachada primeiro. O portão visual do pipeline permanece antes da montagem do kit.
