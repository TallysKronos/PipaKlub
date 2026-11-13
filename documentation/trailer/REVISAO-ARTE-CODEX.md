# Trailer v2 — revisão independente de arte

Revisão visual Codex, 13/11/2026. Esta é uma avaliação técnica/artística independente, não aprovação do dono. Gate solicitado: nota ≥ 7/10 e nenhum BLOCKING. A revisão não altera arte, documento ativo no Aseprite ou runtime.

## Referências e escopo

Lidos `TRAILER-V2-PEDIDO-CODEX.md`, `TRAILER-V2-ROTEIRO.md`, regras locais de produção e skill de personagens. Inspeção visual direta dos PNGs finais, preview, identidades e referências Locutor aprovado/Kael autoral. `portrait-tyler-manga-v1.png` foi usado para comparar o formato final da família existente. Não se deduziu qualidade visual de relatório de QA.

Autoridade de identidade: Mikka em `art/characters/mikka-overworld-v2/fonte.png`; Dona Neve em `art/characters/kronasta-oito-direcoes/serra/fontes/dona-neve.png`. Autoridade de acabamento: Locutor aprovado/Kael autoral da skill `soulmonsters-character-art`.

Eremor: a decisão comunicada pelo dono é somente silhueta e rugido, sem nome ou revelação pública. O pedido/roteiro ainda registra decisão pendente; essa redação antiga não reabre a decisão. A futura inspeção do rugido normal é interna e não autoriza sua exibição no trailer.

## Lote 1 — dois retratos

| Asset | Nota | BLOCKING | Gate | Primeira correção/polimento |
| --- | ---: | --- | --- | --- |
| `godot/assets/campaign/portrait-mikka-manga-v1.png` | 8/10 | Nenhum identificado | Passa na revisão de arte | Reduzir a granulação e as pequenas variações tonais da pele/cabelo para aproximar mais das massas limpas do Locutor. É polimento, sem necessidade de redesenhar identidade. |
| `godot/assets/campaign/portrait-dona-neve-manga-v1.png` | 8/10 | Nenhum identificado | Passa na revisão de arte | Reforçar discretamente as divisões acolchoadas do casaco de pinho, visíveis na identidade original, mantendo a linha leve e sem aumentar o ruído de dobras. |

### Mikka

Reconhecimento forte: duas tranças rosa com laços vermelhos, óculos redondos, blusa branca de mangas curtas e salopete oliva foram preservados. O rosto permanece jovem sem virar bebê; olhos, nariz simples e queixo suave cabem na linguagem do Kael/Locutor. Linha fina, sombra cel e mãos legíveis; sem acabamento 3D ou contorno de adesivo. O cabelo tem mais brilho e a imagem tem mais grão que o Locutor, mas o desvio não rompe a família.

O PNG final usa enquadramento vertical de cabeça a coxas e halo escuro como os retratos mangá existentes; o preview transparente é fonte de inspeção, não o arquivo final. As botas não aparecem nesse recorte, portanto não foram avaliadas nem sua ausência foi tratada como falha. Os óculos mantêm leitura facial e conexão com as hastes.

### Dona Neve

Pele média quente, idade adulta mais velha, cabelo prateado reunido em coque baixo trançado, casaco verde profundo, gola/punhos escuros e calça bordô mantêm a pessoa da referência. As marcas discretas do rosto comunicam idade sem anatomia realista excessiva. Não há infantilização, troca de pele ou mudança de penteado. A silhueta do casaco e os botões estão claros; o acolchoamento da fonte ficou mais liso no retrato e é o primeiro ajuste de fidelidade possível.

Enquadramento, halo e densidade geral são compatíveis com Tyler e com a nova Mikka. Os dedos e punhos permanecem legíveis. Pequena textura/granulação merece o mesmo polimento opcional de Mikka para unificar o acabamento limpo.

## Limites e próximos lotes

