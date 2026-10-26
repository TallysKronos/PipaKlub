# Escada inserida no muro — revisão local PIP-88

## Pesquisa e diagnóstico posterior à revisão do usuário

A entrega inicial desta pasta ainda conservava a face completa de `cliffs` em (11,4), lado u, junto à rampa (12,4). Essa face cobria as paredes internas e parte da escada. Acrescentar coroamento e mudar camadas sem removê-la não abriu corretamente o volume. A revisão posterior suprime essa face somente quando o construtor já desenhou a escada de pedra naquele encontro; a parede exposta passa a ser a lateral construída acima de cada degrau. As capturas `after/` foram atualizadas com essa alteração.

Fontes primárias consultadas:

- [Godot CanvasItem](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html): ordem de desenho, hierarquia, Y-sort e Z. Não há recorte geométrico automático por alterar a ordem.
- [Godot Using TileSets](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html): Texture Origin, Z Index e Y Sort Origin são controles distintos. Este projeto usa Polygon2D; não usa TileMapLayer para essa escada.
- [Shaun Lebron — IsometricBlocks](https://shaunlebron.github.io/IsometricBlocks/): sobreposição de volumes, ordenação por relações espaciais e necessidade de dividir/recortar objetos em casos de oclusão incompatível.
- [Clint Bellanger — Isometric Tiles Math](https://clintbellanger.net/articles/isometric_math/): coordenadas lógicas e projeção são responsabilidades separadas. A projeção atual é 64×32, com altura de nível 64 px.

Conclusão aplicada: remover a face sólida duplicada no encontro com a rampa, preservando as paredes internas que acompanham os degraus. A subida/descida sem falhas de caminho não prova sozinha a qualidade visual; ambas as verificações são registradas separadamente.

Referência do usuário: escadas isométricas com abertura, paredes internas e coroamento. Revisão de 26/10/2026. A referência orienta a estrutura; conserva-se o revestimento de pedra já aprovado.

## Alteração

- As oito pisadas conservam a pegada 2×1 e o desnível de 64 px da navegação.
- Laterais adjacentes a terrenos altos ganham paredes internas entre a pisada e o topo do terreno, com pequena borda de pedra elevada e extremidades fechadas.
- Os cantos chanfrados da tentativa anterior deixam de recortar os encontros dos batentes.
- Pisos ficam na camada -2; degraus e sustentação, -1; paredes internas e coroamentos voltam à camada 0, ordenados pela pegada, junto aos muros e atores. Isso evita tanto terreno cobrindo os degraus quanto degraus cobrindo o corpo dos atores.
- Não altera mapas, colisões, alturas lógicas, saves ou campanha principal. Integração na prévia Godot da PIP-88.

## Conferência realizada

Capturas nativas de 1280×720 em `after/`, geradas com:

```text
Godot --path godot --script res://tools/morro_wall_review.gd -- --stairwell
```

Inclui Praça da Chegada, Escadaria da Sombra e Parque dos Ventos; detalhe texturizado; geometria sem texturas; e quadros de subida e descida com Kael e seguidor. `capture.json` registra aceitação do caminho e chegada aos dois patamares. A execução percorreu o trecho pela função real de movimento, em passos de 1/60 s, sem modificar saves. Log nativo sem erros de script ou renderização.

É uma verificação localizada de passagem e imagem, não uma suíte completa da campanha. As imagens antigas em `escadas-encaixes/` permanecem como histórico da solução anterior.
