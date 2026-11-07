# Percurso contínuo dos atos 4–6 · 05/11/2026

Gerado por `godot/tools/campaign_walker.gd` (F05/F06 do mapa de refinamentos). O caminhante parte do salto de QA `serra` e joga pela interface real, como uma build sem QA: lê o passo, viaja pelo mapa da cidade e pelas saídas, anda pelo caminho do mapa, aperta interagir, responde cada diálogo e fecha cada duelo pelo sinal da batalha. Entre um passo e outro, fecha e reabre o jogo no mesmo save.

As vitórias são simuladas (o resultado do duelo é marcado como vitória, passando pelas viradas de meio de luta como a recusa do Platyx). O percurso não substitui um playtest humano de dificuldade, câmera e arte.

Reproduzir: `godot --path godot -s tools/campaign_walker.gd -- --from=serra --until=final` (relatório em `tmp/campaign-walk/report.md`).


Início: salto QA `serra`. Duelos: 53. Problemas: 0.

## Registro

## tufanocorte — Suba a Serra a pé até o Cume e solte o Tufanocorte.
   saída 'Continuar a subida' (kronasta-montanha-a → kronasta-montanha-b)
   saída 'Continuar a subida' (kronasta-montanha-b → kronasta-montanha-c)
   em kronasta-montanha-c · HUD: Suba a Serra a pé até o Cume e solte o Tufanocorte.
   [Tufanocorte] Tufanocorte: Você subiu até aqui a pé. Agora corte os fios que prendem o meu vento. / Kael: Aguente firme. Vou soltar você. → Enfrentar
   duelo: Tufanocorte (tufanocorte-story, Nv 29)
   [Aviso] Tufanocorte: Os fios cederam. Agora escute o vento que sobe pela pedra. / Corrente de Ar registrada. → Entendi

## serra-habilidades — Aprenda Cavar com o tatu e suba o paredão com a Corrente de ar.
   em kronasta-montanha-c · HUD: Observe o tatu no cume da Serra para aprender Cavar.
   [Tatutrama] O tatu arranha a terra com as garras, para, depois escuta o chão. Sob a camada solta, aparece a ponta de uma vareta. / Kael: Entendi. Primeiro eu procuro onde a terra cede. Depois cavo sem forçar. → Aprender Cavar
   [Aviso] Cavar aprendido. Experimente na terra fofa perto do mirante. → Entendi
   em kronasta-montanha-c · HUD: Experimente Cavar na terra fofa do cume.
   [Aviso] Tatutrama cava ao lado da terra fofa, perto do mirante, e olha para você. → Entendi
   (sem mudança em 'Tatutrama'; tentando a próxima ação)
   em kronasta-montanha-c · HUD: Experimente Cavar na terra fofa do cume.
   [Terra fofa] Há algo logo abaixo da superfície. → Cavar
   em kronasta-montanha-c · HUD: Volte à terra fofa para abrir a galeria sob a Serra.
   [Aviso] Tatutrama cava ao lado da terra fofa, perto do mirante, e olha para você. → Entendi
   (sem mudança em 'Tatutrama'; tentando a próxima ação)
   em kronasta-montanha-c · HUD: Volte à terra fofa para abrir a galeria sob a Serra.
   [Passagem sob a Serra] Kael: Tem uma galeria aqui embaixo. Posso voltar por esta abertura. → Entrar na galeria
   em mina-ferro-a · HUD: Galeria sob a Serra · volte à superfície pela abertura por onde você desceu.
   em kronasta-montanha-c · HUD: Use Corrente de Ar no paredão abaixo do mirante.
   [Aviso] Tatutrama aponta o focinho para o paredão abaixo do mirante, onde o vento sobe. → Entendi
   (sem mudança em 'Tatutrama'; tentando a próxima ação)
   em kronasta-montanha-c · HUD: Use Corrente de Ar no paredão abaixo do mirante.
   [Corrente de Ar] O vento sobe pela face da rocha. Kael pode usá-lo para alcançar o patamar acima. → Subir com o vento