Esta passagem verifica arte estática nos arquivos, identidade e coerência da família. Não inclui captura no Godot, leitura final no quadro de vídeo, aprovação humana ou animação. Os quatro retratos restantes, quatro ilustrações, seis folhas nativas de criaturas, rugido e FX ainda aguardam notificação e inspeção visual própria.

## Lote 2 — seis gerações originais de overworld

Inspeção direta dos seis `geracao.png` e respectivos `normalizacao.json`. Para Vertim, Trincaguarda e Urso-polar jovem, comparação com `concept-v1/concept.png` da respectiva forma; para Carcará, `carcara-family-v1/references/carcara-identity.png`; para Mata Verde e Rabbito, concepts `art/soulgen/keys/<id>/color-rig-v2/concept.png`. Rabbito também foi comparado à folha canônica local `pipa-club-integracao-atualizada/art/creatures/soulmonsters-overworld-v2/rabbito/duas-vistas.png`. A condição approved/proposed dos manifests históricos foi lida; esta revisão não promove concepts propostos a aprovação do dono.

Os caminhos abaixo são relativos a `art/creatures/` e terminam em `/overworld-diagonal-v1/geracao.png`. Frente SW significa rosto apontando para a esquerda/observador; costas NW significa cabeça apontando para esquerda/fundo e ausência do rosto.

| Família/forma | Nota | Vista esquerda | Vista direita | BLOCKING / primeira correção | Gate da geração |
| --- | ---: | --- | --- | --- | --- |
| `estratonte-family-v1/vertim` | 8/10 | Frente SW correta | Costas NW correta, sem rosto | Nenhum; recuperar a grade no conversor e conferir contorno no tamanho nativo. | Passa |
| `trinca-brasas-family-v1/trincaguarda` | 8/10 | Frente SW correta; três cabeças legíveis | Costas NW correta; três nucas sem olhos/focinhos | Nenhum; conferir separação das três chaves e cabeças após redução. | Passa |
| `urso-polar-family-v1/urso-polar-young` | 8/10 | Frente SW correta | Costas NW correta; nuca sem rosto | Nenhum; conferir nós vermelhos e separação das patas na conversão. | Passa |
| `carcara-family-v1/carcara` | 6/10 | **Frente SE, bico para a direita** | Costas NW plausível, sem rosto | **BLOCKING:** direção frontal contradiz `front-sw` e o pedido. Espelhar horizontalmente somente a vista frontal antes da conversão. | Não passa ainda |
| `mata-verde-family-v1/mata-verde` | 8/10 | Frente SW correta | Costas NW correta, sem rosto | Nenhum; preservar lado dos remendos, não espelhar a folha inteira. | Passa |
| `rabbito-family-v1/rabbito` | 8/10 | Frente SW correta | Costas NW correta, sem rosto | Nenhum; preservar remendos de orelha/flanco e duas rabiolas na conversão. | Passa |

### Identidade e construção

Vertim conserva pescoço longo, corpo arredondado, lilás/creme/menta, arcos sobre o corpo, nós e dois losangos pendurados na cauda. Trincaguarda conserva as três cabeças, preto-violeta/laranja, coração turquesa, três chaves e cauda trançada com três pipas. Urso conserva proporção quadrúpede pesada, gola alta vermelha por dentro, capa turquesa, bordas douradas, nós vermelhos, braceletes e cauda de duas folhas. Não encontrei invenção estrutural que troque essas identidades.

Carcará mantém corpo de pipa laranja/creme/castanho, bico amarelo, asas curtas e rabiola dupla. A frente aponta para direita; não basta renomear o JSON. A referência canônica inspecionada não mostra um remendo ou ornamento unilateral que impeça espelhar essa frente. Portanto um flip horizontal **por vista** é aceitável para obter SW, mantendo a ordem frente à esquerda/costas à direita. O consumidor atual `converter-overworld.mjs` apenas recorta as regiões e não lê propriedade de flip; adicionar metadado sem aplicar no consumidor não resolve o bloqueio. Preservar o original e registrar a transformação no preparo/consumidor é uma correção possível. Não espelhar a folha inteira, pois isso inverte também as costas.

