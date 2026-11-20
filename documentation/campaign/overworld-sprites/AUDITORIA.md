# Overworld da campanha Godot

Base de auditoria: 37956dcf de claude/unificacao. Trabalho em codex/overworld-campanha. O cadastro de distritos, eventos e cenas condicionais é a fonte da tabela. Uma ligação existente fica como “registrada” até ser conferida em jogo. A tabela é cumulativa e ainda não cobre todos os atores do prólogo ao pós-jogo.

| Personagem | Cena ou condição | Referência | Sprite encontrado | Ação | Integração |
|---|---|---|---|---|---|
| Faye | Estádio, lobby antes da final da chave e arquibancada durante o duelo pelo título | [Prancha aprovada](../../../art/characters/faye/concept-v1/prancha.png) | faye.png, 64 × 96 | Reutilizada a montagem de elenco por rodada | Integrada e renderizada nas duas posições |
| Raposa ártica | Estádio, ao lado de Faye no lobby e na arquibancada | [Referência aprovada](../../../art/creatures/raposa-artica/referencia-aprovada.png) | raposa-artica.png, 64 × 64 | Pose de repouso. Lacertubo segue como oponente no duelo | Integrada e renderizada nas duas posições |
| Atendente do Campeonato | kronasta-estadio-a, evento 32002 | Kael em jogo, Veyra, figurino novo de funcionário do Estádio | Professor na base | Sprite estático próprio no evento de interação | Integrado e renderizado em Godot |
| Grampo | Estádio, quartas e arquibancada | Folha de Beira-Canal | grampo-idle-eight.png | Conferidas as posições por rodada e na cerimônia | Renderizado no Estádio |
| Platyx | Estádio, quartas e arquibancada; Beira-Canal; Câmara | Arte de Beira-Canal | platyx-overworld-eight.png | Conferida a saída da Câmara e a presença ao lado de Grampo no Estádio | Verificado na Câmara e no Estádio |
| Tyler | Estádio, semifinal e arquibancada; clareira | tyler-clareira-v1 | tyler-overworld-idle-eight.png | Conferida a presença com Rai no Pântano e no elenco do Estádio | Renderizado no Pântano e no Estádio |
| Jamile | Estádio, duelo pelo título e entrega da fita | Kit Câmara do Elo | jamile-0/1/2.png | Alterna as duas poses de passada e entrega a fita a Kael | Renderizada e animada no Estádio |
| Dona Neve | Serra C e reunião dos campeões no Centro | Bíblia, cadastro e roteiro da reunião. Figurino de montanha proposto | Professor nas duas cenas na base | Sprite próprio registrado no duelo e na reunião | Integrado e renderizado nas duas cenas |
| Veyl, Sora | Serra A, eventos gerados por ParkCheckpoint | districts.json, posto de vigia e abrigo | Professor na base | Poses próprias de duelo. Veyl afastado do barranco | Integrados e renderizados |
| Oren, Kaiva | Serra B, eventos gerados por ParkCheckpoint | districts.json, trabalho com linha e passarela | Professor na base | Poses próprias de duelo. Oren afastado do barranco | Integrados e renderizados |
| Davi, Vitra | Centro A | districts.json, papéis e falas | Professor na base | Poses próprias de duelo | Integrados e renderizados |
| Sinal, Oriel | Centro B | districts.json, papéis e falas | Professor na base | Poses próprias de duelo | Integrados e renderizados |
| Leo Antena | Centro C, campeão | Cadastro e roteiro. Colete de rádio proposto | Professor na base | Sprite próprio | Integrado e renderizado |
| Jair, Lívia | Condomínio A | districts.json, papéis e falas | Professor na base | Poses próprias de duelo | Integrados e renderizados |
| Tomé, Rute | Condomínio B | districts.json, papéis e falas | Professor na base | Poses próprias de duelo | Integrados e renderizados |
| Tainá | Condomínio C, campeã | Cadastro e roteiro. Figurino esportivo proposto | Professor na base | Sprite próprio | Integrado e renderizado |
| Neris, Varko | Porto Novo A | districts.json, sinalização e amarração de carga | Professor na base | Poses próprias de duelo | Integrados e renderizados |
| Elune, Tervan | Porto Novo B | districts.json, manutenção da doca e manobras no canal | Professor na base | Poses próprias de duelo | Integrados e renderizados |
| Capitão Jurandir | Porto Novo C, campeão | Cadastro e roteiro. Casaco naval proposto | Professor na base | Sprite próprio | Integrado e renderizado |
| Vael, Ilyra | Mirante A | districts.json, subida e leitura do vento | Professor na base | Poses próprias de duelo | Integrados e renderizados |
| Orvik, Senael | Mirante B | districts.json, guarda da trilha e círculo de Ícaro | Professor na base | Poses próprias de duelo | Integrados e renderizados |
| Ícaro | Mirante C, campeão | Cadastro e roteiro. Jaqueta ocre proposta | Professor na base | Sprite próprio | Integrado e renderizado em (23, 8), com rota alcançável |
| Dona Cida | Exames Azul e Vermelho e Copa Relâmpago | Bíblia e endgame_story.gd | Celina no Centro e posto sem ator no Exame Azul | Pose própria de árbitra nas três cenas | Integrada, renderizada e interagível nas três cenas |
| Produtor da Pipa TV | Centro A, ato 5 | endgame_story.gd | Tião na base | Pose própria de produtor | Integrado, renderizado e interagível |
| Guarda-parque Dito | Bosque A, distinto de Dito do Bambuzal | Evento 943 do mapa e fala sobre as rampas | Ocultado por ParkOverworldView na base | Pose própria de guarda-parque no evento original | Integrado, renderizado e interagível |
| Desalmado | Centro B e Lajes A, Noite do Cerol | Bíblia e transição CitySoul | Capanga no cadastro, substituído pelo atlas tingido em jogo | Sprite cinzento sem rabiola nas duas cenas, com transição para as espécies recuperadas | Integrado, renderizado e interagível |
| Navalha | Bosque C e Galpão | endgame_story.gd, arte do Bando | Capanga na base | Pose própria nas duas aparições | Integrado, renderizado e interagível |
| Peteca, Cola-Fina | Galpão, primeiro e segundo duelos | endgame_story.gd, arte do Bando | Capanga na base | Poses próprias selecionadas pelas rodadas pendentes | Integrados, renderizados e interagíveis |
| Gollia | Galpão e Câmara | warehouse-v1 e historia-v1 | gollia.png e gollia-arrependido.png | Carretel no Galpão e entrada de mãos vazias na Câmara | Validado no Godot |
| Rato e capangas | Bosque C, Câmara, Galpão e barreira noturna | Kit Câmara do Elo | rato-idle-eight.png e variantes feminina/masculina | Conferir a vigia, a Câmara, as rodadas 4 e 5 e a barreira | Validado no Godot |
| Eremor | Câmara D, após despertar | Kit Câmara do Elo | eremor-overworld-idle.png | Proporção e enquadramento conferidos ao lado de Kael | Renderizado após o despertar |
| Mormaço | Pântano C, encontro e transformação | Bíblia, forma livre e possuída aprovadas | mormaco_overworld.gd controla o ator | Conferidos encontro, possessão, chegada de Tyler e libertação | Fluxo gráfico verificado com combate automatizado |
| Heleana | Casa e reunião com Retalho | Bíblia e concept | Atlas e folha de caminhada existentes | Reencontro conferido nas duas vertentes | Fluxo nativo verificado |
| Retalho | Casa e reencontro, seguidora de Kael ou residente com Heleana | Bíblia, concept e folha de oito direções aprovada | Idle preservado, mais 16 poses de passada | Alternância de poses e retorno ao idle na casa | Integrada e verificada nas duas vertentes |
| Retalho mascarado | Bosque e arco de confiança | Concept de máscara e cicatrizes | retalho-mascarada-v1/overworld.png | Conferida a pose no Bosque e no Pântano, a interação e a saída da clareira após a vitória | Fluxos gráficos verificados |
| Rai | Clareira e Pântano, ao lado de Tyler | Concept e rig próprios | tyler-clareira-v1/rai-overworld-idle-eight.png | Conferida a pose 64 × 96 na Clareira e na chegada de Tyler ao Pântano | Validado nos dois fluxos |
| Pipeiro Fantasma | Centro C, após completar o distrito | Bíblia, prancha de Tyler e tyler_arcs.gd | Professor na base | Pose própria com capuz para o disfarce de Tyler | Integrado e renderizado. Oculto antes de concluir o Centro e após a resolução |
| Rastro dos Ventos | Companheiro equipável na casa, na Vila e nos mapas da campanha | Concept v2 indicado em evolutions.json | Arte provisória de combate na base | Folha de 64 × 64 com repouso, corrida e espelhamento lateral | Integrado e renderizado nos três contextos |
| Zeca, Bia, Juninho, Lia, Tião e Mikka | Morro do Sol, cinco duelos | Cadastro e eventos do Morro | Sprites próprios | Conferidos os dois atores do duelo em dupla | Validados no Godot |
| Nara, Dito, Célia, Bento e Lohan | Vila do Bambuzal A–C | Atlas isométrico v2 | Cinco folhas de oito vistas | Giro para Kael ao interagir | Integrados no Godot |
| Vaeli, Noxen, Soryn, Eriska e Kleie | Beira-Canal A–C | Atlas isométrico v2 | Cinco folhas de oito vistas | Giro para Kael ao interagir | Integrados no Godot |
| Veyra, Orven, Zafri, Nymel, Dona Zulmira e Seu Lalau | Feira A–C | Eventos da Feira | Seis folhas de oito vistas | Giro para Kael nos duelos e no diálogo com Seu Lalau | Integrados no Godot |
| Neril, Ossian, Vaelis, Rhuna e Marisol | Cais A–C | Eventos do Cais | Cinco folhas de oito vistas | Giro para Kael ao interagir | Integrados no Godot |
| Vasken, Rivka, Odrik, Teyra e Bruno Solda | Vila Operária A–C | Cadastro da Vila Operária | Cinco poses top-down de 64 × 64 | Câmera mais elevada após revisão visual, com apoio preservado | Integrados no Godot |
| Seyran, Oruvo, Kessai, Veldren e Caio Garça | Palafitas A–C | [Sprites isométricos v2](../../../art/characters/palafitas-overworld-v2/README.md) | Cinco poses 64 × 64 com base comum | Caio fica no patamar (29, 14) após a classificação e usa a mesma pose na reunião dos campeões | V2 ligada aos eventos no Godot |
## Giro de NPCs nos bairros

Nas cenas especiais, Dona Cida, o produtor da Pipa TV, o guarda-parque Dito e o atendente do Estádio têm folhas de oito vistas e giram ao interagir. Faye usa a folha direcional na composição do lobby e da arquibancada.

Centro, Lajes, Porto, Serra e Mirante usam 26 folhas novas de oito direções, inclusive no encontro com o Pipeiro Fantasma. As poses mantêm a altura e o apoio dos sprites anteriores. O teste de elenco abre a interação em cada direção projetada no mapa e confere a célula selecionada pelo Godot. As [prévias por bairro](../../../art/characters/kronasta-oito-direcoes/README.md) mostram as folhas usadas no jogo.
