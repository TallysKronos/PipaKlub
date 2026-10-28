# Gruta dos Elos — biblioteca visual v3

Esta revisão atende ao pedido de distinguir piso, parede, obstáculo e ponto de interesse. As silhuetas da v2 foram preservadas, com cores redistribuídas por família, chão quase liso, paredes de valor intermediário e objetos claros com borda externa mais firme. O resultado é conferido em cor e em cinza nas capturas nativas.

Nos objetos, `ContactShadow` é uma sombra curta independente em geometria, ajustável no editor. `cave_prop_outline.gdshader` reforça apenas o contorno externo da máscara alpha; `outline_width` controla a espessura em pixels da textura. A margem transparente de 8 px comporta o contorno. A abertura do portal conserva um interior bem escuro.

Revisão de identidade solicitada pelo usuário: 2D flat, contorno azul, formas inspiradas em dobras, nós, varetas e rabiolas. Consulte [DIRECAO-VISUAL.md](DIRECAO-VISUAL.md). Os nomes são propostas de assets; não registram novas criaturas, lore ou habilidades.

## Entrega

- 16 pinturas geradas/editadas nesta revisão e 2 pinturas de água herdadas da v2; fontes originais e prompts em `fontes/`.
- 4 pisos: Leito de dobras, Terra de papel, Pedra de maré e Lascas de vela. Cada um tem 47 recortes de terreno + 8 centros: **220 PNGs**.
- 4 paredes: Dobras de calcário, Ardósia do vento, Parede de ecos e Veios de elo. Cada uma tem 8 fases de faces U/V, 4 cantos e 4 terminações: **64 PNGs**.
- 8 objetos recortados com alpha real e pivô de apoio: Pedras dobradas, Nós de pedra, Agulha do vento, Coluna de rabiolas, Ecos de Azulão, Brasa de Carcará, Flores de linha e Portal do elo.
- 2 pinturas de água próprias: Água de linhas e Queda de fitas, movidas pelos shaders do kit de água.
- 4 TileSets, 4 materiais de piso, 8 cenas de objetos, 2 cenas de montagem (seca/inundada) e 1 componente de poço rebaixado.

**292 recortes** derivam das pinturas e de projeção geométrica; não são 292 desenhos independentes. Os 18 originais estão preservados. As versões anteriores permanecem preservadas.

## Poço rebaixado — correção de geometria

A montagem inundada agora usa `poco-rebaixado.tscn` / `cave_basin.gd`: o chão é recortado por um contorno irregular arredondado, com faces internas até a água **24 px abaixo do solo**. A queda soma os 128 px do lábio acima do solo e os 24 px do rebaixo: **152 px**. Piso, margem e água compartilham o contorno; o chão próximo oclui a água e suas faces. A espuma de impacto fica na camada da água, sob a oclusão da margem. Não é uma textura de água desenhada sobre o piso.

A peça tem limite de profundidade 16–24 px para a folga de projeção deste canto. As duas cenas de montagem foram atualizadas e o componente do poço também é fornecido separado: agora são **11 cenas**. O componente inclui a superfície de solo 10×10 recortada e o caminho; não sobreponha outro piso inteiro sobre ele. É uma peça visual de canto, sem colisão ou nado. Sua origem continua sendo o centro da célula (0,0).

Evidências em `documentation/overworld/cavernas-v3/revisao-poco/`, incluindo antes/depois, detalhe e cotas. A regra geral foi registrada em `AGENTS.md` e `documentation/continuidade-terreno-isometrico.md`. A vista geométrica sem objetos está em `nativo/poco-geometria-1280x720.png`.

## Godot

Runtime: `godot/assets/overworld/kits/cavernas-v3/`. Cenas: `godot/scenes/overworld/caves-v3/`. Use o TileSet e o material correspondente no TileMapLayer para a textura continuar entre células. A máscara do atlas permanece fixa; a pintura é amostrada no mundo. `cells_per_repeat=8` e contraste reduzido deixam o piso mais calmo que os objetos. O atlas colorido também pode ser usado estático; seu padrão repete com mais frequência que a versão com material.

Grade 64×32; um nível de altura tem 64 px. Centro da célula (0,0) é a origem das montagens. As cenas seca/inundada são blocos visuais abertos para composição, sem câmera, controle de jogador ou navegação. Não são mapas de campanha prontos.

Os objetos têm a origem no apoio, Sprite2D deslocado pelo pivô e filtragem nearest. Sua `footprintCells` no manifesto é uma estimativa para edição. Não foram criados corpos físicos ou colisões. Ordene objetos pela profundidade com Y-sort; a parte alta do PNG não deve bloquear todo o retângulo.

A montagem inundada usa uma superfície poligonal inferior, com a cortina e a espuma de `aguas-v1` e duas pinturas de água herdadas da v2. `cave_waterfall.gd` expõe `surface_override`, preservada ao salvar a cena; `drop_pixels_override` inclui a depressão do poço. A origem da queda é o lábio; o fundo fica 152 px abaixo, apoiado na água a -24 px do solo. Os filhos procedurais são reconstruídos ao instanciar, sem duplicar a água.

O ZIP inclui o kit `aguas-v1` e seus scripts/shaders como dependências, além da biblioteca de caverna. Extraia a pasta `godot/` sobre a raiz do projeto, preservando os caminhos `res://`. Não substitui `project.godot`, campanha ou saves.

## Revisão

`documentation/overworld/cavernas-v3/` contém arte fonte ampliada, catálogo, 14 páginas nativas 1280×720, GIF/WebP da água e relatórios. Os pisos foram vistos como 8×8 e como L com canto interno/vazado; as paredes em faces consecutivas e cantos; os objetos isolados e nas duas montagens. As duas cenas salvas também foram instanciadas e capturadas. O poço possui revisão geométrica sem objetos e detalhe ampliado da margem e do impacto.

O relatório de preparação registra geometria das 47 máscaras, limites periódicos e alpha/pivô. O relatório de animação compara as fases 0 e 4 s do render nativo. São verificações dos assets e da galeria, sem suíte de testes de gameplay e sem acessar uma campanha.

Reconstruir: `python tools/overworld/build_cave_readability_library.py`; importar o projeto; executar `godot --path godot --script res://tools/cave_readability_preview.gd`. Acrescente `-- --live` para deixar a montagem inundada em movimento. A galeria usa fontes novas e não grava em contas, inventário ou banco de produção.

Aplicação em mapas, colisões, áudio, exploração e interações permanecem para integração futura. Nada foi publicado ou enviado ao Git nesta etapa.
