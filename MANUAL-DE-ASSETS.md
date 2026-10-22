# PipaKlub | Manual mestre de produção de assets

**Versão 1.0 · 18 de outubro de 2026**

**Adendo de direção · 21/10/2026:** a franquia é **Soulmonsters**, com título atual em concepção **Elo das Ruínas**. **Elo** é a palavra recorrente dos jogos, ligada ao vínculo entre humano e Soulmonster; PipaKlub é o clube do universo. Para identidade, desenho de personagens e criaturas e proposta de acabamento das novas artes, consultar [DIRECAO-DE-ARTE.md](DIRECAO-DE-ARTE.md). As regras técnicas deste manual permanecem aplicáveis. O PDF anterior não contém este adendo.

**Escopo:** direção de arte, geração, edição, preparação, animação, integração e auditoria de todos os assets do jogo.

**Público:** direção, artistas, animadores, designers de interface, desenvolvedores e agentes de IA.

Este é o documento central para novas produções. Ele consolida as decisões do projeto e os defeitos observados em uso real. Deve acompanhar qualquer briefing entregue a um desenhista ou gerador de imagens. O Markdown é a fonte editável; o PDF é uma edição de consulta do mesmo conteúdo.

## 01. Como interpretar e aplicar este manual

### 01.1 Três níveis de regra

- **Obrigatório:** requisito para aceitar uma nova entrega, salvo mudança explícita de direção pelo responsável pelo jogo.
- **Referência atual:** descreve o que o repositório e seus consumidores fazem nesta revisão. Não é promessa de que um formato servirá para todos os sistemas futuros.
- **Padrão inicial recomendado:** ponto de partida para uma nova produção. Deve ser ajustado ao tamanho em tela e à medição real, sem ser apresentado como limite já implementado no motor.

As regras artísticas deste documento não implementam código, poderes, drops, raridades ou permissões. Um desenho de um escudo não cria uma habilidade de defesa. Uma ficha na Dex não concede a criatura ao jogador. Um arquivo presente no disco não está necessariamente carregado no jogo.

### 01.2 Ordem de autoridade

1. Pedido explícito e mais recente do responsável pelo projeto.
2. Identidade visual aprovada do personagem, cenário ou família de componentes.
3. Contrato real do consumidor: manifesto, catálogo, renderizador e regras do servidor.
4. Este manual para decisões de produção e aceitação.
5. Documentos antigos e referências externas, usados como contexto.

Se um documento antigo disser que Kael não está no jogo, mas o overworld atual já o usa, o consumidor atual prevalece. Se a imagem pedida tiver tamanho diferente do arquivo entregue pelo gerador, as dimensões reais do PNG prevalecem. Registrar a divergência e atualizar a documentação, em vez de adaptar silenciosamente o sentido da regra.

### 01.3 Estado de uma entrega

Usar estes estados no registro de produção: **briefing**, **conceito**, **em revisão**, **aprovado artisticamente**, **validado tecnicamente**, **integrado localmente**, **publicado** e **substituído**. Uma entrega pode ter aprovação artística e ainda falhar tecnicamente. Validação geométrica não equivale a aprovação artística.

**Exemplo:** um spritesheet com 16 células válidas e uma cauda solta continua em revisão. Um muro sem vãos entre retângulos, mas com pedras que reiniciam a cada módulo, também continua em revisão.

## 02. Identidade do PipaKlub

### 02.1 O universo

PipaKlub é papel, vento, vínculos e vida de bairro. Quintais, telhados de barro, linhas, carretéis, varetas, remendos e rabiolas sustentam sua identidade. Kronasta precisa parecer um lugar habitado, com hábitos e usos reconhecíveis, não uma coleção de construções decorativas sem função.

Conforme a definição mais recente do universo, **a linha é o método de manifestação e todo Soulmonster deve incorporar anatomia de pipa**, seja por traços de construção, asas/velas, dobras, estrutura, nós ou rabiola. A espécie inspira a silhueta; a construção de pipa integra seu corpo. Variar a solução entre espécies, sem exigir o mesmo conjunto de peças em todas. Uma pipa apenas decorativa nas costas de um animal convencional não basta. Preservar as identidades existentes até uma substituição aprovada.

### 02.2 Acabamento de jogo

**Atualização:** para novas pranchas de personagens e criaturas, a proposta de [bíblia visual](DIRECAO-DE-ARTE.md) usa anime 2D simples e sombras de cel animation. As descrições abaixo registram a família de assets anterior e continuam úteis ao preparar sprites compatíveis. Facetas de papel não devem ser aplicadas indiscriminadamente a pele, pelo ou tecido. A prancha piloto do novo acabamento ainda precisa de revisão artística.

- Ilustração 2D com contorno escuro limpo, sombras em planos e bordas nítidas, entre desenho de aventura e pixel art refinada.
- Detalhe concentrado no rosto, na silhueta e nos pontos de interesse. Evitar ruído uniforme em toda a superfície.
- Três ou quatro tons principais por material como ponto de partida; quatro a seis famílias de cor por criatura geralmente bastam.
- Volume sugerido por planos de papel, dobras, sobreposição e contraste. Evitar render plástico 3D, metal fotorrealista e iluminação de cinema em todos os assets.
- Textura deve sobreviver à redução. Pontilhar uma imagem para parecer pixel art não substitui desenho em grupos de pixels coerentes.
- Personagens, UI e cenário devem pertencer ao mesmo mundo, com densidades de detalhe adequadas a suas funções.

### 02.3 Paleta e materiais

Base do mundo: creme de papel e reboco, terracota, azul-petróleo, verdes de quintal e amarelo de sol. Cores de espécie, evento e habilidade podem ampliar essa base sem tornar todos os elementos igualmente saturados.

| Material | Tratamento visual | Reprovar quando |
| --- | --- | --- |
| Papel | Planos claros, dobras e remendos controlados | Parece plástico brilhante ou tecido molhado |
| Bambu e vareta | Estrutura fina, nós e conexão funcional | Ornamento sem apoio ou espessura variável sem motivo |
| Linha e corda | Curva legível, tensão e ancoragem | Parece barra rígida ou atravessa o corpo sem conexão |
| Rabiola | Fitas com continuidade e direção do vento | Fragmentos soltos ou pontas que trocam entre frames |
| Madeira | Massa simples, desgaste localizado | Textura realista compete com o rosto e a interface |
| Pedra e reboco | Planos quentes e juntas legíveis | Blocos criam degraus involuntários nas emendas |
| Metal e gema | Acento de contraste, uso seletivo | Todas as criaturas recebem a mesma coroa, sino e cristal |

As cores exatas da interface vêm do kit e do CSS vigente. Não criar outra paleta global para um único asset. Um conceito pode propor cores novas, mas sua aprovação precisa considerar o conjunto em tela.

### 02.4 Hierarquia visual

O jogador deve reconhecer primeiro a ação, depois seu personagem e alvo, depois os elementos de navegação e, por último, a decoração. Um arbusto não pode ter mais contraste que o personagem que passa à sua frente. Um efeito de habilidade não pode esconder a região da linha necessária para decidir um ataque.

## 03. Referências e briefing obrigatório

### 03.1 Dar uma função para cada referência

- **Identidade:** define rosto, anatomia, roupa, marcas e acessórios de um personagem aprovado.
- **Estilo:** define acabamento, contorno, densidade e forma de sombrear.
- **Composição:** define câmera, posicionamento, profundidade e distribuição dos elementos.
- **Técnica:** mostra como tiles, cortes, pivôs ou componentes se conectam.

Não misturar esses papéis. Uma referência do Sr. Assis usada para acabamento não autoriza dar jaleco e óculos a Kael. Uma imagem de atlas serve para entender encaixes; não obriga copiar seus materiais. Referências de animes orientam linguagem visual, não a reprodução de personagens, símbolos ou marcas de terceiros.

### 03.2 Ficha mínima antes de gerar

Registrar: ID estável; nome; categoria; uso e tela; referências e seus papéis; traços obrigatórios; dimensão de uso; tamanho solicitado da fonte; fundo/alpha; orientação e câmera; estados ou conexões; margens; pivô e apoio; arquivos esperados; responsável pela revisão; critérios de reprovação; status de integração.

**Exemplo de decisão útil:** "botão primário para textos de 4 a 24 caracteres, alvo de 64 px no kit atual, com pontas fixas e centro expansível". "Botão bonito e premium" não fornece um contrato suficiente.

### 03.3 Entender o uso antes de aumentar a resolução

Separar tamanho de fonte, tamanho da célula, tamanho da silhueta e tamanho em tela. Um PNG de 1500 px não garante rosto legível a 48 px. Desenhar primeiro o que deve sobreviver à miniatura e reservar detalhe para superfícies maiores.

Não pedir uma prancha com conceito, paleta, história, vistas, miniaturas e animações se o consumidor espera um asset limpo. Materiais de apresentação e texturas de produção são entregas diferentes.

## 04. Pipeline de produção

### 04.1 Etapas

1. Ler a referência aprovada e o contrato do consumidor atual.
2. Preencher o briefing e escolher a família visual existente.
3. Gerar ou desenhar o conceito, quando ainda não houver identidade aprovada.
4. Revisar silhueta, materiais e identidade no tamanho de uso.
5. Produzir a folha, as partes ou variantes necessárias ao contrato.
6. Medir o arquivo efetivamente recebido e registrar recortes e apoios.
7. Revisar frames, emendas e estados na prévia apropriada.
8. Executar a validação técnica e registrar pendências.
9. Integrar em ambiente local, quando essa etapa fizer parte do pedido.
10. Auditar a tela, o mapa ou a animação dentro do jogo.
11. Publicar somente no escopo autorizado e verificar o resultado servido.

### 04.2 Geração e edição por IA

