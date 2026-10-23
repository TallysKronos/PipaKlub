# Vila — fachadas e interiores na grade

Substitui as fachadas com câmera incompatível da família `village-isometric-v1` e os interiores antigos do professor/loja. Estado: integrado localmente, em revisão visual pelo usuário.

## Origem artística

As três pranchas em `sources/` foram produzidas com a ferramenta integrada **image_gen**. `prompts.json` registra os prompts completos: materiais, elevações planas das fachadas e painéis de móveis. As imagens são superfícies ortográficas, sem isometria própria. Madeira, reboco, telhas, portas arqueadas, plantas e detalhes de pipas preservam a paleta creme/teal/terracota do bairro.

## Construção e limites

`scripts/build-village-grid-art.mjs` aplica cada pintura plana à face correspondente de uma geometria 64×32×32 e exporta PNGs nativos com alpha. Cada face usa uma transformação afim única; a topologia, os vértices e os apoios são definidos antes da pintura. Isso é mapeamento de uma superfície plana, não registro da silhueta de um móvel ilustrado por colunas. Não se deformam cabeças, almofadas, degraus ou móveis completos para passar na auditoria.

Os SVGs são fontes técnicas com as pinturas incorporadas, e não guias vetoriais usadas como acabamento final. `geometry.json` registra os vértices. As bases das fachadas são medidas em ±0,5 e o pivô de runtime é o centro da porta. A âncora do volume no Iso Studio continua no canto frontal da pegada. A rua usa os PNGs em largura nativa, com a escala global da câmera aplicada à cena inteira.

Os telhados agora são de quatro águas: duas superfícies trapezoidais e duas triangulares, todas revestidas com a pintura de telhas. A antiga empena lateral de reboco foi removida. Recortes de face limitam a textura ao plano real; cumeeira, espigões e beirais acompanham os vértices da cobertura.

23 PNGs em `assets/world/village-grid-v2/`: três fachadas, duas cascas de ambiente e dezoito peças. O runtime substitui as três chaves antigas de fachada e acrescenta vinte imagens, totalizando 59 entradas na família de vila. Os atlas originais não são servidos ao jogo.

## Iso Studio e reprodução

- `fachadas.isostudio.json`: três fachadas, seus volumes e pegadas.
- `professor-home.isostudio.json`: biblioteca do professor, nove peças e casca.
- `kite-shop.isostudio.json`: loja, nove peças e casca.
- `conferencia.json`: cenas, conferência raster e hashes SHA-256 dos PNGs auditados. Há avisos de preenchimento em peças abertas/planas; aprovação geométrica não substitui aprovação artística.

Reproduzir: `node scripts/build-village-grid-art.mjs`, `node build.mjs`, `node build-pages.mjs`. Sharp pode vir da instalação local ou do runtime do ambiente. Plantas e ações derivam de `src/service-interiors.js`; `src/service-isometric.js` usa a mesma projeção e ordem por pegadas do quarto/sala.

Verificação no jogo e limites de entrega: `documentation/vila-grade-v2.md`.