Mata Verde conserva corpo de folha/pipa, três folhas superiores, asas de folhas, rabiola única e remendos. Os remendos são assimetria de identidade; nenhum flip adicional é indicado. Rabbito conserva orelhas de pipa turquesa/creme, haste dourada, remendos, gola e duas rabiolas com laços. O concept de combate é mais ereto, mas a pequena folha de overworld canônica já usa o apoio compacto com patas dianteiras baixas. A diferença de pose entre combate e overworld, neste caso, não exige redesenho.

### Alpha, grade e limite desta passagem

O visualizador direto exibiu halos difusos em torno de Vertim/Urso. A inspeção de pixels encontrou RGB oculto em alpha zero; uma composição diagnóstica real desses dois PNGs sobre fundo verde-cinza mostrou os arredores limpos. Não há BLOCKING de halo visível nessa composição, e não se deve redesenhar por causa da visualização de RGB oculto. Há alpha parcial, sobretudo nas bordas: a geração original ainda precisa da recuperação/limpeza normal do conversor. A composição diagnóstica não alterou fontes e foi removida depois da inspeção.

Os blocos são marcados visualmente e os contornos escuros leem na geração. Isso não certifica uma grade uniforme de um pixel lógico nem contorno final de um bloco: são originais grandes destinados à recuperação por `xprite`, não sprites nativos prontos. Não executar o conversor nem editar o Aseprite foi parte do escopo desta revisão. Reavaliar as seis folhas nativas após conversão, principalmente olhos, chaves, remendos, nós, ancoragem e escala frente/costas. Carcará fica bloqueado até a correção de direção ser aplicada e visualmente reinspecionada.

## Lote 3 — quatro retratos, impact frame e onda do rugido

Inspeção dos PNGs finais e fontes de identidade, sem editar arte. Ícaro foi comparado a `art/characters/kronasta-oito-direcoes/mirante/fontes/icaro.png`; Nina à prancha `art/characters/npc-manga-sheets-v2/nina-sheet.png`; Retalho à figura principal aprovada de `art/soulgen/campaign-redesigns-v1/retalho-mascarada/concept-v2/prancha.png`; Tufanocorte às peças e fonte `art/soulgen/keys/tufanocorte/cutout-rig-v1/source.png`. Os prompts de proveniência também foram lidos. O impacto foi comparado ao concept canônico color-rig-v2 do Rabbito.

| Asset | Nota | BLOCKING | Gate | Primeira correção necessária |
| --- | ---: | --- | --- | --- |
| `portrait-icaro-manga-v1.png` | 8/10 | Nenhum identificado | Passa | Nenhuma para este gate |
| `portrait-nina-manga-v1.png` | 8/10 | Nenhum identificado | Passa | Nenhuma para este gate |
| `portrait-retalho-manga-v1.png` | 8/10 | Nenhum identificado | Passa | Nenhuma para este gate |
| `portrait-tufanocorte-manga-v1.png` | 8/10 | Nenhum identificado | Passa | Nenhuma para este gate |
| `art/trailer-v2/impact-especial-rabbito.png` | 9/10 | Nenhum identificado | Passa | Nenhuma para este gate |
| `godot/assets/campaign/eremor-onda-rugido-v1.png` | 7/10 | Nenhum identificado na sequência isolada | Passa | Nenhuma para este gate; verificar contraste e escala na arena |

Os quatro retratos estão em `godot/assets/campaign/`. Ícaro mantém franja assimétrica cobrindo um olho, pele quente, único brinco âmbar, jaqueta ocre com faixas brancas, camiseta escura e cinto. Nina mantém pele, cabelo cacheado alto, fita turquesa, camisa amarela aberta, short escuro e bolsa com rolos/varetas. Linha delicada, sombras econômicas e rostos individuais são coerentes com a família já revisada.