## dona-neve — Vença os quatro desafios do Alto da Serra e dispute o emblema com a Dona Neve.
   saída 'Descer à parte anterior' (kronasta-montanha-c → kronasta-montanha-b)
   saída 'Descer à parte anterior' (kronasta-montanha-b → kronasta-montanha-a)
   em kronasta-montanha-a · HUD: Converse com Veyl · 0/4 desafios vencidos.
   [Veyl] O vento bate de frente no posto de vigia. Firme os pés e mostre sua linha. / Adversário Nv. 27 · vence quem conquistar 2 rodadas. → Disputar
   duelo: Veyl (district, Nv 27)
   [Aviso] Veyl: Você segurou o primeiro rajado. Sora espera perto do abrigo. → Entendi
   em kronasta-montanha-a · HUD: Converse com Sora · 1/4 desafios vencidos.
   [Sora] Perto do abrigo, o vento troca de lado. Ataque quando ele abrir espaço. / Adversário Nv. 27 · vence quem conquistar 2 rodadas. → Disputar
   duelo: Sora (district, Nv 27)
   [Aviso] Sora: Você leu a mudança do vento. Vá à encosta. → Entendi
   saída 'Continuar a subida' (kronasta-montanha-a → kronasta-montanha-b)
   em kronasta-montanha-b · HUD: Converse com Oren · 2/4 desafios vencidos.
   [Oren] Quem trabalha com linha aprende a esperar. Vamos ver se você também sabe. / Adversário Nv. 28 · vence quem conquistar 2 rodadas. → Disputar
   duelo: Oren (district, Nv 28)
   [Aviso] Oren: Uma linha firme vale mais que um puxão forte. Procure Kaiva. → Entendi
   em kronasta-montanha-b · HUD: Converse com Kaiva · 3/4 desafios vencidos.
   [Kaiva] A passarela estreita ensina a escolher um passo de cada vez. Está pronto? / Adversário Nv. 29 · vence quem conquistar 2 rodadas. → Disputar
   duelo: Kaiva (district, Nv 29)
   [Aviso] Kaiva: Dona Neve espera no cume. Leve o que aprendeu com a gente. → Entendi
   saída 'Continuar a subida' (kronasta-montanha-b → kronasta-montanha-c)
   em kronasta-montanha-c · HUD: Quatro desafios vencidos · encontre Dona Neve no cume.
   [Dona Neve] Você subiu, ouviu os quatro e chegou com a linha inteira. Agora enfrente a campeã do Alto da Serra. / Adversário Nv. 30 · vence quem conquistar 2 rodadas. → Disputar
   duelo: Dona Neve (district, Nv 30)
   [Aviso] Dona Neve: A Insígnia do Alto da Serra é sua. Pode seguir em direção ao Centro. / Insígnia recebida · Alto da Serra. O próximo destino está no mapa de Kronasta. → Entendi

## rabiolava — Atravesse a ponte da Ilha do Aracati e solte a Rabiolava no terreiro.
   viagem pelo mapa da cidade: kronasta-montanha-c → kronasta-aracati-a
   saída 'Trilha costeira' (kronasta-aracati-a → kronasta-aracati-b)
   saída 'Trilha costeira' (kronasta-aracati-b → kronasta-aracati-c)
   em kronasta-aracati-c · HUD: Atravesse a ponte da Ilha do Aracati e solte a Rabiolava no terreiro.
   [Rabiolava] Kael: Essa linha é do Carretel Negro. Rabbito, vamos soltar a Rabiolava! → Enfrentar
   duelo: Rabiolava (ruinas-elo, Nv 33)
   [Aviso] Kael: Pronto. A linha cedeu. Você está livre, Rabiolava. / O vento quente volta a soprar sobre a ilha. → Entendi

## trovareta — Uma tempestade caiu sobre o Bosque. Vá à Clareira do Marco: a Trovareta está presa.
   viagem pelo mapa da cidade: kronasta-aracati-c → kronasta-bosque-a
   saída 'Seguir para o Bosque dos Ventos B' (kronasta-bosque-a → kronasta-bosque-b)
   duelo: ? (wild, Nv 3)
   saída 'Seguir à Clareira do Marco' (kronasta-bosque-b → kronasta-bosque-c)
   em kronasta-bosque-c · HUD: Uma tempestade caiu sobre o Bosque. Vá à Clareira do Marco: a Trovareta está presa.
   [Navalha] A tempestade não deixa as pipas subirem. Entre os raios, um tenente do Bando segura uma linha negra presa a uma pipa enorme. / Navalha: A Trovareta é do Rato agora. Se encostar nessa linha, eu corto a sua também. → Enfrentar
   duelo: Navalha (endgame-step, Nv 30)
   [Aviso] Navalha recua para dentro da chuva. A linha negra fica solta no ar, ainda presa à Trovareta. → Entendi
   em kronasta-bosque-c · HUD: Uma tempestade caiu sobre o Bosque. Vá à Clareira do Marco: a Trovareta está presa.
   [Trovareta] A Trovareta desce com a tempestade. Os fios do Carretel Negro brilham nas varetas dela. / Kael: Rabbito, corte só os fios. Não a rabiola. → Enfrentar
   duelo: Trovareta (endgame-step, Nv 31)
   [Rato] Você também deu alma a uma coisa que fez. Podia vir com a gente. / Kael: O Rabbito fica comigo porque quer. Não porque eu mando. / Rato: Então guarde essa resposta. Vai precisar dela nas Ruínas. → Continuar

## reuniao — Os campeões dos bairros esperam você na Praça da Matriz, no Centro.
   viagem pelo mapa da cidade: kronasta-bosque-c → kronasta-centro-a
   em kronasta-centro-a · HUD: Os campeões dos bairros esperam você na Praça da Matriz, no Centro.
   [Mikka] Mikka: Os quatro Ventos voltaram por sua causa. Mas o Bando continua soltando o Carretel Negro pela cidade. / Lohan: Sozinho, cada um só protege o próprio bairro. Isso não basta mais. / Kleie: Então a gente divide as ruas. Canal e Feira ficam comigo e com a Zulmira. / Marisol: O Cais e as Palafitas, eu e o Caio cobrimos pela água. / Bruno Solda: E a Vila Operária fica de olho no galpão do Bando. / Dona Neve: A subida da Serra fica comigo. O Bando não vai passar despercebido. / Mikka: Está decidido: a partir de hoje, os campeões patrulham Kronasta juntos. → Continuar
   [Aviso] Dona Cida: Kael! Venha ao posto da Liga. Está na hora da avaliação Vermelha. → Entendi

