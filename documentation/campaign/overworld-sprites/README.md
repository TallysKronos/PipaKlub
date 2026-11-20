# Sprites de overworld da campanha

## Primeiro lote

Seis poses estáticas para eventos de mapa. Referências de acabamento e escala: Kael atual do Godot e Veyra da Feira. Os figurinos são propostas baseadas nos papéis da campanha. A arte-base, o prompt e a fonte Aseprite ficam junto de cada personagem em `art/characters/<id>/overworld-v1/`.

Foram usadas a geração integrada de imagens e a normalização em Aseprite. As imagens foram recortadas à mesma altura de célula, com paletas de até 24 cores e transparência binária. Os PNGs medidos estão em [validacao-png.json](validacao-png.json).

A ferramenta `res://tools/overworld_cast_review.gd` monta checkpoints em memória e procura o Sprite2D visível com a textura esperada. Em modo gráfico ela registra as sete aparições em [capturas](capturas/). O Estádio, o cume e a reunião mostram as novas artes no fluxo normal de criação dos atores. Na captura do Mirante uma árvore compete com a leitura de Ícaro. No Porto, o Godot registrou uma falha de carregamento da textura de piso bloquete.png, embora o sprite do Capitão tenha sido renderizado.

Regressões executadas no Godot 4.7.2 com perfil de teste isolado: Estádio, roteiro dos atos finais (98 verificações), staging dos atos finais, Heleana, confiança da Retalho (97) e Mormaço (53). Nenhuma registrou falha de asserção. O teste de Heleana registrou avisos de objetos e recursos na saída. Os testes de Retalho e Mormaço incluem resultados de combate simulados e não substituem a revisão visual das variantes.

A auditoria acompanha a produção e a validação dos atores da campanha. A Faye e a raposa ártica têm sprites de repouso no Estádio.

## Segundo lote — Centro e Condomínio

Foram criados nove sprites estáticos para os quatro duelos do Centro, os quatro do Condomínio e o encontro com o Pipeiro Fantasma. Os figurinos foram propostos a partir do papel de cada NPC. O Fantasma usa a silhueta e o calçado do Tyler, com um capuz para encobrir o cabelo e preservar a revelação da história. Os PNGs de 64 × 96 usam transparência binária, até 24 cores e dois pixels de margem inferior.

O ponto de Ícaro passou de (24, 6) para (23, 8) no Mirante C, no mesmo nível do piso, para afastá-lo da árvore. O cadastro do duelo aponta para a mesma célula do evento. Os IDs de eventos e duelos foram preservados, inclusive o ID legado de Davi usado na progressão.

As suítes de fluxo dos distritos, nomes dos distritos, arcos opcionais de Tyler e viagem passaram nas 185 verificações. A suíte de fluxo informou dois objetos ainda ativos ao encerrar.


O Godot gerou 16 capturas, incluindo os nove atores do segundo lote. O teste confirmou a rota até Ícaro e as três condições de visibilidade do Pipeiro Fantasma. A falha do piso do Porto não se repetiu nesta rodada. A importação retornou sucesso, com um aviso de gravação segura das preferências do editor no perfil isolado. As capturas usam checkpoints de teste e não reproduzem um playthrough completo.

## Terceiro lote — Porto Novo e Alto do Mirante

Os oito tenentes receberam poses estáticas de 64 × 96 com apoio na mesma linha das poses do Centro e do Condomínio. Os figurinos são propostas a partir das falas dos duelos. No Porto, os acessórios distinguem sinalização, carga, oficina e pilotagem. No Mirante, destacam corrida na trilha, leitura do vento, guarda da passagem e o círculo de Ícaro. As pranchas-fonte e os prompts ficam em `art/characters/porto-novo/overworld-v1/` e `art/characters/mirante/overworld-v1/`. As fontes Aseprite ficam nas pastas de cada NPC.

Os mapas passaram a declarar o sprite de cada evento pelos caminhos da arte de campanha. Foram preservados os IDs, as posições e o contrato de progressão dos duelos. A ferramenta de captura aceita uma lista de alvos após `--`, o que permite repetir somente as cenas em revisão.

## Quarto lote — Alto da Serra

