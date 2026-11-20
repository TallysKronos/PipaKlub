# Azulfazo — piloto de animação overworld

Idle e caminhada em duas vistas, SW e NW. Cada ciclo tem oito quadros por vista, célula 112×112 e apoio em (56,100). SE e NE usam espelhamento, como as poses estáticas anteriores; a iluminação também é espelhada nesse caso.

Arquivos:

- `azulfazo-animado.aseprite`: 32 quadros, sete camadas de partes e quatro tags.
- `idle.png`, `walk.png`: 896×224; oito colunas, frente na primeira linha e costas na segunda.
- `idle.gif`, `walk.gif`: prévias ampliadas por nearest-neighbour.
- `in-game-idle.gif`, `in-game-walk.gif`: capturas do renderer real durante o teste controlado no parque.
- `animacoes.json`: dimensões, tempos, vistas, apoio e estado de produção.
- `validacao.json`, `playtest.json`: evidências mecânicas.

## Movimento e integração

Rig específico desta anatomia: torso, cabeça/crista, duas asas, duas pernas e rabiola. Poses feitas no Aseprite por deslocamentos inteiros e ajustes de conexão das articulações. A paleta da imagem aprovada é preservada; não houve nova redução, suavização ou geração de vídeo.

Idle de 1,8 segundo com durações variáveis, corpo baixo, cabeça e apêndices defasados. Caminhada com passada curta, asas acompanhando o peso e rabiola atrasada. No runtime, oito poses avançam a cada duas células de deslocamento real; em salas e rotas com coordenadas antigas, a referência é 128 unidades. Parado usa idle. Pausa interrompe o avanço junto com o controlador do mapa.

O consumidor usa `godot/assets/campaign/overworld-animations-v1/manifest.json`. O piloto foi estendido às outras 193 criaturas; consulte `art/creatures/overworld-animacoes-v1/README.md` para a entrega do lote. O retrato permanece na folha estática aprovada. Oclusão usa os limites opacos do quadro atual. Texturas e limites dos quadros são carregados uma vez por modelo.

## Revisão e limites

Primeira revisão: 6/10, com pequenas separações na crista/tornozelos e rabiola abaixo do apoio. Corrigidos os recortes, as conexões de um/dois pixels e o limite inferior da rabiola. A segunda revisão independente preferiu a correção, deu **7/10** e considerou os bloqueantes resolvidos.

Pontos não bloqueantes mantidos: pequeno serrilhado interno da asa próxima no quadro 3 da caminhada frontal (x75–82,y46–53); passada traseira discreta porque uma pata fica encoberta. Não aplicar este rig automaticamente a quadrúpedes, corpos flutuantes ou outras anatomias.

Validação final:

- 32 quadros sem pequenos grupos opacos separados (conectividade de oito vizinhos).
- Variação de volume máximo de 1,53% na revisão.
- 34 verificações de transição idle/walk, distância, direções, apoio, limites e troca de equipamento: zero falhas.
- 518 verificações dos companheiros: zero falhas.
- 1.675 verificações do percurso visual, incluindo caminhada, corrida e oclusão: zero falhas.

Capturas com 1280×720, zoom 1 e CRT desligado. Não representam auditoria de todas as resoluções/filtros. Logs mantêm avisos preexistentes de NPCs Cauê/Celina. Testes usam save isolado e comandos de produção, sem alterar o save do jogador. Integração local; sem commit ou push nesta etapa. O lote foi autorizado após o piloto; os números acima registram a validação original dele.

Reprodução: `scripts/overworld-xprite-v2/animate-azulfazo.lua` no Aseprite batch com parâmetro `root`, seguido de `check-animation.py` para QA e prévias; testes Godot `overworld_animation_checks.gd`, `overworld_companion_checks.gd`, `overworld_visual_playtest.gd`.
