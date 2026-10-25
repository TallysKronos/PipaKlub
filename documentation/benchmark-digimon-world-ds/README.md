# Benchmark de referência — Digimon World DS × Soulmonsters

Data: 25/10/2026. Objetivo: orientar a produção de mapas, criaturas e apresentação do nosso monster tamer, antes de iniciar uma eventual migração de engine. Este trabalho não inicia a migração.

## Conclusão de direção

A principal lição é construir uma linguagem de peças e funções consistente antes de multiplicar conteúdo. Nos mapas examinados, chão, relevo, cobertura vegetal, objetos interativos e estados aparecem organizados em camadas reconhecíveis. A riqueza vem da composição dessas peças em lugares diferentes; aumentar a área ou a quantidade de detalhes não garante exploração melhor.

Para Soulmonsters, recomendo manter a identidade ilustrada brasileira e organizar regiões em setores com funções distintas, usando um kit de terreno completo e uma escala única. Godot pode facilitar a autoria e a revisão, mas esses contratos precisam existir em qualquer engine.

## Método, cobertura e limites

- Inventário das **320 entradas** da página, preservado em catalogo.json, com nome, categoria, endereço e miniatura. Uma entrada é uma prancha ou recurso publicado, não necessariamente uma espécie única, um mapa jogável ou um arquivo original do jogo.
- Inspeção visual direta: Data Forest 1–4; Training Peak 1; Chrome Mine 4; Drain Tunnel 3; Sheer Valley 4; Steamy Jungle 4; Packet Swamp 3; Mangrove Woods 1; Hero; NPC Characters; NPC Digimon; Agumon; Greymon; WarGreymon; Chibomon; Flamedramon; Calumon. São **20 pranchas**, sendo 11 cenários de oito famílias e nove de personagens/criaturas.
- Os cinco mapas enviados anteriormente pelo usuário também ajudaram a reconhecer o conjunto Data Forest; não constituem uma fonte de tempos, colisões ou conexões exatas.
- Consulta textual adicional: Digi-Center, Digi-Farm Default, Digivice e Font/Character Creation. A etapa visual desses recursos não foi concluída: o controle do navegador foi desativado nas configurações do Work durante a pesquisa.
- Não foram examinadas visualmente todas as 320 pranchas. Este é um inventário completo com benchmark transversal por amostragem, não uma auditoria visual exaustiva.
- Não houve execução do jogo de referência, medição de FPS, perfil de memória, extração de código, contagem automática de cores ou reconstrução do grafo de saídas. Nenhum número de velocidade, tile, FPS ou duração apresentado adiante é atribuído ao original sem medição.
- “Animations (0)” no site descreve os previews cadastrados; não prova ausência de animações na prancha. Dimensões do PNG incluem margens, créditos e múltiplos painéis; não são dimensões do mapa jogável nem da célula de animação.

## Inventário

| Categoria do acervo | Entradas |
| --- | ---: |
| Personagens | 3 |
| Fresh | 4 |
| In-Training | 7 |
| Rookie | 49 |
| Champion | 60 |
| Ultimate | 58 |
| Mega | 68 |
| Armor | 8 |
| Sem nível | 1 |
| Cenários | 56 |
| Diversos | 6 |

