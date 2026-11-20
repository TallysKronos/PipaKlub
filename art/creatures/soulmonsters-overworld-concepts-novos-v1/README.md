# Soulmonsters no overworld

Primeiro lote de conversão das pranchas novas. O manifesto e cada ficha da galeria apontam para a prancha usada como referência.

- [Galeria pesquisável](index.html) e [prancha de conferência](preview-todos.png)
- [Manifesto de sprites](manifest.json) e [validação de exportação](validacao.json)
- [Prompts do lote](prompts.json)

Cada criatura tem um PNG de 160 × 80 px com duas células de 80 × 80 px. A primeira mostra a frente em três quartos para sudoeste, e a segunda mostra as costas em três quartos para noroeste. O pivô está em (40, 72) nas duas células. As poses são estáticas. O jogo pode espelhá-las para usar as diagonais opostas, seguindo o contrato do lote anterior.

Mantivemos a progressão de escala entre bebê, criança, jovem e adulto, com recuos para silhuetas abertas. Cada pasta traz as vistas individuais, o atlas e o arquivo Aseprite de dois quadros.

As vistas foram produzidas com ImageGen e finalizadas no Aseprite. Os bebês Lince de Cerco e Najarcal foram desenhados diretamente na grade para preservar o rosto em forma de pipa e o capuz em meia-lua, respectivamente. A vista de costas do Avelince bebê foi espelhada após conferência de orientação.

A entrega cobre a arte e os metadados dos sprites. A integração ao catálogo do Godot é uma etapa posterior.
