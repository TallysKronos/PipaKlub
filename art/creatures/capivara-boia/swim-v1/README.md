# Capivara D · nado V1

Spritesheet 2×2, quatro frames 768×512, PNG RGBA 1536×1024 em `godot/assets/campaign/marisol-row-v1/capivara-d-swim.png`. Gerado com image_gen a partir de `model-d-v1/prancha-d.png`. Prompt inicial integral em `prompt.txt`.

Segunda passagem com image_gen solicitou remoção de halo/gradiente e alinhamento dos sprites em células. O preview da ferramenta mostra RGB residual em áreas com alpha zero; isso não é fundo pintado no jogo. Verificado com leitura do alpha e captura nativa. Corpo chega a alpha254, vazio a zero; não se fez alteração de pixels por Python.

Loop de quatro poses em 6fps; escala e direção aplicadas pelo consumidor `park_row_view.gd`. Rabiola continua presa à vela e as três peças flutuantes foram preservadas. A balsa, o cabo e as ondas são desenhos procedurais do adaptador. A e B/C/D da exploração original e a prancha D foram preservadas.

Primeira integração, não rig Soulgen. Há pequenas diferenças de desenho entre frames; capturas nativas mostram poses, não comprovam por si só estabilidade de um ciclo longo. Controle físico e exportação Steam não foram verificados.
