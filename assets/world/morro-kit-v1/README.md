# Morro do Sol — kit modular v1 (PIP-40)

26 peças em seis PNGs. Geradas com a ferramenta integrada `image_gen`, usando o Kael chibi como referência de linguagem visual e o Morro anterior como referência de materiais/paleta. Prompts completos e referências em `prompts.json`. Os arquivos originais foram preservados e copiados para esta pasta; não houve remoção de fundo por cor ou redesenho por código.

## Inventário

| Folha | Peças |
| --- | --- |
| architecture-v1.png | fachada amarela, telhado de terracota, fachada salmão, portão |
| vegetation-v1.png | copa, tronco, arbusto, bananeira |
| masonry-v1.png | muro horizontal, muro vertical, canto em L, escada |
| props-v1.png | banco, luminária, caixa-d'água, cerca, vaso, bandeirinhas |
| ground-v1.png | terra, grama, calçada, pedras |
| details-v1.png | porta fechada, porta aberta, poste, fio |

## Uso e escala

`manifest.json` contém os recortes reais `{x,y,w,h}`, regiões de autoria `cell`, âncoras normalizadas e dimensões sugeridas. As folhas NÃO usam uma grade perfeitamente regular: usar os recortes do manifesto, não dividir a imagem pela quantidade de linhas/colunas. Os recortes são usados diretamente em drawImage; os PNGs não foram fisicamente cortados. A máscara de transparência do próprio PNG é preservada.

Escala de referência: Kael com 64 px de altura, grade de autoria 32 px. Porta sugerida: 96 px; poste: 128 px; copa: 160 px. Fachadas e telhado compartilham largura sugerida de 448 px; preservar proporção da arte, sem forçar simultaneamente largura e altura. `recommendedWidth` prevalece sobre a sugestão de altura. São pontos iniciais para a montagem, não colisores automáticos. Os pisos podem começar com módulos visuais de 128 px.

Âncora padrão: centro inferior da silhueta. A copa usa âncora abaixo da imagem (`y=1.08`) para alinhar ao apoio do tronco; ajustar o par na composição respeitando o ponto físico. Copa e telhado entram como partes superiores; tronco e paredes precisam de base sólida e `sort_y` definidos no mapa. Portas não tornam uma fachada atravessável: uma entrada exige zona de interação e transição própria.

Fachadas têm floreiras decorativas integradas. Portas avulsas permitem detalhes de interação; não são recortes exatos das portas pintadas nas fachadas. Alinhamento de porta, colisão e animação de abrir devem ser preparados na montagem. O canto e os muros usam o mesmo material; os segmentos são ilustrados, não um autotile matemático. Usar cantos/endcaps e sobreposição controlada na composição, sem esticar pedras para preencher qualquer comprimento. Fios e bandeirinhas não têm colisão de chão.

## Auditoria

- Cinco folhas de objetos têm alpha real; a folha de pisos é opaca.
- 26 recortes não vazios e dentro das imagens, sem cruzar peças vizinhas.
- Regiões de autoria dos objetos mantêm ao menos quatro pixels de margem transparente ao limiar alpha 16. `audit.json` registra as medidas.
- Inspeção da galeria confirmou silhuetas completas e ausência de fundo quadriculado embutido. O quadriculado da galeria é apenas o fundo de inspeção.
- Pisos revisados em repetição 3 × 3; não há uma linha de enquadramento embutida. A repetição de motivos ainda pode ficar evidente em áreas extensas; alternar decoração e composição. Isto não é garantia de continuidade perfeita por pixel em todas as escalas.
- A escala relativa entre copa/tronco, portas e casas deve ser ajustada no mapa final. Galeria normaliza o tamanho de cada card para inspeção; não representa escala final no mundo.

## Integração

`scripts/art-build.mjs` inclui o manifesto em `courtyard.world.kit` e registra as folhas com URLs versionadas. Os builds copiam os PNGs para servidor/Pages e o servidor usa sua lista explícita de assets. O piloto opcional já usa as peças por meio de `morro-pilot/art.json`; o plano de desenho mantém proporções, profundidade e colisões separadas. Montagem final segue na PIP-42 e NPCs chibi permanecem na PIP-41. Auditoria em `morro-pilot/APPLIED-AUDIT.md`. Sem merge ou deploy automático.
