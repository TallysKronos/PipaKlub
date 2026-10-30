# Vídeo do Lacertubo · produção local H3

Pedido: um vídeo cinematográfico renderizado da apresentação do Lacertubo, com identidade de papel vivo e traço 2D mangá.

## Fontes

- `fontes/lacertubo-patio-keyframe.png`: quadro-base novo gerado pela ferramenta de imagem integrada. Layout e identidade guiados pelo cenário atual das Veredas e pela referência aprovada do Lacertubo. Prompt em `keyframe-prompt.txt`.
- `art/tyler-saber-forest-film-v1/keyframes/forest-lacertubo.png`: identidade aprovada, usada somente como referência do monstro.
- `workflows/lacertubo-patio-h3-local.json`: grafo API executável do ComfyUI, referências carregadas e guia temporal no quadro zero.
- `video-prompt.txt`: direção de ação, câmera, material e som.

## Geração

MiniMax H3 ref2va local INT8, Qwen3VL local NVFP4, VAE de vídeo INT8 e VAE de áudio FP32 já instalados. Uma amostragem de 192 quadros a 24 fps (8 segundos), 864×480, 20 passos, res_multistep/beta, seed 3010202688. Sem nós hospedados ou créditos de API. `job.json` registra o ID; `history.json` registra o resultado devolvido pelo servidor.

O quadro-base define o início. O prompt pede dois passos, vela dorsal abrindo, rugido e parada; o resultado generativo será conferido, sem tratar o texto do prompt como prova de que cada ação ocorreu.

## Reprodução e revisão

`tools/render-lacertubo-video.mjs` envia, consulta e recupera o MP4 a partir da API descoberta pelo Pinokio. `tools/export-lacertubo-video.py` preserva o original, produz MP4 de revisão, Theora/Vorbis para Godot, quadros e metadados. O preview 1280×720 é ampliado proporcionalmente: não é geração HD nativa. Sem juntar trechos, inventar quadros parados ou dissolver tomadas.

Estado e observações da revisão serão registrados ao recuperar o vídeo.
## Resultado e revisão

Job `e4cfd5d4-a629-4d4d-a75b-62cd88cdd416` concluído sem erros de validação. Uma geração local levou aproximadamente 8 min 51 s, incluindo preparação e decodificação. Original preservado em `video-original/cinematic-patio-v1_00001_.mp4`.

Foram conferidos a prancha de 12 quadros e o enquadramento do rugido: o personagem conserva a paleta verde-petróleo/dourado, remendos, tubos brancos, nós laranja, quatro patas e cauda de bandeirolas. Há passos, articulação das patas, papéis em movimento, aproximação de câmera e abertura/fechamento da boca. A construção das facetas e dos remendos tem pequenas variações generativas durante a ação; a imagem não corresponde a um rig com registro idêntico quadro a quadro. Não houve aprovação visual nova do dono. A presença da faixa de áudio foi verificada tecnicamente; não houve avaliação auditiva humana nesta rodada.

O arquivo nativo é 864×480, 24 fps, oito segundos, com áudio. MP4 para assistir em `documentation/qa/lacertubo-video-v1/lacertubo-cinematic.mp4` e Ogg Theora/Vorbis para o jogo em `godot/assets/campaign/cinematics/lacertubo-patio-h3-v1.ogv`. O MP4 de revisão foi ampliado para 1280×720 com proporção preservada e pequenas barras; não é HD nativo.

## Integração no jogo

A aproximação inicial do Lacertubo usa o vídeo quando o arquivo está presente e a preferência de movimento reduzido não está ativa. O vídeo reproduz continuamente com seu áudio; os sinais sonoros da versão desenhada pela engine ficam desativados para evitar duplicação. Música/ambiente baixam 12 dB durante a tomada e recuperam os valores anteriores ao sair. Depois do fim real do decoder, entra a fala do Kael e a exploração retorna. Esc interrompe o vídeo e restaura o controle. A decisão de iniciar batalha continua separada.

A versão anterior em `lacertubo_cinematic.gd` foi conservada para movimento reduzido e ausência do arquivo. Saves que já registraram `lacertuboIntroduced` não repetem automaticamente a apresentação; o MP4 permite assisti-la sem modificar o progresso.

Verificação nativa do Godot em 1280×720: `lacertubo_movie_checks.gd`, 15 verificações sem falhas, incluindo avanço efetivo da posição de reprodução, fim do decoder, skip, restauração e gravação da apresentação. Regressão da versão de movimento reduzido: 34 verificações sem falhas. Campanha: 206 verificações sem falhas. Saves isolados, sem uso do progresso do usuário. Capturas do filme rodando no jogo e da volta ao Kael na pasta de QA. Export executável e controle físico não testados.