## exame-vermelho — Faça o exame da categoria Vermelha com a Dona Cida, na Praça da Matriz.
   em kronasta-centro-a · HUD: Faça o exame da categoria Vermelha com a Dona Cida, na Praça da Matriz.
   [Dona Cida] Dona Cida: Exame da categoria Vermelha. Dois duelos de avaliação, um atrás do outro, sem descanso no meio. Quero ver como você conduz o parceiro cansado. → Enfrentar
   duelo: Avaliação Vermelha (endgame-step, Nv 31)
   [Aviso] Dona Cida: Primeiro duelo aprovado. Cuide do parceiro: o segundo vem sem pausa. → Entendi
   em kronasta-centro-a · HUD: Faça o exame da categoria Vermelha com a Dona Cida, na Praça da Matriz.
   [Avaliação Vermelha] Dona Cida: Segundo duelo. Sem pausa: observe o seu parceiro. → Enfrentar
   duelo: Avaliação Vermelha (endgame-step, Nv 32)
   [Aviso] Dona Cida: Categoria Rabiola Vermelha. O Centro está aberto para você. → Entendi

## pipa-tv — Converse com o produtor da Pipa TV na Praça da Matriz.
   em kronasta-centro-a · HUD: Converse com o produtor da Pipa TV na Praça da Matriz.
   [Produtor da Pipa TV] Produtor: Você é o Kael da Rabiola Vermelha? Preciso de ajuda. Um tal de Pipeiro Fantasma solta pipas presas nos fios e some com as rabiolas. A audiência quer saber quem é. / Kael: Vou procurar. Mas primeiro, o campeão do Centro. → Continuar
   [Aviso] Pedido registrado: caçar o Pipeiro Fantasma depois de vencer o Leo Antena. → Entendi

## leo-antena — Vença os quatro desafios do Centro e dispute o emblema com o Leo Antena.
   em kronasta-centro-a · HUD: Converse com Vitra · 0/4 desafios vencidos.
   [Vitra] Todo mundo olhou pra pipa presa. Eu olhei pra linha. Quer ver como ela se soltou? / Adversário Nv. 30 · vence quem conquistar 2 rodadas. → Disputar
   duelo: Vitra (district, Nv 30)
   [Aviso] Vitra: A linha afrouxou antes de a pipa cair. Davi viu de onde veio o puxão. → Entendi
   em kronasta-centro-a · HUD: Converse com Davi · 1/4 desafios vencidos.
   [Davi] Daqui eu vejo os fios todos. Se você acompanhar minha pipa, eu mostro qual deles mexeu. / Adversário Nv. 31 · vence quem conquistar 2 rodadas. → Disputar
   duelo: Noxen (district, Nv 31)
   [Aviso] Davi: O fio balançou pro lado da Pipa TV. Pergunte a Sinal se alguma câmera pegou. → Entendi
   saída 'Próxima parte' (kronasta-centro-a → kronasta-centro-b)
   em kronasta-centro-b · HUD: Converse com Sinal · 2/4 desafios vencidos.
   [Sinal] Voltei a fita três vezes. Tem coisa no canto que ninguém reparou. Acerta meu ritmo e eu te mostro. / Adversário Nv. 31 · vence quem conquistar 2 rodadas. → Disputar
   duelo: Sinal (district, Nv 31)
   [Aviso] Sinal: A fita mostra a pipa caindo, mas a rabiola já tinha sumido. Oriel guardou o trecho inteiro. → Entendi
   em kronasta-centro-b · HUD: Converse com Oriel · 3/4 desafios vencidos.
   [Oriel] Quer ver a gravação sem os cortes do programa? Primeiro me mostra como você se sai com a sua linha. / Adversário Nv. 32 · vence quem conquistar 2 rodadas. → Disputar
   duelo: Oriel (district, Nv 32)
   [Aviso] Oriel: Tá aqui. Dá pra ver o fio e a pipa, mas o rosto ficou fora do quadro. Leva isso pro Leo. → Entendi
   saída 'Próxima parte' (kronasta-centro-b → kronasta-centro-c)
   em kronasta-centro-c · HUD: Siga até a arena do bairro.
   [Leo Antena] Você já viu o que ficou fora do ar. Agora é a sua vez de ir ao vivo. / Adversário Nv. 33 · vence quem conquistar 2 rodadas. → Disputar
   duelo: Leo Antena (district, Nv 33)
   [Aviso] Leo Antena: A Insígnia do Centro é sua. E a pista da fita aponta para longe da TV: alguém soltava as almas presas nos fios antes do Bando chegar. Fale com o Sr. Assis; ele sabe mais do que conta. / Insígnia recebida · Centro. O próximo destino está no mapa de Kronasta. → Entendi

