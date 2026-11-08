# Trailer SoulMonsters · Elo das Ruínas (v1, 08/11/2026)

`trailer-soulmonsters-v1.mp4`: 56 s, 1920×1080, 30 fps, H.264 + AAC. Estilo mangá cinematográfico,
em português, sem spoilers grandes (Eremor, origem do Tyler e desfecho ficam de fora).

Música: "Vento · aventura". Efeitos: `godot/assets/audio/sfx-v1`.

## Como refazer

1. Gravar os planos no Godot (Movie Maker, 1920×1080) com `godot/tools/trailer_capture.gd`:
   - um plano por execução: `--shot=<nome> --secs=<s>`;
   - nomes: `titulo`, os duelos `duelo-*` e as caminhadas listadas no script;
   - exige um `godot/override.cfg` temporário com o tamanho de janela 1920×1080; apague-o depois.
2. Montar o vídeo:
   ```
   python3 tools/trailer/montar_trailer.py --clips <pasta dos clipes> --out video.mp4
   ```
   - `--preview N` e `--stills <pasta>` servem para conferir quadros;
   - `--range t0,t1` renderiza só um trecho.
3. Gerar o áudio:
   ```
   python3 tools/trailer/mixar_audio.py --out audio.wav
   ```
4. Juntar vídeo e áudio:
   ```
   ffmpeg -i video.mp4 -i audio.wav -c:v copy -c:a aac -b:a 256k -shortest trailer.mp4
   ```
