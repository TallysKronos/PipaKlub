# Soulmonsters — arquitetura moderna v1

Biblioteca de **24 construções originais geradas**, em quatro famílias de seis. Estado: preparada como biblioteca local, com revisão artística do proprietário pendente. Não há substituição automática de construções da campanha.

## Direção e conteúdo

Arquitetura contemporânea brasileira, contorno azul-escuro, massas creme/coral/ocre/verde e vidro azul, luz superior esquerda e sombras simples. Os usos são do universo Soulmonsters: pipas, linhas, papel vivo, restauração e pesquisa. Os símbolos são propostas visuais, não marcas canônicas novas. As placas não contêm nomes rasterizados.

| Arquivo em pecas/ | Uso | Pegada proposta | Pavimentos pretendidos | Porta |
|---|---|---|---|---|
| `casa-jardim` | Casa térrea com jardim | 4×4 | 1 | v+ |
| `sobrado-varanda` | Sobrado com varanda | 4×4 | 2 | u+ |
| `casa-geminada` | Casa geminada urbana | 4×4 | 2 | v+ |
| `casa-atelie` | Casa com ateliê de pipas | 4×4 | 2 | u+ |
| `casa-ecologica` | Casa ecológica | 4×4 | 1 | v+ |
| `residencia-terraco` | Residência com terraço | 4×4 | 2 | u+ |
| `loja-pipas` | Loja de pipas e linhas | 5×5 | 1 | v+ |
| `oficina-reparos` | Oficina de reparos | 5×5 | 1 | u+ |
| `cafe-do-vento` | Café do Vento | 5×5 | 2 | v+ |
| `papelaria` | Papelaria de bairro | 5×5 | 1 | u+ |
| `clinica-elos` | Clínica de vínculos | 5×5 | 2 | v+ |
| `clube-pipeiros` | Clube dos pipeiros | 5×5 | 2 | u+ |
| `coworking` | Coworking de inventores | 5×5 | 3 | v+ |
| `torre-elos` | Torre empresarial dos elos | 6×6 | 6 | u+ |
| `centro-logistico` | Centro de logística | 6×6 | 2 | v+ |
| `estacao-meteorologica` | Instituto do vento | 5×5 | 4 | u+ |
| `editora-cartografica` | Editora e cartografia | 5×5 | 3 | v+ |
| `sede-cooperativa` | Sede da cooperativa | 6×6 | 4 | u+ |
| `laboratorio-elos` | Laboratório de vínculos | 6×6 | 2 | v+ |
| `laboratorio-campo` | Estação de pesquisa de campo | 5×5 | 1 | u+ |
| `laboratorio-papel` | Laboratório de papel vivo | 6×6 | 3 | v+ |
| `laboratorio-aerodinamica` | Laboratório de aerodinâmica | 6×6 | 3 | u+ |
| `observatorio-almatico` | Observatório almático | 6×6 | 2 | v+ |
| `centro-restauracao` | Centro de restauração | 6×6 | 2 | u+ |

Porta `v+`: face esquerda visível. Porta `u+`: face direita visível. A quantidade de pavimentos é o briefing de produção e não gera interiores.

## Arquivos

- `pecas/`: 24 PNGs RGBA individuais, com recorte e escala uniforme.
- `fontes/geradas/`: 24 fontes de alta resolução, preservadas.
- `fontes/geometria/`: guias vetoriais e PNG, com projeção 2:1 e escala de andar/porta.
- `fontes/geracao.json`: ferramenta, prompts completos, referências e caminhos originais.
- `kit.json`: dimensões reais, raster, pegada proposta, pivô frontal, face da porta e fonte de cada peça.
- `urbano.isostudio.json`: projeto com as 24 imagens incorporadas, pronto para abrir no Iso Studio.
- Runtime preparado em `godot/assets/overworld/kits/urbano/` e 24 cenas em `godot/scenes/overworld/pieces/urbano/`.
- Catálogo, quatro pranchas de escala com Kael e oito páginas nativas em `documentation/overworld/arquitetura-moderna-v1/`.

## Preparação e conferência

Geração por `image_gen.imagegen`, uma chamada por construção. A casa-jardim foi escolhida como referência de família; os demais desenhos receberam também sua guia geométrica e a esquina de estilo do Morro.

Normalização determinística: corte de alpha, remoção de halo translúcido abaixo de 160/255, escala uniforme pela largura da pegada (64×32 por célula), padding e apoio no canto frontal. Não houve deformação independente nos eixos nem pintura procedural substituindo as fontes.

O catálogo reduz cada imagem para comparação visual; as pranchas ESCALA mantêm um pixel por pixel e Kael com 84 px. A guia pede porta de 96 px, mas o desenho gerado varia; o manifesto registra as dimensões reais e não certifica uma medida de porta exata.

Foram inspecionados o catálogo de 24, as pranchas e a montagem nativa de oito páginas 1280×720 no Godot 4.7.2. Importação e execução gráfica sem erros. Isso verifica apresentação isolada, transparência, silhueta e ausência de cortes nos enquadramentos revisados; não prova encaixe em qualquer lote ou oclusão ao caminhar. Pegadas são retangulares e propostas para composição: jardins, letreiros e brises ainda exigem revisão no mapa escolhido.

Não foram executadas suítes de testes. Não há interiores, eventos de entrada, NPCs, novas funções de serviço, alterações de save, push ou publicação associados às imagens.

## Reproduzir

`python tools/overworld/build_urban_guides.py` gera apenas guias.
`python tools/overworld/build_urban_library.py` prepara a biblioteca a partir das fontes existentes.
`node --input-type=module -e "import {buildPieceScenes} from './tools/import-overworld.mjs';buildPieceScenes();"` atualiza as cenas.
Após importar os assets: `godot --path godot --script res://tools/urban_library_capture.gd` produz as páginas nativas sem campanha.

Os guias e as pinturas ficam em arquivos separados. Uma regeneração precisa de revisão visual; não é autorização para sobrescrever uma imagem aprovada.
