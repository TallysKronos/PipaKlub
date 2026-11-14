# Etapa 0 · Interior público do laboratório

Fonte da verdade: ../referencias/concept-interior.png, concept-designer.png e
concept-detalhe-maleta.png. O interior corresponde ao edifício da fachada.

## Peça central, primeiro elemento do blockout

I1 foi montado primeiro: losango de 86 px em suporte de arcos, sobre bancada de 42 px. O aparelho alcança aproximadamente 151 px a partir do piso, sob o pé-direito central de 200 px. A bancada mede cerca de 4,23 × 1,16 células.

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

## Planta por zonas · etapa 1

Envelope interno de apresentação: **12,4 × 5,3 células**, na régua nativa do Kael. x cresce à direita, d para o fundo. Corte das paredes dianteiras com as duas abóbadas preservadas. Geometria para aprovação antes de pintura e colisões.

```text
FUNDO d=5,3
+----------------+-----------------------+----------------------+
| I4 livros      | I2 torre / janela alta| I6 caixas / estoque |
| quadro-losango |                       | I7 porta / maletas  |
+----------------+-----------------------+----------------------+
| I3 recepção    |       I1 LOSANGO      | acesso ao estoque   |
| monitor/planta | I5 bancada / monitores|                     |
| carrinho       | banqueta              |                     |
+----------------+-----------------------+----------------------+
| Kael / chegada | I9 vidro / capacho    | I8 maleta e sensor  |
+----------------+-----------------------+----------------------+
FRENTE d=0 · I10 paredes cortadas / abóbadas em corte
```

Recepção x≈0,7..3,5; pesquisa x≈4,1..8,4; estoque x≈8,5..12,4. Bancada principal d≈2,9..4,1; mesa de equipamento d≈1..2. Rota de intenção: entrada → frente da bancada → recepção/estoque, contornando os móveis. A faixa central diante da bancada tem aproximadamente 1,3 célula de profundidade; validação dimensional no portão com Kael visível.

A sala dos fundos é apenas o estoque público do concept. Nenhum espaço adicional de revelação narrativa é representado.

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
## Compatibilidade e portão

Mesma régua nativa da fachada. O gerador mapeia as coordenadas de construção da planta para o envelope de 12,4 × 5,3, mantendo as alturas de equipamentos e portas. Sala de produção `professor-home`, gatilhos, colisões e saves pertencem à etapa de integração.

Etapa 1: `blockout.png` e `blockout-sobre-concept.png`. Aguardando aprovação da planta, peça central e corte junto à fachada. Ver `../ETAPA-1.md`.