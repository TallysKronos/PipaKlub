# Diretrizes de continuidade do terreno isométrico

Escopo: mapas da engine JavaScript/Canvas do projeto. Esta diretriz complementa WORLD-ART-DIRECTION.md e deve orientar correções, novos mapas e revisão de assets. Estado: diretrizes e correção do pátio implementadas; revisão local com testes e navegador em 25/10/2026.

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
