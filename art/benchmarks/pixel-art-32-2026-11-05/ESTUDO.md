# Pixel art 2D para Soulmonsters — leitura em 32×32

Estudo de 05/11/2026, motivado pela reprovação da legibilidade do Papisco 32×32. **Conclusão: a versão produzida tem pixels nítidos, mas desenho pouco legível.** Exportação sem suavização, paleta pequena e membros conectados são condições técnicas; não provam clareza visual. O 32 precisa de desenho próprio, com informação reorganizada na grade.

Este documento reúne pesquisa em textos dos próprios artistas, inspeção de exemplos e diagnóstico dos nossos arquivos. As aplicações ao Papisco são propostas de produção, não regras oficiais dos autores ou do Digimon World DS. Não houve nova criação de personagem ou substituição de assets durante este estudo.

## 1. Fontes efetivamente estudadas

Leitura textual e exemplos visuais identificados abaixo; não alegamos ter estudado todos os tutoriais de cada artista.

| Fonte primária | O que foi consultado | Síntese curta |
|---|---|---|
| [Derek Yu — Basics](https://www.derekyu.com/makegames/pixelart.html) | Texto, especialmente seção 32×32; imagem `pinky.png` inspecionada | O espaço pequeno exige escolhas; iniciar por massas de cor pode ser mais útil que desenhar todos os contornos. Detalhes precisam servir ao volume e à leitura. |
| [Derek Yu — Common Mistakes](https://www.derekyu.com/makegames/pixelart2.html) | Texto completo | Cores muito próximas, sombras concêntricas e apêndices excessivamente finos enfraquecem as formas. Simplificação e contraste podem ajudar antes de acrescentar detalhes. |
| [Saint11 — Very Low Resolution](https://saint11.art/blog/thoughts_on_low_resolution/) | Texto completo | Escolher o que comunicar e o que omitir faz parte do desenho. A redução literal do concept não resolve essa tradução. |
| [Saint11 — Cluster Sketching](https://saint11.art/pixel_art_articles/article2/) | Texto completo | Construir massas conectadas e refinar progressivamente. Pixels isolados podem ter função, mas também produzir ruído. As escadas das curvas precisam de organização. |
| [Saint11 — Basic Shading](https://saint11.art/pixel_art_articles/article4/) | Texto completo | Separar sombra de volume, sombra projetada e brilho. Nem todo fenômeno luminoso precisa caber em uma arte pequena. |
| [Saint11 — Anti-Alias and Banding](https://saint11.art/pixel_art_articles/article5/) | Texto completo | AA é decisão manual de cor, diferente de blur. Excesso de meios-tons e faixas repetidas pode prejudicar a leitura. |
| [Saint11 — Glossary](https://saint11.art/blog/glossary/) | Texto completo | Vocabulário de clusters, dithering e pixels isolados; apresentado pelo próprio autor como sua maneira de organizar o assunto. |
| [Slynyrd — Light and Shadow](https://www.slynyrd.com/blog/2018/6/15/pixelblog-6-light-and-shadow) | Texto; GIF Lighting Tips em quatro momentos diagnósticos | Fixar a luz organiza o desenho. Materiais e sombras projetadas podem transmitir profundidade com recursos econômicos. |
| [Slynyrd — Top Down Character Animation](https://www.slynyrd.com/blog/2025/3/24/pixelblog-55-top-down-character-animation) | Texto e prancha Character Design | Desenvolver anatomia e animação simples, comparar direções e só depois detalhar. A informação estática pode virar ruído em movimento. |

As imagens públicas baixadas em `referencias/` são material de análise e mantêm a autoria original; a disponibilidade pública não concede licença de uso comercial. Não copiar seus sprites para o jogo. O estudo de MetalGreymon enviado pelo autor permanece em [outro documento](../overworld-metalgreymon-ds-2026-11-05/ESTUDO.md); ele é observação visual de uma referência, não uma explicação oficial do processo dos artistas do jogo.

## 2. O que muda de 64×64 para 32×32

Metade da largura e altura significa **um quarto da área**: 4.096 posições passam a 1.024. Cada olho, dobra ou fio continua precisando de uma decisão inteira: não existe meio pixel opaco de contorno na grade nativa. Nearest-neighbor mantém bordas duras ao exibir ou reduzir, mas não escolhe qual informação anatômica deveria sobreviver.

Em 32, o tamanho do canvas também engana. O Papisco ocupa uma caixa de apenas **20×29**, com **316 pixels opacos**. A cabeça, a pipa, os braços e os dois pendões disputam essa área real. Não temos 1.024 pixels disponíveis de preenchimento do personagem.

Nosso erro de processo foi tratar o 32 como uma versão menor do 64 e finalizar após poucas correções. A imagem de 64 pode orientar pose e cores; o desenho final deve reorganizar cabeça, focinho, peito e pés na grade menor. Isso pode incluir alargar o peito, afastar a mão e encurtar um membro, preservando sua identidade.

## 3. Hierarquia antes do acabamento

Antes de escolher sombras, escrever três sinais de reconhecimento. Para Papisco:

1. Cabeça canina com uma orelha ereta e outra dobrada, faixa branca e olho âmbar.
2. Peito-pipa marfim em losango, ligado por nós vermelhos.
3. Cauda curva com rabiola de duas abas petróleo/marfim.

O rosto infantil continua sendo de um canídeo, sem virar rosto humano genérico. A pipa precisa aparecer como pipa antes que apareçam sua costura ou vareta. Se um pequeno vinco compete com a inclinação do losango, o vinco sai. A proporção 45/45/10 é direção criativa, não divisão de área nem obrigação de desenhar cada construção de pipa.

Teste inicial proposto: em um olhar a 1×, reconhecer cão + pipa, sem consultar o concept. Não exigir que o observador descubra nome, lore ou anatomia escondida. Em seguida conferir orelha assimétrica e cauda. Se a leitura principal falhar, voltar às massas, não aumentar brilho ou número de frames.

## 4. Silhueta, pose e espaços negativos

Uma silhueta boa separa orelhas, focinho, mão e cauda por mudanças claras de direção. Isso não exige um buraco entre toda articulação: ombro e cotovelo têm conexão; mão junto do rosto pode precisar de uma coluna de ar ou de uma sombra de contato.

No Papisco atual a mão erguida está visualmente próxima do focinho. Ambos são marfim, ambos recebem preto, e os detalhes se juntam. Proposta: descer/afastar a mão 1–2 pixels e encurtar seu gesto. O personagem continua segurando linha, mas o focinho passa a ter uma forma própria. Não resolver isso abrindo um buraco no pulso.

Cabeça grande ajuda, mas olhos maiores não substituem focinho. Reservar área para testa, nariz, projeção do focinho e mandíbula. Orelhas são massas de papel com ângulo; um punhado de pixels petróleo não basta se a dobra desaparece. Cauda pode sobrepor o corpo; sua raiz precisa permanecer conectada em todas as poses.

## 5. Lineart externa: peso e custo

O preto quase puro aprovado, `#080b10`, pode continuar como assinatura. A questão é onde colocá-lo. A ferramenta de outline interno é um começo mecânico, não uma etapa final automática.

Exemplo geométrico: uma tira de 3 px de largura contornada por 1 px de cada lado fica com somente 1 px de preenchimento. Numa tira de 2 px, os lados podem consumir tudo. Isso explica por que uma mão ou pendão pode virar uma linha escura mesmo quando o filtro está correto.

Para o próximo piloto: contornar a silhueta maior com 1 px; revisar cada estreitamento manualmente; compartilhar uma borda nas sobreposições em vez de colocar dois contornos lado a lado. Se a peça precisa de cor para existir, alargá-la ou simplificá-la antes de engrossar o preto.

Não é necessário eliminar toda quina ou todo bloco 2×2: nariz, sombra de contato e uma massa de pelo podem exigir esses agrupamentos. O defeito é uma espessura acidental que muda o desenho sem função. A decisão deve fazer sentido na forma, e não somente satisfazer uma contagem de pixels.

## 6. Lineart interna: oclusão, não grade preta

Três tipos de borda pedem soluções diferentes:

| Borda | Exemplo no Papisco | Solução proposta |
|---|---|---|
| Silhueta contra cenário | Orelha externa | Preto definido, coerente com o estilo aprovado |
| Objeto sobre outro | Mandíbula sobre gola, punho sobre peito | Um traço escuro curto e contínuo ou sombra de contato |
| Mudança de luz no mesmo objeto | Lado sombreado do rosto, plano da pipa | Contraste entre preenchimentos; normalmente sem preto |

O rosto já possui preto natural. Contornar por dentro cada pixel da faixa branca estreita o foco e cria ruído. Em áreas escuras, substituir uma linha preta extra por mudança de valor pode ser mais eficiente. A proposta respeita a preferência do autor por lineart; não transfere automaticamente a preferência de outros artistas por sprites sem contorno.

## 7. Degraus e diagonais

Uma reta inclinada precisa de ritmo: 1:1 para 45°, 2:1 para uma inclinação mais baixa, ou dois comprimentos alternados quando necessário. Curvas mudam o comprimento dos degraus de maneira coerente com sua inclinação. Não usar a mesma regra rígida para um tufo intencionalmente serrilhado.

No nosso desenho, focinho e pipa devem ter poucas mudanças de direção. Na pipa, quatro diagonais legíveis dizem mais que pequenos dentes da redução. Corrigir a linha inteira entre dois vértices, em vez de deslocar um pixel e criar outro cotovelo adiante. A mesma revisão vale para o limite entre luz e sombra: também é uma linha.

## 8. Clusters: desenhar superfícies

Cluster é um agrupamento de pixels da mesma cor. No nosso uso, ele deve representar algo: máscara, focinho, gola, face iluminada da pipa ou pata. Muitos agrupamentos mínimos não são automaticamente ruins, mas a soma de manchas sem função torna o desenho difícil de interpretar.

Passagem de trabalho proposta: preencher primeiro o maior plano de cada parte; inserir uma sombra de forma; então verificar se os pixels isolados explicam algo. Olho âmbar pode ser um pixel isolado intencional. Pontos creme no meio da pelagem carvão precisam justificar brilho, mecha ou borda; caso contrário, juntar ao plano vizinho.

Evitar uma limpeza automática por maioria de vizinhos: ela pode apagar o olho, a ponta da pipa ou a linha vermelha. A limpeza é semântica. As formas grandes precisam continuar claras mesmo quando as cores intermediárias são temporariamente ocultadas.

## 9. Distribuição das sombras

Escolha inicial para a família: luz superior esquerda da tela, simples e fixa durante o ciclo. Não mudar a luz para esconder um encaixe. Para cada parte, distinguir:

- **Sombra de forma:** o plano se afasta da luz. No focinho, fica principalmente na face inferior/lateral; na pipa, numa das faces da dobra.
- **Sombra projetada:** uma parte bloqueia a luz sobre outra. Mandíbula sobre gola, gola sobre peito, mão sobre pipa. É uma faixa localizada, não um anel em volta da peça.
- **Contato:** pequenas regiões muito escuras nos encaixes. Não espalhar preto por toda a barriga.

Para a pipa marfim: começar com uma face clara e uma face sombreada grandes. O limite diagonal ajuda a mostrar a dobra. Não preencher com várias tiras cinza paralelas ao contorno. O resultado desejado é papel com volume, não uma esfera metalizada.

Para pelo carvão: conservar uma massa escura ampla e usar petróleo/cinza em poucos planos que distinguem orelha, têmpora e membro. Não iluminar todas as bordas igualmente. Nas patas claras, uma sombra curta perto do apoio pode indicar volume sem desenhar dedos completos.

Base + sombra costuma bastar nas partes pequenas. Um terceiro tom só permanece se mudar a leitura de material ou forma. Não impor sempre sombras azuis, porcentagem de luz ou uma proporção fixa de cores; luz e material têm contexto. A economia de tons serve à imagem.

## 10. Paleta, valores e foco

O PNG atual já tem só nove cores opacas. Portanto **reduzir cores novamente não é a resposta principal**. Sua organização espacial e o contraste entre regiões importam mais que a contagem.

Proposta para este personagem: manter marfim e carvão como grandes massas; petróleo reconhecível, mas secundário; âmbar reservado aos olhos; vermelho para ligação da pipa e nó da cauda. Se o olho e a vareta usam o mesmo amarelo, reduzir o destaque da vareta para o rosto continuar prioritário.

Conferir em cinza: o focinho precisa separar-se da gola, a pipa da mão e a pata do membro. Não exigir uma taxa de contraste de interface para cada par adjacente; pixels de transição podem ser próximos de propósito. Exigir contraste claro nas separações que comunicam identidade.

## 11. AA, dithering e nitidez

AA manual pode usar cores opacas intermediárias para sugerir uma borda; isso é diferente de pixels semitransparentes ou filtro bilinear. Não é tecnicamente proibido em pixel art, mas não será a primeira ferramenta para esta família em 32×32. Antes, acertar desenho, ritmo das bordas e contraste.

Sem suavização automática no PNG ou renderer. Sem dithering no rosto, mãos e peito desse piloto: essas regiões pequenas precisam de superfícies calmas. Isso é decisão para Soulmonsters, não uma afirmação de que todo pixel art com dithering é ruim. Gradientes de grandes cenários são outro problema.

Nearest-neighbor é apropriado para apresentar o nativo em 2×, 4× ou 8×. Uma ampliação limpa apenas mostra a grade existente; não corrige uma anatomia ambígua.

## 12. Auditoria concreta do Papisco entregue

Medições em `auditoria-papisco.json`, a partir dos PNGs estáticos preservados:

| Medida | Papisco 64 | Papisco 32 |
|---|---:|---:|
| Caixa ocupada | 39×58 | 20×29 |
| Pixels opacos | 1.206 | 316 |
| Cores opacas | 11 | 9 |
| Pixels da cor mais escura | 435 | 125 |
| Cor mais escura / massa opaca | 36,1% | 39,6% |

A cor escura inclui nariz, linhas e outras regiões; **não é uma medição semântica da espessura do contorno**. Serve como alerta de concentração, não como prova ou percentual ideal.

Diagnóstico visual:

| Problema | Consequência | Correção proposta |
|---|---|---|
| Figura ocupa só 20 px de largura | Peito, mãos e focinho espremidos | Redistribuir largura do núcleo, não esticar a imagem inteira |
| Pipa virou faixa clara/amarela estreita | Some a identidade de criatura-pipa | Redesenhar o losango como massa de 7–9 px de largura, valor a testar |
| Mão erguida toca visualmente o focinho | Rosto ambíguo | Separar gesto e focinho em 1–2 px, com braço conectado |
| Muitas pequenas áreas pretas internas | Preenchimentos não explicam o volume | Compartilhar bordas e omitir inlines secundárias |
| Faixa branca, olho e nariz disputam poucos pixels | Expressão instável | Desenhar o rosto isoladamente em seu orçamento nativo |
| Animação começou antes do aceite estático | Repete os problemas em todo o ciclo | Validar a pose primeiro e só depois animar |

Minha avaliação anterior confundiu reconhecimento após conhecer o concept com leitura espontânea. A revisão independente passou o sprite, mas o usuário não conseguiu lê-lo bem. A entrega continua sendo um piloto tecnicamente válido e **visualmente reprovado para o objetivo**, não uma base pronta de produção.

## 13. Plano de redesenho nativo — sem executar neste estudo

Proposta de orçamento, não geometria rígida: canvas 32×32, margens de 1–2 px; cabeça/orelhas com cerca de 13–16 px de altura, pipa de 7–9 px de largura e membros com espessura suficiente para apresentar preenchimento. A cauda usa o espaço lateral restante e não obriga o peito a ficar estreito. Essas caixas podem se sobrepor pela perspectiva.

Sequência:

1. Montar três massas em 32: cabeça, núcleo/pipa e pés. Somente cores planas.
2. Ajustar focinho, orelha ereta/dobrada, gesto e apoio. Testar silhueta.
3. Desenhar losango e separar mão do rosto. Retirar frisos e dedos.
4. Adicionar sombra de forma com luz fixa; depois sombra projetada.
5. Aplicar lineart externa e só as inlines necessárias. Recontar espaço da cor.
6. Colocar olho, nó e linha. São detalhes prioritários, não decoração genérica.
7. Rever em 1×, 2× e 8×, fundos claro/escuro/grama e cinza. Não aprovar só pelo ampliado.
8. Colher aprovação da pose. Guardar um PNG imutável de comparação.
9. Criar idle com pés fixos e caminhada com contatos e passagem visíveis. Não regenerar cabeças diferentes por frame.
10. Rever o loop em tamanho de jogo e depois em movimento no mapa. Corrigir somente onde aparecer a falha.

A geração pode fornecer concept de overworld e proporção; o arquivo final 32 exige redesenho de massas. Não descrever um simples import/resize seguido de três retoques como construção nativa resolvida.

## 14. Aceite visual e técnico

**Visual, obrigatório:** reconhecer cão + pipa em tamanho nativo; distinguir focinho da mão e peito; ler uma orelha dobrada; patas com apoio; duas abas da rabiola como conjunto simples; preto sem enterrar todos os preenchimentos. Olho e detalhes-chave não devem precisar de zoom para existir. Teste com alguém que não esteja olhando o concept ao mesmo tempo, quando disponível; não inventar aprovação humana.

**Animação:** olhos e máscara não trocam de desenho; cabeça mantém volume; uma pata sustenta o peso na caminhada; raiz da cauda permanece ligada; linhas não cintilam; não confundir bobeio inteiro com respiração. Quatro frames podem ser suficientes, mas só quando as poses comunicam a ação. Número de frames não é nota de qualidade.

**Técnico:** dimensões, alpha e paleta coerentes; PNG sem perda; GIF e tags com tempos corretos; export sem reescala não inteira. Componentes de alpha podem encontrar peças soltas, mas uma ligação de um pixel não comprova anatomia. Também é preciso comparar original e jogo, filtros e tamanho aparente. Este estudo não validou runtime.

## 15. Como o aprendizado passa a orientar o projeto

Não transportar limites numéricos de tutoriais como leis: nem todos os personagens precisam ter o mesmo número de cores, cabeça ou contorno. Não trocar nosso traço por um sprite de outra franquia. Preservar criatura/pipa, expressão específica, papel e nós por formas deliberadas.

Mudança de processo: **primeiro resolver a pose em 32×32; depois lineart e sombras; só então multiplicar frames.** Reutilizar o estudo para decidir o que omitir e o que ampliar. Se a criatura continuar ambígua, reconsiderar a distribuição de área antes de tentar uma limpeza cosmética.

Ver também o [laboratório visual local](index.html), que permite alternar escala, fundo, silhueta e cinza nos nossos arquivos preservados. Ele é um instrumento de diagnóstico, não uma nova versão do Papisco.