Veyl, Sora, Oren e Kaiva usam o mesmo formato de 64 × 96. Os sprites foram associados pelo cadastro de duelos usado pelo ParkCheckpoint para criar os eventos. A prancha-fonte e o prompt ficam em `art/characters/serra/overworld-v1/`.

Na primeira captura, os barrancos cobriam Veyl e Oren. Veyl passou de (20, 17) para (22, 17) no Sopé e Oren passou de (29, 14) para (26, 14) na Encosta. Os dois conservaram a altura do piso, aparecem inteiros ao lado de Kael e têm caminho a partir da entrada da área. A captura da Encosta também registrou um painel de objetivo vazio e alto no checkpoint de teste. O layout desse painel ficou fora do lote de sprites.

Foram registradas 12 novas capturas no Porto, no Mirante e na Serra. A lista de PNGs validados contém 27 texturas. As importações do Godot terminaram com código zero e o editor registrou o aviso de gravação segura no perfil de teste.

## Quinto lote — Liga, Pipa TV e Bosque

Dona Cida usa a mesma pose no Posto da Liga, no Exame Vermelho e na Copa Relâmpago. O Produtor da Pipa TV recebeu sprite próprio para a Praça da Matriz. O guarda-parque Dito voltou ao Bosque A com seu evento original e a fala sobre as rampas de terra. O posto e o guarda-parque também estão associados à arte nos mapas-fonte e nos geradores.

Os figurinos são propostas baseadas nas funções da história. Dona Cida leva um apito e um livro de registro. O Produtor usa um headset e leva uma prancheta. O guarda-parque carrega um mapa de trilha e tem chapéu e lenço próprios. As três poses de 64 × 96 têm até 24 cores, transparência binária e dois pixels de margem inferior.

Foram capturadas as cinco aparições junto de Kael. O roteiro de conferência verificou rota desde a entrada, seleção do evento por proximidade e emissão da interação correspondente em cada ponto.

O Exame Azul (47), o roteiro dos atos finais (98) e a integração do Bosque (114) passaram sem falhas de asserção. A suíte de encenação dos atos finais também passou. O teste do Exame Azul informou objetos e recursos ainda em uso ao encerrar.

## Sexto lote — Bando e Noite do Cerol

Navalha, Peteca e Cola-Fina receberam silhuetas próprias. O preto, o verde-musgo, as faixas e a insígnia amarela vêm da direção do Bando existente. O capuz assimétrico, os ombros largos e o avental com óculos distinguem os três. Os figurinos são propostas e as fontes editáveis ficam nas pastas de cada personagem.

O Galpão conserva o evento do cadeado e escolhe o sprite pela próxima rodada pendente no save. As três primeiras rodadas usam Peteca, Cola-Fina e Navalha. As duas últimas reaproveitam os capangas do Bando. Navalha usa o mesmo sprite na tempestade do Bosque.

O Desalmado usa uma silhueta menor, cinzenta e sem rabiola nos dois eventos de rua. A flutuação é visual e mantém o ponto de interação fixo. Com redução de movimento ligada, a pose fica parada. O lote cobre a arte no overworld. Os adversários, diálogos e recompensas das batalhas permanecem os definidos no roteiro.

Foram conferidas seis aparições com Kael, incluindo os três estados do cadeado com três, dois e um nó. Os nós foram afastados do sprite para liberar a leitura do rosto. As capturas antes e depois da restauração mostram o Desalmado cinzento dando lugar a Lacertubo no Centro e Raio de Sol nas Lajes. As suítes headless do roteiro, da libertação da Trovareta e da restauração passaram em 151 verificações, além da suíte de encenação dos atos finais.

No teste gráfico da restauração com movimento, a verificação de bloqueio de input falhou tanto com o sprite novo quanto ao recolocar temporariamente a implementação anterior de CitySoul. A primeira rodada também sinalizou a retomada da exploração. Essa segunda falha não reapareceu no reteste. O painel de objetivo vazio já registrado na Serra apareceu de forma intermitente nas capturas do Galpão.

## Sétimo lote — Câmara do Elo, Mormaço e Retalho