Para arte raster nova ou edição artística, usar a ferramenta integrada image_gen no fluxo atual. Não exigir uma chave de API para usar essa ferramenta. Quando um arquivo local for alvo de edição, inspecioná-lo antes. Para uma família de criaturas, preferir uma geração por personagem; folhas conjuntas favorecem mistura de identidade e escala.

Prompts precisam definir invariantes e finalidade, além do estilo. Em uma correção, declarar o que muda e o que permanece. Exemplo: corrigir apenas a conexão da cauda nos quatro frames da segunda linha, preservando as demais poses e o desenho aprovado.

Preservar o original. Medição de alpha, cálculo de atlas, recorte mecânico autorizado e empacotamento não são repintura. Não usar scripts para inventar anatomia, apagar fundos por cor ou reconstruir artisticamente um asset sem uma decisão explícita de técnica. Vetores geométricos são adequados para glifos, barras e diagramas, não substitutos improvisados de criaturas pintadas.

### 04.3 Iteração com diagnóstico

Cada revisão deve indicar um defeito concreto: rosto alterado, membro extra, margem invadida, halo, espessura inconsistente ou apoio incorreto. Não solicitar "mais qualidade" sem explicar o que falhou. Após duas correções dirigidas sem resolver o mesmo problema, manter as versões e registrar a pendência; não declarar a folha pronta por exaustão. Trabalho adicional pode continuar quando solicitado.

## 05. Arquivos, transparência e cores

### 05.1 Formatos

| Entrega | Padrão de produção | Observação |
| --- | --- | --- |
| Sprite, objeto, ícone pintado, HUD | PNG RGBA | Alpha real; conservar o original aprovado |
| Fundo opaco | PNG ou formato já aceito pelo consumidor | Muitos caminhos atuais servem PNG explicitamente |
| Glifo geométrico e selo de UI | SVG existente ou vetor validado | Conferir o registro e o componente que o consome |
| Atlas e metadados | JSON UTF-8 | Coordenadas e dimensões efetivas |
| Mapa modular | TMJ/JSON do contrato atual | Seis camadas de objetos retangulares |
| Prévia e auditoria | HTML/JS, relatório JSON e capturas | Não são texturas do jogo |
| Pacote de entrega | Pasta e ZIP, quando útil | O ZIP não substitui os arquivos e registros de origem |

Não mudar um PNG para WebP, KTX, AVIF ou textura comprimida apenas por preferência do artista. Isso exige suporte do pipeline e testes de decodificação, alpha e memória. Não usar JPEG para sprites com transparência.

### 05.2 Alpha verdadeiro

Exterior e vazios devem ter alpha zero quando transparentes. Papel creme, olhos brancos e faixas de múmia permanecem visíveis. Um fundo quadriculado pintado não é transparência. Um fundo preto também não é alpha. Remover todo pixel branco ou preto destruiria partes legítimas do desenho.

Inspecionar sobre fundo claro, escuro, uma cor saturada de diagnóstico e o fundo real do jogo. Reprovar halo branco, franja colorida visível, recorte duro indevido e sombra que aparenta piso flutuante. RGB colorido em alpha zero não é um fundo opaco; avaliar a contribuição visível, inclusive de pixels com alpha baixo.

O limite de alpha usado para medir a silhueta deve estar no relatório. Ele não autoriza ignorar resíduos visíveis abaixo desse limite. Alguns originais têm alpha máximo 253 ou 254: não rejeitar automaticamente nem alterar pixels apenas para forçar 255.

### 05.3 Integridade e tamanho real

Ler largura, altura, modo de cor e recortes no arquivo entregue. Não confiar no nome, no tamanho pedido ou numa grade suposta. Um arquivo de 1254 px dividido em quatro colunas precisa distribuir os limites em inteiros, com larguras de 313 e 314 px. Nenhuma célula pode ficar fora da textura.

Exportar em RGB/RGBA, com aparência consistente em sRGB como padrão de trabalho. Não introduzir CMYK no pipeline do jogo. Preservar fontes de maior resolução, mas usar derivados identificados e mensuráveis quando uma etapa aprovada exigir redução.

## 06. Resolução, escala, margens e amostragem

### 06.1 Quatro medidas independentes

**Fonte** é a imagem inteira. **Célula** é o retângulo de um frame. **Silhueta** é a parte visível dentro da célula. **Uso** é a medida final em tela ou no mundo. Registrar as quatro quando houver risco de confusão.

**Obrigatório:** preservar a proporção, salvo um componente explicitamente dividido em partes expansíveis. Não normalizar cada frame para ocupar sozinho a maior área possível: isso faz o personagem respirar em tamanho, em vez de animar.

### 06.2 Margens

Para novos spritesheets, começar com 10% a 15% de margem visual por célula e revisar a pose mais aberta. Como critério técnico inicial, usar no mínimo 8 px de respiro de primeiro plano nos recortes de referência de aproximadamente 313/314 px, ajustando proporcionalmente ao uso e ao filtro. Esses números são ponto de partida, não prova automática de que uma asa está segura.

Margem de animação, espaço entre tiles e proteção contra sangramento de atlas são problemas diferentes. Um tile repetível pode precisar chegar até a borda da célula; não aplicar a margem de uma criatura à conexão de um muro. Um ícone com rabiola longa precisa de área segura proporcional ao seu enquadramento.

### 06.3 Amostragem

O renderizador atual usa imageSmoothingEnabled=false para diversas criaturas e atores. Verificar a aparência em escala de uso, sobretudo em escalas fracionárias. Não trocar globalmente o filtro para consertar uma única folha. A HUD usa sua própria escala e estratégia de recorte; fontes e glifos não devem virar texto raster borrado.

Uma textura de 1254 × 1254 RGBA ocupa aproximadamente 6 MiB decodificada; 1536 × 1024 também ocupa 6 MiB; 4096 × 4096 ocupa 64 MiB. O tamanho comprimido do arquivo não representa o custo de memória. Reduzir desperdício de transparência e carregamento simultâneo antes de pedir tudo em 4K.

## 07. Humanos: conceito, retrato e atuação

### 07.1 Identidade invariável

Registrar idade aparente, proporção, cabelo, olhos, roupa, acessórios, lado dos detalhes assimétricos, postura e personalidade. Toda versão deve conservar esses traços, ainda que mude a densidade de detalhe.

**Sr. Assis:** homem de 45 anos, sem barba ou bigode, cabelo preto com detalhes brancos, óculos de aviação na testa, jaleco branco aberto com crachá, polo azul e calça marrom. Simplificar crachá e armação dos óculos no chibi sem removê-los ou transformá-los em outra peça.

**Kael:** usar a referência e o atlas aprovados para cabelo azul-marinho, roupa azul, camiseta escura e detalhes turquesa. Não trocar a roupa com base numa referência de outro personagem. A arte promocional e o sprite de exploração precisam parecer a mesma pessoa.

Para Zeca, Bia, Juninho, Lia, Tião, Mikka, Lohan e Kleie, consultar a arte individual vigente. Não deduzir trajes ou idade apenas pelo nome. O boné de Juninho e o crachá do professor já exigiram correções; entram na lista de invariantes.

### 07.2 Tipos de arte humana

- Corpo inteiro de apresentação: usado em diálogo e reação, sem fingir que é ciclo de movimento.
- Retrato de expressão: enquadramento estável, cabelo e rosto constantes, olhos legíveis.
- Pose de introdução: gesto narrativo completo e apoio coerente.
- Sprite de overworld: chibi direcional com âncora nos pés e escala de mundo.
- Arte promocional: enquadramento livre, conservando identidade e proporções do projeto.

Não usar uma única imagem espremida para todos esses papéis. Expressões recortadas não se encaixam automaticamente sobre qualquer corpo: encaixe facial por máscara exige contrato próprio de posição, escala e deformação.

### 07.3 Gesto e direção do olhar

Definir o alvo visual em coordenadas da composição: quem olha para quem, quem acompanha um movimento e quem olha para o jogador. Conferir a cena completa após gerar cada personagem. O fato de cada rosto isolado estar correto não garante que Rabbito e Nevagume estejam olhando para Yaguarú na cena.

Não espelhar uma imagem assimétrica sem revisar acessórios, lado do cabelo, roupa, luz e gesto. Quando a identidade não permite espelhamento, gerar a direção necessária.

## 08. Chibis e sprites direcionais do overworld

### 08.1 Contrato atual

O manifesto de atores em assets/characters/overworld-v1/manifest.json contém Sr. Assis e os rivais do Morro. Cada ator tem oito poses: quatro direções de repouso e quatro de passo. A ordem direcional é sul, oeste, leste, norte. O desenho de Kael de exploração tem manifesto próprio em assets/hub/praca-v1/manifest.json.

As divisões efetivas podem ser diferentes entre folhas. Usar x, y, w, h, bounds, footAnchor quando presente e referenceHeight. O consumidor usa uma escala fixa por ator. Não presumir células quadradas ou copiar as medidas de Kael para todos os NPCs.

### 08.2 Regras de produção

Manter cabeça grande, corpo compacto e silhueta legível sem infantilizar a identidade indevidamente. Fixar o centro dos pés no chão. Repouso e passo não podem variar a altura do crânio por mudança de zoom. Há movimento do corpo, mas não uma troca acidental de escala.

Na vista traseira, retirar detalhes que não deveriam estar visíveis e preservar aqueles que continuam aparecendo por volume. Não mostrar o rosto inteiro atrás da cabeça. Um crachá frontal não surge nas costas sem justificativa. A armação de uma pipa ou mochila deve mudar de perspectiva, não teletransportar de lado.

O pacote atual disponibiliza duas poses por direção; isso não equivale a um ciclo completo de quatro ou oito frames por direção. Novos ciclos mais longos exigem ampliar o manifesto e o player. A arte não pode entregar 32 frames e esperar que o consumidor de oito os descubra sozinho.

