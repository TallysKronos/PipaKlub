# Diretrizes de continuidade do terreno isométrico

Escopo: regras geométricas compartilhadas entre os cenários Godot e os mapas da engine JavaScript/Canvas do projeto. Esta diretriz complementa WORLD-ART-DIRECTION.md e deve orientar correções, novos mapas e revisão de assets. As seções históricas do pátio documentam a implementação no renderer legado.

## Diagnóstico das Veredas

A Travessia alta e o Pátio dos canos antigos estão em elevation=96, assim como a Encosta do vento, em src/park-boss-layout.js. São superfícies conectadas, não ilhas suspensas nem uma ponte elevada.

Na versão anterior de src/veredas-region-renderer.js, veredasTerrainPlan gerava faces apenas para ground_frame=grass. As superfícies sidewalk do pátio e da passagem não ganham laterais. Além disso, a face leste da encosta é desenhada sem descontar a ligação com a passagem na mesma altura. O resultado combina piso sem volume de sustentação e parede interna atravessando uma conexão.

A textura de pedra e a sombra não corrigem essa geometria. Vegetação não deve esconder as juntas defeituosas.

## Contrato único de terreno

| Informação | Responsabilidade |
| --- | --- |
| Pegada e elevação | Definem o volume físico do terreno e a superfície de apoio |
| Material | Escolhe grama, terra, pedra ou piso; não determina se existe sustentação |
| Conexão | Define chão contínuo, rampa, ponte ou borda bloqueada |
| Contorno exposto | Define onde há barranco, margem, acabamento e sombra de contato |
| Ocupantes | Apoiam personagens e objetos na mesma superfície usada pelo movimento |

O renderer, a navegação e a seleção pelo mouse devem partir das mesmas pegadas e alturas. level identifica o andar; elevation representa a altura desenhada. Não substituir uma pela outra implicitamente.

## Regras de construção

1. **Unir volumes antes de pintar.** Agrupar pisos conectados de mesma elevação e extrair sua união. A encosta, a passagem alta e o pátio devem formar um maciço contínuo. Unir suas bases não exige que todos usem a mesma textura.
2. **Desenhar só bordas expostas.** Dois terrenos adjacentes da mesma altura não têm parede entre eles. Descontar intervalos compartilhados, inclusive conexões parciais e cantos internos. Onde houver cota inferior adjacente, a face tem a diferença de alturas, não uma altura fixa até zero.
3. **Fechar o volume.** Todo piso elevado precisa de faces visíveis até sua base, ou de um suporte intencional e identificável. No pátio, usar barranco natural contínuo; reservar pilares e tabuleiro para uma futura estrutura realmente definida como ponte.
4. **Preservar os cantos.** Topo, lateral e base compartilham os mesmos vértices. Cantos internos e externos precisam fechar sem buracos, faixas duplicadas ou linhas que terminam no vazio. Arredondar o topo também exige compatibilizar a face lateral.
5. **Encaixar rampas nos dois patamares.** A extremidade alta coincide com o piso superior e a baixa com o inferior. As laterais fecham em cunhas. Recortar a parede na boca da rampa; manter chão e textura contínuos nas chegadas.
6. **Apoiar pontes nas margens.** Separar caminho, cabeceira e tabuleiro. A madeira atravessa o vão e se apoia em terra nas duas pontas. Terra não cobre o deck; sombra acompanha sua altura. O piso pode ser atravessado sem salto ou degrau visual inesperado.
7. **Manter apoio e profundidade.** Banco, baú, boss, personagem e seguidor usam a altura da superfície sob sua base. Sombras de contato ficam nessa superfície. Ordenar faces, pisos e ocupantes pela geometria, verificando os dois sentidos de passagem.
8. **Tratar materiais como revestimento.** As texturas mantêm escala, fase e iluminação entre módulos. A transição grama/terra não cria um degrau. Não esticar uma parede inteira para preencher qualquer proporção nem usar uma sombra para simular volume ausente.
9. **Distinguir cenário e passagem.** Copas de fundo têm escala e contraste coerentes com a distância. Árvores próximas têm troncos apoiados e bases compatíveis com colisão. Não colocar uma árvore para ocultar uma junta quebrada.