Grampo e Platyx reaproveitam as folhas direcionais aprovadas. Na saída do Corredor do Elo, viram segundo o trajeto, Grampo mantém o apoio na projeção do mapa e Platyx alcança a porta antes de desaparecer. Eremor desperto foi conferido no patamar da Câmara ao lado de Kael. A captura compara a escala dos dois.

O teste gráfico do Mormaço passou nas 60 verificações. Ele percorreu a possessão no Pântano, a chegada de Tyler e Rai, a libertação e o reencontro com a criatura livre. A vitória foi obtida com entradas de combate automatizadas. No enquadramento de chegada de Tyler, as pontas dos jatos de Mormaço ficam parcialmente acima da borda da tela.

A nova folha de caminhada de Retalho tem 16 poses de 64 × 96, duas para cada direção. A segunda passada espelha a direção correspondente. O jogo intercala as passadas com a pose original e avança o ciclo conforme a distância percorrida. A Retalho residente e a seguidora de Kael usam a folha dentro da casa. As fontes estão em `art/characters/retalho/overworld-walk-v1/`.

O teste gráfico do fluxo de Heleana passou nas duas vertentes. Na residente foram observadas as duas passadas durante o trajeto. Na seguidora foi verificada a troca de pose pelo deslocamento e o retorno ao idle. A suíte de confiança da Retalho passou em 97 verificações headless, com resultados de combate simulados.

## Oitavo lote — Retalho mascarada e Estádio

O Bosque usa a pose aprovada da Retalho mascarada com filtro nearest. O teste verifica o acesso desde a entrada, o evento de desafio e o desaparecimento da criatura após a vitória. A campanha do Bosque passou em 43 verificações e o arco de confiança passou em 104 no modo gráfico, com resultados de combate simulados.

O lobby preserva Grampo, Platyx, Tyler e Jamile quando Kael ocupa uma posição reservada ao recarregar o mapa. A busca de uma célula alternativa prioriza o lado da arena para evitar a vitrine do troféu. A cerimônia alterna as duas poses de caminhada já existentes da Jamile antes da entrega da fita. O teste gráfico confirmou as quatro fases, as duas passadas e a entrega. As capturas do lobby ocultam o painel de objetivo apenas na ferramenta de revisão, pois o painel vazio registrado nos lotes anteriores encobriu o elenco em alguns quadros.

A final da chave usa Lacertubo no cadastro de batalha. A raposa ártica aparece junto da Faye no overworld do Estádio.

## Nono lote — Rastro dos Ventos

Rastro usa uma folha própria para acompanhar Kael, baseada no concept v2 apontado pelo cadastro de evolução. São quatro células de 64 × 64. A arte conserva as orelhas de pipa, o zigue-zague ciano e os três laços da rabiola. Todos os quadros têm transparência binária, margens livres e uma silhueta conectada.

O ciclo alterna dois quadros de repouso ou dois de corrida conforme o deslocamento do companheiro. A direção lateral usa espelhamento e a pose aérea tem cinco pixels de elevação no apoio. A casa, a Vila e os mapas isométricos da campanha usam a mesma folha em escalas ajustadas à cena. O atlas de combate continua separado.

Nos mapas isométricos, a distância de acompanhamento subiu de 0,8 para 1,25 célula para dar espaço à silhueta do Rastro. O teste gráfico com slot isolado verificou os três contextos, as duas passadas, as duas orientações e o retorno ao repouso. A suíte de evolução passou e a de corrida de companheiros passou em 2.864 verificações. O fluxo de Heleana passou, com avisos de recursos ainda em uso ao encerrar.

## Décimo lote — Gollia, Rato e capangas

O Gollia conserva a arte com carretel no Galpão. Na Câmara, o arrependimento usa uma pose de mãos vazias e duas passadas de 64 × 96, baseadas na arte de overworld existente. A entrada alterna as passadas, acompanha a projeção do piso e termina voltada para Kael. Com redução de movimento, a cena usa a pose parada. A fonte editável está em `art/characters/gollia/arrependimento-overworld-v1/`.

