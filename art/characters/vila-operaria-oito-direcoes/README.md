# Vila Operária · repouso em oito direções

Bruno Solda, Odrik, Rivka, Teyra e Vasken têm uma folha PNG transparente de 256 × 128 cada. São quatro colunas por duas linhas, com células de 64 × 64. A primeira linha é S, SO, O, NO. A segunda é N, NE, L, SE. O ponto de apoio é (32, 64) em todas as células.

As sete vistas adicionais foram produzidas com ImageGen e recortadas a partir das fontes arquivadas em `fontes/`. A vista sudeste é uma cópia exata da pose em uso no jogo. A verificação confirmou os 40 quadros com transparência binária e o último pixel visível na linha 63. A altura permanece igual entre as oito vistas de cada personagem.

As folhas contêm poses de repouso. As cópias de runtime ficam em `godot/assets/npc-ds/vila-operaria-v1/direcoes/`. A pose inicial é sudeste. Ao interagir, o renderizador escolhe a célula pela posição projetada do Kael.
