# Palafitas · sprites isométricos v2

O elenco usa novas poses de repouso em três quartos, com câmera elevada e volumes simplificados para a escala do overworld. A geração tomou as cinco identidades de `../palafitas-overworld-v1/preview-grupo.png` e a câmera e linguagem de pixels da vista frontal de `../kael/overworld-diagonal-v1/preview-cinza-5x.png`.

A fonte e o prompt da ImageGen estão nesta pasta. A normalização usou recortes separados, transparência binária, uma paleta compartilhada e a última linha da célula como base de apoio. A prévia amplia os pixels em 4× sobre fundos claro e escuro e inclui Kael à direita.

| Personagem | Célula | Altura visível |
| --- | --- | --- |
| Caio Garça | 64 × 64 | 56 px |
| Kessai | 64 × 64 | 53 px |
| Oruvo | 64 × 64 | 49 px |
| Seyran | 64 × 64 | 56 px |
| Veldren | 64 × 64 | 54 px |

O Godot carrega os cinco PNGs de `godot/assets/npc-ds/palafitas-iso-v2/`. As poses correspondem às aparições estáticas dos duelos e à participação do Caio na reunião dos campeões. Caminhada e vistas adicionais ficam fora deste lote.
