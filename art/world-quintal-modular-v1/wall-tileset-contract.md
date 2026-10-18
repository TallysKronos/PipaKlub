# Muros de borda: análise e contrato de encaixe

Referências fornecidas pelo usuário em 18/10/2026: detalhe do muro vertical do quintal e atlas de tiles de borda, terreno e alvenaria. Estas imagens orientam a estrutura de montagem; a paleta e o acabamento continuam sendo os do PipaKlub.

## Diagnóstico da montagem anterior

A correção anterior resolveu vãos geométricos e variações de escala, mas não comprovou continuidade artística. A janela vertical de 62×248 px da folha original vira um módulo de 24×96 px. A origem é uma ilustração de um pequeno muro completo, com pedras de larguras diferentes, juntas irregulares, vegetação e extremidades próprias. Seus limites superior e inferior não foram desenhados como um par repetível.

Por isso o detalhe enviado ainda mostra saliências em intervalos regulares, mudanças na largura aparente e interrupções nas juntas. Encostar os retângulos não transforma essa ilustração em um tile contínuo. O encontro em L também exige uma peça de quina: sobrepor duas faixas independentes não garante um topo ou contorno coerente.

Estado daquela revisão: muro ainda não aprovado artisticamente. A aprovação automática anterior valia para a geometria, não para a arte das emendas.

## O que observar na segunda referência

- Existem famílias diferentes. As faixas e molduras têm centro, bordas e cantos; os materiais inferiores fornecem preenchimentos. Não são todos peças intercambiáveis do mesmo muro.
- Cada família conserva espessura, alinhamento e perspectiva. A borda muda de direção com uma quina desenhada, em vez de reiniciar um bloco inteiro.
- Textura interior e contorno cumprem funções diferentes. Uma textura de pedra repetível não contém automaticamente terminais, cantos ou a face lateral necessária ao muro.
- Alguns cantos são convexos e outros são reentrantes. Um retângulo externo correto ainda não resolve um recuo em L do mapa.
- No nosso atlas, o vazio externo e as áreas vazadas serão alpha 0. Contornos escuros, juntas e sombras pertencentes às pedras continuam desenhados: remover toda cor preta destruiria a arte.

## Peças que precisam ser desenhadas como conjunto

| Família | Função |
| --- | --- |
| Retas N, S, E, O | Trechos contínuos com orientação e iluminação próprias. A borda sul pode mostrar a face frontal; não basta girar uma imagem horizontal. |
| Quatro quinas externas | Unir o topo e as faces ao virar ao redor de uma saliência. |
| Quatro quinas internas | Unir o muro nos recuos, sem buraco, sobreposição de faces ou pedra duplicada. |
| Terminais orientados | Encerrar o muro junto a portões ou em pontas livres. Nunca repetir no meio da faixa. |
| Junções específicas, se usadas | T e cruzamento precisam de desenho próprio; não são obtidos empilhando quinas. |
| Decorações separadas | Folhas, flores e rachaduras opcionais, posicionadas depois de aprovar o muro limpo. Não podem esconder uma emenda defeituosa. |

## Contrato antes de gerar arte

1. Grade lógica de 32 px. Definir a espessura, a altura da face e a posição do topo em uma peça mestre antes das variantes. Uma peça pode ocupar mais de uma célula, desde que seus pontos de conexão sejam explícitos.
2. Declarar, para cada variante, direção, conexões N/S/E/O, retângulo de colisão, âncora, ordem de profundidade e recorte no atlas. Separar a borda visual da base física.
3. Todas as conexões compatíveis compartilham posição do topo, largura ocupada, faixa de alpha e fase das juntas. Uma conexão aberta não pode conter contorno de terminal ou sombra de fim de objeto.
4. O topo e a base do trecho vertical precisam continuar um no outro; esquerda e direita do horizontal seguem o mesmo princípio. A malha de pedras deve atravessar a junção sem reiniciar uma pedra cortada em altura incompatível.
5. As quinas preservam exatamente as conexões das retas correspondentes. Não aplicar escala diferente para fechar o canto; não usar rotação que altere a iluminação ou transforme a face frontal em topo.
6. Não medir o passo pelo bounding box variável de folhas ou sombras. Recortes e encaixes usam posições fixas da grade; margens transparentes fazem parte do contrato quando previstas.
7. O renderer escolhe a peça pela vizinhança e pela orientação da borda. Inspecionar diagonais para distinguir quina externa de reentrante. O padrão do chão é uma camada independente.
8. Manter a arte original e gerar uma nova folha versionada. Só substituir o muro do mapa depois que o conjunto passar pelo painel de montagem.

## Painel obrigatório de validação

Montar a partir das peças reais, sem pintura corretiva sobre a prévia:

- Uma reta horizontal e outra vertical com oito repetições cada.
- Um retângulo fechado usando as quatro quinas externas.
- Um contorno em L e outro em U, incluindo quinas internas.
- Dois trechos que terminam nas laterais de um portão.
- A mesma montagem sem vegetação, depois com decoração.
- Visualização sobre fundo claro e escuro para revelar alpha residual e halos.
- Inspeção em 100%, 200% e na escala efetiva do jogo.

Reprovar saliências periódicas, linhas de tampa repetidas, alteração de largura, pedra reiniciada na emenda, diferença abrupta de cor, sombra atravessando o vizinho, cantos tapados por sobreposição e vãos de alpha. Além de checar retângulos, comparar faixas de pixels nas conexões declaradas e inspecionar as montagens. Passar no teste de geometria não é aprovação artística.

## Correção aplicada · revisão de muros v3

Nova folha original `assets/world/quintal-kit-v1/walls-v2.png`, gerada com image_gen e alpha real. Quatro retas orientadas e quatro quinas vêm da mesma moldura conectada, recortada nas coordenadas 128/352/896/1120. Tamanho real da imagem medido: 1254×1254; não se presumiu que o tamanho pedido no prompt fosse o tamanho entregue. O PNG é preservado sem repintura ou alteração de pixels.

Escala uniforme de 3/16 em todas as peças, com cortes finais na origem em vez de compressão ou sobreposição. Trechos do quintal terminam sob os pilares do portão. A folha cobre o fechamento retangular atual; não é um autotile universal para cruzamentos, terminais livres ou qualquer relevo de terreno.

O painel `tools/atelie/wall-audit.html` reproduz oito peças em cada direção e os quatro cantos juntos, sem plantas e com fundos claro/escuro. A análise de alpha nas conexões supera 99% de coincidência; o contorno varia no máximo dois pixels da fonte (0,375 px na escala do jogo). Os resultados estão em `walls-v2-edge-audit.json`. Essa medição não prova continuidade de cor ou textura: a montagem também foi inspecionada no navegador.

Revisão no mapa: `/?project=quintal&revision=muros-v3`, com gravação separada das bancadas anteriores. A planta e o build padrão do jogo também usam a nova folha.
