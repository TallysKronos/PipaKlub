# Linha & Papel — kit de loja TCG v1

Após a revisão de circulação, a gôndola é usada em uma única posição. As duas mesas foram deslocadas à direita. Artes originais preservadas; veja `documentation/overworld/loja-tcg/corredores.md`.

Seis imagens originais geradas com a ferramenta nativa `image_gen.imagegen`: balcão-vitrine, estante, expositor vertical de pipas, ilha de mostruários, mesa com dois bancos e novo dono chibi. Fontes intactas em `fontes/`, prompts exatos e nomes de origem em `prompts.json`, medições alfa em `qa.json`. O balcão, orientado pelo novo ateliê do professor, foi a referência visual das quatro peças relacionadas. O NPC usa o Assis apenas como guia de linguagem chibi, com identidade, roupa e silhueta próprias.

O usuário escolheu um novo personagem como dono. Lia permanece na frente da loja; o novo personagem não recebeu nome pessoal nem história: aparece como Dono da loja. O sprite tem um frame estático; não é um spritesheet de caminhada. A conversa reutiliza o mesmo desenho com recorte alfa no retrato.

Consumidor: `godot/scripts/campaign/shop_modern.gd`. Manifesto e cópias de runtime em `godot/assets/campaign/loja-tcg-v1/`. Projeção 2:1, escala uniforme, filtro linear, pivô inferior central no retângulo medido. Colisão e profundidade vêm das pegadas do layout, não de todo o PNG. Estante usada em duas posições, mesa em duas posições e gôndola em duas posições, como módulos de mobiliário de uma loja. A gôndola foi encaixada com pegada 3×2, coerente com a orientação efetivamente gerada, sem deformar ou rotacionar o bitmap.

O shader de recorte existente descarta a névoa semitransparente dos originais. Há transparência real, medida por imagem; os arquivos não foram pintados ou retocados para fabricar alfa. Janela, tapetes e casca arquitetônica reutilizam os construtores geométricos dos interiores modernos. `preview.png` é uma captura opaca do Godot para o cartão do save e está classificada separadamente no manifesto.

Artefatos de revisão em `documentation/overworld/loja-tcg/`, com hashes das fontes e das cópias. Aprovação técnica local não substitui a revisão estética do dono. Nenhum produto, logotipo ou carta de outra franquia foi copiado; os motivos de cartas/pacotes são pipas abstratas e os móveis são ambientais.