Retalho reproduz a **forma mascarada** da prancha autorizada: máscara lateral longa ameixa, olho amarelo, dorso curvado creme de papel, orelhas assimétricas de pipa/bambu, nós dourados, braços estreitos com garras e cicatrizes de losangos interrompidos. A máscara não foi removida nem foi utilizada a identidade original oculta. Tufanocorte mantém cabeça verde pontuda, focinho/peito creme, duas espirais enormes em creme/dourado/laranja/azul-petróleo e cauda em espiral. As duas espirais cabem no retrato e não surgiu asa ou roupa humana.

O impact frame é 1920×1080, P&B com retícula, linhas radiais e gesto de golpe central claramente legível. O Rabbito tem orelhas construídas com varetas e nós, remendo da orelha, remendo do flanco, gola de papel e rabiola dupla com laços. Não é um coelho genérico. A densidade de linhas é apropriada a um quadro de impacto breve; rosto e ataque continuam destacados.

### Onda do rugido

O JSON define 12 células 512×512 em faixa 6144×512, tag `roar-shockwave`, duração total de 1.10 s e camadas shockwave/dust. Foram inspecionados a faixa completa e frames 0, 2, 4, 6, 8 e 11 compostos no tamanho de célula sobre fundo escuro neutro. O anel elíptico frio cresce de forma contínua e se rompe no final; pequenas massas cinza de poeira acompanham a borda e desaparecem. O fundo é transparente na composição e o centro permanece vazio para sobrepor à criatura/arena.

A solução lê como onda simples e passa no mínimo de 7/10. Os tufos são pequenos e regulares e o anel é fino: a força do rugido depende também da escala, contraste sobre o piso e rachadura dos quadros na montagem. Isso é limite de acabamento/contexto, não defeito impeditivo identificado nesta sequência. Não certifico a leitura na arena nem sincronia com áudio sem uma captura composta no jogo. O diagnóstico temporário foi removido; nenhuma operação foi feita no documento Aseprite ativo.

## Lote 4 — seis folhas nativas e rugido normal

Revisão visual dos seis PNGs de `godot/assets/campaign/overworld-companions-v2/` na resolução original 224×112 e ampliação nearest-neighbor sobre fundo cinza. Comparação às gerações/identidades já descritas; sem editar folhas ou Aseprite.

| Folha | Nota | BLOCKING | Gate | Primeiro ajuste |
| --- | ---: | --- | --- | --- |
| `vertim.png` | 7.5/10 | Nenhum identificado | Passa | Nenhum necessário para o gate |
| `trincaguarda.png` | 7.5/10 | Nenhum identificado | Passa | Nenhum necessário para o gate |
| `urso-polar-young.png` | 8/10 | Nenhum identificado | Passa | Remover pequeno fragmento turquesa isolado à esquerda da vista de costas; limpeza pontual, sem redesenho |
| `carcara.png` | 8/10 | Nenhum identificado após correção | Passa | Nenhum necessário para o gate |
| `mata-verde.png` | 8/10 | Nenhum identificado | Passa | Nenhum necessário para o gate |
| `rabbito.png` | 8/10 | Nenhum identificado | Passa | Nenhum necessário para o gate |

**Carcará desbloqueado:** no PNG convertido, a frente efetivamente aponta SW/esquerda e as costas permanecem NW. A transformação foi aplicada somente à frente; a inspeção da imagem confirma a correção, independentemente do metadado `flip_x`.

Todos mantêm frente à esquerda/costas à direita; não há olhos/focinho desenhados nas nucas. Vertim preserva seu pescoço e corpo arredondado; a redução comprime olhos e nós, mas ainda se reconhece. Trincaguarda é o mais denso: três cabeças se distinguem na frente, três nucas nas costas e coração turquesa dá foco. As três chaves viram pequenos sinais dourados, coerente com o tamanho nativo. Urso mantém massa pesada e capa/braceletes; o pequeno fragmento turquesa separado é limpeza recomendada, sem alteração de identidade.

