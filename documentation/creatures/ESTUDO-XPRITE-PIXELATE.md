# Estudo do xprite-pixelate para Soulmonsters

Estudo em 12/11/2026 do repositório https://github.com/rhinoc/xprite-pixelate, branch main consultada via GitHub. O package.json consultado declara a versão 0.1.2. Este documento registra leitura do código e inspeção do consumidor local. Ainda falta executar uma comparação do algoritmo com nossos originais.

## O que aproveitar

O problema que a ferramenta trata é recuperar células de pixel em imagens ampliadas ou geradas cujas bordas perderam alinhamento. Para a nossa produção, isso permite experimentar recuperação sobre o PNG original de geração, antes da redução que produziu as folhas antigas.

O Auto coleta propostas de grade de diferentes detectores, usa evidência de alinhamento e escolhe entre as candidatas. Quando a grade está inclinada e a evidência é suficiente, há uma etapa de endireitamento.

O arquivo grid-edge-path.ts usa programação dinâmica para posicionar cortes junto das mudanças de cor. As larguras podem variar entre 0,75 e 1,25 do passo estimado, com penalidades para variação e mudança brusca entre células. Assim, um bloco desenhado com largura irregular pode contribuir para uma célula do resultado.

Fonte https://github.com/rhinoc/xprite-pixelate/blob/main/src/grid-edge-path.ts

## Amostragem, cor e transparência

TwoStage escolhe cores por célula com dois agrupamentos RGB deslocados, buscando a mediana do grupo dominante. Existe também uma etapa que aproxima tons quase iguais. A ideia relevante é preservar a estrutura da célula antes de reduzir a paleta final.

A recuperação trata alpha nas bordas, considerando cobertura e translucidez do original. Isso pode remover a franja de uma imagem gerada e conservar transparência intencional. Cordas e pequenas pontas precisam de conferência visual após esse processo.

Fontes https://github.com/rhinoc/xprite-pixelate/blob/main/src/cell-color-picker.ts e https://github.com/rhinoc/xprite-pixelate/blob/main/src/grid-sample.ts

## Escolha do modo

RecoverGrid exige evidência de uma grade consistente. A documentação informa que desenhos sem grade e pixel art já nativa em 1× podem receber reliable=false. Nessa situação, o consumidor deve preservar a arte nativa ou escolher explicitamente uma conversão conforme o caso.

Convert recebe dimensões de saída. O código permite proteção de contornos, regras de amostragem, prepass PixelOE e paleta. Esses parâmetros mudam o resultado e precisam de comparação visual.

Para o piloto de 112×112, a altura e o apoio definidos pelo autor continuam sendo o contrato de saída. O tamanho detectado pelo xprite é uma medição da imagem de entrada, e pode diferir do tamanho necessário ao jogo.

Fontes https://github.com/rhinoc/xprite-pixelate/blob/main/src/pixelate.ts e https://github.com/rhinoc/xprite-pixelate/blob/main/src/types.ts

## Evidência encontrada no jogo local

Checkout inspecionado em C:/Users/user/produto/pipa-club-integracao-atualizada.

| Ponto | Evidência local | Implicação |
| --- | --- | --- |
| Filtro dos companheiros | companion_follow.gd configura TEXTURE_FILTER_NEAREST | Conferir o caminho ativo e a imagem original antes de atribuir o borrado ao filtro linear. |
| Mipmaps do Azulfazo antigo | azulfazo.png.import declara mipmaps/generate=false | Esse importador específico já evita mipmaps. |
| Grade em uso | CELL_SIZE ainda é 80×80 | O novo piloto precisa de consumo próprio das células 112×112 antes de entrar em produção. |
| Escala do companheiro | kael_scale / Avatar.OVERWORLD_SCALE | A escala do nó depende da área e da escala do avatar. Medir também os pais e a câmera. |
| Câmera do parque | park_overworld_view.gd usa zoom 1,15 em áreas selecionadas | Mesmo com Nearest, um pixel de origem pode ocupar larguras alternadas na tela. |
| Janela | stretch canvas_items com aspect expand | Medir também o fator final da janela na resolução testada. |

Escala fracionária com Nearest pode produzir largura irregular de pixels e instabilidade em movimento. Filtragem linear pode produzir mistura de cores. O aspecto de mancha já presente no PNG reduzido permanece visível mesmo quando o filtro do jogo preserva os texels. A captura em escala nativa e a inspeção dos fatores de transformação distinguem essas situações.

A referência exata de Kael indicada pelo autor está em C:/Users/user/produto/pipa-club-overworld-campanha/godot/assets/kael-video/iso-v2/idle.png. O checkout de estudos usa uma versão anterior do avatar. Os quatro pilotos devem continuar seguindo os 70 px da referência indicada.

## Experimento aplicável aos originais

1. Usar o PNG original de geração das quatro criaturas, com referências de identidade ao lado. Guardar o original.
2. Detectar a grade com Auto e registrar reliable, dimensões, limites dos cortes e algoritmo escolhido.
3. Quando a grade for confiável, comparar RecoverGrid + TwoStage com o resultado antigo. Manter dithering desligado.
4. Quando houver ilustração sem grade coerente, experimentar Convert no tamanho planejado e comparar com o redesenho nativo.
5. Conferir cabeça, membros, varetas, cordas, olhos, alpha e contorno em 1× e em ampliação inteira. A etapa manual de Aseprite continua parte da entrega solicitada.
6. Montar as vistas na célula 112×112 e no apoio (56,100), preservando altura e volume entre as duas vistas. Evitar uma nova reamostragem para forçar o enquadramento.
7. Validar no jogo com a escala acumulada conhecida, incluindo pais, câmera e janela. Uma recuperação bem-sucedida no arquivo só pode ser avaliada no contexto dessa exibição.

## Como interpretar o benchmark

O benchmark constrói exemplos degradando pixel art conhecida, o que permite comparar a reconstrução com uma fonte de verdade. Os resultados apresentados pelo autor são medições dessa suíte. A própria documentação ressalta que dano sintético e imagens reais de geradores têm comportamentos diferentes. As métricas por pixel também usam os casos de tamanho exato de cada método, com conjuntos potencialmente diferentes.

Fonte https://github.com/rhinoc/xprite-pixelate/blob/main/bench/README.md

## Decisão de produção

O xprite é candidato para recuperar a grade dos originais do ImageGen e reduzir o trabalho inicial de reconstrução. A aprovação depende de uma comparação em nossos arquivos. A seleção de curvas, expressão, volumes, silhueta e 16–20 cores continua sendo trabalho de direção e acabamento no tamanho final.

O estudo não instalou a biblioteca no jogo nem substituiu assets. A próxima comparação deve ser feita em arquivos de experimento para preservar uma referência verificável dos resultados.

Licença do projeto MIT, com adaptações e atribuições descritas em https://github.com/rhinoc/xprite-pixelate/blob/main/NOTICE.md. Ao incorporar a biblioteca, preservar licença e avisos das partes distribuídas.
