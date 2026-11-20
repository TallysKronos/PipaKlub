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

## Régua atualizada na etapa 1

Célula 64 × 32 px; projeção 2:1. Kael nativo, referência de 70 px (1,46 desnível de terreno de 48 px). Altura não é pegada no chão.

| Referência | Altura nativa | Relação com Kael |
| --- | --- | --- |
| Kael | 70 px | 1 |
| Porta | 92 px | 1,31 |
| Degrau | 8 px, três espelhos | 0,11 |
| Patamar | 24 px sobre passeio | 0,34 |
| Volumes laterais até cobertura | aproximadamente 133 px | 1,90 |
| Pé-direito central | aproximadamente 200 px | 2,86 |
| Torre incluindo patamar | 224 px | 3,20 |

As amostras de cor acima identificam materiais do concept. A pintura será remapeada para a paleta dos personagens e sua extensão de cenário conforme o guia. Na etapa 1, somente cinzas, com Kael original como régua.
## Lote aprovado

A estimativa inicial de 24 × 16 células foi substituída pela reserva do integrador em `../lote/LOTE.md`: **13,5 × 9 células**, u 0,5..14, v −10..−1, terreno +48 px. Entrada no alinhamento **(7,25; −1)**; Sr. Assis em **(6,8; −0,65)**. Vizinho a partir de u=15.

Coordenadas do modelo: x=u−0,5, d=−1−v. O render usa altura relativa ao passeio; a integração deve somar 48 px.

| Volume | x local | d local |
| --- | --- | --- |
| Faixa livre junto à calçada | 0..13,5 | 0..1 |
| Ala esquerda | 0,55..5,35 | 3..8,3 |
| Torre | 5,15..7,55 | 3,8..6,9 |
| Ala direita | 7,2..12,95 | 4,25..8,4 |
| Escada e rampa | 3,85..8,05 | 1,05..3 |
| Pátio e cabine | 8,8..13,2 | 1,05..4,1 |

O lote projeta 720 × 360 px de chão. Alturas nativas fixadas pela régua acima; não se aplica redução global para encaixar o prédio. A distribuição e as proporções estão submetidas ao portão de silhueta.

## Portão

Etapa 1: `blockout.png` e `blockout-sobre-concept.png`. Aguardando aprovação junto ao interior, antes de pintura. A sobreposição identifica os volumes na câmera original do concept; a maquete apresenta a tradução para a câmera 2:1. Detalhes de acabamento serão conferidos no checklist da etapa 2.