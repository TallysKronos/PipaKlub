# PIP-127 — benchmark de HUDs para Soulmonsters

Estudo visual realizado em **01/11/2026**. [Galeria navegável](index.html) · [Fontes e evidências](fontes.json). Escopo: sete famílias de interface, com 27 evidências selecionadas. Este estudo não escolhe a direção da PIP-129 e não altera a HUD atual.

A conclusão é que **a identidade vem de uma gramática que organiza a experiência**, não de colar o símbolo do jogo numa interface comum. Para Soulmonsters, linha, tração, amarração, matéria leve e vida de bairro precisam explicar composição, estados e movimentos. Papel texturizado ou losangos, sozinhos, não bastam.

## Método e limites

Foram abertos e inspecionados visualmente manuais oficiais e capturas de gameplay. As páginas dos manuais são provas documentais: a diagramação externa do manual não foi confundida com a HUD dentro das capturas. A triagem de galerias e folhas de contato serviu para escolher exemplos, não para afirmar que cada imagem foi analisada individualmente em detalhe.

As observações descrevem as imagens vistas. As aplicações a Soulmonsters são **inferências/propostas de design**. Não foram executados os sete jogos, medidos tempos de animação, ouvidos sons nem testados seus controles físicos. Portanto não se atribuem durações, curvas, eficácia de UX ou intenções dos designers sem prova. O reconhecimento discutido é uma avaliação interna, não resultado de teste cego com jogadores.

| Família | Versão efetivamente usada | Exploração | Batalha | Menus |
| --- | --- | --- | --- | --- |
| Pokémon Black/White | Manual oficial **Black Version**, DS | Organização dos controles; cobertura visual reduzida do campo | HUD e escolha de ações | Principal, equipe, Pokédex e mochila |
| Digimon World DS | Inglês, DS; press release japonês complementar | Cenário + fazenda na segunda tela | Informação, alvo e comandos | Formação, atributos e reserva |
| Mystery Dungeon | **Explorers of Sky**, DS | Campo e dungeon | Combate no contexto da dungeon; listas de golpes | Comandos, itens, equipe e opções |
| Persona 5 | **Original PS4**, não Royal | Cidade e dungeon | HUD, comandos e entrada em perigo | Principal, itens/equipamento e resultado |
| Yo-kai Watch | **Primeiro jogo**, 3DS | Radar e mapa | Roda e comando | Principal e equipe |
| Ni no Kuni | **Wrath of the White Witch Remastered** | Imagem oficial de mundo **sem HUD**; não valida leitura da HUD | Comandos e recursos | Submenus de batalha; pausa completa não inspecionada |
| Cyber Sleuth | **Complete Edition PC**; manual PS4 complementar | Minimap e grupo | Recursos e fila de turnos | Atributos e DigiFarm |

White não foi conferido separadamente de Black. A loja de Cyber Sleuth reúne duas campanhas: as capturas analisam a linguagem do pacote sem inventar diferenças entre Cyber Sleuth e Hacker’s Memory. Em Ni no Kuni, não generalizar uma imagem promocional sem HUD para a interface de exploração. Não se usou Ni no Kuni II. Nenhuma tela de Royal fundamenta a ficha de Persona 5.

## 1. Pokémon Black/White — economia de informação e hierarquia