## Ordem de correção do pátio

1. Extrair a união de TODOS os pisos de sustentação na cota 96, incluindo sidewalk. Caminhos pintados sobre grama são revestimentos e não novos volumes.
2. Gerar os intervalos de borda dessa união, excluindo vizinhos na mesma cota e aberturas de rampa. Conferir o encaixe entre encosta, passagem e pátio sem texturas.
3. Fechar as faces do pátio e os cantos da passagem até a base inferior. Eliminar a parede interna da encosta.
4. Aplicar rocha, terra, acabamento de borda e sombras com escala constante. Só então recolocar objetos e vegetação.
5. Percorrer ida e volta com Kael e o seguidor. Conferir banco, boss, baú e item de missão antes e depois da vitória.

## Critérios de aceite

### Revisão de detalhe obrigatória em novos layouts

Além da vista geral, capturar cada encontro de rampa com patamar, canto interno/externo e lateral inclinada em escala ampliada, com e sem personagens sobre a junta. Conferir faces posteriores em bordas côncavas: omiti-las pode deixar triângulos de chão aparecendo entre segmentos que parecem colunas soltas. Topos, faces e laterais devem ter ordenação de profundidade compatível; um pequeno deslocamento na chave de ordenação precisa sobreviver à quantização do renderer, sem deslocar a geometria desenhada.

As laterais não podem usar um revestimento inteiro esticado a cada célula. Os UVs devem acompanhar posição e altura contínuas, com iluminação consistente entre segmentos. Corrigir saliências isoladas da planta quando não representam uma forma intencional. Não entregar uma correção com a junta tapada pelo personagem, por árvore ou por HUD. Registrar a limitação se somente capturas estáticas foram conferidas.

- Em uma prévia com cores simples, o pátio parece ligado fisicamente à encosta.
- Nenhuma parede atravessa uma passagem entre pisos de mesma altura.
- Toda borda elevada visível tem face e base; não existe piso pairando sobre a floresta.
- Não há fendas ou sobreposição nos encontros de cantos, rampas e cabeceiras.
- Pés, bases e sombras do boss, do banco e dos baús pertencem ao pátio.
- O jogador consegue antecipar onde pode andar; a arte não sugere atalhos através de paredes.
- Cliques, movimento e seguidor respeitam as conexões nos dois sentidos.
- Conferência visual em desktop e tela estreita, com personagem parado e andando. Testes geométricos não substituem essa conferência.

## Proteções automáticas da correção

- Pisos elevados de materiais distintos produzem sustentação e contorno externo comuns.
- Adjacência total ou parcial na mesma cota remove a parede compartilhada.
- Bordas para cotas inferiores usam a diferença correta de alturas.
- Cantos côncavos, convexos e aberturas de rampa não deixam faces órfãs.
- Piso, projeção do ator e seleção pelo mouse concordam nos limites da passagem.
- Um caso de regressão usa especificamente a ligação Encosta do vento → Travessia alta → Pátio dos canos antigos.

Registrar screenshots antes/depois do mesmo enquadramento. Só declarar o problema corrigido após verificar a geometria e a imagem no jogo.


## Correção entregue

O plano do terreno agora extrai o contorno da união de todos os pisos em cada altura, independentemente do material. Mantém somente faces externas visíveis, recorta as rampas e desconta cotas vizinhas. Pátio e passagem têm faces até a base; a parede interna da ligação foi removida. Topos de piso elevado são preenchidos até seus vértices estruturais, evitando cantos arredondados sem apoio. O acabamento de terra não recebe a franja de grama.

