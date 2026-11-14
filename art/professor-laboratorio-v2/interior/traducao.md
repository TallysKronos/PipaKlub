# Etapa 0 · Interior público do laboratório

Fonte da verdade: ../referencias/concept-interior.png, concept-designer.png e
concept-detalhe-maleta.png. O interior corresponde ao edifício da fachada.

## Peça central, primeiro elemento do blockout

I1 será o primeiro volume a montar na etapa 1. Um losango gigante, suspenso
em suporte de arcos, fica sobre a bancada de pesquisa, diante da janela alta
e sob o pé-direito duplo. Ele ocupa aproximadamente 3 células de largura no
plano de intenção. O conjunto bancada/aparelho fica dentro de uma área de
8 × 4 células, com circulação ao redor. A altura do losango proposto é de
96 px e a do conjunto é de aproximadamente 160 px a partir do piso.
A silhueta é traçada sobre o concept antes de qualquer acabamento.

## Elementos obrigatórios

| ID | Tradução a conferir no corte isométrico |
| --- | --- |
| I1 | Aparelho de losango gigante no suporte de arcos, sobre bancada central; maior equipamento da sala. |
| I2 | Centro com pé-direito duplo e janela alta da torre. O losango permanece enquadrado dentro desse vão. |
| I3 | Recepção à esquerda com balcão creme/laranja, monitor, carrinho de caixas e planta. |
| I4 | Estante de livros e quadro de losango na parede esquerda. |
| I5 | Bancada central de pesquisa com monitores e banqueta; o acesso frontal do jogador fica livre. |
| I6 | Estoque à direita, estante com caixas amarelas, azuis e laranja. |
| I7 | Sala dos fundos com porta e maletas amarelas visíveis. Trata-se do estoque público mostrado no concept. |
| I8 | Mesa de primeiro plano, maleta laranja aberta e sensor em losango conectado por cabo. |
| I9 | Porta frontal de vidro, ombreiras laranja e capacho, com aproximação livre. |
| I10 | Corte das paredes frontais, seções das duas coberturas curvas e altura central claramente visíveis. |

Os dez elementos estão identificados na referência. O checklist da etapa 2
terá a presença de cada um conferida contra o quadro-chave.

## Planta de intenção por zonas

Coordenadas locais de intenção u=0..18, v=0..10. Fundo em v=0, frente em
v=10. A câmera vê os lados +u e +v. O desenho abaixo é uma planta por zonas,
não um blockout e não representa volumes aprovados.

```text
FUNDO v=0
+------------------+--------------------------+---------------------+
| livros / quadro  | torre / janela alta     | estoque / maletas   |
| I4               | I2                      | I6 / sala pública I7|
+------------------+--------------------------+---------------------+
| recepção I3      |     LOSANGO I1          | acesso ao estoque   |
| monitor/planta   | bancada I5 / monitores  |                     |
| carrinho         | banqueta / circulação   |                     |
+------------------+--------------------------+---------------------+
| chegada livre    | porta de vidro I9       | mesa / maleta I8    |
|                  | capacho / acesso frontal| sensor conectado    |
+------------------+--------------------------+---------------------+
FRENTE v=10 · paredes cortadas, telhados visíveis em corte I10
```

Recepção aproximada u=0..5; pesquisa u=5..13; estoque u=13..18.
Faixa frontal v=7..10 para a chegada e a mesa de equipamento à direita.
Rota proposta: porta → área central livre → Assis/bancada, com ramais
para recepção e estoque. Reservar 2 células livres nos trajetos principais.
A posição final dos objetos será definida após o lote ampliado e o blockout.
O laboratório secreto e qualquer pista sobre a origem do Tyler estão
excluídos da composição, da planta e dos objetos desta entrega.

## Simplificações permitidas

Somente a quantidade de caixilhos e a vegetação miúda seguem as permissões
do brief. Livros, caixas, carrinho, banqueta e sensor conservam sua função e
localização por zona. A maleta usa o próprio recorte como imagem de entrada
na etapa 2. Portas de estoque e entrada devem ter funções visuais distintas.

## Paleta

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

## Dimensão e compatibilidade

Proposta de interior: 18 × 10 células do mapa, coerente com o corpo da
fachada. A sala atual usa 14 × 11 células lógicas de 96 unidades. Seu
renderer divide as coordenadas por 3 e por 6, produzindo células de cerca
de 31,5 × 15,75 px após a câmera. Essa régua interna antiga não equivale às
células 64 × 32 do overworld.

A tradução deverá usar uma única régua com Kael 70 px e projeção 64 × 32.
O integrador precisa transformar entrada, gatilhos, colisões, pontos de
encenação e retorno de saves juntos ao atualizar a sala. A proposta não
altera esses arquivos nesta etapa. O mapa público permanece em professor-home.

## Portão

Aguardando a reserva de 24 × 16 células da fachada e a definição da área
18 × 10 do interior. Não produzir a peça central nem o blockout antes de
confirmar o espaço. Após a atualização, começar por I1/I2, montar a planta
por zonas, acrescentar as demais peças e capturar a silhueta com o Kael.
