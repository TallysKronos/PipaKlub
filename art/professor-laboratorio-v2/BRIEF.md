# Laboratório do Sr. Assis · v2 (fachada e interior)

14/11/2026. Refazer seguindo `documentation/art/PIPELINE-CONCEPT-PARA-JOGO.md`, etapa por etapa,
parando nos portões de aprovação.
O desenho segue `documentation/art/GUIA-DE-ESTILO-CENARIO.md`: o concept dá o conteúdo; pixel,
paleta, contorno e sombra vêm dos personagens.

## Referências (nesta pasta)

- `referencias/concept-designer.png`: o concept do designer, fonte da verdade.
- `referencias/concept-fachada.png`, `concept-interior.png`, `concept-detalhe-telhado.png`,
  `concept-detalhe-maleta.png`: recortes do concept.
- `referencias/jogo-atual-fachada.png` e `jogo-atual-interior.png`: a versão atual, que **não**
  segue o concept (para o comparativo).

## Fachada · elementos obrigatórios

| Nº | Elemento |
| --- | --- |
| F1 | Dois volumes com **telhado curvo** (abóbada), em alturas diferentes, com a borda verde-água grossa |
| F2 | **Torre de vidro central**, mais alta que os dois telhados, com o losango no vidro |
| F3 | **Pórtico de entrada laranja**, recuado, com portas de vidro |
| F4 | **Escada larga e rampa** com corrimão de metal até a entrada; frades (balizadores) na calçada |
| F5 | Faixas de janela horizontais nos dois volumes, com o interior aparecendo (estantes, caixas) |
| F6 | Painel verde-água no volume da direita |
| F7 | **Pátio cercado** (alambrado) à direita, com a **cabine de vidro hexagonal** (mesa e computador dentro), a mesa com a maleta amarela e o cone |
| F8 | **Instrumentos no telhado**: o arco com haste (detalhe do telhado) e o anemômetro |
| F9 | Canteiros com flores e árvores emoldurando o prédio |

Pode simplificar: a quantidade de caixilhos das janelas, as plantas dentro das janelas, as folhas
das árvores.

Paleta: reboco creme, verde-água (bordas e painéis), laranja (pórtico), cinza-azulado (telhados),
vidro azul-claro, metal claro.

## Interior · elementos obrigatórios

| Nº | Elemento |
| --- | --- |
| I1 | **Peça central:** o aparelho de losango gigante num suporte de arcos, sobre a bancada central, **sob o pé-direito duplo da torre de vidro** |
| I2 | Pé-direito duplo no centro, com a janela alta da torre |
| I3 | **Recepção** à esquerda: balcão creme e laranja, monitor, carrinho com caixas, planta |
| I4 | Estante de livros e quadro com o losango na parede esquerda |
| I5 | **Bancada de pesquisa** central com monitores e banqueta |
| I6 | **Estoque** à direita: estante com caixas coloridas (amarelo, azul, laranja) |
| I7 | **Sala dos fundos** com porta e maletas amarelas |
| I8 | **Mesa da maleta** em primeiro plano, com a maleta de equipamento laranja e o sensor de losango (detalhe da maleta) |
| I9 | Porta de entrada de vidro na frente, com o capacho |
| I10 | Corte de câmera como no concept: paredes da frente cortadas, telhados curvos visíveis no corte |

## Lote e escala

Hoje o laboratório ocupa um lote pequeno na Vila do Primeiro Vento
(`art/village-grid-v2/professorHouse.svg`, mapa `quintal`). O concept pede mais área: a fachada
com escada e rampa mais o pátio cercado da direita. Na etapa 0, diga quantas células o prédio
precisa; o Claude aumenta o lote no mapa antes do blockout. O interior (cena `professor-home`) pode
crescer na mesma proporção.

## Entregas

Em `art/professor-laboratorio-v2/`, separado em `fachada/` e `interior/`, as entregas de cada etapa
do pipeline (traducao.md, blockout, quadro-chave, comparativo, checklist, kit). Pare depois do
blockout e depois do quadro-chave para aprovação.