As alturas frente/costas informadas (55/57, 69/63, 70/72, 55/55, 55/55 e 52/54) não foram usadas como reprovação automática. A inspeção mostra volume compatível entre vistas. Trincaguarda tem costas um pouco mais compactas, explicadas pela pose/oclusão das cabeças e cauda; não há salto material de escala. Carcará, Mata Verde e Rabbito preservam forma de pipa, remendos principais, rabiolas e rosto limpo na frente. A paleta reduzida produz alguns degraus de cor, sem ruído que troque a criatura. Esta passagem verifica folhas estáticas; caminhar em cena continua sendo uma validação distinta.

### Rugido normal — uso interno

`godot/assets/campaign/eremor-rugido-v1.png`: **8/10, sem BLOCKING, passa no gate artístico interno**. Inspeção de todos os oito quadros, compostos individualmente na célula 350×313 sobre cinza, comparados à folha `combat-eremor.png`. JSON lido para dimensões/tempos. Oito estados mostram repouso, elevação/inspiração, abertura da boca, três intensidades do rugido e retorno/recuo. Cabeça sobe com pescoço, mandíbula abre sem duplicar dentes ou focinho e patas continuam apoiadas. Painéis de pipa do dorso, nós, listras creme/vermelho/azul profundo, garras e cauda mantêm a identidade e escala de combate; não há membros extras ou ornamentos inventados.

O ciclo tem variação de gesto efetiva, em vez de apenas translação da mesma imagem. A montagem de quadros permite avaliar continuidade de anatomia e âncora; não equivale à reprodução no Godot nem sincronização final com som. O sprite normal continua **fora da autorização pública do trailer**: somente a variante em silhueta pode ser usada no bloco do lendário, sem nome/revelação. A silhueta ainda aguarda inspeção própria.

## Lote 5 — abertura, céu e fecho

Inspeção direta das três ilustrações finais 1920×1080, respectivos prompts e atlas canônico `godot/assets/campaign/maps/kronasta-atlas-manga-v3.png`; identidades de Kael/Rabbito já inspecionadas nos lotes anteriores. Nenhuma alteração de arte ou Aseprite.

| Asset em `art/trailer-v2/` | Nota | BLOCKING | Gate | Primeira correção necessária |
| --- | ---: | --- | --- | --- |
| `abertura-carretel.png` | 8/10 | Nenhum identificado | Passa | Nenhuma para este gate |
| `kronasta-ceu.png` | 8/10 | Nenhum identificado | Passa | Nenhuma para este gate |
| `fecho-estadio.png` | 8/10 | Nenhum identificado | Passa | Nenhuma para este gate |

A abertura mostra somente as duas mãos/antebraços do Kael com manga azul e punho branco. A mão esquerda apoia a lateral de madeira; a direita pinça o laço junto à barra inferior. Não identifiquei dedo extra ou ferramenta desconectada. Os dedos parcialmente ocultos pela madeira correspondem à empunhadura, sem exigir que todos apareçam. Barras unem as laterais e dão eixo/apoio à linha enrolada; a rabiola prende ao nó e a linha esticada sai do quadro pelo alto à direita. Nó e gesto ficam em área central legível. O fundo de oficina tem textura e profundidade suave mais ricas que os retratos, mas mãos/contornos/sombras continuam 2D mangá, sem aparência de render 3D.

O céu apresenta muitas pipas de papel de formatos e cores diferentes, com linhas e rabiolas, sobre telhados de barro, tijolo aparente, reboco, caixas-d'água, postes, vegetação tropical e costa. O estádio oval e os acidentes de relevo remetem ao atlas; não virou arquitetura japonesa ou cidade medieval. O céu ocupa aproximadamente a metade superior e fornece campo amplo às pipas. O detalhamento do bairro é alto, mas a leitura geral de panorama e pipas sobrevive ao enquadramento 16:9.