**Evidências:** [BW-7](evidencias/bw-pdf-07.png), [BW-8](evidencias/bw-pdf-08.png), [BW-10](evidencias/bw-pdf-10.png). Fonte: [manual Nintendo](https://csassets.nintendo.com/noaext/image/private/t_KA_PDF/DS_Pokemon_Black).

**Observado.** Placas compactas distinguem os dois lados do combate; nome, nível e HP têm agrupamento previsível. O comando principal domina a tela inferior; alternativas ocupam áreas secundárias. Equipe, mochila e Pokédex não são a mesma lista com outra legenda. Ícones pequenos trabalham junto de palavras. A tipografia funcional é contida; o sprite conserva protagonismo. A alternância entre ambiente, comando e ficha usa as duas telas como separação física de tarefas.

**Leitura de identidade.** O reconhecimento depende do conjunto: silhueta dos status, relação entre adversários, botão principal e elenco. Isoladamente, uma barra de HP não é assinatura suficiente.

**Transferir.** Separar o dado que orienta a decisão do comando que a executa. Manter posições previsíveis sem precisar de molduras enormes.

**Não transportar.** Poké Ball, desenho das placas, touchscreen dividido e arranjo literal das quatro ações. A intro VS de líderes não foi inspecionada nesta amostra; ela exige referência específica na PIP-133.

## 2. Digimon World DS — um instrumento para administrar criaturas

**Evidências:** [batalha](evidencias/dwds-001.jpg), [campo/fazenda](evidencias/dwds-008.jpg), [formação](evidencias/dwds-012.jpg), [comunicado oficial](evidencias/dwds-pdf-01.png). Fontes: [RPGFan](https://www.rpgfan.com/gallery/digimon-world-ds-screenshots/), [Bandai Namco](https://www.bandainamco.co.jp/releases/images/3/30796.pdf).

**Observado.** Ciano, verdes luminosos, placas técnicas e pequenos conectores reaparecem. Na batalha, a área de informação e a miniatura do campo ficam separadas da cena e dos comandos. Retratos repetidos mantêm a equipe comparável. Na formação, atributos e reservas ficam explícitos. A fazenda ocupa a outra tela durante o percurso, sem transformar o chão explorável num quadro de números. Letras são compactas e o contraste entre fundos e painéis ajuda a conter a densidade.

**Leitura de identidade.** A linguagem de instrumento digital une criar, observar e combater. O painel existe para relacionar dados, não só emoldurá-los.

**Transferir.** Pipa Dex, Varal e quadro de evolução devem revelar relações diferentes do mesmo parceiro. Dados comparáveis merecem alinhamento consistente.

**Não transportar.** Circuitos neon, scan percentual, Digivice ou a densidade DS ampliada para desktop. Os dois monitores não justificam dois painéis permanentes cobrindo Soulmonsters.

## 3. Explorers of Sky — retratos e contexto com muita informação compacta

**Evidências:** [campo](evidencias/pmd-pdf-09.png), [dungeon](evidencias/pmd-pdf-10.png), [golpes/itens](evidencias/pmd-pdf-11.png). Fonte: [manual Nintendo](https://www.nintendo.com/eu/media/downloads/games_8/emanuals/nintendo_ds_21/Manual_NintendoDS_PokemonMysteryDungeonExplorersOfSky_EN.pdf).

**Observado.** Campo e dungeon recebem conjuntos de dados distintos. Localização, piso e recursos são agrupados; comandos aparecem em listas curtas sobre o mundo. Itens, golpes e equipe compartilham uma gramática de janela, com seleção, rótulo e informação numérica. Retratos pequenos tornam os parceiros identificáveis sem precisar da ilustração inteira. Texto e ícones precisam funcionar em poucos pixels; o fundo da janela estabiliza a leitura sobre o mapa.

**Leitura de identidade.** A afinidade com os parceiros e a estrutura de expedição aparecem na maneira de apresentar equipe, local e ação. Não é a decoração de madeira do manual que define a HUD.

**Transferir.** Dado contextual deve mudar conforme o modo. Conversa pode ser expressiva enquanto inventário e golpes permanecem diretos.

**Não transportar.** Belly, PP, grade tática e a estética pixel/DS como exigências para o nosso sistema. Não adicionar recursos só porque aparecem na referência.

## 4. Persona 5 — consistência sem repetir o mesmo layout

**Evidências:** [cidade](evidencias/p5-manual-019.jpg), [dungeon](evidencias/p5-manual-031.jpg), [menu](evidencias/p5-manual-034.jpg), [batalha](evidencias/p5-manual-039.jpg), [comandos](evidencias/p5-manual-040.jpg), [resultado](evidencias/p5-manual-046.jpg). Fonte: [manual ATLUS, PS4 original](https://atlus.com/persona5/manual/ps4/).

**Observado.** Massas pretas e brancas, recortes, contraste forte e tipos expressivos atravessam as telas. O menu ocupa o quadro com personagem e opções; a exploração concentra informação nas bordas; a batalha aproxima comandos do personagem ativo. Seleção é explícita por forma, contraste e posição, não apenas por uma cor discreta. Texto de explicação permanece mais regular que títulos e chamadas. O resultado tem sua própria composição sem abandonar a família.

**Leitura de identidade.** O sistema repete relações gráficas, não uma única caixa. O enquadramento permite intensidade variável.

**Transferir.** Uma mesma assinatura pode existir numa interação pequena e numa apresentação de campeão, mudando escala e densidade.

**Não transportar.** Paleta preto/vermelho/branco inteira, recortes ransom, estrelas e composição dos Phantom Thieves. Um Persona 5 recolorido com pipas continuaria parecendo Persona 5.

## 5. Yo-kai Watch — o objeto do mundo estrutura a interface

**Evidências:** [campo](evidencias/yokai-pdf-22.png), [menu](evidencias/yokai-pdf-29.png), [batalha](evidencias/yokai-pdf-40.png). Fonte: [manual Nintendo/LEVEL-5](https://www.nintendo.com/eu/media/downloads/games_8/emanuals/nintendo_3ds_2/yo_kai_watch_/ElectronicManual_Nintendo3DS_YokaiWatch_EN.pdf).

**Observado.** Radar, relógio, medalhas e roda dão funções diferentes ao círculo. A equipe se organiza num mecanismo visual coerente; ações se distribuem ao redor dele. O menu usa objetos reconhecíveis junto de rótulos. O mapa oferece referências espaciais distintas do cenário. Painéis e botões são mais arredondados e coloridos do que nas referências digitais, mas continuam hierarquizados.

**Leitura de identidade.** O objeto central deixa de ser um ícone aplicado no canto e vira modo de organizar e agir. Essa relação é mais específica que simplesmente usar círculos.

**Transferir.** Investigar como carretel, amarração e continuidade do fio podem explicar foco, progressão ou tensão. A relação precisa funcionar, não apenas ilustrar.

**Não transportar.** A roda de seis parceiros, o desenho do relógio ou minijogos de stylus. Não forçar toda tela de Soulmonsters a caber num carretel circular.

## 6. Ni no Kuni — o comando participa da relação com o parceiro

**Evidências:** [comandos](evidencias/nnk-02_command-balloons.jpg), [listas](evidencias/nnk-06_spells-provisions.jpg), [mundo promocional](evidencias/nnk-world.jpg). Fontes: [capturas anotadas The Picky Champy](https://champicky.com/2020/12/15/ni-no-kuni-wrath-of-the-white-witch-battle-screen-interface-design-analysis/), [loja oficial](https://store.steampowered.com/app/798460/Ni_no_Kuni_Wrath_of_the_White_Witch_Remastered/).

**Observado.** Comandos claros em balões se agrupam junto ao retrato do treinador. As listas preservam o balão, com ícone, nome, custo e seleção. As barras informativas são mais discretas e não competem pela mesma forma de ação. Fundos claros, bordas finas e preenchimento suave combinam com a ilustração. A imagem de mundo sem HUD ajuda apenas a avaliar o contexto artístico; não demonstra quanto a interface ocupa durante exploração.

**Leitura de identidade.** A relação humano/parceiro pode ser expressa pela forma do comando. A interpretação de “ordem falada” é uma leitura de design, não uma declaração de intenção do estúdio.

**Transferir.** Mostrar quem orienta e quem age; separar ação de informação com gramática compreensível.

**Não transportar.** Balões de comando como assinatura própria, pergaminho medieval ou a estética Ghibli. Pausa completa e transições não foram verificadas.

## 7. Cyber Sleuth — densidade com alinhamento e seleção inequívoca

**Evidências:** [batalha](evidencias/cyber-3.jpg), [campo](evidencias/cyber-5.jpg), [atributos](evidencias/cyber-6.jpg), [fazenda](evidencias/cyber-7.jpg). Fontes: [loja oficial Complete Edition](https://store.steampowered.com/app/1042550/Digimon_Story_Cyber_Sleuth_Complete_Edition/), [manual de controles PS4](https://media-center.namcobandaigames.eu/manuals/digimonstory_cybersleuth/DSCS_PS4_emanual_GB.pdf).

**Observado.** Azul/ciano e superfícies claras organizam estatísticas em colunas e barras; na fazenda, o amarelo identifica a linha escolhida. Retratos, rótulos e abas distribuem informação sem depender de desenhos enormes. Na batalha, status ficam juntos e a ordem de turnos forma uma faixa própria. O minimapa é periférico. A fonte funcional e os alinhamentos repetidos estabilizam a quantidade de números.

**Leitura de identidade.** A linguagem tecnológica funciona como sistema de consulta. Os dados parecem pertencer ao mesmo instrumento mesmo quando muda a cena.

**Transferir.** Alinhar atributos, distinguir seleção de propriedade e separar estado do parceiro do ritmo da disputa. Cabeçalho expressivo não exige números inclinados.

**Não transportar.** Ciano holográfico como padrão universal, painéis de terminal ou uma fila de turnos numa batalha que usa outro ritmo. As imagens do pacote não comprovam qual campanha gerou cada captura.

## Comparação transversal

| Pergunta | Evidência útil | Consequência para nós |
| --- | --- | --- |
| O que dá reconhecimento além do logo? | Sistema de recortes P5; mecanismo YK; instrumento DW/CS | Repetir relações e comportamento, não um adesivo |
| Onde a interface pode ser intensa? | Composição diferente entre campo, menu e batalha | Exploração calma; confronto concentrado; pausa consultável |
| Qual o papel do parceiro? | Retratos persistentes e comandos atribuídos | O Elo precisa aparecer como relação entre atores |
| Como cabem muitos dados? | Alinhamentos de CS/DW; listas compactas PMD | Dados regulares sobre superfície tranquila |
| Forma pode explicar ação? | Roda YK; comando junto ao retrato em NK | Linha e nó podem comunicar vínculo, tensão e foco |
| O que hardware limita? | Separação física DS/3DS | Redistribuir por prioridade, não copiar duas telas |

## Dez princípios próprios para Soulmonsters

Os dez princípios abaixo são o resultado proposto deste estudo. Não são a direção escolhida nem aprovação artística do dono. Os critérios de conferência são metas para os mocks, não resultados de teste já obtidos.

### 1. Construção de pipa, não decoração de pipa

**Origem:** objeto funcional em Yo-kai Watch; repetição de gramática em Persona 5. **Aplicação:** um eixo de vareta, uma união amarrada e uma borda de seda precisam ter papéis consistentes na família. Se tudo for apenas um desenho sobre um retângulo, a assinatura ainda não nasceu. **Conferir:** esconder logo, personagens e ornamentos figurativos; a relação entre placa, junção e foco ainda deve unir exploração, batalha e pausa.

### 2. Linha e Armação devem parecer recursos diferentes

**Origem:** agrupamento legível de status em Black; comparabilidade em Cyber Sleuth. **Aplicação:** investigar fio/tensão para Linha e suporte/reforços para Armação, sempre com nome e valor. Energia e XP não reutilizam o mesmo sinal sem distinção. **Conferir:** versões monocromáticas, valores baixos e texto ampliado; o jogador consegue distinguir recurso e proprietário sem depender apenas de cor. Nenhuma nova regra de desgaste é criada por esse desenho.

### 3. O Elo é uma relação entre parceiros

**Origem:** proximidade entre comando/retrato em Ni no Kuni e organização da equipe nas referências Digimon. **Aplicação:** o vínculo visual deve indicar quem orienta, quem executa e qual parceiro está ativo. Um fio pode conectar elementos relacionados, sem atravessar todo o cenário. **Conferir:** troca de parceiro, membro derrotado, reserva e montaria; nunca parecer que um membro diferente está usando a ação. Não expor lore secreto para justificar um ornamento.

### 4. Explorar, disputar e consultar têm densidades distintas

**Origem:** campo/dungeon de Explorers of Sky e composições de Persona 5. **Aplicação:** bairro deixa chão e interação respirarem; batalha concentra leitura urgente; pausa aceita mais detalhe organizado. Mesma família, três ocupações. **Conferir:** os nove mocks usam o mesmo mundo e dados; área de conflito, caminho e personagem não ficam encobertos por decoração. Não exigir uma porcentagem universal de HUD para todos os cenários.

### 5. A seleção é uma amarração visível e estável

**Origem:** destaque de linha em Cyber Sleuth e contraste estrutural de Persona 5. **Aplicação:** explorar ponto de nó, pequena rabiola ou conexão curta como foco. O símbolo tem versão imóvel e contrasta também sem cor. **Conferir:** teclado, direcional e mouse levam ao mesmo alvo; foco não salta por hover incidental, e voltar recupera a escolha. O nome e o contorno do alvo continuam claros com animação reduzida.

### 6. A enroscada merece uma frase visual própria

**Origem:** forma explicando mecânica em Yo-kai Watch e separação entre alvo/comando nas referências de batalha. **Aplicação:** diferenciar aproximação, contato e enroscada confirmada com o fio e seu ponto de cruzamento; acompanhar por rótulo e instrução adequada ao estado real. **Conferir:** reconhecer enroscada versus golpe, dano ou guarda em miniatura, sem depender de som. Antes de implementar, ler a regra do motor: este estudo não redefine detecção, janela ou resultado.

### 7. Kronasta aparece nos suportes da informação

**Origem:** coerência entre universo e interface nas sete amostras. **Aplicação:** cartaz de bairro, marca pintada, anotação de oficina ou papel preso têm função na navegação e nos avisos. Não trocar todo fundo por cimento. **Conferir:** uma lista longa mantém área lisa para leitura; lambe-lambe e muro se concentram no suporte, título e estado, sem textura sob números e fala. O resultado deve comunicar bairro brasileiro sem virar cenário genérico de grafite.

### 8. Pipa TV guarda a energia dos acontecimentos grandes

**Origem:** composição dedicada de resultado em Persona 5; separação entre informação e espetáculo nas batalhas estudadas. **Aplicação:** VS do campeão e vitória podem assumir enquadramento de transmissão com assinatura Soulmonsters. O status persistente continua contido durante a ação. **Conferir:** leitura de nome, adversário e condição da disputa antes da liberação; reprise/pular/movimento reduzido mantêm informação. A sequência VS de Black/White ainda precisa de inspeção específica; nenhum timing foi copiado ou medido aqui.

### 9. Uma família, instrumentos de consulta diferentes

**Origem:** equipe/Pokédex/mochila em Black, formação/fazenda em DW, listas contextuais em PMD. **Aplicação:** Dex é consulta, evolução é relação, Varal é organização e emblemas são trajetória de 12 conquistas. Eles compartilham materiais, foco e tipografia, sem serem a mesma grade reciclada. **Conferir:** vazio, cheio, bloqueado e detalhe extenso; cada tela deixa claro o que se pode fazer e o que só informa.

### 10. Reconhecimento precisa sobreviver à redução do efeito

**Origem:** redundância de forma, contraste, retrato, texto e posição observada em várias famílias. **Aplicação:** a assinatura continua com movimento reduzido, sem som, texto maior e fundo difícil. Fonte de título pode ter personalidade; números e descrições mantêm regularidade. **Conferir:** pranchas sem logo em miniatura e quatro resoluções, incluindo foco de controle e mouse. Primeiro revisão interna; só declarar reconhecimento por jogadores depois de um teste real, com método e resultado registrados.

## Como os princípios entram na PIP-128

| Direção | Pergunta a responder | Risco principal |
| --- | --- | --- |
| A — papel de seda e vareta | A tensão entre superfície e suporte organiza a informação? | Virar painel de bambu genérico ou textura demais |
| B — muro do bairro | A hierarquia de cartazes comunica Kronasta e campeonato? | Parecer outro jogo de recortes/grafite; ruído permanente |
| C — carretel e Elo | O percurso do fio torna foco, vínculo e recurso compreensíveis? | Fazer roda decorativa ou interface tecnológica genérica |

As três precisam provar os dez princípios nos mesmos contextos: exploração, batalha e pausa. Não há vencedora antecipada. A decisão PIP-129 compara identidade, leitura, interação e custo; não ganha automaticamente a proposta com mais textura ou animação.

## O que este estudo não autoriza afirmar

- Não medimos duração, curva, ritmo sonoro, latência ou legibilidade em controle físico dos jogos de referência.
- Não identificamos fontes comerciais nem autorizamos reutilização de arte, ícones ou screenshots como assets.
- Não comprovamos a intro VS de Black/White; isso fica explícito para a PIP-133.
- Ni no Kuni tem cobertura parcial do campo e da pausa; a análise de comando está sustentada pelas telas de batalha e listas. Seu peso na comparação fica restrito a essa evidência.
- O kit Recorte atual não foi reprovado por um teste de usuário nesta tarefa. O pedido do dono inicia uma nova direção; este estudo fornece critérios, não uma falsa auditoria retrospectiva.

## Entrega e reprodução

`fontes.json` registra crédito, versão, endereço direto, localizador, data e SHA-256 de cada imagem. `evidencias/` contém apenas a amostra selecionada, não manuais completos nem pacotes de sprites. A página `index.html` permite filtrar por jogo e ampliar cada evidência. Os arquivos de referência são de seus respectivos titulares, usados aqui como estudo crítico, sem licença implícita para produção.

A inspeção e os dez princípios são a entrega local da PIP-127. A PIP-128 continua pendente: nenhum dos nove mocks foi criado nesta etapa. Nenhum merge, push ou alteração no Linear foi feito.
