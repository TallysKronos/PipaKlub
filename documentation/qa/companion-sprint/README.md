# Acompanhamento do Soulmonster durante a corrida

Correção posterior à introdução da corrida do Kael.

## Problemas corrigidos

- No quarto, o jogador corria a 648 unidades/s, mas o seguidor tinha limite de 400. Além disso, consumia apenas um ponto da trilha por quadro. Agora usa orçamento de deslocamento de 720 unidades/s e pode percorrer vários passos curtos no mesmo quadro.
- Os mapas externos tinham duas implementações de acompanhamento. Todas as áreas desse controlador agora registram cada movimento aceito do jogador, incluindo os passos laterais usados para deslizar em cantos. O Soulmonster segue essa trilha a até 6,3 células/s, mantendo a distância de 0,8 célula, sem recalcular atalhos através de obstáculos.
- As árvores e construções passam a considerar também o corpo do seguidor para a transparência de oclusão, utilizando sua própria altura e posição.
- A orientação agora é comum a quarto, cidade, mapas externos e rotas do Morro: oeste e diagonais esquerdas espelham a criatura, leste e diagonais direitas desfazem o espelhamento. A direção oeste faltava no controlador da cidade e a orientação dos mapas externos ficava fixa.

Os sprites de criaturas disponíveis têm uma única vista lateral/diagonal. O ajuste usa espelhamento horizontal e conserva o último lado no movimento puramente vertical; não cria poses novas de frente/costas nem gira a imagem ou o pivô.

## Verificação

`godot/tests/companion_sprint_checks.gd`: 2.864 verificações, zero falhas, em execução nativa 1280×720. Inclui ida e volta em corrida contínua no Jardim e no Bosque, distância máxima do seguidor, apoio, fila de passos limitada, múltiplos passos por quadro, transparência de oclusão somente do seguidor, corrida sustentada no quarto e troca de lado na cidade. O teste anterior à adição das duas verificações de oclusão também passou headless (2.862 verificações).

`locomotion_checks.gd`: 222 verificações, zero falhas, depois da alteração. `locomotion_city_room_checks.gd`: 11 verificações, zero falhas.

`locomotion_traversal_checks.gd`: 72 destinos, 144 percursos, 36.900 passos de simulação nas Veredas, zero falhas de percurso, apoio do jogador/seguidor ou chegada. Inclui pontes, rampas e saída/retorno entre áreas.

Capturas inspecionadas: `cidade-left.png`, `cidade-right.png` e `kronasta-bosque-a.png`, com o Soulmonster visível junto ao Kael e os lados correspondentes. `jardim-das-pipas.png` registra o retorno ao ponto inicial nessa área. Os mapas externos foram capturados pelo controlador de prévia; a cidade, pelo adaptador da campanha. Os testes usam dados locais sem abrir saves do jogador.