### 08.3 Aprovação em cena

Inspecionar lado a lado com Kael; diante e atrás de árvores e telhados; parado e em passo; perto de uma porta e de um banco. Corpo inteiro de diálogo e chibi podem ter proporções distintas, mas devem conservar a mesma identidade. NPCs são atores separados do fundo e não precisam ser repintados no mapa quando mudam de lugar.

## 09. Pipamons: anatomia de pipa viva

### 09.1 Ficha de identidade

Definir ID, nome, espécie/tema, personalidade, silhueta, paleta, dois ou três traços exclusivos, construção de papel, sistema de armação, ponto de linha e rabiola. Quando houver lenda ou conto, distinguir inspiração identificada de história ficcional criada para o projeto.

O rosto deve ser reconhecível por volta de 96 px como referência inicial. A silhueta precisa diferenciar espécies sem depender só de recoloração. Variar peso visual, eixo corporal, tipo de vela, pontas, orelhas, fitas, rigidez e forma de se mover.

### 09.2 Construção funcional

Varetas sustentam uma forma; nós unem partes; o papel tem dobras e tensões; a rabiola responde ao vento. Tudo pode ser estilizado, mas deve parecer conectado. Conferir encontros entre asa e corpo, cauda e quadril, vela e armação, fita e nó. Uma sombra ou partícula não corrige uma ligação anatômica ausente.

Nem toda criatura precisa de asas. Uma cobra pode serpentear; um golfinho, flexionar nadadeiras; um hipopótamo, deslocar massa; uma fada, girar velas e fitas. A ação deve partir da anatomia, em vez de dar a todos o mesmo movimento de flutuação.

### 09.3 Variações e raridade

Uma variação mumificada deve preservar a leitura da espécie e transformar papel, remendos e fitas de forma coerente. Não embrulhar o rosto e perder sua identificação. Faixas não podem esconder ou substituir a articulação entre frames.

Cor, iluminação, símbolo de raridade, borda de evento e efeito de nível são camadas distintas. Não incorporar tudo permanentemente na textura base. Só cadastrar distribuição, poderes, chance de drop e concessão de itens quando isso fizer parte do trabalho autorizado e estiver implementado no sistema correspondente.

### 09.4 Narrativa para a Dex

Entregar uma origem, um comportamento e uma nota curta do Sr. Assis. O texto deve ajudar a entender materiais, personalidade e movimento. A história ficcional da espécie não substitui o histórico real de captura ou propriedade de um item.

## 10. Spritesheets e linguagem de animação

### 10.1 Padrão inicial para novos Pipamons

Quando o consumidor aceitar o padrão completo da skill pipamonsters, usar 4 colunas × 4 linhas, 16 quadros, leitura da esquerda para a direita e de cima para baixo.

| Estado | Índices base zero | Tempos iniciais em ms | Reprodução |
| --- | --- | --- | --- |
| idle | 00 a 03 | 220, 150, 220, 220 | Loop |
| flight | 04 a 07 | 130, 110, 130, 110 | Loop |
| skill | 08 a 11 | 160, 180, 110, 180 | Uma vez, retorna a idle |
| hurt | 12 a 13 | 150, 210 | Uma vez, retorna a idle |
| victory | 14 a 15 | 300, 420 | Loop |

Esses tempos são base de produção, não regra de balanceamento. O legado possui exceções: Nozinho usa greet e happy, por exemplo. Alguns personagens têm poses de apresentação em vez de estados de combate. Verificar o atlas e o mapeamento do player antes de padronizar nomes.

### 10.2 Movimento que precisa existir

- Repouso: respiração ou flutuação sutil, sem deformação do desenho-base.
- Voo: articulação contínua de asas, nadadeiras, corpo ou fitas; início e fim do loop combinam.
- Habilidade: antecipação, carga, liberação e recuperação claramente diferentes.
- Dano: leitura breve e recuperação, sem transformar a espécie.
- Vitória: gesto próprio da personalidade, mantendo margens e apoios.

Não deslocar a mesma figura alguns pixels e chamar isso de ciclo articulado. Não inflar o corpo como substituto de animação. Mudança de hash prova que há pixels diferentes, não que o movimento faz sentido.

### 10.3 Identidade temporal

Conferir contagem de cabeças e membros, forma dos olhos, posição de manchas, lado dos acessórios, varetas e terminação da rabiola. Quando um membro é ocluído, a oclusão deve ser explicada pela pose. Ele não pode sumir entre dois frames frontais equivalentes.

A cauda precisa continuar presa em todos os quadros. Revisar especialmente poses de giro, ataque e dano: o problema do tigre com cauda aparentemente separada é um bloqueio de produção, mesmo com atlas válido.

### 10.4 Pivô, escala e root motion

Fixar uma referência corporal: pés para quem caminha; centro de massa ou nó principal para quem flutua. Medir a referência em cada pose. Uma oscilação intencional pode existir, mas deve ser desenhada e documentada. Não recentralizar cada frame pelo bounding box sem considerar a anatomia.

O movimento pelo mundo ou pela arena é normalmente aplicado pelo código. A textura descreve a ação local. Um dash pintado como deslocamento de uma célula inteira pode duplicar o movimento do motor. Declarar qualquer root motion necessário e confirmar suporte antes de usar.

### 10.5 Dados e casos de falha

Os nomes em animations devem apontar para frames existentes. Duração e reprodução devem ser consistentes entre frames.duration e playback.durations quando esses campos existirem. Holds intencionais podem repetir quadros, mas precisam ser declarados. Nenhuma pose aberta pode invadir a célula vizinha.

Testar loop lento, velocidade final, pausa, retomada, troca de estado, movimento reduzido, textura ausente e duas espécies com margens diferentes. Uma primeira pose estática não pode esconder falhas nos outros 15 quadros.

## 11. Retratos, expressões e Pipa Dex

### 11.1 Retrato é uma entrega própria

Retratos de lista mostram o rosto; o painel de detalhes mostra o corpo inteiro animado. A lista não deve virar uma sequência de miniaturas microscópicas de corpos completos. Definir o recorte facial por espécie com rosto, orelhas ou chifres necessários à identificação.

O enquadramento facial deve ter escala e posição coerentes entre estados, sem cortar olhos, focinho ou marca principal. O retrato não define a escala do corpo na arena. Espécies longas precisam de enquadramento próprio; uma cobra não deve ser ampliada até perder a cabeça só para encher o quadrado.

### 11.2 Expressões humanas

Manter o mesmo rosto em neutro, fala, alegria, pensamento, surpresa, preocupação e determinação. Evitar olhos e mandíbula de personagens diferentes por expressão. A expressão não deve remover óculos, cabelo ou outras invariantes.

Se as cabeças forem independentes, declarar isso. Para um sistema de rosto sobreposto ao corpo, entregar separadamente máscara, pontos de conexão, poses compatíveis e teste de composição. O pacote atual do professor não garante automaticamente esse sistema.

### 11.3 Estados e informação

Selecionado, equipado, não adquirido, evento e indisponível são estados diferentes. A ficha da Dex não pode ser interpretada como posse. Cor e ícone de raridade precisam de texto ou símbolo redundante. Informações e história ficam em texto real, abaixo ou ao lado da prévia, sem serem pintadas na textura.

## 12. HUD e botões redimensionáveis

### 12.1 Separação obrigatória

Arte decorativa, conteúdo e interação são camadas separadas. O texto é texto real. A área clicável não depende de pixels opacos. A moldura não recebe o foco semântico no lugar do botão. Uma textura de botão não deve conter o nome da ação, o preço ou o atalho atual.

### 12.2 3-slice: pontas fixas e centro expansível

Botões e faixas horizontais usam esquerda fixa, centro expansível e direita fixa. Ornamentos ficam nas pontas. O centro pode ser repetido ou estendido conforme a textura, mas não pode conter uma figura cuja deformação fique perceptível.

**Regra geométrica:** largura total = ponta esquerda + centro + ponta direita. A escala das pontas é escolhida pela altura ou densidade do componente, nunca pela largura do rótulo. Aumentar o texto aumenta o centro; não engrossa o contorno nem alarga uma folha ornamental.

No kit Switch atual, os insets de vários botões têm 64 px por lado na fonte, com escala 0,5: cada ponta resulta em 32 px. A pintura usa aproximadamente 54 px de altura, dentro de um alvo de 64 px. São medidas daquela família, não valores universais para qualquer botão novo.

### 12.3 9-slice: quatro cantos, quatro bordas e centro

Painéis redimensionáveis preservam cantos fixos. Bordas superior e inferior acompanham a largura; bordas laterais acompanham a altura; o centro preenche a área útil. Cortes atravessam trechos retos, sem pingentes, nós ou folhas.

Declarar a ordem dos insets como topo, direita, baixo, esquerda. Exigir largura mínima maior que esquerda + direita e altura mínima maior que topo + baixo, além do espaço do conteúdo. minSize do manifesto é um mínimo geométrico; o texto e as ações podem exigir um mínimo maior.

O kit legado de HUD e o kit Switch usam escalas e medidas diferentes. Não misturar as pontas de um com as bordas do outro. Medalhões diagonais, ícones circulares e brasões preservam proporção inteira, a menos que tenham sido desenhados para subdivisão.

### 12.4 O risco da linha de 1 px

Inspecionar junções sob diferentes larguras, alturas, zooms e DPR. Uma linha transparente pode vir de coordenadas fracionárias, arredondamentos diferentes, filtro ou recorte insuficiente. Corrigir a estratégia de montagem, não esconder o defeito com sombra pesada.

