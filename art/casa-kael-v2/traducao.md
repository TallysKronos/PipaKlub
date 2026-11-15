# Casa do Kael v2 — ficha de tradução

Etapas 0 e 1, 15/11/2026. Fonte visual aprovada em `concept/prancha.png`. Segue `documentation/art/PIPELINE-CONCEPT-PARA-JOGO.md`. Esta ficha fixa a proposta de escala para aprovação, sem substituir os assets do jogo.

## Elementos obrigatórios

| ID | Fachada |
| --- | --- |
| F1 | Sobrado de corpo marfim com volume superior azul recuado e faixa coral na borda da cobertura. |
| F2 | Coberturas planas escalonadas, platibandas e pequeno núcleo superior de serviço. |
| F3 | Janela horizontal longa no andar superior e esquadrias azul-escuras. |
| F4 | Varanda frontal à direita, guarda-corpo azul perfurado e acesso pelo quarto. |
| F5 | Entrada térrea sombreada por marquise, pilares finos e porta azul. |
| F6 | Janela térrea à direita, iluminação de entrada e vasos. |
| F7 | Jardim com árvores laterais, flores, canteiros e muros baixos marfim. |
| F8 | Portão frontal, caminho de entrada, caixa de correio azul e interfone. |
| F9 | Bicicleta junto ao muro lateral e equipamento solar reservado na cobertura, conforme referência anterior. |

| ID | Térreo |
| --- | --- |
| T1 | Sala à esquerda, sofá azul sob janela longa, estante e plantas. |
| T2 | Mesa de centro baixa sobre tapete e circulação livre à frente. |
| T3 | Cozinha moderna ao fundo à direita, armários creme e azul, pia e fogão de indução. |
| T4 | Geladeira alta na ponta da bancada. |
| T5 | Mesa de jantar com quatro cadeiras, entre cozinha e sala. |
| T6 | Escada no lado direito da frente, com guarda-corpo, conectando ao quarto. |
| T7 | Porta frontal, objetos domésticos e parede frontal cortada para leitura do interior. |

| ID | Quarto |
| --- | --- |
| Q1 | Cama individual azul, travesseiro e tapete. |
| Q2 | Janela longa sobre bancada de estudo e criação de pipas. |
| Q3 | Notebook, luminária, fones, livros e materiais de pipa sobre a bancada. |
| Q4 | Estante baixa e cadeira de trabalho. |
| Q5 | Guarda-roupa e TV plana sobre móvel baixo à direita. |
| Q6 | Abertura verdadeira no piso, escada e guarda-corpo na frente à direita. |
| Q7 | Porta para a varanda e decoração de pipa, sem aparência rústica. |

O blockout representa massas, recuos, aberturas e mobiliário principal. Perfurações, ferragens, flores, objetos pequenos e cores entram no quadro-chave e devem ser conferidos por estes IDs. Não considerar o cinza como acabamento aprovado.

## Simplificação permitida

Agrupar folhas e flores em massas legíveis. Reduzir as perfurações do guarda-corpo a um ritmo regular de pixels, preservando a leitura de painel vazado. Livros e itens de bancada podem virar grupos de cor. Preservar a silhueta do prédio, os recuos, o volume da varanda, as janelas e a relação sala/cozinha/escada.

## Paleta de tradução

Rampas de referência compatíveis com o concept, selecionadas das paletas existentes `art/overworld/estilo/paleta-mestra.hex` e `paleta-cenario.hex`. Não é uma extração automática das cores da imagem. A pintura final deve preservar o acabamento dos personagens, luz de cima à esquerda e sombras em grupos limpos.

| Material | Cores hex |
| --- | --- |
| Marfim e reboco | #F7F3EE, #F0DCC0, #D6B79F |
| Azul arquitetônico e esquadrias | #16368A, #2B5BA5, #303B58 |
| Azul de tecidos | #445B86, #55709B, #8A99B0 |
| Faixa coral | #BB6457, #D58168, #ECA789 |
| Metal | #788497, #9DA9B5, #C8CDD1 |
| Vidro | #34798A, #589CA6, #95C8C5 |
| Madeira clara | #A07457, #C59A70, #DFBB92 |
| Vegetação | #3D6850, #527D56, #789661 |

## Escala e lote

| Medida | Proposta |
| --- | --- |
| Célula isométrica | 64 × 32 px, projeção 2 para 1 |
| Kael visível | 70 px nativos, cerca de 2,19 alturas de losango de 32 px |
| Porta | 92 px de altura |
| Pavimento | 136 px entre pisos |
| Escada | 17 espelhos de 8 px, total 136 px |
| Guarda-corpo | 44 px |

O jardim atual em `starter_neighborhood.gd` vai de u 1,2 a 9,8 e v 11 a 18,2, total 8,6 × 7,2 células. O prédio anterior ocupava u 2 a 7 e v 12 a 16, total 5 × 4. A proposta ocupa u 2 a 8 e v 11,5 a 16, total 6 × 4,5, dentro do jardim existente. Marquise, varanda e canteiros também ficam dentro desse jardim. Não é necessário ampliar o lote para esta proposta.

Portão preservado em (4,4, 18,2), entrada física em (4,4, 16) e retorno de campanha em (4,4, 17,4). Piso exterior na cota 8, piso superior na 144 e teto na 280. O núcleo de cobertura e a reserva solar chegam às cotas 320 e 333.

## Planta por zonas e conexão vertical

As plantas são `interior/planta-terreo.png` e `interior/planta-quarto.png`.

O térreo mantém a dimensão efetiva atual de 15 × 11 células do consumidor `HouseArt.room_data`, com sala à esquerda, cozinha ao fundo à direita, jantar no centro-direita e acesso livre da porta até a sala e a escada. O quarto mantém 10 × 8 células, com estudo à esquerda, cama à frente à esquerda, armário/TV ao fundo à direita e varanda na frente.

Os interiores de campanha usam espaços independentes do mapa exterior. As suas células não equivalem a uma planta arquitetônica em escala física única com a fachada. A proposta preserva esse contrato existente. A posição relativa da escada coincide nas duas plantas, entre u normalizado 0,88 e 0,97 e v 0,53636 e 1. A largura e o comprimento são adaptados às dimensões de cada sala. A integração futura deverá conectar os patamares por transição de cômodo, não por sobreposição física desses dois mapas.

O piso do quarto é recortado no retângulo da abertura. A escada desce até a cota -136 nessa vista. A abertura e os guarda-corpos ficam visíveis, com as paredes frontais cortadas. A circulação está proposta em planta, ainda sem teste de colisão ou navegação no jogo.

## Portão de aprovação

Etapa 1 pronta para revisão dos volumes, escala, disposição e escadas. O contorno sobre o concept usa escala uniforme e serve como comparação de massas entre câmeras diferentes, não como registro exato das perspectivas. A pintura, o kit modular e a integração só começam após a aprovação do blockout, conforme o pipeline solicitado.