## homunculo — Volte ao ateliê e desça ao laboratório sob a casa do Sr. Assis.
   viagem pelo mapa da cidade: kronasta-centro-c → quintal
   porta 'professor-home' na rua
   [Laboratório do Professor] Debaixo da mesa de estudos do Sr. Assis, um alçapão leva ao laboratório. Tyler encontra a gaveta com o nome dele e puxa os registros. / Um zumbido: a sentinela do laboratório acorda e fecha a escada. / Tyler: Kael, fica comigo. → Enfrentar a sentinela
   duelo: Sentinela do laboratório (tyler-lab, Nv 33)
   [Aviso] A sentinela se apaga. Os registros estão espalhados pelo chão. / Tyler: Esse registro diz que eu fui criado aqui. O resto foi apagado. / Kael: O Rabbito também foi feito, e ninguém manda no que ele escolhe. / Lá em cima, as luzes da Vila se apagam de uma vez. O Bando escolheu esta noite: começou a noite do cerol. → Entendi

## barreira — A noite do cerol caiu. No Centro, tire a braçadeira de um capanga do Bando.
   viagem pelo mapa da cidade: professor-home → kronasta-centro-a
   em kronasta-centro-a · HUD: A noite do cerol caiu. No Centro, tire a braçadeira de um capanga do Bando.
   [Barreira do Bando] A noite do cerol caiu sobre Kronasta. O Bando cortou as rabiolas de meio bairro. Uma capanga fecha a passagem do Centro. / Capanga: Sem braçadeira, ninguém passa. → Enfrentar
   duelo: Capanga da barreira (endgame-step, Nv 33)
   [Aviso] Kael pega a braçadeira do Bando. Com ela, as barreiras da noite deixam passar. / Braçadeira do Bando registrada. → Entendi

## taina — Com a braçadeira, entre no Condomínio e vença a Tainá, mesmo de noite.
   viagem pelo mapa da cidade: kronasta-centro-a → kronasta-lajes-a
   em kronasta-lajes-a · HUD: Converse com Jair · 0/4 desafios vencidos.
   [Jair] Toque de recolher no condomínio. Ei, essa braçadeira é do Bando... mas o jeito de segurar a linha, não. Duela comigo antes que alguém veja. / Adversário Nv. 33 · vence quem conquistar 2 rodadas. → Disputar
   duelo: Portaria (district, Nv 33)
   [Aviso] Jair: Você não é do Bando. Siga pelos jardins, e mantenha a braçadeira à vista. → Entendi
   em kronasta-lajes-a · HUD: Converse com Lívia · 1/4 desafios vencidos.
   [Lívia] Os capangas passam pelos jardins de hora em hora. Quero ver se você segura a linha no escuro. / Adversário Nv. 34 · vence quem conquistar 2 rodadas. → Disputar
   duelo: Jardins (district, Nv 34)
   [Aviso] Lívia: Segurou no escuro. O clube fica logo acima; lá a vigia é mais dura. → Entendi
   saída 'Próxima parte' (kronasta-lajes-a → kronasta-lajes-b)
   em kronasta-lajes-b · HUD: Converse com Tomé · 2/4 desafios vencidos.
   [Tomé] O Bando fechou o clube para guardar carretéis. Se você quer passar, prove que não está com eles. / Adversário Nv. 35 · vence quem conquistar 2 rodadas. → Disputar
   duelo: Clube (district, Nv 35)
   [Aviso] Tomé: Ninguém do Bando puxa assim. Vá pela piscina até o terraço. → Entendi
   em kronasta-lajes-b · HUD: Converse com Rute · 3/4 desafios vencidos.
   [Rute] O vento da piscina sobe direto para o terraço da Tainá. Ela só recebe quem passa por aqui. / Adversário Nv. 35 · vence quem conquistar 2 rodadas. → Disputar
   duelo: Piscina (district, Nv 35)
   [Aviso] Rute: Pronto. A Tainá já viu sua luz do terraço. Suba. → Entendi
   saída 'Próxima parte' (kronasta-lajes-b → kronasta-lajes-c)
   em kronasta-lajes-c · HUD: Siga até a arena do bairro.
   [Tainá] Do terraço dá pra ver a cidade toda apagada. Você entrou de braçadeira, mas veio pela insígnia. Vamos disputar? / Adversário Nv. 36 · vence quem conquistar 2 rodadas. → Disputar
   duelo: Tainá (district, Nv 36)
   [Aviso] Tainá: A Insígnia do Condomínio é sua. Daqui de cima eu vejo o galpão do Bando aceso na Vila Operária: é lá que eles guardam os carretéis. Desfaça os três nós do cadeado. / Insígnia recebida · Condomínio. O próximo destino está no mapa de Kronasta. → Entendi

