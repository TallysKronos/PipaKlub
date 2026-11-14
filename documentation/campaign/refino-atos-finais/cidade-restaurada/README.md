# F23 — as almas voltam à cidade

## Implementação

Após a ativação salva da Torre do Vento, duas tomadas mostram os cenários reais do Centro B e do Condomínio A. Kael e o parceiro ficam no cume; suas imagens não são duplicadas nas tomadas. Uma alma luminosa chega à criatura cinzenta. Ela recupera a cor e o movimento enquanto a noite desaparece. Depois retorna à exploração no cume e à indicação da Copa Relâmpago.

Os eventos Desalmado agora mostram Lacertubo e Raio, correspondentes aos seus duelos, usando os atlas existentes. As antigas imagens de capanga ficam ocultas. Vencer o duelo opcional não apaga a criatura: ela aguarda cinzenta. Após geradorLigado, permanece recuperada também ao retornar ao bairro ou carregar o save. O duelo não reabre. A cinemática não cria operações de recompensa, não altera o inventário e não transfere o jogador para a cidade.

Em movimento reduzido, cada tomada apresenta o estado recuperado brevemente, sem voo da alma, transição luminosa ou oscilação de idle. A entrada de mapa/menu fica bloqueada durante a apresentação e é devolvida no retorno. Cancelar a confirmação ou falhar a gravação não inicia a apresentação.

## Arquivos

- city_restoration_scene.gd: tomadas em SubViewport, energia e transição para o dia.
- city_soul.gd e city_soul.gdshader: corpo da criatura, perda/retorno de cor e idle.
- park_overworld_view.gd: persistência visual, mesmo após acalmar os Desalmados.
- front_end.gd: ligação com a ativação confirmada e devolução da exploração.
- endgame_story.gd: retira a descrição textual da recuperação que agora é mostrada.
- city_restoration_checks.gd: teste integrado da confirmação até o retorno ao cume.

## Verificação

- CITY RESTORATION: 25 checks; 0 failures, com movimento normal e reduzido.
- ENDGAME STORY: 98 checks; 0 failures.
- Endgame staging: 0 failures.
- Capturas antes/depois dos dois bairros revisadas a 1280×720. HUD e minimapa ocultos durante as tomadas.
- Testes cobrem cancelamento, falha ao gravar, retomada, permanência após o duelo opcional, retorno do controle, tecla de mapa durante a tomada, posição do save e ausência de recompensa adicional.

## Limitações e arte pendente

São os mapas e atlas atualmente integrados, sem nova ilustração. Os sprites ainda não possuem uma variante específica com a rabiola cortada: o estado desalmado é indicado por imobilidade e descoloração. Os interiores/objetos urbanos legados, incluindo a base visual atual do Condomínio, ainda precisam de refinamento próprio; esta entrega não redesenha esses mapas. NPCs de fundo conservam os modelos provisórios existentes.

A ativação já é salva antes da apresentação. Se o jogo for fechado durante a tomada, a cidade estará recuperada ao carregar; a montagem não é obrigatoriamente repetida. Saves anteriores com geradorLigado também recebem o estado recuperado, sem repetir a cena da torre.

As capturas são de teste com progresso preparado. Não houve uma partida humana contínua do ato 5. Sem publicação, merge ou push nesta entrega.
