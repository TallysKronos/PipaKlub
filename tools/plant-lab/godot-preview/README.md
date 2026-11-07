# Bancada Godot exportada

Abra `project.godot` no Godot 4 e execute o projeto. Todos os recursos acompanham o pacote. O layout top-down usa tiles de 32 px, cotas de 16 px, filtragem nearest e as mesmas regras do Studio para volume, bordas, rampas e água.

Tab alterna editar/testar. WASD/setas anda; Shift corre; E interage em teste. Kael usa caminhada animada frontal/traseira e idle. NPCs podem ter patrulhas por pontos. Colisões preservam círculo, retângulo e polígono com deslocamento da base.

Na edição de apoio: N próxima peça, K floresta, V mover, E apagar, P piso, H altura, L cota zero, U rampa norte, J parede, T revestimento, O revelar atrás, [/] cota de apoio, G grade, Del excluir, F espelhar. A criação completa de rampas nas quatro direções e escadas é feita no Studio web; a bancada nativa reproduz todas elas.

F5 dentro do jogo salva uma cópia em `user://jardim-<id>.json`, separada por projeto. R restaura a exportação original. Não altera saves da campanha.

`area_bridge.gd` oferece runtime sem os controles de edição e emite `interaction_requested(event)` para conexão ao jogo. `integration/area.overworld.json` é o adaptador lógico da campanha; `integration/area.topdown.json` conserva a fonte visual. Use a ponte para manter a projeção top-down.

Para montagem em outro projeto, os caminhos `res://` precisam do namespace correto. No repositório de origem, `tools/plant-lab/reimport-godot.mjs` revisa diferenças e protege mudanças manuais; `stage-embedded.mjs` prepara e verifica a versão aninhada. Consulte `documentation/plant-lab-v1/INTEGRACAO-GODOT.md` nesse repositório.

O editor principal é o Studio web. Este projeto é uma bancada executável e uma fonte de integração; não incorpora automaticamente combate, narrativa ou inventário da campanha.
