# PIP-88 — grama do Morro

> Registro da primeira revisão. A base visual foi posteriormente substituída
> pela família ilustrada de [pisos do Morro](../pisos-morro/README.md), que passa
> a ser a referência atual para os tiles e a renderização do chão. As capturas
> abaixo permanecem como histórico; os sete decalques continuam em uso.

Base de trabalho: `claude/pip-88-mapa-melhorado`, commit `293ff73`.
Escopo: kit e cena de revisão do overworld; a campanha continua usando seus
consumidores atuais. Esta entrega não troca o mapa da campanha nem modifica saves.

## Arte e integração

- Oito PNGs 64×32 e fontes SVG editáveis. Mesma base verde clara `#95B773`, sem
  contorno, sombra de quintal, ruído ou variação de luminosidade entre tiles.
- Variantes 0–5 com grupos pequenos de folhas assimétricas; 6–7 quase lisas.
  Um hash de coordenadas distribui as oito sem a antiga periodicidade diagonal.
- Cada losango tem 1.024 pixels opacos, calculados pelo centro do pixel; não há
  alpha parcial na aresta. As áreas transparentes externas conservam o RGB da
  base para evitar franjas escuras na filtragem.
- No Godot o chão usa o losango geométrico exato, UVs de 64×32 e um material
  compartilhado que mantém o interior opaco no zoom fracionário de 1,4. Isso
  impede que a máscara raster crie pontos nas juntas durante a ampliação. Não
  existe um plano colorido por baixo dos tiles internos para ocultar frestas.
- Sete decalques 64×48: três capins, duas terras e dois trevos/flor miúda. Pivô
  `[32,32]`, sprites sem corpo físico, área de colisão ou mudanças na navegação.
  Distribuídos nas células da transição para quintais, excluindo as ocupadas por
  construções. Os sete tipos estão descritos em ambos os `kit.json`.
- `_yard_shade()` foi preservado. A sombra é interpolada no jogo, separada das
  texturas. Os novos PNGs não contêm a sombra do quintal.
- `build_art.py` chama a nova família para que regenerar o kit não restaure os
  quatro tiles antigos com tufos em `^`.

## Evidências

- `before/`: capturas da revisão original, antes de editar a grama.
- `after/`: Parque dos Ventos e Praça da Chegada em **1280×720**, renderizados no
  Godot 4.7.2 oficial com OpenGL Compatibility. Inspeção visual feita nas duas
  capturas e nas pranchas de tiles/decalques.
- `grama-8x8.png`: campo de 64 tiles sem fundo, ampliado em
  `grama-8x8-ampliada.png`.
- `after/grama-8x8-godot-1280x720.png`: o mesmo contrato exercitado no renderer,
  com zoom 1,4, fundo preto e sem underlay. **126.024 pixels internos examinados;
  zero frestas pretas**.
- `validacao.json`: dimensões, alpha, espelhamento fonte/runtime e **256 pares
  de adjacência aprovados**. Duas variantes quase lisas e sete decalques.
- `geometry.log`: suite existente de overworld, **34.410 verificações, zero
  falhas**, incluindo navegação, rampas, eventos e acompanhamento do parceiro.
- Os caminhos e colisões permanecem os do mapa original; nenhum JSON de mapa
  foi editado. Capturas não constituem integração da revisão na campanha.

## Reprodução

```powershell
python tools/overworld/build_morro_grass.py
godot --path godot --rendering-driver opengl3 --script res://tools/morro_grass_review.gd
python tools/overworld/build_morro_grass.py
godot --headless --path godot --script res://tests/overworld_checks.gd
```

O segundo comando precisa de renderização gráfica. O terceiro incorpora a
verificação da captura nativa em `validacao.json`.

## Proveniência

Chão: geometria e ilustração vetorial próprias em
`tools/overworld/build_morro_grass.py`, com rasterização determinística Pillow.
Decalques: sete gerações independentes com a ferramenta `imagegen`; originais
preservados em `art/overworld/kits/morro/fontes/grama-morro/`. Não foi usado stock
externo. Recorte por alpha, limpeza de halos, escala proporcional e posicionamento
do pivô foram normalizados por script; nenhum elemento de cenário foi colado no
chão. O kit mantém o estado `pending_owner_review` para a aprovação visual final.

Limites: esta revisão resolve a família da grama. Portões, muros e proporções das
casas são arte preexistente e ainda podem receber uma revisão própria.
