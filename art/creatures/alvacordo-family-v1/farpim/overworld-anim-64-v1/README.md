# Farpim — overworld 64 v1

Pixel art nativa desenhada no Aseprite a partir de concept-v1/concept.png. Modo headless. Nenhuma redução automática do conceito.

Canvas fixo 64×64, RGBA transparente, amostragem nearest-neighbor. Centro virtual (32,62), mesma escala por pixel da família; não ampliar o bebê para preencher o canvas. Cabeça e orelhas ocupam 27px (28px incluindo o nó vermelho), cerca de 28px de largura. Sem pernas: Farpim é uma cabeça-pipa bebê, flutuando. A ponta normalmente está em y49, 13px acima da linha virtual do chão y62. O fio e a única bandeirola chegam abaixo da cabeça. Na derrota a cabeça desce 10px, ficando perto do chão. A vista usa o focinho deslocado para a esquerda e o olho distante menor; a direita é espelho exato.

Dois fontes editáveis: farpim-overworld-64.aseprite (esquerda, sprite #3 na sessão) e farpim-overworld-right-64.aseprite (direita). Layers head e tail, 32 frames por direção. Atlases farpim-left-atlas.png/.json e farpim-right-atlas.png/.json: 32 células de 64×64, sem trim. JSON preserva tempos e tags. Os PNGs farpim-left/right.png são previews 4×; não são os frames nativos.

| Ação | Frames Aseprite | Duração | Uso |
|---|---:|---:|---|
| idle-left/right | 1–8 | 1200ms | Loop de flutuação 1px e piscada |
| walk-left/right | 9–16 | 800ms | Loop de deslocamento flutuante; não há passada de pernas |
| victory-left/right | 17–24 | 1080ms | Subida feliz de 5px, boca aberta, volta à pose |
| defeat-left/right | 25–32 | 1380ms | Descida de 10px, olhos fechados; tocar uma vez e segurar último frame |

Idle e walk são loops. Victory e defeat devem tocar uma vez no jogo; GIFs de prévia podem repetir. Os quatro GIFs *-left-4x.gif têm 8frames em 256×256. Filmstrips *-left/right-filmstrip.png têm 8 células ampliadas 4×.

Preservado: cabeça-pipa canina, carvão e branco quente, teal nas orelhas, raio branco, olhos âmbar, orelha dobrada, fio vermelho e uma bandeirola. Simplificações deliberadas: sem linhas internas de estrutura da pipa, focinho reduzido a nariz e boca em poucos pixels, bandeirola pequena e sem trama de papel.

Paleta de 12 slots compatível com a família; 8 cores usadas no bebê. Aseprite palette analyze: clean, sem cores fora da paleta. A ferramenta validate não está exposta nesta sessão. Verificação alternativa: PNG/JSON com 32frames, alpha binário, 32frames direita iguais ao espelho exato da esquerda, quatro GIFs com 8frames e tamanho256×256, inspeção visual dos filmstrips. Revisão independente solicitada ao coordenador antes da entrega final.

Revisão independente: alvacordo_pixel_critic, 8/10, sem achados bloqueadores. Nenhum pixel alterado depois da crítica.