O gerador do HUD legado já usa amostragem com pequeno respiro em bordas expansíveis; o kit Switch usa border-image em seus painéis. Preservar a estratégia de cada família. Não acrescentar um bleed arbitrário que copie parte de um ícone ou contamine o canto vizinho.

### 12.5 Matriz de estados

Produzir ou definir normal, hover, pressionado, desabilitado, foco, selecionado e carregando conforme a função. Os quatro estados pintados de um botão devem compartilhar dimensões, cortes e alinhamento. Foco pode ser desenhado em código; selecionado não equivale a foco. Não mover rótulos ou alterar a área clicável ao trocar de estado.

Validar rótulo curto e longo, números grandes, português com acentos, quebra de linha proibida/permitida, tradução futura e escala de interface. Nunca reduzir indefinidamente a fonte para fazer um botão caber.

## 13. Menus, inventários, barras e comandos

### 13.1 Elementos de UI que precisam de contrato

Entregar bases e estados para janelas, cartões, listas, slots, abas, campos, tooltips, avisos, barras de rolagem, seletores, switches, sliders, divisores e cabeçalhos. Cada componente precisa declarar área decorativa, área útil, tamanho mínimo e expansão permitida.

Uma aba com indicador triangular central pintado não pode ser simplesmente esticada. Separar o indicador da base expansível, como faz a variante redimensionável do kit atual. Bases circulares preservam proporção. O retrato dentro de um cartão é outra camada, com recorte próprio.

### 13.2 Barras e anéis

Separar trilho, preenchimento, ornamento e valor. Uma barra em zero não pode parecer cheia por causa de um brilho fixo. Conferir 0%, 1%, 50%, 99% e 100%. Não repetir pontas decorativas dentro do preenchimento.

Recarga circular é adequada a SVG ou geometria de código ligada ao valor real. Não gerar dezenas de PNGs para uma informação contínua que o componente já calcula. Imagem de cadeado ou de energia não substitui o estado acessível do controle.

### 13.3 Glifos e entrada

Glifos de Xbox, PlayStation, teclado, mouse e toque devem representar o mapeamento real. A mesma letra física pode ter funções diferentes no menu e na batalha. Nunca pintar permanentemente "Q" em uma habilidade que também será usada por controle.

O kit atual usa glifos vetoriais em viewBox 0 0 64 64, com uso comum em torno de 28 a 32 px. São referências existentes. Novos glifos precisam de peso visual consistente, fundo legível e associação clara à ação. Mapear pares de habilidade esquerda/direita de forma explícita.

### 13.4 Conteúdo e acessibilidade

Separar loading, vazio, erro, indisponível e bloqueado. Não decorar um estado de erro como se fosse uma coleção vazia. A seleção deve aparecer com teclado e controle; a informação não pode depender só de cor. Imagens decorativas ficam fora da árvore acessível; a ação recebe rótulo textual.

O alvo de interação pode ser maior que a pintura. Usar os 64 px do kit atual como referência de seus componentes, sem assumir que todos os contextos já seguem essa medida. Testar foco, ordem de leitura, navegação entre abas, rolagem, movimento reduzido e ampliação da interface.

## 14. Tiles de chão e transições

### 14.1 Textura preenchível não é borda

Grama, terra, calçada e pedra precisam de preenchimentos que repitam sem molduras em cada célula. Bordas e transições são outra família. Não colocar uma sombra de objeto completo numa textura que vai preencher um pátio inteiro.

Fixar tamanho lógico, escala do grão, direção da luz e contraste. Pedras de uma calçada não podem dobrar de tamanho porque o retângulo ficou maior. Introduzir variações controladas de material sem destruir o ritmo das conexões.

### 14.2 Topologia necessária

Prever preenchimento, bordas N/S/E/O, quinas externas, quinas internas, corredores, ilhas e junções utilizadas pelo mapa. A escolha depende dos vizinhos e, quando necessário, das diagonais. Não chamar um conjunto de tiles de autotile universal se ele não cobre as topologias prometidas.

Quinas externas contornam saliências; quinas internas acompanham recuos. Um preenchimento com quatro cantos arredondados não resolve sozinho um cruzamento em T. A borda não deve aparecer no meio de duas células do mesmo terreno.

### 14.3 Estado atual do quintal

O quintal usa retângulos de piso caminhável sobre gramado e calcula o contorno da união por material e piso. O parâmetro ground_corner_radius é 24 px nessa planta. O arredondamento acompanha o contorno completo, incluindo curvas internas, não cada retângulo isolado.

Esse mecanismo não é um editor genérico de autotiles. Uma coleção futura baseada em tilelayers exigirá outro contrato. O Ateliê atual exporta objetos retangulares, não GIDs de tiles. Não entregar uma planilha de autotiles e presumir que ela já será interpretada automaticamente.

### 14.4 Painel de teste

Montar preenchimento pelo menos 8 × 8 células, reta longa, L, U, T, cruzamento, ilha e recuo, conforme o escopo. Testar encontros entre três materiais quando existirem. Inspecionar o resultado em 100%, na escala de jogo e com personagens por cima.

## 15. Muros, cercas e bordas conectadas

### 15.1 O erro que não pode voltar

Um recorte de um pequeno muro ilustrado não se torna tile porque foi repetido. Se contém tampa, pedestal, folhagem ou uma pedra saliente no fim, esses detalhes reiniciam a cada módulo. Retângulos encostados podem continuar produzindo um muro visualmente quebrado.

### 15.2 Contrato de conexão

Declarar as conexões abertas N/S/E/O, largura ocupada, altura do topo, face aparente, faixa de alpha, fase das juntas, orientação da luz, base física e âncora. Peças compatíveis mantêm essas propriedades na junção. Uma conexão aberta não contém contorno de terminal.

Produzir as quatro retas orientadas e as quinas necessárias. Não girar uma faixa horizontal em 90 graus quando isso transforma sua face frontal em topo ou troca a iluminação. Terminais livres e pilares ficam apenas onde a montagem termina ou muda de estrutura.

### 15.3 Solução atual do quintal

walls-v2.png é uma fonte RGBA de 1254 × 1254. Quatro retas e quatro quinas derivam da mesma moldura conectada, com cortes fixos nas coordenadas 128, 352, 896 e 1120. Todas usam escala 3/16. Os finais curtos cortam a origem em vez de encolher ou sobrepor o módulo.

O recorte do meio vertical tem 224 × 544 px e é usado como 42 × 102 px. Esses valores incluem áreas transparentes previstas no contrato; a espessura visível não deve ser confundida com a largura da célula. A colisão é uma base separada. O kit resolve o fechamento retangular atual; não oferece automaticamente terminais livres, T, cruzamento ou todos os recuos de terreno.

### 15.4 Teste de pixels e teste visual

A auditoria atual compara a faixa de alpha nas repetições e mede a variação do contorno. Ela exige coincidência mínima de 97% e variação máxima de 4 px na fonte; a folha aprovada passou com coincidência superior a 99% e variação de até 2 px. São limites daquele teste, não tolerância universal de qualquer material.

Alpha compatível não prova continuidade de cor, desenho das pedras ou sombra. Revisar oito repetições por direção, retângulo fechado e os demais formatos incluídos na entrega. Mostrar sem plantas, em fundo claro e escuro. Reprovar saliências periódicas, degraus, juntas reiniciadas e pedras duplicadas nas quinas.

## 16. Objetos, árvores e vegetação

### 16.1 Construção por partes

Separar partes quando isso ajuda uso real: base e teto, tronco e copa, porta e fachada, poste e luz, carretel e linha. Separar apenas por hábito também cria trabalho: cada parte exige ponto de conexão, escala, ordem e teste.

Toda peça de apoio precisa de um socket visual, ainda que definido por coordenadas do atlas. A copa se encaixa nos galhos; o telhado encosta nas paredes; a tampa se apoia no corpo; o cartaz se prende ao mural. Não usar o centro geométrico da imagem como se fosse sempre o ponto de apoio.

### 16.2 Árvores

O tronco possui base física; a copa possui profundidade compatível com o mesmo pé da árvore. Usar uma sobreposição que esconda a junção nos galhos, preservando a leitura do tronco e da raiz. A auditoria do quintal exige sobreposição de pelo menos 25% da altura visual do tronco e pelo menos 25% de tronco aparente.

Essas proporções são verificação geométrica inicial. Um tronco pode passar no cálculo e continuar parecendo um toco separado por causa da forma da copa. Conferir alpha, encaixe real e sombra. Variar altura e largura de árvores sem criar copas gigantes sobre troncos minúsculos.

### 16.3 Vegetação modular

Criar variações de arbusto, flor, vaso e bananeira com escala coerente. Folhas não devem tapar permanentemente uma saída, um NPC ou uma bancada. Vegetação pode enquadrar o mapa, mas não corrigir artificialmente uma emenda defeituosa do muro.

Definir se a planta bloqueia os pés. Uma moita pintada não cria colisão sozinha. Quando a copa encobre Kael, respeitar o comportamento de oclusão do renderizador, inclusive a alternativa de transparência prevista para o jogador.

### 16.4 Móveis e pequenos objetos

Bancos precisam de encosto, frente e área de aproximação coerentes. A arte frontal atual do banco tem encosto ao norte e acesso ao sul; a auditoria reserva 48 px à frente. Outra orientação exige outro desenho e outra descrição do acesso.

Uma mesa deve permitir alcançar sua frente útil. Uma banca precisa de circulação e local plausível para o atendente. Vasos não flutuam acima de sua base. O interior de uma caixa não pode atravessar a borda ao animar. Cordas e bandeirolas precisam de pontos de fixação.

## 17. Edificações, telhados e interiores

### 17.1 Perspectiva comum

Usar a vista elevada de RPG 2D do mapa. Fachadas, piso, telhados, portas e mobiliário devem compartilhar a mesma câmera aparente. Evitar uma casa quase frontal ao lado de outra vista diretamente de cima sem uma razão espacial.

