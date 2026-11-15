# Como construir mapas jogáveis a partir dos concepts

Este é o roteiro de produção de áreas completas de Soulmonsters. Ele aplica o método do laboratório do Sr. Assis ao terreno, aos edifícios e ao percurso, da leitura das imagens à conferência no Godot.

O concept é a referência de conteúdo, silhueta, materiais, marcos e relações do lugar. A planta e o blockout estabelecem o espaço jogável. A paleta, os sprites nativos e a câmera do projeto estabelecem como ele aparece no jogo.

## 1. Preparação e leitura das imagens

1. Atualize as referências remotas e confira a branch, o worktree e o `--path` do Godot. Para novas regiões, a base definida pelo dono é `origin/claude/unificacao`. Confirme que a branch de trabalho contém a documentação, a paleta e as peças aprovadas que vai usar. Se ainda estiverem em outra branch, peça ao integrador para trazer a revisão necessária ou consulte os arquivos dessa branch durante a preparação.
2. Leia o [catálogo de concepts](../../art/overworld/conceitos/README.md), o `BRIEF.md` da região, `vista-geral.png`, todos os recortes pertinentes e `DETALHAMENTO.md`, quando existir. Abra as imagens. Use os próprios PNGs como entradas se fizer paintover ou edição por referência.
3. Leia a [skill do construtor](../../.agents/skills/soulmonsters-construtor-de-mapas/SKILL.md), o [pipeline de arte](PIPELINE-CONCEPT-PARA-JOGO.md), a [continuidade de terreno](../continuidade-terreno-isometrico.md), a [regra de regiões em partes](../../art/overworld/REGIOES-E-PARTES.md) e os trechos correspondentes da [bíblia](../historia/BIBLIA-DA-HISTORIA.md).
4. Identifique a implementação que realmente monta a cena. Mapas compilados normalmente entram pelo `view.gd`; a Vila e alguns interiores usam construtores próprios. Leia o carregador, o modelo de movimento, o ponto de entrada e os testes da área antes de editar. Preserve os IDs e as ligações já usados pela campanha.
5. Trabalhe em uma região por vez, com fonte versionado e commits por etapa. Na sequência do pedido de 14/11, siga Rua dos Ventos → Morro do Sol → Parque dos Ventos e Veredas → Bosque de Kronasta. Escolha cada elemento conforme o concept e a função do lugar.

## 2. Ficha de tradução e planta por cotas

Crie `art/overworld/briefs/<area>.md` ou uma `traducao.md` na pasta de revisão da área. Faça esta ficha antes de pintar.

- **Inventário visual.** Numere os elementos obrigatórios (`E01`, `E02`…), cite a imagem ou o recorte que prova cada um e diga em que zona aparece. Marque separadamente detalhes simplificáveis e decisões de implantação. Mostre a pegada, cota, altura, orientação e acesso de cada marco grande.
- **Percurso.** Desenhe a entrada, saídas, rotas principais, atalhos, descanso, encontros, itens, NPCs, travas e retornos. Uma região explorável tem pelo menos partes A/B/C, ligadas em ambos os sentidos. Preveja ao menos três itens por parte, incluindo um escondido alcançável, conforme as regras regionais e a bíblia. Um trecho aberto seguido de um estreitamento e nova abertura dá ritmo. Cada ramal tem destino ou recompensa, e o jogador vê de onde chega e como volta.
- **Cotas e seções.** Faça uma planta por nível e um corte lateral nas ligações difíceis. Registre cada superfície com ID, cota, espessura ou sustentação, início e fim da ligação. Em andares sobrepostos, faça uma planta por andar e uma tabela de portas, pontos de chegada e destinos.
- **Escala.** Use o Kael nativo, com cerca de 70 px na folha, como régua. A projeção 2:1 usa células 64 × 32 px. Uma porta comum tem aproximadamente 92 px e um espelho de escada comum mede 8 px. Confirme as alturas do consumidor antes de usá-las.
- **Implantação.** Confira a largura e a profundidade reais do lote, a folga dos corredores e o acesso às portas. Quando um conjunto obrigatório exceder o lote, mostre a pegada necessária e aguarde a revisão da implantação.

### Grade e exemplo medido