## galpao — Invada o galpão do Bando, na Vila Operária: desfaça os três nós do cadeado.
   viagem pelo mapa da cidade: kronasta-lajes-c → kronasta-industrial-a
   saída 'Seguir pelo distrito' (kronasta-industrial-a → kronasta-industrial-b)
   saída 'Porta do galpão' (kronasta-industrial-b → kronasta-industrial-d)
   em kronasta-industrial-d · HUD: Invada o galpão do Bando, na Vila Operária: desfaça os três nós do cadeado.
   [Cadeado de três nós] O galpão do Bando tem um cadeado de três nós. Cada tenente guarda um. Depois deles, os capangas até o fundo. → Enfrentar
   duelo: Peteca (endgame-step, Nv 34)
   [Aviso] O primeiro nó do cadeado cede. Peteca sai correndo pela porta lateral. → Entendi
   em kronasta-industrial-d · HUD: Invada o galpão do Bando, na Vila Operária: desfaça os três nós do cadeado.
   [Cola-Fina] Cola-Fina: O segundo nó não solta fácil. → Enfrentar
   duelo: Cola-Fina (endgame-step, Nv 35)
   [Aviso] O segundo nó cede. Cola-Fina larga o carretel e foge. → Entendi
   em kronasta-industrial-d · HUD: Invada o galpão do Bando, na Vila Operária: desfaça os três nós do cadeado.
   [Navalha] Navalha: Na tempestade você teve sorte. Aqui dentro, não. → Enfrentar
   duelo: Navalha (endgame-step, Nv 36)
   [Aviso] O último nó estala. Navalha some entre as prateleiras, mas ainda há guardas no fundo do galpão. → Entendi
   em kronasta-industrial-d · HUD: Os três nós cederam. Vença os guardas até o fundo do galpão.
   [Capanga do galpão] Capanga: Ninguém chega ao fundo. → Enfrentar
   duelo: Capanga do galpão (endgame-step, Nv 35)
   [Aviso] Um capanga cai sentado entre as caixas. Resta um no fundo. → Entendi
   em kronasta-industrial-d · HUD: Os três nós cederam. Vença os guardas até o fundo do galpão.
   [Capanga do galpão] Capanga: Último aviso. → Enfrentar
   duelo: Capanga do galpão (endgame-step, Nv 36)
   [Aviso] O último guarda cai entre as caixas, e a porta do fundo se abre. As almas guardadas no galpão se soltam e voam pela claraboia. → Entendi

## gollia-bando — Enfrente o Gollia no fundo do galpão.
   em kronasta-industrial-d · HUD: Enfrente o Gollia no fundo do galpão.
   [Gollia] No fundo do galpão, o Gollia espera com o Carretel Negro preso ao parceiro. / Gollia: O Rato me deu força. Eu fico do lado de quem tem força. → Enfrentar
   duelo: Gollia (endgame-step, Nv 36)
   [Aviso] Gollia cai de joelhos. Atrás dele, o parceiro começa a tremer, puxado pelo Carretel Negro. → Entendi
   em kronasta-industrial-d · HUD: Enfrente o Gollia no fundo do galpão.
   [Parceiro descontrolado] O Carretel Negro sobrecarrega o parceiro do Gollia. Ele perde o controle e ataca tudo. / Gollia: Para! Eu não mandei isso! → Enfrentar
   duelo: Parceiro descontrolado (endgame-step, Nv 37)
   [Aviso] O Retalho se põe na frente do Gollia e segura o golpe. O parceiro dele cai, sem forças. / Gollia: ...Eu não queria isso. / Ele foge com o Bando, abalado. → Entendi

## gerador — Suba à torre do vento, no Cume da Serra, e chame os Quatro Ventos.
   viagem pelo mapa da cidade: kronasta-industrial-d → kronasta-montanha-a
   saída 'Continuar a subida' (kronasta-montanha-a → kronasta-montanha-b)
   saída 'Continuar a subida' (kronasta-montanha-b → kronasta-montanha-c)
   em kronasta-montanha-c · HUD: Suba à torre do vento, no Cume da Serra, e chame os Quatro Ventos.
   [Torre do vento] No Cume, a torre do vento está apagada. Um a um, os Ventos que Kael soltou chegam ao alto da Serra: Mormaço, Tufanocorte, Rabiolava e Trovareta. / Kael: O Bando prendeu as almas da cidade nesta noite. Juntos, vocês conseguem devolver todas. → Continuar
   [Aviso] A torre acende. O vento desce a Serra e atravessa Kronasta, e as luzes voltam bairro por bairro. As almas presas pelo Bando encontram o caminho de casa. / Kael: Acabou a noite do cerol. / Pipa TV: Kronasta voltou ao ar! E estão abertas as inscrições para a Copa Relâmpago, na Praça da Matriz! → Entendi