Definir medidas em relação ao personagem: altura de porta, banco, janela, corrimão e degrau. A construção precisa parecer utilizável. Não reduzir a casa inteira para caber num card e usar essa miniatura como prédio de exploração.

### 17.2 Separação de base e cobertura

Quando o jogador passa atrás ou sob uma parte, separar base sólida, teto/foreground e partes móveis. A colisão cobre o apoio físico, não o retângulo inteiro da textura com sombra e telhado. Manter a conexão visual entre fachada e cobertura em todas as posições de câmera.

Portões abertos têm pilares e folhas próprias; o vão central é transitável. Uma arte de porta aberta não autoriza o personagem atravessar a parede se a base física continua fechada. Vistas aberta e fechada precisam de dimensões e ancoragem compatíveis.

### 17.3 Interiores e alturas futuras

Antes de produzir interiores, definir entrada, saída, transição, paredes oclusoras, áreas acessíveis e escala de câmera. Escadas devem desembocar em piso válido, com apoio no início e no fim. Quedas, saltos, rampas e passagens sob pontes exigem suporte explícito do motor; não resolver uma topologia ausente apenas desenhando um cenário convincente.

## 18. Mapas exploráveis e profundidade

### 18.1 Identidade dos lugares

**Quintal:** casa e varanda a oeste, portão ao norte, bancada do professor, banca de linhas a leste, círculo de invocação, mural dos amigos e área livre para circular. Papel, telhado, plantas e objetos de trabalho dão identidade; uma praça de resort genérica não substitui esse lugar.

**Morro do Sol:** progressão de bairro com praça, escadaria, laje, mirante e parque, ligados por circulação plausível. Cada trecho ensina um caminho e apresenta encontros. Não adicionar edifícios ou atalhos sem relação com o fluxo existente.

### 18.2 Geometria antes do acabamento

Definir limites, entrada, destinos, pisos, cotas, conectores, bases sólidas e faixas de circulação. Medir o raio dos pés e o espaço de manobra. Verificar as rotas antes de preencher o terreno com objetos.

O mapa não deve ser uma pintura com personagens e marcadores já incorporados. NPCs, parceiro, partículas, HUD e marcadores pertencem a camadas móveis. Fundos panorâmicos existentes podem continuar em usos específicos; novas áreas que precisam de edição e colisão detalhada devem obedecer ao contrato modular escolhido.

### 18.3 Contrato Tiled atual

| Camada | Função | Cuidado |
| --- | --- | --- |
| Walkable | Áreas de piso e nível | A união precisa cobrir o espaço dos pés |
| Solids | Bases que bloqueiam caminhada | Não confundir com a silhueta inteira da arte |
| Foreground | Copas, telhados e partes de frente | Informar apoio de profundidade e piso |
| Interactions | Zonas de uso e encontro | Geometria não cria recompensa ou ação nova |
| Spawns | Chegada do personagem | Deve estar num ponto seguro |
| Exits | Saídas autorizadas | Precisam ser alcançáveis e coerentes com a cena |

A grade atual é de 32 px. O quintal mede 1536 × 1024, com 48 × 32 células. O contrato do parser é ortogonal finito e utiliza objectgroups de retângulos. O editor atual aceita mapas de 8 a 64 células por eixo; esse é limite do editor, não da resolução de uma folha de textura.

### 18.4 Ordenação e passagem

Ordenar por piso e posição de apoio, normalmente os pés. A altura da copa não determina sozinha sua ordem. Um objeto no piso inferior não deve encobrir um ator do piso superior apenas porque seu Y é maior.

O parceiro segue a mesma rota de Kael e não corta uma construção para manter a distância. Escadas conectam pisos pelos lados previstos. Uma rota precisa continuar válida para a largura dos pés, não apenas para uma linha sem espessura. Visitar uma zona não concede vitória nem XP por desenho.

### 18.5 Uso do Ateliê

O Ateliê é uma ferramenta local de composição e recorte. Não gera arte por IA, não cria NPCs nem altera banco de dados. Seus projetos salvos no navegador pertencem à origem e à porta usadas; abrir uma revisão não deve substituir silenciosamente o trabalho anterior.

Exportação gera um pacote para revisão e integração. Não é deploy automático. Salvar um rascunho inválido é permitido; teste e exportação devem apontar o problema. A planta fonte e seu gerador, quando houver, precisam ser corrigidos juntos.

## 19. Arenas, fundos e modo com profundidade

### 19.1 Arena de combate

Reservar área visual para ler personagens, linhas, cruzamentos, mira, energia, dano e HUD. Não concentrar postes, galhos escuros ou diagonais de alto contraste exatamente sobre a área em que o jogador precisa julgar as linhas.

Separar céu distante, camadas de fundo e eventuais elementos de primeiro plano. O fundo não deve pintar o inimigo, os nomes ou efeitos permanentes de uma habilidade. Testar com duas e com várias pipas, não apenas com uma composição vazia.

### 19.2 Profundidade alternativa

O modo com batalha em profundidade permanece um protótipo enquanto não for assumido como oficial. Assets dessa experiência precisam de categoria e caminho próprios. Não substituir silenciosamente as convenções da batalha normal por perspectiva, controle de câmera ou colisão do protótipo.

Perspectiva visual não autoriza alterar a posição simulada de uma pipa ou a área de um golpe. Escala por distância, oclusão e VFX de profundidade precisam de transformações coerentes e uma prévia que mostre suas regras.

### 19.3 Diferentes proporções de tela

Definir zona segura para o combate e áreas que podem ser cortadas. Evitar esticar um panorama horizontal para preencher uma tela retrato. Usar recorte/câmera ou variante desenhada, conforme o consumidor. Compor fundos para conviver com a HUD em vez de embutir buracos fixos no desenho para uma única resolução.

## 20. VFX, linhas, habilidades e feedback de batalha

### 20.1 Função antes da beleza

Todo efeito deve indicar algo: antecipação, direção, acerto, dano, proteção, crítico, recarga, corte, vitória ou fim de uma ação. Um brilho permanente não deve parecer uma habilidade sempre ativa. O observador precisa entender a diferença entre uma tentativa e um acerto confirmado.

### 20.2 Fases

Separar antecipação, execução, impacto e dissipação. Definir duração, ponto de origem, orientação, área visual máxima, camada e comportamento de interrupção. A animação termina ou reduz ao pausar, encerrar a ação ou sair da tela correspondente.

Um VFX pode ter sua animação interna numa folha e sua trajetória em código. Evitar duplicar a trajetória nos frames e no movimento externo. A cerimônia de troca existente usa esse princípio para o espírito e seus rastros.

### 20.3 Skills de linha

Puxão, chicote, estilingue, laço, folha e duplo precisam de leituras próprias, conforme o sistema vigente. Usar curva, tensão, rastro e ritmo para comunicar sua diferença. Ícones representam o movimento; a linha em jogo continua ligada à posição e à simulação reais.

Não desenhar crítico, quebra ou corte como resultado garantido em toda ativação. A arte de um golpe só confirma dano após o evento aceito pelo jogo. A mira e o cruzamento necessário à decisão não podem desaparecer sob uma explosão opaca.

### 20.4 Regras visuais de VFX

Sprites luminosos usam alpha suave controlado e área de dispersão limitada. Sem fundo preto opaco para ser escondido por blend. Declarar se há cor original, tintura em código ou blend específico. Não usar tintura indiscriminada sobre personagens e materiais que precisam conservar a paleta.

Produzir variantes de densidade ou permitir redução de partículas. Movimento reduzido deve preservar informação com menos deslocamento e pulsação. Não depender de flashes rápidos, tela tremendo ou cor isolada para comunicar perigo. Limites de segurança e conforto devem ser avaliados em uso; não declarar uma animação certificada apenas por ter poucos frames.

### 20.5 Brilho de nível

O progresso individual atual tem nível máximo 50 e famílias de brilho prata, ouro, platina, diamante e aura. A consulta dos marcos e cores deve vir de eng.pipamons, não de números pintados ou copiados numa textura.

| Família atual | Nível de início | Cor de referência atual |
| --- | --- | --- |
| Prata | 20 | `#dce5f5` |
| Ouro | 30 | `#ffd46a` |
| Platina | 40 | `#b8f4de` |
| Diamante | 45 | `#8be5ff` |
| Aura | 50 | `#edb7ff` |

Esta tabela registra a implementação desta revisão; mudanças devem ser feitas na fonte de regras e refletidas aqui. Cor sozinha não identifica o estágio: combinar nome, símbolo e comportamento legível.

O brilho atual é procedural, com partículas limitadas e alternativa reduzida. Não gerar uma nova folha completa da criatura para cada nível. Separar o efeito da aparência base, do selo de raridade e da condição de evento. A arte não concede XP nem altera status.

## 21. Itens, rabiolas, drops e equipamentos

### 21.1 Identidade de item

Um item precisa de ID, nome, categoria, referência da espécie ou coleção, silhueta e finalidade visual. Entregar o ícone limpo e, quando necessário, uma versão de exibição maior. Reusar o item entre lista e detalhes por recorte/escala consciente, sem inventar outro desenho no inventário.

Rabiolas conservam o nó, o padrão de fitas, as cores e a terminação do Pipamon de origem. No ícone de item, a rabiola pode ser isolada; na criatura, continua presa ao corpo. Não confundir essa separação intencional de entregas com uma cauda solta num frame de animação.

### 21.2 Convenções atuais

O catálogo de itens está em assets/pipa-items.json e as fichas da Dex em assets/pipa-dex.json. A coleção inicial contém rabiolas de 209 × 209 px; o item de Javali de Biscoito tem fonte maior e dimensão declarada. O consumidor deve respeitar metadados, não presumir que todos os ícones possuem o mesmo tamanho físico.