São 255 entradas nas categorias de criaturas, três em personagens, 56 cenários e seis diversos. Isso descreve o acervo publicado, não uma meta de quantidade para nossa demo. [Índice do acervo](https://www.spriters-resource.com/ds_dsi/dgmnworldds/).

### Famílias de cenário catalogadas

| Família | Pranchas catalogadas | Inspeção visual nesta pesquisa |
| --- | ---: | --- |
| Data Forest | 5 | 1, 2, 3, 4 |
| Chrome Mine | 8 | 4 |
| Drain Tunnel | 6 | 3 |
| Mangrove Woods | 1 | 1 |
| Packet Swamp | 6 | 3 |
| Sheer Valley | 7 | 4 |
| Steamy Jungle | 7 | 4 |
| Training Peak | 6 | 1 |
| Fazenda, cidade, lojas, laboratório e Union Room | 10 | Catalogados; sem análise visual concluída |

A numeração das pranchas não demonstra ordem de progressão nem conexão entre saídas. O grafo real precisa ser confirmado com gameplay.

## 1. Espaço e level design

### Floresta: clareiras, ilhas de vegetação e desvios

Data Forest 1 apresenta uma área aberta articulada por massas de vegetação e blocos de relevo, com objetos distribuídos em locais distintos. Nas pranchas 2–4, a água passa a organizar margens e travessias. A composição alterna espaços abertos com estreitamentos. A separação entre painel base, objetos e composição ajuda a entender o papel de cada camada. Isso não permite deduzir quais objetos bloqueiam passagem ou qual caminho é obrigatório.

Aplicação: cada setor das Veredas deve ter uma função espacial. Um abre uma escolha, outro oferece um desvio para recompensa, outro concentra a passagem sobre água, outro prepara o boss. Não preencher todos com a mesma combinação de caminho reto, baú e árvores. [Data Forest 1](https://www.spriters-resource.com/ds_dsi/dgmnworldds/asset/508011/), [2](https://www.spriters-resource.com/ds_dsi/dgmnworldds/asset/508012/), [3](https://www.spriters-resource.com/ds_dsi/dgmnworldds/asset/508013/), [4](https://www.spriters-resource.com/ds_dsi/dgmnworldds/asset/508014/).

### Montanha: altura participa da composição

Training Peak 1 combina patamares estreitos, paredes de rocha e escadas verticais visíveis. O percurso é lido pelo contraste entre topo e face. A imagem oferece uma referência de sustentação: o terreno superior tem espessura e base, em vez de depender só de sombra. Não é possível afirmar apenas pela prancha quais patamares são acessíveis.

Aplicação: nossas rampas devem conectar cotas explícitas; esconder uma face com árvore ou pintar uma textura no vazio não é solução. O setor alto precisa oferecer vista ou mudança de percurso que justifique a subida. [Training Peak 1](https://www.spriters-resource.com/ds_dsi/dgmnworldds/asset/508018/).

### Mina e túnel: função reconhecível pelo material

Chrome Mine 4 usa rocha, madeira estrutural e trilhos para organizar o lugar. Drain Tunnel 3 usa alvenaria, canos, água e passagens estreitas. Os dois compartilham uma leitura de volume, mas têm vocabulários próprios. A diferença de identidade não depende apenas de trocar a cor do chão.

Aplicação: a área de Lacertubo deve ser reconhecida por canos quebrados, marcas e infraestrutura integrada ao relevo. Hoje o pátio ainda se aproxima de um pedaço genérico de chão com um boss. Criar uma família pequena de canos, junções e bases faz mais sentido que adicionar ornamentos sem função. [Chrome Mine 4](https://www.spriters-resource.com/ds_dsi/dgmnworldds/asset/559263/), [Drain Tunnel 3](https://www.spriters-resource.com/ds_dsi/dgmnworldds/asset/559249/).

### Vale, selva e pântano: silhueta antes do detalhe

Sheer Valley 4 é caracterizado por paredes altas e travessias contrastantes. Steamy Jungle 4 combina vegetação tropical, água e uma elevação central marcada. Packet Swamp 3 usa plataformas recortadas e efeitos aquáticos em posições recorrentes. Mangrove Woods 1 mostra passagens ramificadas cercadas por água e árvores; alguns painéis têm áreas não preenchidas, portanto não devem ser interpretados como uma cena final completa.

Aplicação: desenhar a silhueta de cada ambiente em miniatura antes de produzir as texturas. Se duas áreas continuam iguais quando reduzidas a manchas de cor, precisam de diferenças de estrutura. As pranchas não comprovam mecânicas de dano, correnteza ou interação desses efeitos. [Sheer Valley 4](https://www.spriters-resource.com/ds_dsi/dgmnworldds/asset/509048/), [Steamy Jungle 4](https://www.spriters-resource.com/ds_dsi/dgmnworldds/asset/509038/), [Packet Swamp 3](https://www.spriters-resource.com/ds_dsi/dgmnworldds/asset/559270/), [Mangrove Woods 1](https://www.spriters-resource.com/ds_dsi/dgmnworldds/asset/559274/).

## 2. Terreno, tiles e acabamento

| Padrão observado na amostra | Fragilidade no nosso protótipo | Diretriz proposta |
| --- | --- | --- |
| Topos, paredes e bases compõem volumes legíveis | Pisos elevados já ficaram sem sustentação | Definir volume antes do material e testar contorno externo |
| Vegetação forma massas que recortam o espaço | Árvores isoladas e copas de fundo repetidas chamam atenção | Compor grupos de tamanhos coerentes e preservar rotas visíveis |
| Margens fazem parte do desenho da água | Canal ainda muito reto e uniforme | Kit de margens com variações, cantos e travessias testadas |
| Material caracteriza o ambiente | Mesma terra e grama dominam setores diferentes | Separar biblioteca de materiais de biblioteca de estruturas |
| Objetos repetem uma linguagem reconhecível | Pontos de interesse podem competir com o fundo | Reservar contraste e animação para o que importa |

Kit mínimo proposto para uma família de terreno original: centro, bordas nos quatro sentidos, cantos internos/externos, topo/lateral/base de barranco, entrada/saída de rampa, margem e cabeceira de ponte. Antes de ampliar a biblioteca, montar uma sala de testes com trechos longos, curvas, cruzamentos, buracos, cotas diferentes e objetos junto às bordas.

Não foi identificado um atlas original completo de autotiling nessas pranchas. O kit acima é uma proposta de produção nossa, inferida das necessidades visuais, não uma reconstrução do sistema usado pelo jogo de referência.

## 3. Personagens e animações

Hero contém duas apresentações de protagonista, retratos e séries direcionais, além de poses adicionais. NPC Characters organiza muitos personagens com retrato e conjuntos compactos de poses. NPC Digimon mostra criaturas com representações direcionais. Isso evidencia uma separação útil entre identidade facial e corpo no mundo; não autoriza atribuir duração ou nome a cada sequência sem inspeção temporal. [Hero](https://www.spriters-resource.com/ds_dsi/dgmnworldds/asset/48323/), [NPC Characters](https://www.spriters-resource.com/ds_dsi/dgmnworldds/asset/48318/), [NPC Digimon](https://www.spriters-resource.com/ds_dsi/dgmnworldds/asset/50031/).

Para nós: Kael, Nina, mãe, professor e locutor precisam de contratos separados para retrato, exploração e eventos. Uma direção não deve ser simulada repetindo o mesmo quadro em oito slots. O conjunto necessário deve depender do papel do personagem: NPC parado não precisa do mesmo pacote de um seguidor que atravessa o mapa.

### Criaturas: apresentação por contexto

Agumon, Greymon e WarGreymon separam desenhos maiores e representações pequenas; Chibomon também tem apresentações de escalas diferentes. Flamedramon e Calumon reforçam essa distinção, e a prancha de Calumon nomeia grupos de batalha e movimento. Não é adequado contar tudo como uma única animação contínua ou deduzir tamanho de quadro pelo tamanho total do PNG.

Para nós: manter identidade entre a pipa voando na batalha, o parceiro no chão e o retrato de coleção. É aceitável adaptar a silhueta ao contexto; esticar uma única imagem para todas as funções reduz legibilidade. [Agumon](https://www.spriters-resource.com/ds_dsi/dgmnworldds/asset/48418/), [Greymon](https://www.spriters-resource.com/ds_dsi/dgmnworldds/asset/48406/), [WarGreymon](https://www.spriters-resource.com/ds_dsi/dgmnworldds/asset/48613/), [Chibomon](https://www.spriters-resource.com/ds_dsi/dgmnworldds/asset/48416/), [Flamedramon](https://www.spriters-resource.com/ds_dsi/dgmnworldds/asset/48588/), [Calumon](https://www.spriters-resource.com/ds_dsi/dgmnworldds/asset/20456/).

## 4. Objetos, estados e recompensas

Nas pranchas de cenários examinadas há objetos apresentados isoladamente e variantes sucessivas, além de composições com e sem objetos. Isso é uma referência para separar estado do cenário estático. Não se pode concluir a lógica de cada variante apenas pela imagem.

Contrato proposto: baú fechado/aberto; item presente/coletado; boss presente/derrotado; NPC antes/depois da missão. Cada estado precisa definir imagem, interação, persistência e comportamento após recarregar. A retirada de um boss deve preservar o interesse do lugar e a leitura da recompensa.

Nossa decisão de encontros **somente no mato** permanece. As pranchas não medem frequência nem provam a regra de encontros; o relato do usuário sobre andar pelo mapa deve ser tratado como contexto, não como resultado de teste desta pesquisa.

## 5. Cidade, fazenda e interface: o que falta verificar

Digi-Center e Digi-Farm Default estão catalogados como recursos separados, assim como Digivice e Font/Character Creation. As páginas confirmam sua presença; não completei sua inspeção visual e não extraio daqui conclusões sobre menus, fontes, tamanhos de texto ou ciclo de cuidados. [Digi-Center](https://www.spriters-resource.com/ds_dsi/dgmnworldds/asset/20468/), [Digi-Farm](https://www.spriters-resource.com/ds_dsi/dgmnworldds/asset/20471/), [Digivice](https://www.spriters-resource.com/ds_dsi/dgmnworldds/asset/43933/), [Font/Character Creation](https://www.spriters-resource.com/ds_dsi/dgmnworldds/asset/43934/).

O acervo consultado também não constitui uma documentação completa da interface de combate, navegação de menus, som ou economia. Para completar essa parte, a próxima pesquisa deve combinar essas quatro pranchas com capturas de gameplay e percurso de menus. Evitar reconstruir nossa interface inteira com base em uma folha de fonte ou dispositivo.

Para Steam, nossa proposta deve ser avaliada em uma tela única: texto legível, foco por controle, pausas e informações contextuais. Não transportar automaticamente uma organização de duas telas para o PC. Essa é uma recomendação de projeto, não uma observação comprovada dessas quatro pranchas.

## 6. Comparativo de produção

| Tema | Referência observada | Situação de Soulmonsters | Próxima entrega verificável |
| --- | --- | --- | --- |
| Região | Famílias com vários mapas e silhuetas variadas | Veredas amplas em um mapa contínuo | Planta com setores e funções distintas; conexões explícitas |
| Terreno | Volumes e margens reconhecíveis | Correções recentes de sustentação e pontes | Sala de encaixes com casos de regressão |
| Identidade de área | Estruturas próprias por ambiente | Pátio ainda pouco caracterizado por canos | Kit original de infraestrutura e marco do boss |
| Personagens | Retratos e poses de mundo separados | Retratos melhores; pacotes de NPCs desiguais | Matriz de animações por personagem e função |
| Criaturas | Representações grandes e pequenas | Rigs e atlas próprios já existem | Revisão da mesma espécie em três contextos |
| Estado do mundo | Pranchas separam objetos e composições | Boss, baús e missão já alteram o mapa | Reentrada e save testados em cada estado |
| Direção visual | Peças coerentes entre mapas da mesma família | Materiais ilustrados misturados a formas muito regulares | Cena-alvo aprovada em escala de jogo |
| Ferramentas | O acervo não comprova a engine original | Engine Canvas com autoria em código | Comparação prática de autoria com Godot |

Não atribuí notas numéricas de qualidade: a comparação é qualitativa e a amostra é desigual. Não há base para afirmar que um jogo roda melhor, custa menos ou exige menos tempo de produção apenas a partir dos PNGs.

## 7. Metas propostas para nossa primeira região

Estes números são pontos de partida para playtest, não medidas de Digimon World DS:

- Quatro a seis setores legíveis, com pelo menos uma diferença de silhueta ou travessia em cada um.
- Uma rota principal reconhecível e dois desvios opcionais com recompensas de funções diferentes.
- Um circuito ou retorno curto que evite repetir todo o percurso após o boss.
- Uma antecipação ambiental de Lacertubo antes da arena: marcas nos canos, dano no caminho e relato de Nina, sem sequência de falas explicando cada passo.
- Descanso antes do trecho de maior risco; mato opcional para buscar encontros e treinar.
- Escala medida em larguras do personagem: validar passagem de Kael e seguidor antes de definir o tamanho definitivo do tile.
- Câmera acompanha o jogador e deixa ver a próxima decisão; minimapa revela apenas o que já foi explorado.

Não fixar duração da expedição nem frequência dos encontros sem jogar. Medir percurso direto, exploração, retorno, tempo em menus e número de batalhas; ajustar pelo comportamento observado.

## 8. O que isso muda na avaliação de Godot

O benchmark favorece uma produção baseada em cenas e kits consistentes. Não demonstra por si só que precisamos migrar. A avaliação deve usar os mesmos assets e o mesmo trecho funcional, para comparar ferramentas sem confundir ganho de engine com uma arte refeita.

Prova de migração proposta: um setor com dois materiais de piso, duas cotas, rampa, ponte, árvore que oclui, baú persistente, Nina com diálogo, Kael e seguidor, entrada/retorno de batalha e save local. Depois integrar autenticação/servidor em etapa própria. Registrar tempo de alteração do mapa, problemas de profundidade, comportamento com controle, carregamento e desempenho em hardware identificado.

A primeira versão Windows deve funcionar como jogo instalado. A política offline e a integração de conta precisam ser decisões explícitas. Não iniciar simultaneamente novos mapas, reescrita de combate e mudança de estilo artístico.

## 9. Plano de trabalho por prioridade

| Ordem | Entrega | Aceite |
| --- | --- | --- |
| 1 | Cena-alvo de arte e escala | Kael, parceiro, árvore, baú, água e desnível coerentes na mesma imagem de jogo |
| 2 | Kit completo de terreno | Bordas, cantos, rampas e pontes encaixam sem vegetação escondendo falhas |
| 3 | Planta da região de Nina | Cada setor tem função, desvios são úteis e retorno é legível |
| 4 | Pacotes de personagens | Direções reais, retratos próprios e estados de evento definidos |
| 5 | Estados e save | Coleta, boss e missão continuam corretos após sair e voltar |
| 6 | Prova em Godot para Windows | Mesmo trecho jogável, build reproduzível e comparação registrada |
| 7 | Decisão de migração | Ganhos demonstrados e plano de reaproveitamento do servidor/dados |

## 10. Uso da referência e arquivos

O benchmark usa o acervo como estudo de organização e linguagem visual. Nenhuma imagem foi adicionada aos assets de produção, aos builds ou ao catálogo de criaturas do nosso jogo. Não foi identificada autorização de reutilização comercial neste levantamento; não tratar a disponibilidade das pranchas como licença para distribuí-las na Steam.

Arquivos desta entrega: catalogo.json (inventário de 320 links e categorias) e este relatório. A pesquisa não altera engine, mapas ou regras do jogo e não foi enviada ao Git automaticamente.
