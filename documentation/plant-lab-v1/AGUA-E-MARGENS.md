# Água e margens — primeira etapa

## Uso

Recarregue o Studio e escolha Água ou Areia nas propriedades de terreno ou na biblioteca. Pincel, preenchimento, conta-gotas, desfazer, JSON e exportação mantêm os materiais. O botão **Lago de teste** abre uma composição de demonstração; **Desfazer** recupera a composição anterior. Não substitui automaticamente o mapa salvo.

Há três novos sprites 64×64 com pivô [32,52]: pedra de margem, junco e vitória-régia. As pedras da amostra possuem colisão de objeto; as plantas são decorativas.

## Arte e comportamento

Tiles de 32×32, 47 máscaras e 3 variações para areia/grama e água/grama. A margem de água vizinha à areia recebe o fundo de areia; a margem junto à grama conserva o fundo verde, sem halo de terra do antigo material. Ondulações têm quatro fases a intervalos de 240 ms e ficam restritas ao interior da superfície, respeitando a oclusão do terreno. A animação não exige regenerar o raster estático a cada quadro.

Kael não entra na superfície de água. A colisão acompanha o recorte visível do autotile, incluindo os cantos. Um personagem colocado acidentalmente dentro dela pode sair. Esta etapa cria lagos e margens; não inclui natação, correnteza, poços profundos ou cachoeiras.

Assets procedurais originais, paleta limitada, contornos por pixels, sem copiar pixels das referências fornecidas. Geradores: `build-water-props.mjs` e `build-autotile-kit.mjs`. O mapa da amostra está definido em `water.mjs` e adapta-se às dimensões suportadas do editor.

## Godot

A exportação inclui os novos sprites e atlas, renderização dinâmica das margens, animação e bloqueio de entrada na água. `terrain-set.tres` tem quatro conjuntos pintáveis (grama/terra, pedra/terra, areia/grama e água/grama). A animação e a mistura de margens areia/água são responsabilidade do renderer do projeto exportado, além do TileSet estático. `prepare-godot.mjs --water` prepara a amostra de verificação isolada.

## Testes realizados

- 37 testes Node aprovados, incluindo importação/exportação, regressões de rampas, novos materiais e dimensões de mapa de 8×8 a 40×32.
- Navegador: pintura de água pelo mouse, amostra, desfazer/refazer, duas capturas com ondulações diferentes, e Kael correndo contra a margem por teclado.
- Capturas: `captures/water-lake-studio.png`, `water-frame-a.png`, `water-frame-b.png` e `water-shore-detail.png` (2×). Margem ampliada inspecionada.
- Godot 4.7.2: importação, execução da cena, teste de bloqueio e fases de animação, comparação pixel a pixel do raster dinâmico com o exportado, e pintura dos quatro conjuntos no TileMapLayer.

As verificações do navegador usaram uma sessão isolada. Não alteraram a sessão do usuário nem a campanha do jogo. Sem publicação Git nesta etapa.
