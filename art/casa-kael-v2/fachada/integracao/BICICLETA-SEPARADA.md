# Bicicleta independente

A bicicleta foi retirada do kit de texturas da casa e da função que monta o portão.
Agora é um prop reutilizável, com cena própria em
`godot/scenes/overworld/props/bicycle.tscn`, script em
`godot/scripts/overworld/bicycle_prop.gd` e textura/manifesto próprios em
`godot/assets/overworld/props/kael-bicycle/`.

O desenho aprovado de 80×85 px e a fonte Aseprite foram preservados.
Na casa, a montagem instancia a cena e a instala antes da reconstrução de visibilidade.
O prop configura sua célula, espelhamento, apoio pela cota do piso e filtro nearest.
Os pés das rodas usam o centro inferior dos limites opacos, com escala nativa 1.
A posição atual continua (2; 18,85), fora do vão do portão.

Validação no Godot: **55 verificações, zero falhas**. Conferidos cena independente,
referência ao mesh reconstruído, asset próprio, nearest, apoio das rodas, travessia
e fluxo de entrada/retorno. A suíte usa um slot descartável sem tocar saves pessoais.

Para reutilizar: instanciar a cena, configurar `cell` e `flip_h`, chamar `install(world)`
antes de `order_faces()` e da geração de profundidade. É um componente estático de
cenário: não implementa pilotagem ou movimento da bicicleta durante a partida.