Testes de regressão verificam as duas junções do acesso ao boss, a frente e a lateral do pátio, a sustentação da passagem, uma diferença de cota de 48 e a projeção/seleção dos dois lados das junções. A prévia isolada inclui “Veredas: acesso ao patio (previa)” para revisão reproduzível sem modificar uma conta. Screenshots locais em outputs/veredas-support, na pasta da tarefa. Não altera colisões, posições de save nem recompensas.

## Apoio de construções ilustradas

Na Rua das Rabiolas, alinhar o pixel opaco mais baixo de uma casa não garantiu apoio: as duas arestas da base do desenho tinham inclinações diferentes dos eixos do piso. Não aprovar uma fachada só pelo pivô ou pelo contato de um canto. Conferir as duas arestas completas, os três cantos visíveis, a implantação inteira e o telhado em captura ampliada.

Quando a perspectiva pintada divergir, usar elevações ortográficas em planos nativos isométricos com paredes, fundação, empenas e telhado derivados da mesma planta (`street_building.gd`). Deslocamento vertical ou sombra não corrige uma base oblíqua. A implantação da casa/loja desta cena permanece toda no passeio +10, sem atravessar guia ou rampa.

## Margens e cotas de água

Regra adicionada após a revisão do poço da Gruta dos Elos, em 27/10/2026.

- Poços naturais que recebem quedas são volumes escavados, não texturas retangulares sobre o solo. O chão superior deve ter um recorte real, e as faces internas da margem devem chegar à superfície da água na cota inferior.
- Um único contorno medido gera o recorte do solo, a borda superior e a base das faces. A água recebe a mesma projeção com o deslocamento vertical da profundidade. Não arredondar a água deixando o buraco ou o barranco quadrado.
- A margem natural usa assimetria e curvas/poucos segmentos suaves. Bordas perfeitamente retas e retangulares só representam uma estrutura construída intencional.
- Declarar separadamente altura do lábio, altura do chão e altura da água. A queda termina na água: comprimento = altura do lábio menos altura da água. A espuma de impacto pertence à superfície inferior.
- Na ordenação, a margem próxima e o chão superior ocluem a água e as faces ocultas. A espuma não pinta o chão caminhável. Conferir também a projeção inferior contra o limite externo do terreno, para não deixar uma lateral solta aparecendo fora do piso.
- Preservar passagem, apoio e contraste dos objetos. Não resolver a junta cobrindo-a com um mon, pedra decorativa ou vegetação.

### Referência medida da caverna

| Superfície | Altura em pixels |
| --- | ---: |
| Lábio da cachoeira | +128 |
| Solo e borda do poço | 0 |
| Água | -24 |
| Comprimento da queda | 152 |

O componente `godot/scripts/overworld/cave_basin.gd` mantém o recorte, a superfície inferior, as faces e a queda juntos. Sua pegada de canto 10×10 tem folga de projeção para profundidade de 16–24 px. Um rebaixo maior exige redimensionar a pegada e revisar a folga, não somente aumentar a altura das faces.

A diferença de polígonos usa a operação geométrica documentada em [Geometry2D.clip_polygons](https://docs.godotengine.org/en/stable/classes/class_geometry2d.html#class-geometry2d-method-clip-polygons). Nesta peça o contorno encontra a borda posterior do terreno, gerando uma superfície de chão recortada sem um anel interior separado. Para um poço inteiramente interno, tratar corretamente os anéis/triangulação; não desenhar o polígono do furo como piso.

### Revisão mínima

Capturar o mesmo enquadramento antes/depois, detalhe da boca, margem próxima, terminação lateral e ponto de impacto, mais uma montagem em cores simples sem objetos. Conferir a cena salva instanciada e a animação. Registrar cotas, comprimento da queda e contorno compartilhado junto às capturas. Essa revisão comprova os assets e sua montagem; navegação, colisão e campanha dependem da integração do mapa.
