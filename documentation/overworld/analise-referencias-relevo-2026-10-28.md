# Estruturas isométricas: arquipélago de passarelas e parque com ponte

Análise das duas imagens fornecidas pelo usuário em 28/10/2026. As cotas, colisões e ligações ocultas não podem ser medidas com segurança a partir desses recortes. A decomposição abaixo distingue observação visual de proposta de implementação. O objetivo é reproduzir a qualidade das estruturas com a pintura 2D mangá de Soulmonsters, sem copiar a textura ou o desenho dos mapas.

## Referência 1 — plataformas de madeira, rochedo e água

### Estrutura observável

- Água forma um plano visual comum e separa massas de rocha, uma ilha de areia e uma rede construída. A variação azul também sugere fundos submersos; não comprova que esses fundos sejam percursos.
- A parte inferior tem um cais baixo em zigue-zague. O centro reúne decks mais altos, pisos com espessura, escadas e pilares. Algumas passagens se sobrepõem na projeção.
- À esquerda há uma sequência de terraços junto ao rochedo, com acessos verticais por escadas de mão. A parede rochosa continua entre os terraços: não são plataformas soltas sem sustentação.
- À direita, uma torre/cabana combina pilares, decks, cobertura e acessos. Uma ponte curva liga visualmente massas separadas. Os apoios e cabeceiras tornam legível a travessia.
- As escadas abertas do centro mostram degraus regulares, largura constante e chegada em decks. As ligações usam patamares que permitem mudar a direção sem torcer os degraus.
- As tábuas acompanham cada módulo de plataforma. Tapetes e faixas coloridas distinguem áreas de parada e direção; detalhes ficam subordinados à continuidade dos tabuleiros.
- Pilares, faces inferiores, sombra e oclusão reforçam a diferença entre água, passarela baixa e deck alto. Partes da estrutura desaparecem atrás de pisos próximos.
- As regiões brancas externas correspondem ao recorte da imagem; não devem ser interpretadas como buracos do mapa.

### Contratos necessários

1. Cada deck tem uma pegada, uma altura e uma identidade própria. Dois decks que se cruzam em tela não se conectam automaticamente.
2. Uma escada registra piso de origem, piso de destino, largura e direção de subida. Uma escada de mão é outra categoria de ligação, com movimento e interação próprios.
3. Uma ponte tem tabuleiro, espessura, cabeceiras e apoios quando previstos. O vazio sob ela permanece independente do percurso superior.
4. O ator mantém a identidade da superfície/andar em que está. Ordenação por Y isolada não resolve atravessar embaixo e por cima do mesmo trecho.
5. Tábuas, pilares e guarda-corpos precisam ser divididos em componentes ocludentes; um único sprite opaco da plataforma inteira ocultaria o ator de forma incorreta.
6. As conexões exatas de partes ocultas devem ser decididas em uma planta nossa. A imagem não revela todas elas.

## Referência 2 — parque, encosta e ponte de pedra

### Estrutura observável

- Uma massa principal de terra tem borda recortada, topo gramado e faces laterais expostas. Caminhos pavimentados se encontram em uma praça com marco central.
- No alto à esquerda, a trilha clara muda de direção sobre faixas elevadas de terreno. Faces de terra e bordas de grama indicam variações de cota; a resolução não permite afirmar a inclinação exata de todos os trechos.
- Próximo da construção superior, um acesso curto articula trilha, edifício e área inferior. A chegada é uma região de apoio, não uma ponta inclinada desconectada.
- A ponte de pedra segue um eixo claro, com tabuleiro contínuo, parapeitos e apoios repetidos em arco. Os arcos pertencem à sustentação; não são degraus do percurso superior.
- A cabeceira liga a ponte ao terreno. A face do barranco deve terminar ou mudar de forma nesse intervalo, sem bloquear o tabuleiro.
- A praça e os caminhos oferecem descanso visual. Árvores, cercas e arbustos ocupam grupos e bordas, preservando cruzamentos e entradas legíveis.
- Recortes junto à água e pequenos trechos estreitos exigem cantos côncavos/convexos fechados, sem repetir tampas de barranco em cada tile.

### Contratos necessários

1. Extrair o contorno do maciço contínuo: topo, borda de grama e faces usam a mesma pegada.
2. Material de caminho não altera a altura. Grama e pavimento vizinhos na mesma cota compartilham apoio.
3. Rampas recortam as paredes nos acessos. Laterais em cunha vão a zero na chegada inferior, respeitando o terreno adjacente.
4. A ponte começa na cota do patamar de chegada. Arcos e pilares podem variar sem interromper a superfície caminhável.
5. Morros suaves usam altura contínua; terraços usam patamares e barrancos. Pintar uma encosta em um piso plano não cria apoio para o ator.