No modelo do [overworld compilado](../../godot/scripts/overworld/map_model.gd) um nível equivale a 64 px. Para uma cota expressa diretamente em pixels `z_px`, projete `x = (u - v) * 32` e `y = (u + v) * 16 - z_px`. No sistema compilado, `z_px = level * 64` em piso plano, e a rampa é medida por `height_at`. Alguns trechos da Vila usam cotas próprias de 48 px; leia o consumidor e mantenha as unidades declaradas no manifesto.

Exemplo de ligação de cota 0 a 64 px: construa duas faixas lado a lado, com duas células de comprimento e subida em `u-`. Em cada faixa, marque a célula imediatamente antes do patamar alto e configure `rampa_comprimento=2` no Tiled. O compilador estende a rampa pela trilha de terra na direção descendente. Deixe as duas células de rampa na cota base, sem peças e eventos. Use um trecho de 0 a 32 px e o seguinte de 32 a 64 px; no formato compilado, são frações `rampFrom/rampTo` de 0→0,5 e 0,5→1 do mesmo intervalo de nível. Reserve a faixa livre na cota 0 e duas células livres na chegada. Uma escada para o mesmo desnível tem oito espelhos de 8 px, com pisos iguais e o último espelho rente ao patamar. Desenhe a seção antes de fechar as faces.

## 3. Blockout jogável e revisão da estrutura

1. Faça primeiro a forma geral, os volumes altos, poços e água. Depois abra as rotas, conecte os níveis e marque entradas e saídas. Em mapas naturais, use 40% de platôs como referência do projeto e justifique desvios do concept no brief. Acrescente móveis grandes e obstáculos ao fim, em cinza. Use uma cor chapada por nível ou função apenas no modo de diagnóstico. Use o Kael original em 1× na vista principal.
2. Para mapa compilado, siga o [gerador de referência do Bosque](../../tools/mapa-studio/desenhar-kronasta-bosque.mjs). Gere um `.tmj` determinístico em `art/overworld/mapas/`, com `chao`, `altura`, `pecas` e `eventos`, conforme a [especificação](../../art/overworld/ESPECIFICACAO-MAPAS.md). Use `parseTiled` e `audit` de `tools/mapa-studio/model.mjs`, corrija os erros e justifique os avisos no brief. Compile a área com `compile(raw, id)` de `tools/import-overworld.mjs` e atualize só sua entrada em `godot/assets/overworld/maps/index.json`. Evite a regeneração global de kits.
3. Instancie o consumidor no Godot. Entregue `blockout.png`, a planta anotada e `blockout-sobre-concept.png`. Marque correspondências numeradas entre a maquete e o concept. Quando as perspectivas forem diferentes, mostre a referência anotada e a maquete 2:1 com as mesmas marcações. Declare a mudança de câmera.
4. Faça a rota principal com Kael e o seguidor antes do acabamento. Confira largura, acessos em ambos os sentidos e apoio nos pontos onde o jogador vai parar. Pare no portão da planta e do relevo.

## 4. Receitas para construir volume