## copa-relampago — Dispute a Copa Relâmpago, o exame da categoria Dourada, na Praça da Matriz.
   viagem pelo mapa da cidade: kronasta-montanha-c → kronasta-centro-a
   em kronasta-centro-a · HUD: Dispute a Copa Relâmpago, o exame da categoria Dourada, na Praça da Matriz.
   [Copa Relâmpago] Dona Cida: Exame da categoria Dourada: a Copa Relâmpago. Três rodadas seguidas, ao vivo na Pipa TV. → Enfrentar
   duelo: Copa · 1ª rodada (endgame-step, Nv 34)
   [Aviso] Locutor: Primeira rodada vencida! A arquibancada pede a segunda! → Entendi
   em kronasta-centro-a · HUD: Dispute a Copa Relâmpago, o exame da categoria Dourada, na Praça da Matriz.
   [Copa · 2ª rodada] Locutor: Segunda rodada, sem descanso! → Enfrentar
   duelo: Copa · 2ª rodada (endgame-step, Nv 35)
   [Aviso] Locutor: Kael está na final da Copa Relâmpago! → Entendi
   em kronasta-centro-a · HUD: Dispute a Copa Relâmpago, o exame da categoria Dourada, na Praça da Matriz.
   [Copa · final] Locutor: A final da Copa Relâmpago! → Enfrentar
   duelo: Copa · final (endgame-step, Nv 36)
   [Aviso] Dona Cida: Categoria Rabiola Dourada. O Porto Novo espera por você. → Entendi

## jurandir — Vença os quatro desafios do Porto Novo e dispute o emblema com o Capitão Jurandir.
   viagem pelo mapa da cidade: kronasta-centro-a → kronasta-porto-a
   em kronasta-porto-a · HUD: Converse com Neris · 0/4 desafios vencidos.
   [Neris] Se a bandeira baixa, ninguém entra no canal. Mostre que sabe ler o sinal. / Adversário Nv. 36 · vence quem conquistar 2 rodadas. → Disputar
   duelo: Neris (district, Nv 36)
   [Aviso] Neris: Boa leitura. Varko está no fim do terminal. → Entendi
   em kronasta-porto-a · HUD: Converse com Varko · 1/4 desafios vencidos.
   [Varko] Vento lateral derruba carga mal amarrada. Vamos ver como você segura a linha. / Adversário Nv. 37 · vence quem conquistar 2 rodadas. → Disputar
   duelo: Varko (district, Nv 37)
   [Aviso] Varko: Carga segura. Procure Elune nas docas. → Entendi
   saída 'Próxima doca' (kronasta-porto-a → kronasta-porto-b)
   em kronasta-porto-b · HUD: Converse com Elune · 2/4 desafios vencidos.
   [Elune] A doca só funciona se cada peça aguenta o tranco. Vamos testar sua armação. / Adversário Nv. 38 · vence quem conquistar 2 rodadas. → Disputar
   duelo: Elune (district, Nv 38)
   [Aviso] Elune: Armação firme. Tervan está perto da saída das docas. → Entendi
   em kronasta-porto-b · HUD: Converse com Tervan · 3/4 desafios vencidos.
   [Tervan] Pra virar entre os barcos, você tem que puxar na hora certa. Quero ver. / Adversário Nv. 39 · vence quem conquistar 2 rodadas. → Disputar
   duelo: Tervan (district, Nv 39)
   [Aviso] Tervan: Boa manobra. Jurandir espera no cais. → Entendi
   saída 'Próxima doca' (kronasta-porto-b → kronasta-porto-c)
   em kronasta-porto-c · HUD: Siga até a arena do bairro.
   [Capitão Jurandir] Você passou pelo terminal e pelas docas. Agora dispute comigo a insígnia do Porto Novo. / Adversário Nv. 40 · vence quem conquistar 2 rodadas. → Disputar
   duelo: Capitão Jurandir (district, Nv 40)
   [Aviso] Capitão Jurandir: A Insígnia do Porto Novo é sua. Agora escute: ontem à noite um barco do Bando saiu daqui sem luz, levando três pessoas amarradas. A menina do Carcará, uma de óculos e a Jamile. / Capitão Jurandir: Eles desembarcaram na entrada do Coração das Ruínas, no fim do cais. Se vai atrás delas, vá agora. / Insígnia recebida · Porto Novo. O próximo destino está no mapa de Kronasta. → Entendi

## ruinas-aliados — Entre no Coração das Ruínas e solte a Nina, a Mikka e a Jamile.
   viagem pelo mapa da cidade: kronasta-porto-c → kronasta-coracao-a
   em kronasta-coracao-a · HUD: Entre no Coração das Ruínas e solte a Nina, a Mikka e a Jamile.
   [Capanga do Cerol] Capanga: A moça quase soltou o nó com os dentes. Agora ninguém chega perto. / Nina: Kael, o fio passa pelo carretel dele. Se ele perder o controle, eu consigo soltar o resto. / Kael: Então segura firme mais um pouco. → Enfrentar
   duelo: Capanga do Cerol (ruinas-elo, Nv 40)
   [Aviso] Nina: Pronto. A linha afrouxou e eu consegui tirar a mão. Ouvi o Bando falar de outra prisioneira na galeria seguinte. / Kael: A Mikka. Eu vou atrás dela. / Nina: Vai. Eu fico aqui até conseguir mexer os dedos direito. → Entendi
   saída 'Continuar' (kronasta-coracao-a → kronasta-coracao-b)
   em kronasta-coracao-b · HUD: Siga pelas Ruínas e solte a Mikka e a Jamile.
   [Capanga do Cerol] Capanga: O chefe mandou vigiar a curva. Você pode voltar pelo mesmo caminho que veio. / Mikka: Kael, ele enrolou a ponta na fivela. Se você vencer, eu alcanço o fecho. / Kael: Entendi. Deixa a linha comigo. → Enfrentar
   duelo: Capanga do Cerol (ruinas-elo, Nv 41)
   [Aviso] Mikka: Ufa. Meus óculos sobreviveram. A Jamile fez barulho de propósito pra trazer os guardas pra longe de mim. Levaram ela adiante. / Kael: Você consegue voltar até a Nina? / Mikka: Consigo. Vou buscar ela e a gente alcança você. → Entendi
   saída 'Continuar' (kronasta-coracao-b → kronasta-coracao-c)
   em kronasta-coracao-c · HUD: Siga pelas Ruínas e solte a Jamile.
   [Grampo] Grampo: Rato já entrou na câmara. Platyx, segura a linha. / Jamile: Grampo, olha pra ele. Ele está tremendo desde que você amarrou minhas mãos. / Grampo: É só mais um duelo. Vai, Platyx. → Enfrentar
   duelo: Platyx · Grampo (ruinas-elo, Nv 43)

