# Crítica independente — lote 07

Revisão somente de arquivos, sem editar pixels ou acessar a sessão ativa do Aseprite. Comparei as fontes canônicas com as duas vistas dos atlas de idle/caminhada, pranchas ampliadas, recortes dos apoios e sequências nativas. Examinei os quadros e tempos dos GIFs; isso não equivale a verificar deslizamento na velocidade do jogo. Aprovação humana permanece separada.

| Modelo | Nota | Decisão |
| --- | ---: | --- |
| Traminho | 7/10 | Sem bloqueante visual nesta amostra; movimento mínimo |
| Tramino | 6/10 | Corrigir a passada completa |
| Tramassauro | 5,5/10 | Corrigir pernas e restos de contorno |
| Tramadraco | 6/10 | Corrigir alternância dos dois apoios |
| Pipa-dragão | 5,5/10 | Corrigir locomoção quadrúpede |

## Identidade e repouso

Os cinco preservam rosto, câmera, paleta e ornamentos da fonte, sem frontalização nova evidente. Os idles mantêm a silhueta e os apoios; não identifiquei arranque de caminhada. São extremamente discretos, uma limitação conhecida. A auditoria de cópia do núcleo não comprova qualidade da locomoção: uma máscara excessiva pode preservar o desenho e bloquear a articulação.

## Traminho

A cabeça-pipa permanece reconhecível, sem torso ou pernas inventados. Pequenos estabilizadores mudam de posição nas duas vistas e continuam conectados. O centro não deriva e o ciclo fecha sem salto estrutural evidente. A atuação é mínima; aceitável como flutuação curta de bebê, sem alegar uma animação expressiva ou equivalente a uma passada terrestre.

## Tramino — bloqueante

O movimento se concentra nas pontas das pernas. SW: o pé distante aparece praticamente na posição de repouso nos quadros 1/5 e some/encolhe nos demais, enquanto o pé próximo oscila abaixo do quadril. NW: há mudança do pé próximo, mas não uma troca de apoio claramente construída pelos dois membros. A leitura é de alternar manchas abaixo de um corpo congelado, sem passagem convincente da perna distante.

Primeira correção: retirar da máscara de núcleo as pernas completas abaixo do quadril, preservando cabeça/torso, e construir contato, elevação e passagem de **ambas** as pernas com comprimento/espessura constantes. Não ampliar só a viagem dos dedos.

## Tramassauro — bloqueantes

Além da articulação distal limitada, a perna NW recolhida perde leitura de canela/pé e vira uma massa escura em parte do ciclo, especialmente no quadro 3. SW contém um resto de contorno separado de três pixels em `(80,90)`, `(80,91)`, `(80,92)`, nos quadros 1/2/4/5/6. O fragmento é visível ampliado ao lado dos pés.

Primeira correção: revisar a máscara das pernas, reconstruindo o membro recolhido inteiro e removendo ou reincorporando o fragmento conforme a parte de origem. Manter os elementos canônicos superiores.

## Tramadraco — bloqueante

Na frente, a bota visível sob a espada permanece quase fixa enquanto a outra alterna elevação e contato. A espada explica a oclusão parcial da perna distante, mas não justifica manter sua ponta visível presa no mesmo lugar durante quase todo o ciclo. Nas costas existe mais articulação, porém a frente ainda lê como um passo incompleto repetido.

Primeira correção: desenhar a trajetória da perna parcialmente oculta, incluindo os momentos em que o pé deixa o contato e passa atrás da lâmina. Conservar espada, cabeça e armadura superior; não animar tudo com deslocamento global.

## Pipa-dragão — bloqueante

SW e NW preservam quatro membros identificáveis, mas os segmentos grandes permanecem praticamente na pose original. O que muda majoritariamente são pontas de patas, pequenos recortes escuros e o enfeite da cauda. Isso não estabelece uma marcha quadrúpede com elevação de membro, passagem e carga alternada; a criatura tenderá a deslizar com pés pulsando.

Primeira correção: liberar patas completas desde ombro/quadril, com pares diagonais de apoio e pelo menos uma pose intermediária mostrando claramente o membro recolhido. Preservar face, casco/moldura e barris canônicos sem copiar as pernas estáticas por cima da articulação.

## Encaminhamento

Preservar os cinco idles e as partes canônicas superiores. A correção necessária é de articulação e conexão das pernas, não de identidade ou redesign. Não publicar os quatro ciclos terrestres como animação final apenas porque os testes geométricos e a cópia do núcleo passaram. Após corrigir, conferir sequência nativa e velocidade no renderer.