| Estrutura | Como construir e conferir |
| --- | --- |
| Platô, morro e barranco | Comece com massas de pelo menos 2×2 células e sequências longas nos eixos da grade. Una pisos adjacentes da mesma cota mesmo quando o material muda. Gere faces pela diferença de altura nas bordas expostas. Topo, lateral e base compartilham vértices. Conferir cantos côncavos, faces posteriores visíveis, dobra da grama e sombra de contato no piso de baixo. |
| Rampa e escada | Num desnível jogável, deixe a subida visível em `u-` ou `v-` no padrão dos mapas compilados. Aproxime-se pela frente do platô. Abra a face na passagem, feche as laterais da rampa com cunhas que terminam no pé e alinhe os dois patamares. Escada tem pisos e espelhos iguais. Caminho principal de duas células e chegadas sem decoração, NPC ou eventos no gargalo. |
| Lajes e andares | Dê a cada andar apoio, paredes em corte, perímetro de colisão, entrada, saída e ligação vertical. O mapa compilado guarda uma altura por célula. Para dois andares no mesmo `u,v`, use cenas ou áreas ligadas por escada/elevador conforme o consumidor, ou especifique superfícies independentes e seus conectores com o integrador. Identifique o andar no ponto de chegada; clique, movimento e seguidor devem usar a mesma superfície. Varanda, ponte ou laje precisa de espessura e sustentação reconhecíveis. |
| Muro de arrimo e guarda-corpo | Revestimento de arrimo segue a face estrutural. Mureta segue a aresta exposta, com cantos, pontas e abertura na chegada de rampas, pontes e escadas. Muro de divisa separado tem pegada bloqueante e portão explícito. |
| Ponte e passarela | Separe margem, cabeceiras e tabuleiro; encoste as duas pontas em terra firme. Verifique cota e material em cada emenda, sombra debaixo do tabuleiro e colisão nas bordas. Uma ponte com caminho passando por baixo precisa distinguir as superfícies, como os andares. |
| Água, poço e cachoeira | Declare cotas do lábio, da borda e da água. Use o mesmo contorno para recortar o chão e gerar as faces; a queda termina na água, com a espuma na superfície inferior. Margem próxima oclui a água. Use o [exemplo de poço da caverna](../../godot/scripts/overworld/cave_basin.gd). |
| Árvores, arbustos e capim | Organize grupos e clareiras, com portes variados. O pivô e a colisão da árvore pertencem à base do tronco; a copa é volume acima do chão. Teste Kael parado e em movimento à frente e atrás. Quando a copa encobrir o caminho principal, reduza o porte ou use o sistema de oclusores testado no consumidor. O mato de encontro precisa se distinguir da trilha segura. |
| Vinhas, trepadeiras e cipós | Prenda a raiz ou início ao piso, muro, tronco ou treliça. Prenda cada ponta suspensa ao volume que a sustenta. Separe a parte que pode cobrir Kael da parte pintada na parede, e use sombra sobre o plano correto. Decida se serve de decoração, barreira ou acesso. Se for escalável, a interação precisa de origem, destino, direção, desbloqueio e retorno implementados. Registre a dependência de mecânica e use um acesso jogável autorizado durante a blocagem. |
| Fachada, portas e interiores | Marque os três cantos visíveis da fundação e confira as duas arestas completas sobre o piso. Separe portal, cobertura, apoios e móveis altos conforme oclusão e interação. Em corte interno, veja onde o ator pode passar à frente e atrás de cada parte, inclusive ao abrir o mapa de um save antigo. |

Para cada encontro, confira sem texturas se a colisão coincide com o chão que aparece. Depois faça a mesma captura com arte. Quando houver fenda, parede atravessando o caminho ou chão sem apoio, corrija os vértices ou a cota que deram origem ao defeito.

## 5. Arte e peça-teste

- Leia o [guia de cenário](GUIA-DE-ESTILO-CENARIO.md). Importe a [paleta mestra](../../art/overworld/estilo/paleta-mestra.gpl) e a [extensão de cenário](../../art/overworld/estilo/paleta-cenario.gpl). Use luz de cima à esquerda, sombras em 2–3 tons por material, contorno cromático fino na silhueta e detalhes em agrupamentos legíveis. Preserve contraste para Kael e para os elementos interativos.
- Faça **um prédio e dois props** da região como peça-teste, conforme o pedido de produção. Escolha peças que exercitem o problema real daquela região: por exemplo, prédio em desnível, mureta com trepadeira e árvore contra a trilha. Mostre o prédio inteiro e os pontos de encaixe.
- Se recorrer à geração de imagem, forneça o concept, seus detalhes e a maquete sem textos como insumos. Use saída gerada como referência de acabamento; confira pegadas, silhueta e proporções no Godot. Redesenhe ou limpe os pixels no Aseprite na densidade final. Uma imagem com filtro de redução ainda precisa de trabalho de contorno, clusters e sombra.
- Entregue o quadro-chave, a fonte editável, `comparativo.png` (concept | arte | jogo atual ou referência anterior), `checklist.md` com todos os elementos numerados e a prova de convivência com Kael, Rabbito e um NPC em 1× e 2× nearest, em cor e em cinza. Aguarde aprovação da peça-teste antes do kit inteiro.

## 6. Kit, montagem e provas