## gollia-arrependimento — Siga até a porta da Câmara do Elo, na parte D das Ruínas.
   saída 'Câmara do Elo · sem volta até vencer' (kronasta-coracao-c → kronasta-coracao-d)
   [Câmara do Elo] Depois de entrar, só será possível sair após derrotar Eremor. → Entrar
   em kronasta-coracao-d · HUD: Siga até a porta da Câmara do Elo, na parte D das Ruínas.
   [Gollia] Gollia: No galpão, o Retalho me protegeu. Eu não esqueci. / Gollia: Vai, Kael. Eu seguro a porta. → Continuar
   [Aviso] O Gollia larga o Bando e segura os capangas na entrada. O caminho até o Rato está livre. → Entendi

## rato — Enfrente o Rato no altar do Elo.
   em kronasta-coracao-d · HUD: Enfrente o Rato no altar do Elo.
   [Rato · Bando do Cerol] Grampo: Rato, para. Olha pro Platyx. Eu achei que podia escolher por ele. Você ainda pode largar essa chave. / Rato: Passei anos vendo parceiros irem embora quando bem entendiam. Com o Elo, eu posso criar um que fique. / Kael: Se ele é obrigado a ficar, você já decidiu tudo por ele. Largue a chave. / Rato: Venha tirar da minha mão. → Enfrentar Rato
   duelo: Rato (ruinas-elo, Nv 44)
   [Altar do Elo] Kael: Acabou, Rato. A chave. / Rato: Eu prometi um duelo. Não prometi entregar nada. / Tyler: Kael, ele está indo pro selo! → Continuar
   [Câmara do Elo] Tyler: Nina, Mikka, Jamile, comigo! Grampo, segura a retaguarda. → Continuar

## eremor — O Eremor despertou. Vença o lendário antes que ele saia das Ruínas.
   em kronasta-coracao-d · HUD: O Eremor despertou. Vença o lendário antes que ele saia das Ruínas.
   [Eremor] Kael: Eremor! Olha pra mim. Você fica aqui. → Enfrentar
   duelo: Eremor (ruinas-elo, Nv 45)
   [Aviso] Kael: A linha parou de puxar. / No altar, só restaram os pedaços da chave do Elo. O Rato sumiu pela fenda durante o desabamento. / Tyler: Todo mundo passou. Vem, Kael. / Grampo: Platyx, pronto pra sair? / Kael: Primeiro, vamos recuperar a equipe. Depois, falta o Alto do Mirante. Ícaro é o último campeão de bairro. → Entendi

