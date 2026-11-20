# Vegetação top-down pixel — piloto v1
Seis variações para o universo Soulmonsters: capim-rabiola A/B, arbusto-folha-pipa A/B e bromélia-do-vento A/B. São nomes propostos para organizar a arte, não espécies ou itens canônicos.

## Entrega
- Seis PNGs RGBA individuais,64×64 cada.
- `atlas-64.png`: atlas transparente192×128,3colunas×2linhas.
- `kit.json`: IDs, retângulos, âncoras, ocupação e verificações.
- `vegetacao.aseprite`: fonte editável64×64 com6frames/tags, um por variante. Não é animação.
- `atlas.aseprite`: fonte do atlas, fundo de prévia oculto.
- `preview-4x.png`: atlas ampliado sem suavização, fundo cinza.
- `escala-kael-4x.png`, `comparacao-escala.aseprite`: Kael ao lado das variantes B, raízes alinhadas.
- `index.html`: galeria de zoom/fundos e comparação.
- `geracao.png`, `prompt.txt`, `normalizacao.json`: base e decisões de produção.

## Direção
Câmera elevada oblíqua compatível com os sprites recém-aprovados, contorno azul quase preto, linhas internas em sobreposições e sombras em planos. Folhas com silhuetas e dobras que lembram pipas, mantendo vegetação natural. Variedade por ramificação, quantidade/orientação de folhas, flores e largura; não simples espelho/recoloração.

Verdes de quintal e azul-petróleo recebem luz amarela discreta; creme/coral marcam flores. As bromélias são estilizações de fantasia, não representações botânicas rigorosas. A folhagem precisa ser testada sobre o piso definitivo antes de fechar contraste.

## Produção e proveniência
Geração de uma folha de6peças com image_gen integrada, usando os novos sprites de Kael/Alvacordo como câmera/acabamento. Aseprite MCP headless normalizou a folha de1536×1024 para192×128, com recortes64×64, paleta compartilhada de24cores e alpha0/255. As raízes foram alinhadas por translação inteira, sem ajustar cada planta para preencher o mesmo bounding box.

Os fundos coloridos visíveis na visualização da geração continham RGB residual em pixels transparentes; não fazem parte dos PNGs finais. Os assets finais não têm piso nem sombra pintada. Trata-se de adaptação e normalização de base gerada, não de desenho integral manual nem recuperação comprovada de uma grelha original.

## Uso no Godot
Destino solicitado: jogo top-down no Godot. Os arquivos são objetos de vegetação para camadas de decoração/objetos; não são pisos seamless ou autotiles com transições.
- Usar PNGs separados ou atlas com célula64×64.
- Manter filtragem Nearest e escala inteira para conservar os pixels.
- A âncora de raiz proposta é(32,52), registrada por peça no manifesto. A bromélia tem folhas projetadas abaixo da raiz.
- Conferir ordenação de profundidade pela base, separando copa e colisão quando necessário.
- Colisões e bloqueios de navegação não foram criados: dependem do uso de cada peça.

Nenhum TileSet, cena ou código do jogo foi alterado. Não foi alegada integração nem validação no mapa.

## Conferido
Inspecionados a prancha ampliada e o comparativo com Kael. Verificados seisPNG64×64, alpha binário, até24cores por peça, margens transparentes e igualdade exata de cada retângulo do atlas com seuPNG individual. Menor margem lateral3px no arbusto B; nenhuma peça toca a borda.
As variantes B são maiores/densas; a escala é proposta e ainda deve ser conferida em câmera real, especialmente o capim mais alto e as flores. Não houve playtest, teste em Godot ou revisão independente nesta entrega.


O ZIP inclui Kael somente como referência de escala da galeria e omite a geração original de alta resolução; a geração permanece nesta pasta do projeto. Os seis IDs de plantas são os únicos assets vegetais do manifesto.