Os campos source e availability fazem parte do catálogo. planned não é um drop funcionando. Uma origem de evento não equivale a origem selvagem. Consultar a ficha não equipa, não transfere e não cria um item.

### 21.3 Equipamento sobreposto

Para uma rabiola equipável aparecer no corpo, definir socket, ponto de rotação, escala, estados compatíveis, oclusão e comportamento em cada orientação. A existência de um PNG isolado não implementa equipamento visual. Antes de gerar dezenas de variações, fazer uma prova de encaixe com uma criatura em todos os estados relevantes.

Slots vazios, equipado, reservado, bloqueado e em transferência precisam de estados distinguíveis. Dados de propriedade e transação vêm do servidor; um marcador pintado não é prova de posse.

## 22. Tipografia, símbolos e localização

Nunito, Lilita One e Pixelify Sans aparecem na linguagem atual da interface. Usar as famílias para funções consistentes e conferir o componente existente antes de introduzir outra. A prévia desktop já inclui fontes locais, sem depender de Google Fonts em tempo de execução.

Nomes, instruções, preços, níveis, contadores e falas devem ser texto real. Exceções como lettering promocional precisam de fonte editável ou camada separada. Não pedir ao gerador para pintar letras pequenas num ícone e esperar leitura perfeita.

Manter acentos e caracteres portugueses. Testar nomes longos, números de várias casas, porcentagens e rótulos em outra língua quando a tela for localizada. Não usar símbolos de controle, emojis ou uma fonte externa como único suporte de uma informação crítica.

Cada ícone deve ter significado principal e ser reconhecível sem legendas em miniatura, mas o texto acessível continua necessário. Moeda, diamante, energia e raridade não podem usar silhuetas tão parecidas que dependam de uma mudança sutil de cor.

## 23. Arte promocional, anime e materiais de loja

### 23.1 Linguagem aprovada

Para cenas em anime, buscar desenho de animação japonesa com contornos claros, formas simplificadas e sombras em células. A referência de aventuras de criaturas orienta o gênero. Não transformar automaticamente cada pedido em pintura cinematográfica extremamente detalhada ou semirrealista.

Preservar anatomia, roupa e espécie a partir dos spritesheets aprovados. A referência de composição não substitui a identidade. Uma arte promocional bonita com um Rabbito diferente continua errada para o jogo.

### 23.2 Composição e proporção

Antes de gerar, definir câmera, horizonte, primeiro plano, distância entre atores, direção de queda ou movimento e alvos dos olhares. Objetos próximos podem parecer maiores por perspectiva, mas a relação corporal deve ser coerente. Diferenciar perspectiva intencional de um Pipamon que virou gigante sem motivo.

Para cidade ao fundo, declarar o que identifica Kronasta e qual detalhe será legível. Não encher o plano distante com cidades genéricas sem relação com o bairro aprovado. Compor respiro para eventual texto, sem pintar interface do jogo sobre a cena.

### 23.3 Exportações e loja futura

Guardar master, versão sem texto e derivados por proporção. Anotar zonas seguras para rostos, logotipo e títulos. As dimensões de cápsulas, biblioteca, ícones e trailers devem ser confirmadas nas especificações da plataforma no momento da entrega; este manual não fixa números externos que podem mudar.

Capturas anunciadas como gameplay precisam vir do jogo. Conceitos e cenas promocionais devem ser identificados como tal. Não anunciar overlay, Cloud, conquistas, Steam Input ou disponibilidade na loja apenas porque existe uma prévia Windows.

## 24. Som, música e vídeo

### 24.1 Escopo atual e novos arquivos

O jogo já usa efeitos procedurais por Web Audio. Não há um pipeline geral de trilha sonora e arquivos de voz validado neste manual. As regras abaixo são contratos recomendados para expansão, não descrição de integração pronta.

Para novos sons, entregar master WAV sem perdas, preferencialmente 48 kHz/24-bit como padrão inicial, e um derivado de execução escolhido após teste no consumidor. Música, voz, ambiente e UI precisam de categorias, mixagem e controles separados. Não converter tudo em MP3 sem verificar cortes, atraso, loop e suporte.

### 24.2 Qualidade e sincronização

Evitar clipping, silêncio acidental antes do impacto, cortes bruscos e níveis inconsistentes entre botões semelhantes. Registrar ponto de ataque, duração, loop, transição e variações. Um efeito de crítico deve ser reconhecível sem ser muito mais alto que o restante.

Loops precisam ser revisados repetidos, não só uma vez. Música deve permitir entrada, saída e redução durante diálogos. Voz exige texto final, identidade vocal consistente e alinhamento com a fala. O áudio não pode ser a única informação de um alerta de jogo.

### 24.3 Vídeo e trailers

Separar captura, edição, áudio, legendas e exportação. Conservar arquivo de projeto e master. Validar resolução, proporção, taxa de quadros, legibilidade e apresentação honesta do produto. Vídeo de menu ou cutscene exige suporte próprio, alternativa de pular e tratamento de falha; não é um PNG maior.

## 25. Organização, nomes e procedência

### 25.1 Identificadores

Usar IDs em minúsculas, ASCII e kebab-case: estáveis entre catálogo, atlas e código. O nome exibido pode ter acentos e mudar sem renomear o identificador. Não reutilizar o ID de uma espécie para outra e não usar caminhos absolutos do computador do artista nos manifestos públicos.

Separar ID de asset, ID de modelo, ID de item e ID de instância pertencente a uma conta. Um nome artístico provisório não deve virar identidade definitiva no banco sem revisão.

### 25.2 Pastas

| Área | Conteúdo esperado |
| --- | --- |
| art/ | Prompts, referências autorizadas, estudos, fontes e relatórios de produção |
| assets/ | Arquivos e manifestos consumidos pelo jogo |
| tools/atelie/ | Editor e auditorias locais de composição |
| scripts/ | Compilação, cópia, medição e validação |
| src/ | Consumidores e regras de renderização |
| docs/ | Saída da versão Pages; não é a fonte principal da arte |
| desktop/ | Código e preparação do cliente Windows |
| dist/ | Artefatos gerados; não editar como fonte |

Preservar uma versão aprovada antes de substituir. Usar v1, v2 ou revisão descritiva, não "final-final-agora-vai". As cópias de distribuição devem vir do build; não corrigir manualmente apenas docs/assets ou o pacote Windows.

### 25.3 Rastreabilidade

Registrar ferramenta e data de geração, prompt completo, referências e seus papéis, tamanho pedido e tamanho recebido, alterações, autor/revisor, status, hashes e arquivos publicados. Documentar correções e limitações. Fontes, ferramentas e materiais externos precisam de origem e licença registradas quando aplicável.

Não colocar senhas, chaves de banco, tokens de sessão, dados privados de jogadores ou arquivos de ambiente em prompts, pacotes de arte e capturas. Uma captura de auditoria deve mostrar o problema visual sem expor campos de credenciais.

## 26. Atlas e metadados: contratos distintos

### 26.1 Não existe um único JSON universal no projeto

| Família | Estrutura observada | Fonte de verdade |
| --- | --- | --- |
| Criaturas e vários personagens | atlases, frames, animations, meta; playback quando presente | assets/atlas.json |
| Atores chibi | characters, frames com x/y/w/h, bounds, footAnchor e referência de altura | assets/characters/overworld-v1/manifest.json |
| Kael de exploração | actor e frames próprios | assets/hub/praca-v1/manifest.json |
| Mundo modular | sheets, frames planos, âncoras e bindings por objeto | manifestos dos kits e art.json do mapa |
| HUD legado | sheets, frames em arrays e slices | manifesto hud-papel-bambu-v1 |
| Kit de interface | components/icons, sourceRect, insets, scale e hashes | manifesto kit-switch-v1 |
| Itens e Dex | Catálogos por ID e referências cruzadas | pipa-items.json e pipa-dex.json |

O nome frame pode conter um retângulo em uma família e representar uma referência em outra. Verificar o consumidor antes de copiar um exemplo. Nunca substituir um manifesto inteiro para cadastrar um único asset.

### 26.2 Dados mínimos de animação

Imagem e tamanho reais; IDs de frame; retângulos inteiros; sourceSize e spriteSourceSize quando usados; rotated/trimmed; pivô; contentBounds e limiar de medição; sequências, tempos, loop e fallback. Os índices devem ser inequívocos, inclusive se a documentação usa base zero.

contentBounds mede a área visível dentro do frame, não uma licença para aplicar zoom diferente a cada pose. Em atores, footAnchor é relativo ao frame; o ponto mundial do pé é outro dado. Declarar unidade e espaço de coordenadas.

### 26.3 Dados mínimos de UI e mundo

UI: fonte, recorte, insets, modo de expansão, escala/densidade, tamanho mínimo e área útil. Mundo: folha, retângulo, âncora, dimensões de uso, piso, sort_y/apoio, base física e conexões quando aplicável.

Um fim recortado de muro pode usar sourceWidth ou sourceHeight no binding atual, mantendo a escala. Valores fora do frame são inválidos. Isso não autoriza qualquer formato de crop em todos os players: trata-se do renderizador modular atual.

## 27. Integração no jogo e na distribuição

### 27.1 Registro completo

1. Colocar a fonte final no caminho versionado em assets/.
2. Adicionar o asset ao manifesto ou catálogo apropriado, preservando IDs existentes.
3. Ajustar meta.image ou referência equivalente para o caminho publicado.
4. Registrar a imagem no carregador estático permitido, quando necessário.
5. Incluir no build e na cópia dos assets, com hash de conteúdo na URL quando o sistema já usa esse padrão.
6. Adicionar retrato, Dex, item ou ator apenas se fizerem parte do escopo.
7. Testar o carregamento local e as alternativas de falha.
8. Compilar servidor, Pages e cliente desktop quando forem afetados.

