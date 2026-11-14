# F20 — reunião dos campeões

A reunião reúne Mikka e os outros sete campeões, incluindo Dona Neve. Sua arte própria ainda não está integrada; ela usa o modelo provisório do professor autorizado pelo dono. Nenhuma imagem foi gerada.

## Encenação

O ponto da reunião na praça define a disposição preferida. A busca resolve conflitos com Kael, o seguidor, Mikka e os NPCs presentes. Os campeões ficam em chão alcançável na mesma cota, fora de rampas e escadas. A separação considera os pés e a silhueta, impedindo a sobreposição de cabeças e pernas observada na primeira captura.

A câmera enquadra o grupo acima do diálogo. O sinal speaker_changed identifica quem fala no cenário, mostra nome e círculo de apoio e reduz o destaque dos outros. Páginas, controles e retratos do kit foram preservados. Dona Neve recebe uma fala breve sobre patrulhar a Serra. A conclusão aponta o posto de Dona Cida e o Exame Vermelho.

A retirada evita paredes, desníveis e segmentos que cruzariam Kael. Ao terminar ou cancelar, os atores e o marcador são removidos, e câmera, cores, HUD e controle são restaurados. Não cria uma simulação de patrulha nos outros bairros.

## Evidências

- CHAMPIONS MEETING: 118 checks; 0 failures, com movimento normal e reduzido.
- ENDGAME STORY: 98 checks; 0 failures.
- Endgame staging: 0 failures.
- Testes cobrem elenco, silhuetas, terrenos, destaque por página, cancelamento, falha ao salvar, nova tentativa, limpeza, câmera, Exame Vermelho e persistência.
- meeting.png e neve.png: capturas do jogo a 1280×720 após corrigir sobreposições e estabilizar a câmera.

## Limites

Os testes usam progresso preparado e acionamento interno dos controles. Não representam uma sessão humana contínua ou controle físico. As artes são as existentes; Dona Neve ainda precisa de sprite próprio. A retirada usa movimentos e fade disponíveis, sem novos ciclos de caminhada.

O teste geral da HUD de diálogos também foi iniciado. Ele percorre cenas de outras partes do jogo e emitiu avisos anteriores sobre carregamento de imagens em house_modern.gd incompatível com exportação. Essa pendência está fora da nova reunião e não foi corrigida nesta etapa.

Não houve alterações de terreno, recompensas, balanceamento ou ordem da história. Sem publicação ou push.

O teste geral terminou com DIALOGUE HUD: 629 checks; 0 failures. Além dos avisos de imagem da casa, emitiu avisos de instâncias/recursos ainda em uso ao encerrar. Não foi declarado como encerramento técnico limpo.
