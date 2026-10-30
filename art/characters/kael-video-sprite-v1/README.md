# Kael: teste vídeo → spritesheet

Teste solicitado após o usuário rejeitar o desenho procedural do rig.

- Referência: estudo DS v3, isolado como keyframe pela ferramenta de imagem (referencia.png).
- Geração: MiniMax H3 local no ComfyUI,512×512,124 frames a24fps,16steps. Sem API paga. Workflow exato e prompt guardados.
- Vídeo original: video-original/2ee8f5c1_000.mp4.
- Extração: oito amostras entre1.1667 e2.1875 segundos, recorte/escala únicos para a seleção, sem auto-fit por quadro; chroma binário e uma paleta compartilhada.
- Comparações: folha-48x64 (20 cores) e folha-64x96 (24 cores). Cada pasta tem PNGs individuais, sheet.png, revisao.png, video.pixelgen.json e manifest.json com os timestamps.

## Resultado e limites

A revisão independente considerou a fonte de movimento melhor e a versão64×96 mais legível. Ainda identificou variação de volume da cabeça e do tronco, pixels soltos e necessidade de conferir a emenda8→1. São rascunhos para revisão, não sprites aprovados para substituir Kael no jogo. Limitar cores e alpha não recupera automaticamente clusters desenhados. A extração entrega uma camada: não existe segmentação anatômica automática nem rig inferido.

A referência também tem uma grade visual mais detalhada que48×64; a redução perde rosto e fones.64×96 é uma comparação, não um novo padrão de escala aprovado para o jogo.

## Repetir

```powershell
python tools/pixelgen/video-to-sheet.py video.mp4 --out pasta-nova --start 1.1666667 --duration 1.1666667 --frames 8 --width 64 --height 96 --colors 24
```

Use espaços entre flags e valores; exemplo:
`--start 1.1666667 --duration 1.1666667 --frames 8 --width 64 --height 96 --colors 24`.

No Pixelgen: botão “Kael · vídeo → 8 quadros ·64×96”; ou Abrir arquivo → video.pixelgen.json. Próxima correção artística: estabilizar cabeça/torso contra um frame escolhido e revisar contatos e loop, antes de expandir direções.