Arquivos de desenvolvimento, prompts e projetos privados não precisam virar URLs públicas. A allowlist do servidor é uma decisão explícita. Não servir a pasta inteira de assets por conveniência se isso expuser arquivos não previstos.

### 27.2 Publicação real

Subir um commit não prova que o Render concluiu o deploy. Concluir um build não prova que um asset novo está na allowlist. Publicação exige confirmar o commit ativo, a resposta do jogo e os arquivos corretos, preferencialmente comparando hashes.

O desktop instala sua própria versão de HTML, imagens e fontes. Uma atualização só no site não troca o conteúdo do executável existente. Preparar e empacotar outra versão quando a mudança visual afetar o cliente instalado.

### 27.3 Economia e autoridade

Inventário, XP, propriedade, transferências, eventos e captura são dados de jogo. O cliente apresenta efeitos e seleciona assets com base em dados autorizados. Não registrar um especial como uma cor numérica arbitrária fora do contrato do motor; separar aparência e classe de combate.

Projetos de arte não concedem todos os itens a uma conta automaticamente. Uma prévia usa fixtures identificadas e isoladas. Nunca apresentar o estado de uma conta de teste como confirmação de alteração da produção.

## 28. Desempenho, acesso e compatibilidade

### 28.1 Metas de trabalho

Definir orçamento por tela antes da geração: quantidade de texturas simultâneas, maior dimensão, memória estimada, número de atores, partículas e animações visíveis. Medir em aparelhos-alvo; não declarar mínimos de hardware com base só no computador de criação.

Como direção inicial, testar 60 fps quando possível e uma variante leve que permaneça legível em máquinas mais lentas. A regra é medir fluidez e tempos de quadro, não esconder problemas diminuindo o contador de ping. Ping, FPS, carregamento e uso de memória são métricas diferentes.

### 28.2 Carregamento e fallback

Carregar folhas por necessidade, cachear estáticos e evitar redesenhar o mesmo fundo a cada quadro quando uma composição cacheada serve. Não recarregar textura ao abrir cada frame de um loop. Se uma imagem falhar, preservar navegação, texto e ação; não bloquear a conta ou conceder estado fictício para compensar.

Nós, rostos e linhas importantes precisam continuar visíveis no modo leve. Reduzir partículas e sombras antes de reduzir a informação que define a luta. Uma versão menor pode exigir simplificação desenhada, não apenas compressão.

### 28.3 Matriz visual mínima

- Interface desktop: 1280 × 800 e 1920 × 1080 como referências de produção, mais janela menor suportada pelo consumidor.
- Web móvel: retrato e paisagem, incluindo tela estreita e baixa altura.
- DPR e zoom: testar combinações relevantes para detectar a emenda de 1 px e texto fora da moldura.
- Entrada: mouse, teclado, toque e controle, conforme o componente.
- Preferências: movimento reduzido, escala de UI e modo leve.
- Falhas: conexão ausente, textura ausente, recarga de tela e retorno do menu.

São casos de auditoria, não uma afirmação de que todas as plataformas estão certificadas. A prévia Windows ainda requer testes funcionais manuais; Steam Deck e integração Steam Input precisam de validação própria.

## 29. Auditoria e critérios de reprovação

### 29.1 Matriz mestre

Os códigos abaixo organizam a revisão. Só chamar uma regra de automática quando houver verificação real indicada. O restante depende de inspeção humana ou teste de uso.

| Família | Verificar | Bloqueio de entrega |
| --- | --- | --- |
| GEN | Identidade, formato, alpha, origem e dimensões | Arquivo diferente do conceito ou falso transparente |
| SPR | Membros, acessórios, cauda, margens e pivô | Anatomia alterada, recorte ou peça solta |
| ANI | Ritmo, loop, fases e troca de estado | Tremor de escala, frames sem continuidade |
| HUD | Cortes, cantos, texto, foco e estados | Deformação, emenda aberta ou conteúdo fora |
| TIL | Continuidade de material e topologia | Grade visível, transição errada ou quina ausente |
| MUR | Silhueta, juntas, quinas e terminais | Blocos reiniciando, degrau ou vão |
| OBJ | Apoio, orientação, escala e circulação | Flutuação ou uso fisicamente incoerente |
| MAP | Caminhos, níveis, destinos e profundidade | Saída inacessível ou passagem por construção |
| VFX | Informação, duração, área e interrupção | Obscurece a decisão ou confirma ação inexistente |
| ITEM | Origem, ID, vínculo e estados de catálogo | Mostra posse/drop não implementado |
| DIST | Registro, cópia, cache e arquivos finais | Fonte correta, mas arquivo publicado antigo |

### 29.2 Verificações atuais de cenário

ARB-01 exige copa e tronco centrados no mesmo apoio; ARB-02 confere sobreposição e tronco aparente. MUR-01 detecta vãos geométricos e MUR-02 diferenças de escala/alinhamento. MOB-01 confere banco visível e acesso frontal; MOB-02, piso de aproximação. PIS-01 exige configuração de quinas arredondadas nos projetos auditados.

MUR-03 a MUR-06 detalham continuidade artística, quinas, terminais e painéis de montagem. A comparação de alpha é complementar. Nenhuma delas deve ser contornada renomeando segmentos para que a checagem deixe de agrupar um muro contínuo.

### 29.3 Erros já encontrados

| Problema real | Causa a evitar | Regra preventiva |
| --- | --- | --- |
| Árvore parece flutuar sobre toco | Copa e tronco apenas tangentes | Socket e sobreposição visual medida |
| Muro sobe em degraus | Objeto ilustrado usado como repetição | Fonte conectada e teste de oito módulos |
| Quina de caminho quadrada | Retângulos sem contorno conjunto | União do terreno e curva interna/externa |
| Banco escondido na grama | Orientação sem área de uso | Frente livre e revisão com vegetação |
| Botão perde qualidade ao alargar | Imagem inteira esticada | Pontas fixas, centro expansível |
| Risquinho entre partes de HUD | Arredondamento/filtro/corte | Testar dimensões fracionárias e DPR |
| Cauda do tigre se separa | Anatomia inconsistente no frame | Revisão quadro a quadro do ponto de conexão |
| Arte promocional distante do estilo | Detalhe e volume excessivos | Contorno e cel shading simplificados |
| Pipamons olham para o lado errado | Revisão isolada dos personagens | Conferir vetores de olhar na composição |
| PNG gerado invade célula | Grade e margens apenas pedidas | Medir dimensões reais e silhueta |

### 29.4 Revisão final

Revisar o asset isolado, na família, no tamanho de uso e na cena real. Fazer uma passagem sem VFX e decoração para revelar problemas. Guardar captura ou prévia reproduzível, número da revisão e lista de limitações. Aprovação precisa dizer o que foi verificado; "ficou bonito" não é relatório técnico.

## 30. Prompts de produção por categoria

Os modelos a seguir são briefings reutilizáveis. Campos entre colchetes devem ser substituídos por decisões reais antes de gerar. Os prompts não criam suporte no código, não garantem dimensões de saída e não substituem a validação.

### 30.1 Conceito de Pipamon

> Criar [nome], uma criatura original de pipa viva de [espécie/tema]. Referência A define identidade; B define acabamento. Construção: [papel, armação, nós e rabiola conectados]. Preservar [traços exclusivos]. Contorno escuro nítido, planos facetados, cel shading simples e acabamento 2D entre ilustração e pixel art refinada. Corpo completo em [orientação], silhueta legível na miniatura. PNG RGBA, alpha real, margens transparentes. Sem cenário, rótulos, paleta pintada, grade ou marca-d'água.

### 30.2 Spritesheet de criatura

> Usar o conceito aprovado como autoridade de identidade. Uma única criatura, mesma anatomia, roupa e ornamentos em 16 quadros, grade 4 por 4, ordem temporal indicada. Linha 1 repouso; linha 2 voo; linha 3 antecipação, carga, liberação e recuperação; linha 4 dano e vitória conforme o mapa entregue. Escala e pivô corporal constantes, articulação real, rabiola presa em todos os quadros. Margem inicial de 15% por célula, inclusive na pose mais aberta. Fundo realmente transparente; papel claro opaco. Não pintar efeitos soltos entre células, títulos ou divisórias.

### 30.3 Correção localizada de frame

> Corrigir somente [defeito] nos quadros [índices]. Preservar identidade, escala, ordem, câmera, paleta e demais desenhos. Conectar [parte] em [ponto anatômico], com continuidade nos frames anterior e posterior. Não alterar o fundo, não redesenhar a espécie, não acrescentar membros ou acessórios. Manter todas as silhuetas dentro de suas células.

### 30.4 Chibi humano direcional

> Adaptar [personagem aprovado] para o overworld do PipaKlub. Referência A define identidade e roupa; Kael chibi define escala e acabamento. Oito poses: sul, oeste, leste e norte em repouso, seguidas das mesmas direções em passo. Mesmo corpo e tamanho de cabeça, pés apoiados com âncora consistente. Preservar [acessórios e assimetrias]. Vistas traseiras coerentes. RGBA transparente, corpo completo e margens, sem cenário, texto ou ícones.

### 30.5 HUD expansível

> Produzir uma família de [botões/painéis] em papel e bambu do PipaKlub. Planejar regiões de corte retas: [3-slice ou 9-slice]. Pontas/cantos com ornamentos fixos; bordas e centro discretos, apropriados à expansão prevista. Mesmas medidas e cortes entre normal, hover, pressionado e desabilitado. Textura pintada 2D limpa, sem rótulo, número, atalho, texto de exemplo ou fundo. Margens transparentes e área útil livre. Entregar fonte e indicação das regiões, sujeitas à medição do PNG final.