## Escadas consistentes

Uma escada exige duas cotas, comprimento útil, largura, direção e número de degraus. Todos os espelhos têm altura `Δh/N`; todos os pisos têm profundidade `L/N`. A terminação precisa ser explícita: o último espelho encontra o patamar superior, sem criar um piso duplicado ou um degrau de altura diferente. Ambos os lados derivam da mesma seção.

Exemplo proposto, não medida das imagens: desnível de 48 px, 12 espelhos de 4 px, 3 células de avanço e 1,5 célula de largura. Comprimento e número de degraus devem ser ajustados à escala e leitura da câmera antes de virar um padrão do jogo.

Para um movimento fluido em escadas pequenas, a superfície lógica de apoio pode ser uma rampa entre as mesmas cotas, com degraus desenhados acima dela. Se degraus tiverem impacto mecânico, o movimento precisa tratar o apoio discretizado. Em ambos os casos, o pé e a sombra devem parecer apoiados e não flutuar. Isso exige validação com o ator em movimento, não apenas uma imagem estática.

## Estado real do nosso projeto

- `underwater_terrain.gd` demonstra patamar, depressão, rampas, recorte do piso e apoio com altura. A consulta atual escolhe uma altura por posição; não demonstra vários pisos caminháveis sobrepostos.
- `japanese_street.gd` demonstra calçada, acessos rebaixados e drenagem, em uma cena visual isolada.
- `street_building.gd` demonstra projeção comum para paredes, telhado e volumes salientes. A varanda é visual; não demonstra circulação no andar superior.
- O renderer principal `view.gd`, em `_draw_stone_stairs`, já constrói oito pisos e espelhos de pedra para um desnível de 64 px, com quatro direções e tratamento de laterais junto ao terreno. Também há rotinas de ponte. Essas peças devem ser aproveitadas e parametrizadas conforme o novo consumidor, em vez de concluir que escadas e pontes ainda não existem.
- `map_model.gd` já tem grafo de percurso, restrições de passagem entre cotas e altura interpolada nas rampas. Seu identificador de célula é `v * largura + u`, e cada célula consulta uma superfície. Este modelo ainda precisa ser ampliado para representar dois pisos caminháveis diferentes na mesma coordenada em planta.
- A regra de contorno compartilhado e recorte de acessos já está em `documentation/continuidade-terreno-isometrico.md`.

Esses exemplos validam peças da construção visual. Não comprovam um sistema completo de escadas, pontes sobrepostas, seleção de andar, colisão e navegação em toda essa complexidade.

## Próxima implementação proposta

Construir uma cena de prova única, antes de um mapa grande: praça inferior → escada com patamar → terraço → ponte sobre uma passagem inferior → rampa de retorno. Incluir um barranco com canto interno e externo. Primeiro revisar a montagem em cores simples, depois aplicar a arte mangá.

Cada superfície deve registrar ID, pegada, cota/perfil, espessura, material e ligações. O jogador registra a superfície de apoio, além da posição em planta. A troca de superfície acontece em uma conexão explícita. As saídas entre mapas registram mapa de destino, entrada, superfície e direção; preservar altura de chegada e estado de campanha será parte da integração, não da biblioteca visual.

## Aceitação visual e jogável

- Revisar as quatro orientações de escada e rampa; uma orientação correta não comprova as outras.
- Conferir chegada inferior, superior, laterais e mudanças de direção em captura ampliada e sem personagem cobrindo a junta.
- Nenhuma parede atravessa uma boca; nenhum degrau sobra depois do último patamar.
- A ponte encontra os apoios e permite distinguir seus dois percursos, quando ambos forem caminháveis.
- Caminhar nos dois sentidos, parar nas juntas e passar atrás/à frente dos apoios; conferir pés, sombra e seguidor.
- Selecionar pelo mouse uma superfície sobreposta deve respeitar o andar e não teletransportar o ator.
- A ligação entre mapas mantém uma entrada apoiada e uma volta coerente.
- Só considerar a prova concluída após revisar o movimento real. Aplicar pintura e vegetação depois da geometria; preservar leitura de mangá com cores chapadas e tinta seletiva.

Esta entrega é análise e proposta, sem nova implementação ou testes de gameplay.
