# Pipa TV · vinheta H3 local

Estado: vídeo gerado e integrado localmente; aprovação artística do usuário pendente. Sem push ou publicação.

## Produção

Vinheta cinematográfica original, sem captura da batalha jogável. As referências de Carcará e Azulão vieram dos modelos existentes, reinterpretadas pela ferramenta integrada image_gen; uma terceira pintura define o céu e a cidade brasileira. Originais e prompts em `art/pipa-tv-cinematic-v1/`.

O vídeo foi gerado no ComfyUI local, MiniMax H3 reference-to-video INT8, com três referências independentes, 20 passos e sampler res_multistep/beta. O ramo Turbo opcional do template foi removido por depender de uma LoRA ausente; não foi substituído por uma LoRA de outra tarefa. Nenhum modelo grande novo foi baixado. O workflow foi validado contra o catálogo local: zero erros, zero avisos e nenhum nó pago.

- Workflow editável do projeto: `art/pipa-tv-cinematic-v1/pipa-tv-h3-local.json`.
- Biblioteca da instalação ComfyUI: **PipaTV - Duelo H3 local**.
- Job local: `36bb2109-06ca-4ebb-897d-b94226cabd94`, concluído.
- Fonte: `video-original/36bb2109_000.mp4` no diretório de arte; H.264, 864×480, 24 fps, 6,58 segundos, áudio AAC estéreo 32 kHz.
- Revisão: `pipa-tv-duelo-h3.mp4` nesta pasta.
- Runtime: `godot/assets/campaign/cinematics/pipa-tv-duelo-h3.ogv`, Theora/Vorbis, aproximadamente 6,9 MB.
- As versões de revisão e runtime usam um quadro 1280×720 por redimensionamento e ajuste de proporção; a geração original não é 720p nativo.

O roteiro pede mergulho, esquiva, contra-ataque de vento e separação dos adversários; é uma interpretação generativa, não uma simulação das regras de combate. Não declara vencedor nem introduz uma habilidade nova no gameplay.

## Integração

`opening_tv.gd` reproduz o OGV num quadro maior acima do diálogo, com filtro linear e áudio reduzido. Mantém o mesmo vídeo ao avançar entre as duas falas da transmissão, repetindo quando termina. Pausar a cena ou perder foco também pausa o vídeo. Ao retornar a Kael, a inserção desaparece e o player é parado, incluindo áudio. O quarto permanece vivo por baixo da vinheta. A apresentação anterior fica apenas como fallback se o arquivo de vídeo estiver ausente.

## Revisão realizada

Inspeção de planos extraídos do vídeo, metadados, importação e reprodução nativa no Godot a 1280×720, incluindo retorno ao quarto. Capturador `godot/tools/tv_cinematic_preview.gd` usa snapshot fictício, sem criar slots ou confirmar progressão. Não houve suíte automatizada nem playthrough completo. Áudio está presente no arquivo; não foi feita revisão auditiva humana. Suavidade e identidade entre quadros continuam sujeitas à revisão artística do usuário.

Para converter outra saída aprovada, executar `tools/encode-pipa-tv-video.py <arquivo.mp4>`, com imageio-ffmpeg disponível em `tmp/video-encoder/`. Esse codificador foi instalado na pasta temporária do projeto; o jogo distribuído usa apenas o OGV e não depende de Python/FFmpeg. Para reutilizar o workflow em outra instalação, carregar as três referências em `input/` com os nomes registrados e selecionar os modelos locais equivalentes.
