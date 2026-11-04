# Ateliê do Sr. Assis — kit moderno v1

Cinco peças novas produzidas com a ferramenta nativa `image_gen.imagegen`: biblioteca, terminal de estudo, bancada de montagem, mesa do professor e arquivo modular. Os PNGs originais permanecem intactos em `fontes/`; os prompts exatos e nomes de origem estão em `prompts.json`. A bancada foi o alvo visual da família, combinando as proporções do mobiliário anterior com a marcenaria moderna da casa do Kael. As outras quatro peças usam essa bancada como referência de estilo. Não foi usada arte externa baixada.

Estilo: 2D mangá/cartoon com contorno azul-marinho, branco, azul, madeira clara, prata e pequenos acentos ciano. Biblioteca de papel e ferramentas de pipas preservam a identidade do Assis. As peças não contêm revelações sobre a história.

Consumidor: `godot/scripts/campaign/professor_modern.gd`. Kit: `godot/assets/campaign/professor-moderno-v1/kit.json`. Uma imagem/um frame por peça, recorte alfa apenas no runtime, escala uniforme e filtro linear. Pivô inferior central no retângulo canônico; ordenação e colisão pelas pegadas existentes. Janela, painel de desenhos, tapetes e casca arquitetônica são geometria nativa. A janela não reaproveita as antigas venezianas de madeira.

`qa.json` registra dimensões reais, transparência e limites das regiões sólidas. O shader de recorte existente descarta a névoa semitransparente produzida ao redor de algumas imagens; nenhum fundo opaco é desenhado no jogo. O alfa dos originais não foi editado. A prova visual nativa e os hashes das cópias ficam em `documentation/overworld/professor-moderno/`.

`preview.png` no kit é uma captura opaca do ateliê no Godot para o cartão de save, não uma peça transparente. Sua classificação está separada no manifesto. O preset de exportação inclui os PNGs e JSON lidos diretamente; executável exportado não foi testado.

Aprovação técnica local e aprovação estética do dono são distintas: as peças finais aguardam a revisão visual do dono. Sem push/deploy automático.