1. Faça módulos reutilizáveis de chão, transições, bordas, rampas, laterais, quinas, cabeceiras, paredes e vegetação. Teste um conjunto 3×3 e as emendas entre materiais, quinas e cotas. Reuse os contratos do kit da região e registre `kit.json`, grade, retângulo de atlas, pivô, pegada, apoio, camada e material. Teste a composição de referência em 1× com nearest.
2. Em um marco fixo, o recorte do quadro-chave pode ser usado como no laboratório. Nesse caso, recomponha os recortes pelo manifesto e confira o PNG original pixel a pixel. Preencha as superfícies ocultas se o projeto exigir mover peças ou revelar o chão debaixo delas. Para uso jogável, divida a arquitetura e os móveis pelo que pode ocluir Kael em cada posição.
3. Integre somente quando a etapa e o responsável estiverem definidos. No Godot, prefira o construtor e o sistema de profundidade existentes. Posicione apoios, desenhe sombras na mesma superfície e confirme os limites de colisão contra os pontos de contato. Se o mapa substitui uma área existente, confirme o retorno, a saída e um checkpoint legítimo em perfil isolado.
4. Gere as provas no Godot com a [conferência zero quebra](../../.agents/skills/soulmonsters-construtor-de-mapas/references/conferencia-zero-quebra.md). Capture em 1280 × 720 a vista geral, cada entrada/saída, os pontos de decisão e os patamares em zoom de jogo. Faça versões em cores chapadas e com arte, e detalhes ≥2× de cada canto, junta, boca de rampa, escada, cabeceira, margem e encaixe de parede. Tire a captura da junta sem atores e uma segunda mostrando apoio e oclusão.
5. Percorra ida e volta com controle e com clique onde disponível. Confirme seguidor, interação com NPC e objeto, passagem entre andares, bloqueio de áreas fechadas, retorno pelo atalho e câmera nos limites da cena. Registre o que conseguiu jogar e o que só conferiu em imagem.

Comandos de referência, da raiz do checkout. Use o executável Godot instalado na máquina e um projeto aberto no `--path` correto.

```powershell
node --test tools/mapa-studio/model.test.mjs
godot --headless --path godot --script tests/overworld_checks.gd
godot --headless --path godot --script tests/morro_map_checks.gd
godot --path godot --rendering-method gl_compatibility --script tools/kronasta_bosque_capture.gd -- --out=<pasta-de-capturas>
```

O último comando é um modelo de captura, não um capturador de qualquer mapa. Adapte os pontos e o sinalizador de geometria ao construtor da área. Rodar teste headless confirma lógica; use render gráfico para as capturas. Guarde relatórios da região e separe os artefatos gerados de outras áreas para manter o commit legível.

## 7. Exemplos prontos no repositório

| Referência | O que copiar do processo |
| --- | --- |
| [Laboratório, etapa 1](../../art/professor-laboratorio-v2/ETAPA-1.md) e [planta interna](../../art/professor-laboratorio-v2/interior/planta.png) | Inventário por elemento, régua de Kael e revisão do espaço de circulação. |
| [Kit da fachada](../../art/professor-laboratorio-v2/fachada/kit/README.md) e [kit do interior](../../art/professor-laboratorio-v2/interior/kit/README.md) | Recorte visível para montagem fixa, manifesto, pivôs e remontagem comparada. |
| [Fachada em jogo](../../art/professor-laboratorio-v2/fachada/integracao/README.md) e [interior em jogo](../../art/professor-laboratorio-v2/interior/integracao/README.md) | Calibração de entradas, colisão, profundidade e provas de roteiro. |
| [Loja-piloto Linha & Papel](../../art/overworld/estilo/loja-piloto-v2/README.md) | Fachada redesenhada em pixel art, comparação de escala, teste em cor e cinza. |
| [Construtor do Bosque](../../godot/scripts/overworld/kronasta_forest.gd) e [capturas](../../godot/tools/kronasta_bosque_capture.gd) | Construção procedural sobre planta, terreno, árvores, câmeras e detalhes. |

Em cada portão, entregue os caminhos dos fontes, as capturas, o estado de aprovação, os testes dispostos por escopo e as pendências que afetam a etapa seguinte. Um commit por etapa em branch própria. Use o [pedido pronto para o agente](PEDIDO-AGENTE-MAPAS.md) para iniciar uma região.