No fecho, Kael e Rabbito estão integralmente de costas, com pés/corpo apoiados no mirante. Kael conserva cabelo azul, fones turquesa no pescoço, jaqueta azul com faixas claras e duas abas longas, calça cinza e botas. Rabbito conserva orelhas de pipa com varetas/nós, corpo de papel creme/turquesa, gola/capa, remendo e rabiola dupla amarela; não foi substituído por mascote de pelúcia. O estádio replica os sinais do atlas: oval aberto, arcadas claras, anel vermelho de arquibancada, refletores, bandeiras vermelhas e escadaria frontal. Porto, pântano e falésias também remetem ao atlas. O pôr do sol e a composição destacam a dupla e o estádio; rostos não são revelados pela pose. A inserção final do logo e o recorte/movimento de câmera ainda precisam de conferência na montagem, sem alterar o gate desta ilustração.

O impacto já revisado permanece em 9/10. O pacote completo não é declarado concluído nesta passagem: silhueta do rugido e eventuais correções novas ainda dependem de inspeção própria; aprovação humana e captura final permanecem distintas da avaliação dos arquivos.

## Lote 6 — silhueta pública do rugido

`godot/assets/campaign/eremor-rugido-silhueta-v1.png`: **8/10, nenhum BLOCKING identificado, passa no gate artístico da variante pública**. Foram inspecionados todos os oito quadros da faixa e compostos individualmente em fundo cinza/marrom. JSON confirma células 350×313, 2.9 s, sem loop e pivô (175,285), compatíveis com o ciclo normal.

O preenchimento é preto e uniforme; a borda externa é fria e fina. Não há olhos luminosos, cores locais, cicatrizes, desenhos dos painéis ou detalhes internos que revelem a identidade. A abertura da boca é lida apenas como mudança de contorno. Cabeça sobe, o vão da boca aumenta e se fecha, e o apoio/pivô se mantém. Não surgem membros, rosto interno ou nome desenhado na arte. Fundo transparente funciona na composição.

Esta é a variante prevista para o uso público do bloco do lendário. Manter a montagem sem nome e sem alternar para o rugido colorido/normal. O nome técnico do arquivo não precisa aparecer em texto de tela. A borda fina pede conferência de contraste no fundo real das ruínas, mas não identifiquei falha impeditiva no arquivo. A composição temporária foi removida; fontes e Aseprite permaneceram intactos.

Situação desta revisão: os assets de arte solicitados e anunciados até este lote passaram no gate independente, incluindo a correção do Carcará. FX opcional de vento do Rabbito ainda não foi recebido/revisado. Este registro não substitui revisão da captura final, sincronização audiovisual ou aprovação do dono.

## Lote 7 — comparação cega de apoio, vento do Rabbito e lettering

### Apoio do rugido — escolha cega

Arquivos avaliados em `tmp/trailer-sprite-alignment/`, sem consultar chave do artista: **normal = B; silhueta = A**. Ambos mantêm **8/10, sem BLOCKING na alternativa selecionada**. A referência fornecida para o apoio original é y=284 na célula 350×313.

Na comparação visual, B-normal mantém os pés na mesma cota e A-silhouette acompanha o corpo com a borda externa adicional. A medição de pixels alpha>128 confirma o último pixel em y=284 nos oito quadros de B-normal; A-normal termina em y=288–289. A-silhouette termina em y=285, coerente com um pixel de borda externa ao corpo y=284; B-silhouette termina em y=289–290. A alternativa escolhida resolve o deslocamento do apoio sem alterar o gesto.

Comparação RGBA dos pixels visíveis confirmou **zero diferenças após somente translação**: A-normal→B-normal e B-silhouette→A-silhouette usam dx=-4 e dy=-4 nos quadros 1–3, dy=-5 nos demais (índices iniciados em zero). Nenhuma repintura de anatomia foi necessária, e normal/silhueta recebem a mesma translação por quadro. Esta conclusão seleciona os candidatos cegos; a instalação dos candidatos escolhidos nos caminhos finais é responsabilidade da integração e não foi executada nesta revisão.