A revisão no Godot cobriu sete cenas e verificou os dois capangas na entrada da Câmara, as variantes das rodadas 4 e 5 do Galpão, a barreira noturna e o Rato no Bosque e na Câmara. As três poses do Gollia foram validadas quanto à transparência, ao alinhamento dos pés e à continuidade da silhueta. As suítes de história, Galpão e Trovareta somaram 226 verificações aprovadas. A suíte de montagem das cenas do final também passou.

## Décimo primeiro lote — Elenco dos bairros antigos

A revisão carregou 35 duelos em 23 mapas e conferiu 36 atores, incluindo a dupla Juninho e Lia. As artes existentes foram reaproveitadas. O teste também verifica que Caio Garça fica oculto antes da classificação. Há capturas de Lohan e Caio na pasta de capturas. Na doca, o sprite de Caio perde contraste sobre a escada, ponto que precisa de revisão visual.

Execute a checagem com Godot em modo headless e o argumento `--script res://tools/legacy_district_cast_review.gd`. Para capturas, execute em modo gráfico com `-- bambuzal-5 palafitas-5` após o script.

Caio foi movido de (26, 12) para (29, 14), no mesmo patamar da doca. A captura atual confirma que a escada saiu de trás da silhueta. A suíte das Palafitas passou 114 verificações, incluindo o caminho da entrada até o novo ponto, a classificação e o início do duelo. A inspeção do PNG encontrou 2.741 pixels parcialmente transparentes de 3.072 pixels visíveis, o que explica por que a madeira ainda interfere na leitura.

Os PNGs de Seyran, Oruvo, Kessai, Veldren e Caio passaram a usar alfa binário. A conversão preserva as dimensões e o RGB dos pixels com alfa de pelo menos 128. Os pixels abaixo desse limiar foram descartados. A revisão de Rai verifica o atlas e o recorte de 64 × 96 na Clareira e na chegada de Tyler ao Pântano. Passaram 21 verificações na Clareira, 61 no Pântano em modo gráfico e 114 no campeonato de Palafitas.

## Faye e raposa ártica

A primeira prancha da Faye, feita com ImageGen a partir do traço do Kael e do locutor, propõe uma silhueta atlética, jaqueta azul acinzentada com recorte curvo e fones coral. A prancha recebeu aprovação. A raposa tem uma pose de repouso sudoeste em PNG transparente de 64 × 64, produzida com ImageGen a partir da referência aprovada e normalizada para a escala de sprite. As duas pastas preservam o prompt. Os dois sprites são poses de repouso. A Faye e a raposa esperam no lobby antes da final da chave e vão para a arquibancada quando Jamile assume o lobby.

A revisão gráfica do Estádio confirmou os quatro estados do lobby, a mudança de posição da Faye e da raposa e a entrega da fita pela Jamile. A checagem do epílogo passou após separar da contagem o aviso de gravação que o próprio teste força. As quatro telas do epílogo seguem verificadas.

## Regressão do pacote

Passaram 36 suítes no Godot 4.7.2, incluindo exploração, campanha, classificação, elenco condicional, saves e epílogo. A suíte geral registrou 725.102 verificações em 77 mapas, sem falhas. O fluxo do Parque até Lacertubo passou 148 verificações. A revisão gráfica do Estádio passou nos quatro estados do lobby e na entrega da fita.

## Polimento dos NPCs de Palafitas

Caio, Kessai, Oruvo, Seyran e Veldren receberam contorno seletivo de um pixel. A borda de sombra ficou mais escura e a borda iluminada preserva tons mais claros. As dimensões, a máscara de alfa e os pixels internos foram preservados. As cinco texturas importadas correspondem aos PNGs e os cinco atores foram conferidos em modo gráfico. O campeonato passou 114 verificações. A captura comparativa do Caio mostra o antes à esquerda e o depois à direita.

## Palafitas isométrico v2

Os cinco NPCs foram redesenhados em três quartos com câmera elevada, em células de 64 × 64 com apoio comum e alturas visíveis entre 49 e 56 pixels. A versão estática anterior ficou preservada. Os PNGs novos foram usados nas três áreas de Palafitas e na reunião dos campeões para Caio. Passaram a revisão gráfica do elenco, as 114 verificações do campeonato e a suíte de montagem de cenas do final.