### 30.6 Muro conectado

> Criar fonte de alvenaria creme para o mapa do PipaKlub, em perspectiva elevada ortogonal. Trechos contínuos de espessura constante, topo e face compatíveis, juntas que continuam nas conexões. Quatro orientações e quinas do escopo [descrever topologia]. Sem pilares, tampas, plantas ou pedras salientes reiniciando nos meios repetíveis. Vazios em alpha real. As quinas precisam nascer conectadas às retas, não como peças decorativas independentes. A montagem será testada em oito repetições e contornos fechados sem repintar a prévia.

### 30.7 Chão e transições

> Produzir [material] para piso em grade lógica de [medida]. Grão e pedras em escala constante, iluminação comum e contraste abaixo dos personagens. Entregar preenchimento repetível e bordas/quinas [lista exata]. Sem moldura em cada tile interior, sombra externa de objeto, texto ou vegetação obrigatória. Vizinhos do mesmo material devem formar uma superfície contínua, incluindo L, U e junções do escopo.

### 30.8 Árvore ou objeto multipartes

> Criar [objeto] para vista elevada do overworld. Referência A define acabamento e escala. Separar [partes] com conexão visível em [socket]. Base física e ponto de apoio declarados. Para árvore: galhos entram sob a copa, raiz permanece no chão, mesma escala e luz. Sem personagens, HUD, chão pintado ou sombra opaca fora do contrato. O objeto precisa permanecer plausível visto junto de Kael e dos móveis existentes.

### 30.9 Ícone de item ou rabiola

> Isolar [item] ligado a [Pipamon aprovado], preservando nó, padrão de papel, cores e terminação. Uma composição única e simples, legível em slot pequeno, com contorno e cel shading do jogo. PNG RGBA com respiro; sem pedestal, selo de raridade, preço, quantidade, legenda ou fundo. A apresentação de equipamento e propriedade será feita pela interface.

### 30.10 VFX animado

> Uma única sequência de [efeito], em [grade e contagem] frames consecutivos. Fases: antecipação, ação, impacto e dissipação. Origem, orientação e escala constantes, trajetória externa aplicada pelo motor. Núcleo legível, alpha suave sem fundo preto, dispersão contida na célula. Não incluir criatura, linha de colisão, número de dano, grade ou legenda. O efeito não deve esconder a região de decisão do combate.

### 30.11 Arte promocional anime

> Criar cena [composição] com personagens [lista], usando os spritesheets aprovados como identidade. Linguagem de anime com formas simplificadas, contorno claro e sombras em células; evitar pintura semirrealista e excesso de textura. Câmera [posição], movimento [vetor], alvos dos olhares [relações explícitas], proporções [relação entre personagens]. Kronasta [marcos relevantes] ao fundo. Formato [proporção], zona segura [área], sem interface ou texto pintado.

## 31. Pacote de entrega e formulário de aprovação

### 31.1 Entrega mínima por família

| Família | Arquivos e provas mínimas |
| --- | --- |
| Conceito | Imagem limpa, ficha de identidade, prompt e status |
| Criatura animada | PNG original, atlas, estados/tempos, retrato, prévia e auditoria |
| Humano de diálogo | Corpo/expressões definidos, recortes, identidade e enquadramento |
| Chibi | Folha direcional, apoios, escala, prévia com Kael e manifesto |
| HUD | Fonte, partes/recortes, insets, estados, mínimos e painel de tamanhos |
| Tiles e muros | Fonte, conexões, escala, quinas, painel de montagem e auditoria |
| Objeto | Fonte/partes, sockets, base física, orientação e teste de uso |
| Mapa | Projeto editável, geometria, kit, bindings, rotas e prévia em jogo |
| VFX | Fonte, frames/tempos, origem, área, blend e variantes reduzidas |
| Item | Ícone, referência da espécie, ID de catálogo e estado de disponibilidade |
| Promoção | Master, sem texto, derivados, referências e enquadramentos |

Retrato e variações de uso só são obrigatórios quando fazem parte do consumidor ou do pedido. Não interpretar esta tabela como autorização para inventar categorias, histórias ou poderes ausentes.

### 31.2 Registro de produção copiável

```text
ID e nome:
Categoria e consumidor:
Versão e data:
Objetivo e tamanho de uso:
Referências: identidade / estilo / composição / técnica:
Invariantes:
Fonte solicitada e fonte recebida:
Formato e alpha:
Grade, recortes e margens:
Pivô, socket e apoio:
Estados, tempos e loop:
Conexões ou regiões expansíveis:
Arquivos e registros alterados:
Prompt e ferramenta:
Validação automática executada:
Inspeção visual executada:
Limitações e defeitos pendentes:
Status: conceito / revisão / aprovado / validado / integrado / publicado:
Responsável e referência da aprovação:
Commit/deploy, somente se realmente realizado:
```

### 31.3 Checklist de fechamento

- Identidade corresponde à referência correta; nenhuma peça foi inventada por mistura de personagens.
- PNG real, alpha correto, recortes dentro da fonte e arquivos sem resíduo visível.
- Anatomia e conexões se mantêm em todos os frames, orientações e estados.
- Escala, pivô e apoio são coerentes; as partes se encaixam no uso real.
- HUD cresce sem deformar pontas; texto e interação continuam funcionais.
- Tiles e muros repetem e viram quinas sem degraus ou terminais no meio.
- Objetos têm acesso; mapas têm rotas, pisos e profundidade válidos.
- VFX informa a ação sem tapar o combate; modo leve/reduzido conserva a leitura.
- Catálogos e distribuição respeitam o que está implementado e autorizado.
- Prévia reproduzível, relatório, prompt, fonte e versão estão preservados.
- Pendências foram escritas; nenhum rascunho foi chamado de produção.

## 32. Comandos, fontes e manutenção

### 32.1 Comandos existentes no projeto

Executar a partir da raiz do repositório, com as dependências já instaladas. Usar Python com Pillow para scripts de leitura de imagem e geração de metadados. Não fixar o caminho pessoal de um runtime no contrato entregue a outro artista.

```sh
npm run build
npm run build:pages
npm run validate
npm test
npm run audit:world
npm run atelier
node --test world-structure.test.mjs
node --test tools/atelie/atelie.test.mjs
python art/world-quintal-modular-v1/audit-wall-edges.py
```

Para preparar a distribuição desktop quando um asset consumido mudar:

```sh
npm run desktop:prepare
npm run desktop:test
npm run desktop:package
npm run desktop:smoke:packaged
npm run desktop:smoke:packaged -- --offline
```

Os testes desktop exigem o bundle preparado e suas dependências próprias. Um teste de abertura offline não substitui uma partida completa. Não executar builds caros ou regenerar todos os assets por uma edição documental sem necessidade.

### 32.2 Fontes internas principais

- HUD-KIT.md: cortes e auditoria da HUD legada.
- assets/ui/kit-switch-v1/README.md: família atual de componentes, glifos e variações.
- tools/atelie/AUDIT-RULES.md: códigos de auditoria estrutural e visual do cenário.
- art/world-quintal-modular-v1/wall-tileset-contract.md: análise e correção dos muros.
- art/world-quintal-modular-v1/walls-v2-edge-audit.json: medição do alpha e da silhueta da folha aprovada.
- WORLD-ART-DIRECTION.md: identidade dos lugares; distinguir suas decisões artísticas do antigo pedido de fundos panorâmicos.
- assets/atlas.json e src/art-client.js: registros e reprodução de criaturas.
- assets/characters/overworld-v1/manifest.json e src/world-actors.js: atores chibi e âncoras.
- assets/hub/praca-v1/manifest.json: Kael de exploração.
- assets/pipa-dex.json, assets/pipa-items.json e src/dex-client.js: fichas, retratos e itens.
- scripts/art-build.mjs e src/static-assets.js: registro, cópia e publicação de imagens.
- src/world-art.js, src/world-map.js e src/world-navigation.js: desenho modular, camadas, apoio e circulação.
- src/pipamon-level-client.js: apresentação do brilho e do progresso individual.
- desktop/README.md: instalação local, empacotamento e limites da prévia Windows.

As skills pipamonsters e imagegen complementam o processo de geração. Elas não substituem os contratos de consumo do repositório. Uma regra útil descoberta durante produção deve ser incorporada neste manual e na auditoria apropriada.

### 32.3 Glossário curto

**Atlas:** imagem e mapa de recortes. **Frame:** uma pose ou amostra. **Pivô:** referência usada para posicionar a pose. **Foot anchor:** apoio do personagem no mundo. **Socket:** ponto de encaixe entre partes. **Silhueta:** área visível que define a leitura. **Bleed:** respiro de amostragem para evitar emenda de filtro. **3-slice/9-slice:** montagem expansível com extremidades preservadas. **Tile:** peça com contrato de repetição/conexão. **Autotile:** seleção de variantes por vizinhança. **Sort Y:** apoio usado na profundidade. **Fallback:** alternativa quando um recurso falha. **Root motion:** deslocamento do corpo contido na animação. **Master:** fonte de produção preservada. **Derivado:** exportação para um uso específico.

### 32.4 Evolução do manual

Atualizar a versão quando mudar um contrato: novos estados, outro formato de mapa, alteração de escala, novo pipeline de compressão ou integração de plataforma. Registrar qual regra mudou e quais assets precisam de migração. Uma exceção aprovada deve ter ID, justificativa e alcance; não pode virar um segundo padrão silencioso.

O objetivo final é produzir assets que se reconheçam como PipaKlub, se encaixem uns nos outros, sobrevivam à animação e funcionem dentro do jogo. A aprovação depende desse conjunto, e não apenas de uma imagem isolada impressionante.