### FX opcional do Rabbito

`godot/assets/campaign/rabbito-rastro-v1.png`: **8/10, sem BLOCKING, passa**. Seis células 512×512, total 0.533 s pelos tempos do JSON, sem loop. Todos os seis quadros foram inspecionados em composição sobre fundo escuro, além da faixa original. Três arcos de vento ciano/marfim surgem pequenos, expandem, engrossam no pico e afinam até desaparecer. Aberturas entre os arcos e centro vazio permitem sobreposição ao golpe. Não há fundo opaco, mascote inventado, texto ou detalhe que substitua a identidade do Rabbito. É um efeito simples e legível; posição/escala/sincronia do golpe ainda dependem da captura na arena.

### Sete onomatopeias e duas texturas

Inspeção dos PNGs reais, previews de lettering/velocidade e composições sobre fundos sólidos diferentes. Os checkerboards dos previews não estão gravados nas artes; a composição das letras e das texturas revela o fundo sólido por baixo. Letras pretas com borda branca têm peso e recorte consistentes, traço inclinado/angular e sinais auxiliares de impacto. Os caracteres não se fundem a ponto de impedir a leitura.

| Asset | Texto visual conferido | Nota | BLOCKING / gate |
| --- | --- | ---: | --- |
| `onomatopeias/tsk.png` | TSK | 8/10 | Nenhum; passa |
| `onomatopeias/zaak.png` | ZAAK | 8/10 | Nenhum; passa |
| `onomatopeias/fwush.png` | FWUSH | 8/10 | Nenhum; passa |
| `onomatopeias/krak.png` | KRAK | 8/10 | Nenhum; passa |
| `onomatopeias/vuuum.png` | VUUUM | 8/10 | Nenhum; passa |
| `onomatopeias/splash.png` | SPLASH | 8/10 | Nenhum; passa |
| `onomatopeias/grrraaaooo.png` | GRRRAAAOOO | 8/10 | Nenhum; passa |
| `onomatopeias/grrraaaooo-01.png` a `-03.png` | Três partes do mesmo GRRRAAAOOO | 8/10 | Nenhum; passa |
| `linhas-velocidade-horizontal.png` | Linhas horizontais | 8/10 | Nenhum; passa |
| `linhas-velocidade-radial.png` | Linhas radiais | 8/10 | Nenhum; passa |

Todos os caminhos dessa tabela partem de `art/trailer-v2/`. As sete palavras completas são PNG 1536×1024. As três partes do rugido são 512×1024 cada: a concatenação reconstitui exatamente o PNG completo (zero diferenças RGBA), sem letra omitida ou repetida. Cortes atravessando o lettering servem à separação/rachadura solicitada e precisam ser posicionados sem espaçamento até a animação de ruptura.

As duas texturas têm 1920×1080, alpha real e centro aberto. A horizontal deixa espaço à ação no meio; a radial converge à área central sem cobri-la. Inspeção composta sobre fundo bege mostrou apenas linhas pretas e transparência, sem checkerboard falso nem painel branco. A legibilidade das sete palavras e o contraste das linhas devem ser mantidos no tamanho final da montagem. Não há correção de arte necessária para atingir este gate.

### Estado final desta revisão independente

Todos os assets anunciados, incluindo o vento opcional, passaram no gate de nota mínima 7/10 sem BLOCKING pendente de arte, **considerando a seleção B-normal/A-silhouette na correção de apoio**. A normal colorida continua restrita ao uso interno; a silhueta é a variante pública, sem nome. O relatório não declara gravação pronta, aprovação humana, integração dos candidatos cegos ou sincronização audiovisual verificada. Fontes/Aseprite não foram modificados; composições diagnósticas temporárias foram removidas.