## icaro — Vença os quatro desafios do Alto do Mirante e dispute o emblema com o Ícaro.
   viagem pelo mapa da cidade: kronasta-coracao-d → kronasta-mirante-a
   em kronasta-mirante-a · HUD: Último bairro · quatro pipeiros guardam a subida até Ícaro, o ex-campeão que largou o título. Converse com Vael · 0/4 desafios vencidos.
   [Vael] Você é quem desceu às Ruínas e voltou com o Eremor acalmado? Então veio ver o Ícaro. Primeiro, a subida: aqui o vento muda a cada passo. / Adversário Nv. 40 · vence quem conquistar 2 rodadas. → Disputar
   duelo: Vael (district, Nv 40)
   [Aviso] Vael: Puxou contra a virada sem perder a linha. Ilyra cuida das bandeiras logo acima. → Entendi
   em kronasta-mirante-a · HUD: Converse com Ilyra · 1/4 desafios vencidos.
   [Ilyra] Repare nas bandeiras. O Ícaro ensinou a gente a ler o céu antes de ler o placar. / Adversário Nv. 41 · vence quem conquistar 2 rodadas. → Disputar
   duelo: Ilyra (district, Nv 41)
   [Aviso] Ilyra: Você leu o vento, e não a plateia. É isso que ele quer ver. Orvik guarda as passagens. → Entendi
   saída 'Próxima parte' (kronasta-mirante-a → kronasta-mirante-b)
   em kronasta-mirante-b · HUD: Converse com Orvik · 2/4 desafios vencidos.
   [Orvik] Cuido das passagens do mirante. Quando a Pipa TV quis subir com câmeras, fomos nós que fechamos a trilha. / Adversário Nv. 42 · vence quem conquistar 2 rodadas. → Disputar
   duelo: Orvik (district, Nv 42)
   [Aviso] Orvik: Rajada nenhuma te tirou do eixo. Pode passar. Senael espera na praça do topo. → Entendi
   em kronasta-mirante-b · HUD: Converse com Senael · 3/4 desafios vencidos.
   [Senael] O Ícaro só desafia quem passou por nós quatro. Ele largou o título no dia em que viu a final decidida num estúdio. Prove que sua linha é sua. / Adversário Nv. 43 · vence quem conquistar 2 rodadas. → Disputar
   duelo: Senael (district, Nv 43)
   [Aviso] Senael: Pronto. Ele já sabe que você está subindo. Sinta a mudança do vento antes de chegar até ele. → Entendi
   saída 'Próxima parte' (kronasta-mirante-b → kronasta-mirante-c)
   em kronasta-mirante-c · HUD: Siga até a arena do bairro.
   [Ícaro] Já fui campeão de Kronasta. Saí quando percebi que a TV escolhia quem merecia vencer antes do primeiro corte. / Mas ouvi falar de você: soltou os Ventos do Carretel, ligou o gerador na noite do cerol e desceu às Ruínas pelos seus amigos. Ninguém filmou isso. / Por isso aceito. Aqui em cima não tem câmera nem patrocínio. Só a linha. Mostre se ela aguenta o topo. / Adversário Nv. 44 · vence quem conquistar 2 rodadas. → Disputar
   duelo: Ícaro (district, Nv 44)
   [Aviso] Ícaro: Fazia tempo que eu não perdia assim, de verdade. Essa luta ninguém comprou. / Ícaro: A última insígnia é sua. Leve essa linha para o Estádio de Kronasta. A Jamile defende o título lá, e o título dela ainda vale alguma coisa. Faça a TV ver uma final que ela não escreveu. / Insígnia recebida · Alto do Mirante. Todas as insígnias de Kronasta estão com você. Próximo destino: Estádio de Kronasta. → Entendi

## final — Vá ao Estádio de Kronasta e dispute a chave final.
   viagem pelo mapa da cidade: kronasta-mirante-c → kronasta-estadio-a
   em kronasta-estadio-a · HUD: Fale com o atendente no balcão para disputar a próxima rodada. Você pode salvar e cuidar da equipe no lobby.
   [painel Campeonato de Kronasta] Enfrentar Grampo
   duelo: Grampo (ruinas-elo, Nv 47)
   [Aviso] Grampo: Perdemos, mas o Platyx puxou porque quis. Ele nunca voou assim comigo. / Platyx encosta a cabeça na mão de Grampo. / Grampo: A gente assiste ao resto da chave daqui de baixo. / Atendente: Próxima rodada: semifinal contra Tyler. Dá tempo de cuidar da equipe e salvar; fale comigo quando estiver pronto. → Entendi
   em kronasta-estadio-a · HUD: Fale com o atendente no balcão para disputar a próxima rodada. Você pode salvar e cuidar da equipe no lobby.
   [painel Campeonato de Kronasta] Enfrentar Tyler
   duelo: Tyler (ruinas-elo, Nv 48)
   [Aviso] Tyler: A gente aguentou até o fim, Rai. Kael, desde a Clareira eu sabia que essa luta ia acontecer. / Tyler: Vou torcer com a Heleana e o Assis. / Atendente: Você está na final da chave. Faye espera no lobby. Fale comigo quando estiver pronto. → Entendi
   em kronasta-estadio-a · HUD: Fale com o atendente no balcão para disputar a próxima rodada. Você pode salvar e cuidar da equipe no lobby.
   [painel Campeonato de Kronasta] Enfrentar Faye
   duelo: Faye (ruinas-elo, Nv 49)
   [Aviso] Faye: Então essa é a linha que chegou à final. Guarde esta luta, Kael. Um dia eu volto para a revanche. / Atendente: A chave é sua. Só falta o duelo pelo título: Jamile já está no lobby. → Entendi
   em kronasta-estadio-a · HUD: Fale com o atendente no balcão para disputar a próxima rodada. Você pode salvar e cuidar da equipe no lobby.
   [painel Campeonato de Kronasta] Enfrentar Jamile
   duelo: Jamile (ruinas-elo, Nv 50)
   [Jamile] Jamile: Da última vez, você assistiu à minha final pela TV, do seu quarto. Hoje a cidade inteira assistiu à sua. / Jamile amarra a fita dourada da Liga no carretel de Kael. / Jamile: A linha é sua, campeão. Cuide bem dela. / Rabbito pula de alegria e puxa a ponta da fita. / Tyler: Eu falei que ia ser você! / Grampo: O Platyx quer ver a fita de perto. / Heleana: Você foi lá e voltou com todo mundo, filho. → Ver créditos
   [Soulmonsters] CAMPEONATO DE KRONASTA / Criação e desenvolvimento Equipe Soulmonsters / Obrigado por jogar! → Voltar à cidade
== campanha concluída
