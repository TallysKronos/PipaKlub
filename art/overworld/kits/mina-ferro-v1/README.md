# Kit mina de ferro v1

Seis novos sprites estáticos gerados com image_gen.imagegen em 31/10/2026: carrinho cheio, carrinho vazio, veio de hematita, guincho, ferramentas e estoque. Prompts exatos em prompts.json, fontes originais em fontes/. O carrinho cheio foi a referência de contorno, perspectiva e paleta para os outros cinco. Nenhum bitmap foi editado; alfa preservado. Manifesto de consumo: godot/assets/overworld/kits/mina-ferro-v1/kit.json.

Direção: isométrico 2:1, desenho 2D mangá/cartoon, contorno azul-escuro, sombras em planos, ferro cinza e ferrugem ocre, hematita vermelho-terra, madeira quente. A origem são imagens originais geradas; Dofus/Wakfu serviu como referência de linguagem gráfica. Aprovação visual do dono pendente.

Todos os PNGs são 1536×1024 e possuem alfa zero, conforme amostragem de dois pixels em alpha-qa.json. Há halos semitransparentes nas fontes: o shader de runtime existente industrial_cutout os descarta abaixo de .88. Não se declara que as fontes estejam livres desses halos. Âncoras e escalas foram conferidas no jogo; os carrinhos têm espelhamento horizontal para acompanhar o eixo dos ramais. Sombras de contato são desenhadas no chão medido, não fazem parte do PNG.

Reuso da gruta seca cavernas-v3: três superfícies e seis formações. Mantidos os arquivos e a autoria/licença existentes, sem atribuição nova. As cenas PackedScene originais preservam pivôs, sombras e contornos. Trilhos, curvas, dormentes, junções, portais, escoras, lanternas e luz no piso são módulos gráficos nativos, medidos na mesma grade do mapa. Colisão dos apoios vem dos objetos Tiled; a imagem do pórtico não cria um retângulo bloqueando o vão.

Uso: estático, cenário de exploração. Não há animação de mineração, carrinho dirigível, trem, inventário novo nem concessão de ferro à conta.
