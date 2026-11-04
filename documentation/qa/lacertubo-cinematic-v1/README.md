# Lacertubo · apresentação cinematográfica v1

Cinematic de 10,5 segundos integrada à primeira aproximação do pátio das Veredas, quando a missão de Nina foi aceita e o guardião ainda não foi vencido. Preserva o requisito da missão e a decisão explícita de enfrentar o chefe.

## Direção

- 0–3,25 s: barras cinematográficas entram, HUD e minimapa saem, a câmera se aproxima do guardião e a arte dos canos vibra discretamente.
- 3,25–7,6 s: recorte diagonal em azul-petróleo e ouro, Lacertubo em destaque com sua arte aprovada, vela dorsal armando, cauda articulada e expressão de rugido. Assinatura sonora e voz do catálogo existente.
- 7,6–10,5 s: câmera regressa ao Kael; uma fala curta liga a rabiola de Nina à abertura do golpe. A exploração volta com seis segundos de tolerância a encontros.

O Lacertubo usa as peças do rig Soulgen aprovado, já normalizadas em `godot/assets/care-room-v1/lacertubo/`. Não houve redesenho da criatura. O ator cinematográfico preserva pivôs, quatro patas, PVC, remendos, vela e rabiola. Efeitos e recortes são desenhados nativamente no Godot. A cena é uma timeline na engine; não é um arquivo de vídeo prerenderizado.

## Comportamento

Esc ou botão Pular encerra a sequência com a mesma limpeza do término natural. Jogador e parceiro não são teleportados. HUD, câmera, zoom, suavização e posições originais dos canos são restaurados, inclusive ao remover a cena. A flag `lacertuboIntroduced` só é persistida no fim/pulo; ao reabrir o save ela evita a repetição automática. Falha de gravação mantém a possibilidade de tentar a apresentação novamente. Nenhuma batalha é iniciada pela cinematic e nenhum XP, item ou moeda é concedido.

Movimento reduzido mantém a leitura e o deslocamento de câmera, retirando tremor, zoom, vibração dos canos, deslocamento das linhas e movimentos do rig. Controles e texto ficam fora da arte. O dimensionamento do retrato considera largura e altura, evitando cortar cabeça e rabiola em janela 4:3.

## Arquivos

- `godot/scripts/campaign/lacertubo_cinematic.gd`: câmera, timeline, composição, entrada e restauração.
- `godot/scripts/campaign/lacertubo_cinematic_actor.gd`: atuação do rig aprovado.
- `front_end.gd`: integração em camada acima do viewport da exploração e gravação ao concluir.
- `godot/tests/lacertubo_cinematic_checks.gd`: save isolado, gatilho real de aproximação, conclusão, pulo, retorno, acessibilidade, persistência e proteção da economia.
- `godot/tools/lacertubo_flow_review.gd`: ferramenta anterior de revisão adaptada ao novo componente.
- Preset Windows inclui explicitamente os JSONs dos rigs usados pela cena; export empacotado não testado nesta entrega.

## Validação

34 verificações da nova apresentação, com execução nativa em 1280×720 e 960×720. Reprodução contínua por `-- --realtime`, além da timeline determinística. 206 verificações de campanha aprovadas. Capturas nativas em `documentation/qa/lacertubo-cinematic-v1/` (canos, destaque e volta ao Kael). Foi corrigido um corte da cabeça na janela 4:3 encontrado na inspeção das capturas.

Não houve teste com controle físico, export Windows ou nova auditoria de todos os mapas. O `lacertubo_flow_review.gd` foi adaptado, mas não executado integralmente nesta rodada; a validação do novo gatilho usa seu próprio teste com o frontend real.

Para repetir a apresentação, use um save anterior ao primeiro encontro; saves com a flag já registrada continuam sem repetição automática. Teste isolado: Godot `--path godot --script res://tests/lacertubo_cinematic_checks.gd -- --realtime`.
