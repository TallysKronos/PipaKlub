# Veredas — conceito de vale v3

Conceito gerado e aprovado como referência de composição em 29/10/2026. O usuário esclareceu que a imagem não deve ser usada como fundo jogável: reconstruir com terreno, relevo e objetos separados, no modelo da cidade e com a arte 2D mangá. Implementação atual: `veredas_modular_landscape.gd`; evidências em `documentation/overworld/veredas-modular-v5/`.

Fonte: image_gen.imagegen, geração baseada nas capturas aprovadas de planície e caverna. Original preservado no diretório generated_images do Codex. Imagem: veredas-vale-conceito-v3.png, 1536×1024, fundo opaco.

Direção solicitada: uma paisagem isométrica coesa no traço ilustrado 2D mangá, com massas de cor legíveis, caminhos de terra largos e bordas naturais; entrada inferior esquerda, rio rebaixado com duas pontes formando um circuito, mirante lateral com escada, pátio elevado dos canos à direita e áreas de descanso visual. Árvores em grupos, troncos apoiados, terreno preenchendo os espaços internos e preto azulado somente fora da silhueta. Sem HUD, personagens, textos, grade ou mapa composto de plataformas suspensas.

Referências de traço fornecidas ao gerador:
- documentation/overworld/planicie-v1/planicie-1280x720.png
- documentation/overworld/cavernas-v3/nativo/gruta-inundada-1280x720.png

A imagem define uma proposta de composição, não garante passagem, colisão, escala ou perspectiva perfeita de todos os elementos. A reconstrução exige medir planta e cotas, conferir as duas cabeceiras de cada ponte e as bocas da rampa/escada antes do revestimento. Não copiar distorções locais da pintura para a geometria.

A tentativa de vale em park_landscape.gd permanece um protótipo visual rejeitado. A correção independente da câmera em park_view.gd foi reproduzida e validada nos cinco baús; as evidências estão em documentation/overworld/veredas-valley-v3/. Preservar essa correção ao reconstruir a paisagem.
