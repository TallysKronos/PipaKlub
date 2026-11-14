# Etapa 0 · Fachada do laboratório

Fonte da verdade: ../referencias/concept-designer.png e concept-fachada.png.
Os recortes concept-detalhe-telhado.png e concept-detalhe-maleta.png fixam os
equipamentos. As capturas jogo-atual-* servem exclusivamente ao comparativo.

## Elementos obrigatórios

| ID | Tradução a conferir na câmera 2:1 |
| --- | --- |
| F1 | Duas abóbadas independentes, com alturas diferentes e borda verde-água espessa. Mostrar separação dos volumes, não uma cobertura única contínua. |
| F2 | Torre de vidro central mais alta, vertical, com losango visível no vidro. |
| F3 | Pórtico laranja recuado, moldurando portas de vidro de entrada. |
| F4 | Escada larga e rampa lateral ligadas ao mesmo patamar; corrimãos metálicos e balizadores na calçada. |
| F5 | Janelas horizontais nos dois volumes, mostrando caixas e estantes internas. |
| F6 | Painel verde-água no volume direito, próximo da transição para o pórtico. |
| F7 | Pátio cercado à direita, cabine hexagonal envidraçada com mesa e computador, mesa com maleta amarela e cone. A cabine deve conservar volume e espaço de uso. |
| F8 | Arco com haste e anemômetro separados e apoiados no telhado; usar o recorte do instrumento para a construção. |
| F9 | Árvores e canteiros floridos emolduram as laterais e o pátio sem ocultar rampa, porta ou cerca. |

Os nove elementos estão identificados no concept. Sua presença em arte final
só será marcada no checklist da etapa 2.

## Simplificações permitidas

Reduzir quantidade de caixilhos, folhas e objetos pequenos nas janelas.
Preservar massas de vegetação, flores, caixas de cor e instrumentos reconhecíveis.
As curvas dos telhados mantêm seu perfil e desnível, inclusive no pixel art.

## Paleta extraída

| Material | Cor base | Sombra / contorno | Amostra do recorte da fachada |
| --- | --- | --- | --- |
| Reboco creme rosado | #F9E9E5 | #153A54 | (315,270) e (930,292) |
| Painel verde-água | #34B3AA | #0B595F | (662,292) e (300,209) |
| Pórtico laranja | #FD9B28 | #B25613 | (350,250) e (388,327) |
| Telhado cinza azulado | #C2D1E7 | #9CB3B6 | (920,166) e (970,207) |
| Vidro azul | #81B7D4 | #153A54 | (770,310) e (930,292) |
| Piso claro | #F5E2D8 | #2C4457 | (500,464) e (645,468) |

Amostras obtidas diretamente de concept-fachada.png, com origem no canto superior
esquerdo. Metal claro reutiliza o claro do telhado; a seleção final de highlight
vem do recorte do instrumento. Caixas amarelas, azul e laranja e a luz ciano
serão amostradas dos recortes específicos na etapa 2, sem substituir estas bases.

## Régua de escala

Kael tem 70 px visíveis em godot/assets/kael-video/iso-v2/idle.png.
A projeção do mapa é 64 × 32 px por célula, com 64 px por nível vertical.
Logo, o Kael mede 1,094 nível vertical. Isso mede altura, não sua pegada no piso.

Proposta dimensional para validar no blockout, sem transformar o concept em
projeto arquitetônico com medidas reais conhecidas:

| Referência | Medida nativa proposta | Relação com Kael |
| --- | --- | --- |
| Kael | 70 px | 1 |
| Porta de vidro | 96 px de altura livre | 1,37 |
| Espelho da escada | 6 px; quatro espelhos | 0,086 por espelho |
| Patamar da entrada | 24 px acima do passeio | 0,343 |
| Pé-direito dos volumes laterais | 128 px | 1,83 |
| Pé-direito central | 208 px | 2,97 |
| Topo da torre, incluindo base elevada | aproximadamente 256 px | 3,66 |

O número de caixilhos e a espessura do desenho serão adaptados à densidade
nativa. O enquadramento inteiro pode mudar de zoom no jogo, mantendo a relação
entre Kael, porta e edifício. As alturas relativas e as duas abóbadas virão
do traçado sobre as imagens na etapa 1.

## Lote necessário e portão

O runtime atual coloca o laboratório em [2,-5,8,-1.7] no gerador
godot/scripts/overworld/starter_neighborhood.gd. Esse retângulo tem 6 × 3,3
células. A calibração de neighborhood_architecture.gd redistribui o somatório
das duas dimensões usando groundCorners da pintura antiga, resultando em uma
pegada aproximada de 4,35 × 4,95 células. O SVG antigo professorHouse.svg é
referência legada; não é a fonte geométrica do lote renderizado hoje.

Solicitação para o integrador: reservar **24 × 16 células** para o conjunto
público, além da calçada/rua existentes. Esta é uma estimativa técnica para o
blockout e deve ser reservada antes de desenhá-lo.

- Corpo principal e torre: 18 × 10 células.
- Pátio direito: 6 × 8 células, contíguo ao volume direito.
- Faixa frontal de 5 células de profundidade para escada, rampa e chegada.
- Faixa de fundo de 1 célula para fechamento/vegetação.
- Na lateral do pátio, usar o restante da profundidade para canteiros e acesso.

Na câmera 2:1, o envelope de 24 × 16 projeta aproximadamente 1280 × 640 px
de chão, antes da altura da torre. O corpo 18 × 10 projeta 896 × 448 px.
A dimensão por eixos foi estimada pela proporção das portas duplas e das
alas no concept, pela escala do Kael e pelo espaço de aproximação à cabine.
São medidas propostas; não são dimensões fornecidas pelo designer.

O pátio e o acesso não cabem no lote existente com essa régua. Não há
blockout nem alteração do mapa nesta etapa. O integrador deve confirmar
coordenadas do lote ampliado, cota da calçada e orientação da entrada.
A fachada e o interior retomam juntos a etapa 1 depois dessa atualização.

## Próxima etapa

Sobrepor os volumes cinza ao concept, apresentar a projeção na câmera do jogo
e colocar Kael ao lado da porta, da rampa e da cabine. O portão da silhueta
exige aprovação antes de pintar o quadro-chave.
