# Plano detalhado de refinamento — Soulmonsters Godot

Data: **05/11/2026**. Base documental e de código: `f3116a2a` mais a substituição da CI web por Godot em `b51fd293`.

Este documento detalha os dez grupos apresentados na revisão do produto. Ele é uma especificação de execução e aceite, **não uma declaração de que as correções foram implementadas**. O produto ativo é somente Godot. Código, mapas e sistemas web históricos não precisam ser mantidos funcionais para entregar esta versão.

## Como interpretar o plano

- **Confirmado:** há lacuna identificada no mapeamento, código ou capturas anteriores. A correção deve começar conferindo se a lacuna ainda existe no commit de execução.
- **Validar:** existe implementação/cobertura, mas falta observação suficiente para aprovação comercial. Primeiro testar, depois corrigir o que falhar; não reconstruir uma função já pronta sem necessidade.
- **Decidir:** uma regra precisa de definição do produto. Não transformar uma recomendação deste plano em mudança de história/economia sem aprovação.
- **Obrigatório:** sem isso, existe risco de bloqueio, perda de progresso ou promessa descumprida. **Acabamento:** requisito da qualidade artística e de experiência pretendida. **Condicional:** depende de entrar no escopo anunciado.

O percurso automatizado dos atos 1–3 registrou 44 duelos e o dos atos 4–6 registrou 53, ambos sem problemas reportados. **As vitórias foram simuladas**, com entradas preparadas e minijogos com cobertura própria. Esses relatórios comprovam cobertura de fluxo, não uma partida humana completa, balanceamento ou aprovação visual.

Referências de trabalho: [mapa S01–S66](MAPA-DE-PRONTIDAO-STEAM.md), [inventário F01–F36](../campaign/refino-atos-finais/MAPA-DE-REFINAMENTOS.md), [percurso atos 1–3](../campaign/refino-atos-finais/percurso/atos-1-3.md), [percurso atos 4–6](../campaign/refino-atos-finais/percurso/atos-4-6.md), [validação Godot](VALIDACAO-GODOT.md). Os parágrafos históricos desses relatórios podem citar pendências depois resolvidas; usar a evidência mais recente, não somar todos os estados como defeitos atuais.

### Entrega mínima de cada refinamento

Registrar condição inicial, alteração, resultado esperado, testes e limites. Para cena visual: captura antes/depois na câmera real e vídeo curto com entrada, ação e retorno ao controle. Para persistência: save de teste antes/depois e relatório de interrupção. Para batalha: jogar o duelo, além de testar o sinal de vitória. Tudo vinculado a um commit e, na aprovação final, ao executável exportado.

Não adicionar nomes, revelações, regiões ou regras econômicas ausentes da Bíblia silenciosamente. Não gerar assets antes de verificar as artes aprovadas disponíveis. Mudança de mapa exige skill de construção, referências e conferência geométrica; mudança de personagem exige as skills locais de personagem. Este plano não altera esses contratos.

## 1. História e encenação

### R01 — Prólogo: transformar exposição em descoberta

**Situação:** validar; acabamento e continuidade obrigatórios. O prólogo já existe e deve ser refinado sobre a versão atual.

**Execução:** dividir em momentos legíveis: assistir à final, decisão de Kael, mesa de criação, falta da rabiola, chegada de Heleana, presente, tentativa inesperada e nascimento. Deixar cada plano comunicar uma informação principal. Conferir posições da mãe, Kael, mesa e TV; orientar o olhar pela câmera, luz e pose. Mostrar o item centralizado com fundo esmaecido quando recebido, sem exigir animação literal de toda troca de mão. Permitir explorar quando não houver ação cinematográfica em andamento. Explicar só os controles necessários naquele momento. O aviso de próximo objetivo deve aparecer quando o controle voltar.

**Resultado:** o jogador compreende o aniversário, a ambição e a singularidade do Rabbito, sem precisar ler a Bíblia.

**Aceite:** primeira partida sem instruções externas; nome padrão e personalizado; tentar sair cedo; fechar antes/depois do presente e da nomeação; retornar sem repetir item, nascimento ou escolha concluída.

### R02 — Mural: mudança de perspectiva com começo e fim claros

**Situação:** validar; acabamento. Câmera frontal já faz parte da proposta.

**Execução:** conferir gatilho e posição de observação; parar Kael/Tyler em marcas que não escondam a ilustração. A câmera deve apresentar o mural antes do trecho de diálogo que depende dele. Preservar uma pausa de leitura e evitar que o jogador avance duas falas com a tecla da interação inicial. Na aparição de Retalho, enquadrar sua entrada antes de iniciar sua fala/reação. Salvar e restaurar câmera, zoom, limites, foco e movimento dos atores ao sair, cancelar ou retomar.

**Resultado:** a mudança parece um recurso cinematográfico deliberado dentro do jogo isométrico.

**Aceite:** entrar por lados diferentes; confirmar/cancelar; pressionar rápido; retomar a missão; nenhuma câmera fica presa nem um NPC desaparece atrás da geometria.

### R03 — Varal, Pipa-Dragão e fuga: substituir a elipse essencial

**Situação:** lacuna parcial confirmada em F13/F14; acabamento narrativo.

**Execução:** listar as ações ainda contadas pelo texto e selecionar as indispensáveis: ameaça, perda de controle, reação, abertura para fugir, decisão de Retalho e saída. Criar uma sequência de marcações no chão, com movimentos curtos e poses existentes antes de encomendar animação nova. Separar a derrota prevista da derrota comum: transição e reação precisam explicar por que a história continua. Não colocar uma caixa “eles fugiram” no lugar do deslocamento decisivo. Usar cortes entre espaços se a travessia longa não acrescentar informação, preservando origem/destino.

**Resultado:** o jogador vê a causa da fuga e entende a escolha de Retalho.

**Aceite:** vídeo sem texto descritivo de movimento; estados antes/durante/depois retomáveis; saída liberada no momento correto e sem recompensa de vitória para uma derrota roteirizada.

### R04 — Retalho e Heleana: fechar as duas vertentes

**Situação:** lógica implementada e testada parcialmente; validar interface e encenação; obrigatório.

**Execução:** na vertente aceita, exigir a presença real de Retalho no time conforme regra aprovada; preservar nome escolhido e novo laço, com reação emocional de Heleana ao reconhecê-lo sem recuperar a memória anterior dele. Na recusada, iniciar o grunhido fora da casa, mostrar mãe e Kael saindo e só então o reencontro/reconexão; Retalho seguiu Tyler, não foi concedido previamente como parceiro. Retirar qualquer condição indevida por emblema. Definir posições de chegada e destino do Retalho na casa depois da cena, coerentes com o resultado.

**Resultado:** os dois caminhos são emocionalmente completos e não se contradizem.

**Aceite:** aceito/recusado, time cheio, banco cheio, parceiro fora da equipe, nome alterado, reload no interior/exterior; sem cópia extra, renomeação indevida ou bloqueio da missão principal.

### R05 — Mormaço: duas lutas ligadas por uma transformação

**Situação:** fluxo existente; validar continuamente; obrigatório.

**Execução:** iniciar Kael contra Mormaço padrão. Ao perder 30% do HP inicial, resolver uma única transição; impedir que dano excedente pule a fase. Voltar ao overworld, mostrar os vilões lançando o carretel negro, reação, forma intermediária e posse. Usar Mormaço Soulgen no duelo e o atlas overworld correto na cena. Mostrar Tyler e Rai chegando por um caminho livre; as falas devem reagir ao que acabou de acontecer. Iniciar a segunda luta com a configuração aprovada de ajuda, deixando visível quem participa e como.

**Resultado:** transformação e reforço têm consequência perceptível na luta.

**Aceite:** dano fraco/forte no limiar, derrota em cada fase, fechamento na cutscene, retorno para preparar equipe quando permitido; sem transformação repetida ou duas recompensas pelo mesmo encontro.

### R06 — Trovareta: consolidar a libertação já implementada

**Situação:** arte e sequência integradas; caminhada do Rato ainda pendente; acabamento e validação.

**Execução:** conservar ruptura da linha, retomada da cor, decolagem, limpeza do clima e chegada do Rato antes da conversa. Jogar os duelos reais para ajustar o tempo entre término, comemoração e ameaça seguinte. Trocar a translação do Rato com pose parada por ciclo de caminhada coerente. Conferir que direção, sombra e pés acompanham o deslocamento. Mostrar a saída livre e restituir a câmera antes de pedir exploração.

**Resultado:** libertação com ritmo e continuidade, sem parecer uma coleção de eventos disparados juntos.

**Aceite:** vitória/derrota/fuga, fechar antes de encerrar a conversa, carregar depois da conclusão; chuva e Navalha não retornam indevidamente; recompensa/conclusão únicas.

### R07 — Reunião dos campeões: elenco reconhecível e conversa encenada

**Situação:** separação, foco e câmera implementados; mock Dona Neve confirmado; acabamento.

**Execução:** substituir o mock quando sua arte for produzida; conferir as oito silhuetas no cenário. Ordenar a conversa por uma necessidade dramática, eliminando saudações repetidas e falas que só recitam missão. Usar a mudança de interlocutor já existente para acompanhar a fala; incluir pequenos olhares/reações quando acrescentarem informação, sem movimentar todos o tempo todo. Preservar caminhos e área de saída de Kael durante a retirada do grupo.

**Resultado:** cada campeão tem presença e o encontro prepara o próximo objetivo.

**Aceite:** leitura a 720p, aproximação lateral, cancelamento e retomada; sem personagens sob a HUD ou sobrepostos; Exame Vermelho liberado somente no estado correto.

### R08 — Laboratório: revelar Tyler sem misturar arcos

**Situação:** sequência em três etapas existente; interior próprio e acabamento visual pendentes.

**Execução:** especificar a ordem espacial entre descoberta, ameaça/Sentinela, batalha e reação à revelação. Plantar a informação visual antes da fala explicativa; depois reservar tempo à reação de Tyler e Kael. Não usar a sidequest do Pipeiro Fantasma como pré-requisito da revelação principal. Conferir que termos e diálogos funcionam com a sidequest feita, não feita ou feita depois. Mostrar a passagem para a noite e sinalizar a mudança de objetivo sem abrir abruptamente outro arco.

**Resultado:** revelação compreensível, emocional e independente da investigação opcional.

**Aceite:** ambas as ordens de missão, recusa/cancelamento, derrota e load; sem conhecer informação antes de descobri-la, nem repetir a revelação como novidade.

### R09 — Torre e cidade: tornar a consequência inequívoca

**Situação:** torre, emissão e recuperação implementadas; cenários/variantes ainda pedem acabamento.

**Execução:** conferir causa e efeito: feixes chegam ao receptor, ativação muda o ambiente e a recuperação é vista no Centro/Condomínio. Mostrar as mesmas criaturas antes/depois, não substituí-las sem contexto. Diferenciar uma batalha opcional contra um Desalmado de sua cura pelo gerador. Ajustar a duração dos cortes para mostrar recuperação sem obrigar rever longos trechos. Na volta ao cume, manter time, posição segura e estado da cidade.

**Resultado:** o jogador reconhece que sua ação recuperou a região.

**Aceite:** retorno posterior e reload; variantes visuais coerentes; nenhuma cura antecipada por duelo, inventário alterado pela apresentação ou reaparição do estado possuído concluído.

### R10 — Campeonato e final: fechar a jornada

**Situação:** chave, título, Pipa TV e epílogo integrados em graus diferentes; retorno cinematográfico ao quarto pendente.

**Execução:** deixar o atendente organizar cada próxima batalha e permitir preparação entre rodadas. Mostrar atualização da chave de oito participantes, com Jamile aguardando fora dela. Ajustar falas de retorno após vitória/derrota e presença de Faye. Conferir a chegada da campeã, passagem do título, reação do Rabbito e comemoração. Planejar um fechamento visual que dialogue com a TV/quarto do início; manter isso separado da entrega opcional da flor. Revisar cortes para os créditos e continuação pós-jogo.

**Resultado:** vitória reconhecida pelo mundo e encerramento satisfatório mesmo sem sidequests.

**Aceite:** três rodadas de Kael mais Jamile, derrota em cada uma, retorno ao lobby, créditos, load pós-final; sem repetir título/recompensa. A flor funciona nas duas ordens permitidas e nunca bloqueia terminar.

## 2. Caverna do Elo — pacote de revisão próprio

### R11 — Resgates conquistados por batalhas

**Situação:** fluxo existe; validar visualmente e com resultados reais; obrigatório.

**Execução:** escrever uma tabela A–D com prisioneiro, guarda, condição de batalha, condição de abertura e estado após derrota. Dar ao guarda presença e fala antes do duelo; o resgate só pode ocorrer com sua condição vencida. Ao libertar, mostrar abertura e deslocamento para uma área segura, deixando o próximo objetivo claro. Retirar do texto personagens que não participam, especialmente mãe/professor. Usar os sprites aprovados dos grunts e Rato.

**Resultado:** libertação faz parte da ação de Kael, não de uma mudança invisível de flag.

**Aceite:** tentar interagir antes de vencer, perder, voltar por outra entrada e carregar após libertar; nenhum prisioneiro duplicado ou guarda reaparecido indevidamente.

### R12 — Platyx e Grampo: recusa, aproximação e reconciliação

**Situação:** virada de 50% existe; refinar apresentação observada; obrigatório.

**Execução:** interromper a luta no limiar aprovado e voltar ao cenário com atores separados. Mostrar Platyx protegendo quem precisa proteger e se recusando a atacar; usar cabeça/corpo/olhar para o contato com Grampo. Deixar a fala expressar emoção e conflito, não narrar “ele encosta a cabeça”. Grampo reage à ação antes de decidir ajudar. Guardar a decisão quando a conversa se encerra; só depois iniciar partida dos dois para a próxima sala.

**Resultado:** a mudança de lado é demonstrada e a relação fica compreensível.

**Aceite:** dano que cruza 50%, tecla mantida, pausa/reload e retorno; diálogo nunca acontece depois de os dois saírem; Platyx único mantém identidade e vínculo corretos.

### R13 — Deslocamentos e reserva de posições

**Situação:** houve problemas de empilhamento corrigidos ao longo do fluxo; validar todas as entradas.

**Execução:** definir marcas por ator em cada estado e reservar espaço por tamanho da silhueta/pés. Calcular entradas e destinos na mesma cota ou por rotas válidas. Escalonar deslocamentos por gargalos; não teleportar o grupo inteiro para o spawn do jogador. Conferir que atores que atravessam saídas são removidos apenas quando sua partida terminou. Posicionar os acompanhantes fora da área frontal de Eremor.

**Resultado:** elenco identificável, com leitura de quem está falando e para onde foi.

**Aceite:** cenas com todos os resgatados, chegada pelos dois sentidos, escadas e retorno; nenhum par ocupa a mesma posição; nenhuma sombra/pivô muda de nível antes do corpo.

### R14 — Rato, despertar, pedra e intervalo de preparação

**Situação:** cadeia aprovada; validar causalidade, impacto e recuperação; obrigatório.

**Execução:** depois da derrota do chefe, mostrar a decisão de má-fé, o deslocamento para ativar Eremor e a transformação. O rugido deve anteceder o desprendimento da pedra; enquadrar a pedra acertando Rato, com reação breve coerente com o alívio cômico. O evento não pode parecer que atingiu um aliado próximo. Após a cena, liberar exploração, cura e save; disponibilizar interação de Eremor com prompt e confirmação/contexto adequados. A luta não deve disparar por proximidade.

**Resultado:** ameaça, consequência cômica e preparação claramente separadas.

**Aceite:** repetir com movimento reduzido, não interagir com Eremor, salvar/carregar e perder; pedra e despertar não repetem por acidente, chefe continua disponível para o duelo pendente.

### R15 — Eremor e evacuação

**Situação:** validar enquadramento e fluxo completo; obrigatório.

**Execução:** manter escala grande com pivô no chão, área de aproximação e silhueta que não cubra o elenco. Usar câmera que apresente criatura e humanos em posições distintas, em vez de empilhar todos diante dela. Depois do resultado correto, mostrar Tyler/Grampo/Platyx auxiliando a saída e conferir destino dos resgatados. Registrar conclusão da sequência de maneira que reload não refaça libertações nem mantenha portas indevidamente fechadas.

**Resultado:** clímax legível e resolução espacial da caverna.

**Aceite:** A até D em uma sessão, derrota/revanche, retorno após finalização e saída pelas conexões válidas; sem atores fantasma, input preso ou missões essenciais perdidas.

## 3. Mapas e cenários

### R16 — Laboratório: planta e interior definitivos

**Situação:** interior próprio/escada pendentes; acabamento confirmado.

**Execução:** desenhar planta geométrica com acesso exterior, recepção/área de estudo, setor da revelação e ligação entre andares quando prevista. Dimensionar por Kael e pelo grupo máximo da cena. Marcar posições de professor, Tyler, Sentinela, objetos narrativos e câmera antes da arte. Só depois gerar peças proporcionais e montar em camadas. Dar função visual aos objetos, evitando preencher o chão com decoração que reduza circulação.

**Resultado:** um laboratório reconhecível, capaz de sustentar os eventos sem reaproveitamento aparente do ateliê.

**Aceite:** entradas exteriores/interiores correspondem, rotas não cruzam bancadas, escada tem início/fim coerentes, todos os atores cabem e a cena funciona sem mudar temporariamente a geometria.

### R17 — Centro e Condomínio: identidade urbana coerente

**Situação:** cenários legados identificados; acabamento.

**Execução:** separar linguagem dos dois lugares. Centro precisa comunicar circulação/comércio/vida urbana conforme sua função aprovada; Condomínio deve comunicar organização e padrão luxuoso por arquitetura, manutenção, materiais e jardim, sem virar feira reaproveitada. Construir antes os espaços dos eventos: barreiras, moradores, Desalmados e recuperação. Definir módulos comuns para manter o mesmo universo, com variação de fachadas e objetos orientados nos eixos isométricos.

**Resultado:** destinos reconhecíveis sem depender do título no HUD.

**Aceite:** referência/planta/captura comparadas; mesma escala do elenco; recuperação e noite usam o mesmo espaço, sem trocar abruptamente de cenário ou bloquear a passagem crítica.

### R18 — Torre: marco integrado ao relevo

**Situação:** função física implementada com pilar reutilizado e receptor; acabamento.

**Execução:** avaliar a silhueta na aproximação e na ativação. Ajustar base, escala, direção dos componentes e conexão dos feixes, preservando a pegada em rocha e o percurso aprovado. Se a arte atual destoar, produzir uma peça própria que respeite a geometria, sem pintar degraus/passagens inexistentes. Conferir estado apagado, recebendo energia e ativo, com luz/partículas em camadas apropriadas.

**Resultado:** marco visível e funcional, pertencente ao lugar.

**Aceite:** câmera do jogador e da cut, giro/luz persistentes após load, movimento reduzido legível e nenhuma peça atravessando Kael, paredão ou caminho.

### R19 — Continuidade geométrica de todas as áreas da 1.0

**Situação:** validação transversal obrigatória, sem afirmar que todo mapa está quebrado.

**Execução:** catalogar por parte as cotas, entradas, saídas, rampas, escadas, pontes, obstáculos e itens. Conferir cada conexão nos dois mapas, com direção/material/altura combinando. Inspecionar rampas subindo ao fundo, faces e bordas de barrancos, paredes internas/externas e cabeceiras. Água tem recorte e margem coerentes, não decalque fingindo poço. Validar alcance e largura usando o corpo real do jogador e pathfinding.

**Resultado:** aquilo que parece caminho é caminho; aquilo que bloqueia parece bloqueio.

**Aceite:** testes geométricos mais captura geral e detalhes sem ator cobrindo a junta; nenhum bolsão obrigatório inalcançável, degrau isolado, parede órfã ou acesso atravessado por mureta.

### R20 — Pisos naturais, transições e repetição

**Situação:** revisão artística por mapa; acabamento.

**Execução:** conferir escala do grão/textura antes de gerar variantes. Usar o conjunto de transições Wang/terreno para bordas e cantos completos; evitar que cada tile tenha uma moldura própria. Misturar variantes internas com distribuição controlada, preservando a continuidade entre células. Variar bordas do caminho de forma compatível com sua largura e uso; grama/mato decorativo não pode maquiar emenda ou cobrir navegação. Água e gelo precisam de leitura clara de superfície caminhável/proibida.

**Resultado:** o chão lê como uma superfície contínua desenhada, não um mosaico de peças repetidas.

**Aceite:** captura aproximada e afastada, área grande repetida e junção de três materiais; nenhum quadrado luminoso, linha involuntária, mudança de fase ou transição faltante.

### R21 — Composição, escala e ocupação

**Situação:** revisar no percurso publicado; acabamento.

**Execução:** identificar a função de cada área vazia: circulação, arena, enquadramento ou descanso. Reduzir espaço sem propósito ou criar composição útil, em vez de espalhar objetos aleatoriamente. Agrupar props por uso, estabelecer marcos de navegação e criar primeiro/segundo plano sem esconder a rota. Conferir orientação de cadeiras, portas, bancadas e estruturas nos eixos da projeção. Comparar tamanho de porta, banco, árvore e prédio ao Kael atual.

**Resultado:** ambiente habitável e intencional, sem impressão de assets jogados.

**Aceite:** jogador novo aponta caminho e destinos; grupos de objetos não interrompem movimento; cenário continua legível com HUD, chuva, noite e elenco da cena.

### R22 — Desvios, atalhos, exploração e encontros

**Situação:** validar diversão e orientação; acabamento, com correções obrigatórias se houver bloqueio.

**Execução:** desenhar rota principal, desvio opcional e retorno de cada região. Dar recompensa ou informação aos becos sem saída deliberados. Colocar mato de encontros fora das interações obrigatórias e prever janela de segurança após batalha/cut/transição. Conferir que atalhos só abrem quando apropriado e não pulam um requisito central. Sinalizadores de entrada devem ser discretos e consistentes, sem transformar o mapa em um painel de bolinhas clicáveis.

**Resultado:** explorar é uma decisão, e voltar não vira tarefa cansativa.

**Aceite:** ida/volta sem guia, encontro quase disparando em uma porta, retorno depois da missão e load numa área desbloqueada; nenhum item visível impossível de alcançar.

### R23 — Geradores, arquivos integrados e catálogo publicado

**Situação:** divergência conhecida no teste/gerador da montanha; obrigatório para reprodutibilidade.

**Execução:** decidir qual arquivo é fonte da região, documentar ajustes manuais e alinhar gerador, mapa, metadados de viagem e teste. Resolver a diferença entre expectativa de Mirante e destino integrado de Tufano/corte pelo contrato correto, não apagando a asserção. Separar mapa de campanha e prévia experimental no catálogo, para não expor área sem propósito. Regerar em cópia de teste e comparar resultado.

**Resultado:** atualizar um asset ou gerar o mapa não desfaz conteúdo aprovado.

**Aceite:** mesma navegação e eventos após regeneração; testes corretos passam; nenhum kit alheio ou relatório automático entra no commit por acidente.

## 4. Personagens, criaturas e animação

### R24 — Elenco ainda provisório

**Situação:** Dona Neve, Faye overworld e participantes da qualificação estão na fila conhecida; verificar inventário atual.

**Execução:** montar tabela de cada personagem nomeado que aparece na campanha: concept, retrato, atlas direcional, ações e cenas consumidoras. Reaproveitar arte aprovada existente antes de gerar. Produzir os faltantes pelo processo de personagem, preservando personalidade e silhueta; integrar tanto no mapa quanto nas cenas e menus. O professor pode continuar durante desenvolvimento como mock explícito, mas não como identidade final de outro personagem importante.

**Resultado:** elenco principal completo e reconhecível.

**Aceite:** rastreamento nome → arte → cena sem ligação trocada; nenhum personagem anunciado apenas em texto quando a cena exige presença visual.

### R25 — Igualar a identidade ao Kael atual

**Situação:** auditoria comparativa necessária; acabamento.

**Execução:** colocar Kael, Tyler, Rai, Heleana, Grampo, Gollia, Rato, grunts e campeões na mesma prancha de chão e escala. Conferir cabeça/corpo, espessura de linha, número de sombras, saturação e ângulo. Corrigir só os discrepantes. Preservar particularidades: Gollia parrudo sem hipertrofia exagerada, Grampo alongado/corcunda, roupas com volumes próprios, sem uniformizar todos no mesmo corpo.

**Resultado:** variedade de design dentro da mesma linguagem 2D mangá.

**Aceite:** captura em grupo e inspeção ampliada; personagem não muda de identidade entre retrato, idle e walk; iluminação e traço parecem parte da mesma produção.

### R26 — Ciclos direcionais e locomoção sem deslizamento

**Situação:** Rato tem pendência conhecida; auditar demais personagens em movimento.

**Execução:** mapear quais direções e ações cada cena realmente usa. Fixar âncora de pés e tamanho de célula; construir walk com contato/passo/retorno coerentes e transição para idle. Sincronizar velocidade de deslocamento e cadência, inclusive correndo. Conferir diagonais, virada e acessórios assimétricos; não espelhar indiscriminadamente. Garantir que troca de cota não altere a altura aparente do corpo.

**Resultado:** personagem anda, para e vira com naturalidade no mesmo plano do cenário.

**Aceite:** percurso reto, diagonal, curva, parada curta e escada, em velocidades normal/reduzida; nenhuma perna cortada, troca de escala, salto de pivô ou patinação contínua.

### R27 — Variantes e identidade dos Soulmonsters

**Situação:** Desalmados sem rabiola pendentes; outras variantes exigem conferência.

**Execução:** criar matriz espécie × estado: normal, mascarado, possuído, transformação, curado, fossilizado e classe, apenas onde existe uso aprovado. Vincular cada estado a atlas correto no overworld, duelo e coleção. Corrigir alias de apresentação que possa esconder um modelo mecânico diferente; Trovareta não deve depender somente de nome sobre Raio sem decisão documentada. Preservar Platyx único e Retalho de história.

**Resultado:** transformação muda o que o jogador vê de maneira coerente, sem trocar por criatura genérica.

**Aceite:** ver todos os estados em contexto e após load; forma possuída não persiste depois de cura; classe jogável não fica sem arte por engano; sem duplicatas narrativas em encontros aleatórios.

### R28 — Animações especiais e efeitos no estilo do jogo

**Situação:** ações principais existem em parte; acabamento e revisão quadro a quadro.

**Execução:** conferir antecipação, ação e repouso de nascimento, invocação, evolução, rebicar, posse, recusa, despertar e rugido. Preservar face/silhueta dos concepts; não aumentar detalhe pictórico para simular qualidade. Organizar sombras, partículas, rabiolas e luz em camadas com origem e duração claras. Preferir movimento desenhado ou deformação discreta coerente ao atlas, evitando esticar o corpo inteiro sem articulação.

**Resultado:** ações expressivas sem sair do 2D mangá ou encobrir a cena.

**Aceite:** loop sem tranco; transições sem célula errada; nenhuma borda/halo; versão reduzida mostra o mesmo acontecimento sem flashes ou tremores necessários à compreensão.

## 5. Combate, coleção e economia

### R29 — Curva de dificuldade de bairros e chefes

**Situação:** balanceamento foi adiado; etapa própria necessária.

**Execução:** registrar time/nível/itens esperados em cada bairro, campeão, exame e chefe. Jogar com equipe concentrada e diversificada, anotar duração, mortes e recursos consumidos. Identificar saltos de dano/HP e vantagens obrigatórias não ensinadas. Ajustar parâmetros em conjuntos pequenos e repetir os trechos afetados. Separar desafio de habilidade, preparação e grind; nenhum deles deve mascarar um bug de IA.

**Resultado:** dificuldade crescente e compreensível, com alternativas de estratégia.

**Aceite:** iniciante consegue aprender e progredir; jogador experiente não trivializa tudo com um padrão inevitável; vitórias são reais, não geradas por sinal de teste.

### R30 — Ritmo, IA e feedback de ação

**Situação:** validar em luta real; acabamento, com bugs de combate obrigatórios.

**Execução:** medir intervalo de ataque, rebicar, defesa, esquiva, skills e especial. Diferenciar comando aceito, cooldown e alvo fora de alcance. Sincronizar som/efeito/dano e indicar direção/perigo. Conferir IA sob pressão, perto de bordas e em obstáculos; não permitir alvos inválidos, perseguição imóvel ou invulnerabilidade sem término. Garantir que aliados em dupla contribuam de forma perceptível e previsível.

**Resultado:** o jogador entende por que acertou, errou ou recebeu dano.

**Aceite:** testes com teclado/controle, FPS diferentes e comando mantido; nenhuma habilidade dispara múltiplas vezes por um toque; ação aceita sempre tem feedback proporcional.

### R31 — Derrota, fuga, revanche e recuperação

**Situação:** validar contrato de cada família; obrigatório.

**Execução:** definir tabelas de resultado para selvagem, capanga, campeão, exame, derrota roteirizada e chefe de fases. Especificar posição/HP/itens/flags após cada resultado. Conferir oferta de cura ou caminho de recuperação quando sem dinheiro. Se fuga não for permitida, comunicar antes de desperdiçar uma ação; se for, retornar com graça de encontros. Ao perder uma fase de chefe, esclarecer o ponto de retomada.

**Resultado:** perder custa algo compreensível e nunca torna o save inviável.

**Aceite:** KO simultâneo, equipe ferida, sem cura, fugir/reentrar, fechar no resultado e rematch; sem vitória por sair da tela, recompensa duplicada ou reinício indevido de bairro.

### R32 — Parceiros emprestados e batalhas com aliados

**Situação:** empréstimos/habilidades existem em trechos; validar; obrigatório.

**Execução:** distinguir parceiro da conta, emprestado para exame/travessia e aliado de cena. Definir quem ocupa vaga, recebe XP, usa itens e pode ser trocado. Repor o time correto depois do exame ou duelo em dupla. O Carcará de avaliação não pode virar prêmio por falha de limpeza; o auxílio de Remar não usa Platyx genérico. Conferir disponibilidade de mobilidade se o jogador alterar a equipe.

**Resultado:** ajuda temporária não interfere indevidamente na coleção e não prende o jogador.

**Aceite:** time cheio, empréstimo cancelado, derrota, load durante atividade, transferência de parceiro e retorno do outro lado do obstáculo.

### R33 — XP do tamer e dos parceiros

**Situação:** cap de parceiro 50 existe; intenção tamer 100 deve ser reconciliada à implementação.

**Execução:** documentar nível → XP acumulado → ganho de atributos/recompensa. Conferir cap, exibição e migração nas mesmas funções centrais. Simular campanha, coleção diversificada e farm, depois comparar com sessões reais. Manter XP do tamer menor conforme intenção, sem obrigar centenas de repetições sem conteúdo. Definir quais skills de tamer entram agora e quais são futuras, sem telas prometendo desbloqueio inexistente.

**Resultado:** progressão previsível, com incentivo à coleção sem bloquear a história atrás de grind excessivo.

**Aceite:** limite máximo, XP excedente, vitória com parceiro no cap e save antigo; nenhum nível ou recompensa duplicado; tempo medido para marcos principais e objetivo de endgame.

### R34 — Grind, encontros e fontes de obtenção

**Situação:** validar ritmo de exploração; acabamento.

**Execução:** listar por área espécies, níveis, raridades, rascunhos, drops e taxas de encontro. Garantir uma área acessível de treino em cada faixa relevante. Ajustar graça após luta, interação e mapa; evitar passos obrigatórios em mato quando o jogador só quer retornar. Conferir distribuição de rabiolas e proteção de itens essenciais contra azar extremo. Tornar claro onde procurar sem exigir consulta externa.

**Resultado:** grind disponível como escolha útil, com variedade e metas legíveis.

**Aceite:** amostra de encontros e drops, níveis compatíveis, fuga e retorno à porta; criaturas únicas de história fora de tabelas comuns e nenhuma missão essencial dependente de drop arbitrariamente raro.

### R35 — Classes e evolução no Godot

**Situação:** escopo e integração precisam de rastreamento; obrigatório se incluído na 1.0.

**Execução:** verificar ponta a ponta dados → constelação → requisito → confirmação → transformação → efeito de combate → save. Exibir silhuetas dos bloqueados com requisitos compreensíveis sem estragar descobertas deliberadas. Validar level + atributo, itens especiais, consumo e troca de classe. Rabbito mantém as duas linhas com evoluções e Rabbitknight especial terminal; isso não significa uma cópia por conta. Não transportar automaticamente conclusões da versão JS para o Godot.

**Resultado:** árvore bonita e funcional, com escolhas reais e estados claros.

**Aceite:** requisitos abaixo/no limite/acima, item insuficiente, banco cheio quando relevante, cancelar, fechar ao consumir, retornar de classe e carregar; sem duplicar item/criatura ou perder atributos indevidamente.

### R36 — Ritual de invocação

**Situação:** rastrear integração atual Godot; obrigatório se oferecido.

**Execução:** conferir NPC → espécies vistas → cards invocáveis/bloqueados → criatura e rabiolas lado a lado → selecionar/usar → feitiço. Consumir na utilização, limitar às três tentativas e marcar como danificada a rabiola de ritual abandonado; a danificada só pode ser descartada conforme regra. Manter infraestrutura de rabiola alternativa sem habilitar casos não definidos. Preparar nomeação e solução para banco cheio antes de concluir a concessão.

**Resultado:** ritual compreensível e satisfatório, sem perder um mon obtido por falta de uma decisão de armazenamento.

**Aceite:** mouse/controle escolhido, erro triplo, saída, encerramento abrupto, rabiola danificada, espécie não vista, sem item e banco cheio; nenhuma recuperação grátis de tentativas ou concessão duplicada.

### R37 — Loja, cura, recompensas e economia

**Situação:** etapa de balanceamento e verificação; obrigatória para funções incluídas.

**Execução:** montar lista item → preço → origem → uso → descarte/venda. Separar itens-chave dos consumíveis e dos especiais de evolução. Medir renda por bairro/farm e custo médio de recuperar uma derrota. Conferir quantidade e feedback de compra/uso, evitando ações repetidas durante loading. Eventos/lojas online só entram se escolhidos para o Godot e sustentados por backend validado.

**Resultado:** economia que sustenta a aventura sem dinheiro infinito trivial ou falta irreversível de cura.

**Aceite:** saldo exato/insuficiente, inventário no limite, repetir confirmação, fechar após compra, missão já premiada; valores e inventário corretos após reabrir.

## 6. Saves, banco e conta

### R38 — Autosave e slots manuais

**Execução em 05/11:** corrigido travamento após falha de autosave; implementados espaço 0 separado, opção ligada por padrão em Configurações → Jornada, três saves manuais com confirmação e estados de gravação/sucesso/erro. Autosave desligado mantém avanços em memória e pede confirmação ao sair sem salvar. Nova suíte com 55 checks passou também no renderizador real, além das regressões. Restam percurso prolongado da campanha, formatos de tela adicionais e política de exclusão conjunta em R39. [Relatório](refinamentos/r38-autosave/README.md).

**Situação:** fundação de save existe; validar toda a interface; obrigatório.

**Execução:** conferir slot 0 reservado ao autosave, opção ligada no primeiro uso e ícone somente durante gravação real. Separar estado “gravando”, “salvo” e “falhou”, sem notificação enganosa de sucesso. Gravar em pontos seguros de transição/resultado e evitar posição no meio de uma parede ou estado incompleto de cutscene. Slots manuais precisam mostrar informação suficiente para reconhecer a partida e confirmar overwrite.

**Resultado:** jogador entende quando pode sair e qual partida retomará.

**Aceite:** autosave ligado/desligado, manual antes/depois de luta, arquivo vazio, overwrite cancelado, abrir menu durante gravação, disco sem permissão e load do mesmo local.

### R39 — Excluir e reiniciar campanha

**Execução parcial em 05/11:** exclusão por identidade remove autosave e cópias manuais vinculadas após confirmação; cópias verificadas e diário recuperável permitem concluir exclusão/desfazer interrompidos. Reiniciar concede outro Rabbito com nova identidade e recibos separados. Saves antigos sem vínculo confirmado são mantidos com aviso. Na continuação R40, a preservação do depósito local foi testada com propriedade real de criatura; conta Steam/online permanece pendente. [Relatório](refinamentos/r39-campanha/README.md).

**Situação:** regras de persistência global precisam de fechamento; obrigatório.

**Execução:** explicar antes da exclusão o que some: história, itens e banco do save; e o que permanece no depósito global conforme decisão. Não usar a mesma ação visual de carregar sem confirmação clara. Invalidar retomada/autosave pertencentes à campanha removida para não ressuscitá-la. Permitir novo Rabbito na nova campanha, como autorizado, preservando identidade de instância e depósitos anteriores legítimos.

**Resultado:** reinício previsível, sem apagar a coleção global ou recuperar campanha excluída por acidente.

**Aceite:** cancelar, confirmar, fechar durante operação, reiniciar imediatamente e carregar slot antigo relacionado; nenhuma duplicação por reexecutar o mesmo reset incompleto.

### R40 — Banco 30 por save e depósito global 20

**Execução em 05/11:** banco da campanha 30 (inclui parceiro ativo), depósito compartilhado 20 neste perfil local, transferência e liberação confirmadas em Pipamons → Banco e depósito. Registro independente de propriedade impede recuperar a mesma instância por save antigo ou desfazer exclusão. Transferência pendente é retomada após falha/reabertura. Na continuação R41, aquisições sem espaço passam à reserva persistente. Conta Steam/online ainda não integrada. [Relatório](refinamentos/r40-banco/README.md).

**Situação:** contrato definido pelo produto, integração precisa de comprovação; obrigatório.

**Execução:** distinguir visualmente origem, destino e lotação. Cada mon precisa de identificador persistente e atributos próprios. Tratar transferência como operação indivisível: validar espaço/restrições antes, persistir origem/destino com protocolo de recuperação e só então confirmar. Resolver parceiros ativos, essenciais, emprestados e vinculados a cena; não permitir removê-los no meio de uma obrigação sem tratamento explícito. O que significa “conta” local/Steam/online ainda deve ser decidido separadamente.

**Resultado:** o jogador sabe onde cada criatura pertence e consegue preservá-la entre campanhas.

**Aceite:** limites 29/30/31 e 19/20/21; dois saves, transferir nos dois sentidos, falhar entre gravações, deletar origem depois e descartar; nenhuma instância perdida ou duplicada.

### R41 — Recompensas com banco/time cheio

**Execução em 05/11:** aquisição e escolha de destino separadas por identidade/recibo de campanha; banco cheio reserva a criatura sem ultrapassar 30. Rabbito, Retalho e invocação têm cobertura pelos serviços reais; entrega opcional também tem API genérica. Recebimento, depósito, substituição ou recusa são recuperáveis e confirmados, com proteção de parceiros essenciais/ativos. Perfil v1 migra a v2 na próxima operação; perfil ausente/incompatível não é tratado como vazio. Captura direta de criaturas não existe neste Godot: encontros atuais entregam rabiolas. Restam playtest prolongado, outros viewports e conta online. [Relatório](refinamentos/r41-recompensas/README.md).

**Situação:** teste transversal necessário; obrigatório.

**Execução:** conferir concessões de Rabbito, Retalho, invocação, captura e recompensas especiais. Separar “ganhou o direito à recompensa” de “escolheu o destino”; manter pendência recuperável se não houver espaço. Apresentar opções coerentes de guardar/trocar/descartar com identidade e confirmação suficientes. Nunca consumir um item único e perder a criatura só porque o usuário fechou a tela de gerenciamento.

**Resultado:** falta de vaga gera uma decisão informada, não punição invisível.

**Aceite:** banco/time/global cheios em combinações, sair da tela, recusar uma concessão opcional e load; pendência e objeto são únicos e não bloqueiam a campanha além da regra aprovada.

### R42 — Migração, corrupção e encerramento durante save

**Migração e perfil:** quatro checkpoints reconstruídos no formato antigo validam conversão, preservação de conteúdo e recuperação pelo backup. A cena principal impede outra janela de usar o mesmo perfil; o gate prova disputa real e reabertura após encerramento forçado no Windows. [Evidência e limites](refinamentos/r42-migracao-perfil/README.md).

**Complemento em 05/11:** 16 casos de encerramento real de processos Godot, com duas reaberturas independentes por caso: save, depósito global, recompensa pendente, exclusão e restauração. Gate separado adicionado à CI; sem mudanças na persistência de produção. Migração representativa dos atos, concorrência e falhas físicas seguem pendentes. [Relatório de processos R42](refinamentos/r42-processos/README.md).

**Execução em 05/11:** matriz de falhas de escrita/cópia/rename/leitura, recuperação e idempotência passou em 152 checks; campanha passou em mais 207. Cobertura adicionada à CI. Migração representativa completa, falhas físicas e concorrência real permanecem pendentes. [Relatório R42](refinamentos/r42-saves/README.md).

**Situação:** armazenamento já possui validação e backup; validar resistência; obrigatório.

**Execução:** criar amostras representativas por versão/ato/escolha e testar migração com cópia preservada. Injetar falhas em temporário, gravação, substituição e conclusão de recompensa. Manter distinção entre arquivo corrompido, schema futuro e erro de permissão; não restaurar um backup antigo silenciosamente em todos os erros. Conferir proteção contra escrita desatualizada e duas instâncias abertas.

**Resultado:** recuperar o último estado válido ou informar um erro recuperável, sem sobrescrever a única cópia útil.

**Aceite:** primário truncado, backup inválido, disco cheio, permissão negada, arquivo grande inválido, schema futuro e kill do processo; sem perda conhecida de instância e sem promessa de proteção contra toda queda de energia sem ensaio específico.

### R43 — Isolamento por usuário e reinstalação

**Validação local:** o pacote Windows de referência (`9951cbac`) passou em seis aberturas com dois perfis APPDATA descartáveis. Ambos retomaram suas campanhas em uma instalação nova, com hashes distintos e preservados. A validação com contas Steam reais permanece pendente.

**Situação:** diretório local PipaKlub existe; política por conta ainda precisa de decisão/comprovação.

**Execução:** definir seleção de perfil e importação de progresso antigo. Testar duas contas Steam no mesmo Windows e dois usuários Windows; não misturar saves só porque compartilham pasta padrão. Conferir caminhos com Unicode/espaços e instalação em biblioteca diferente. Preservar save em atualização/reinstalação; não levar dados pessoais no pacote.

**Resultado:** cada jogador retoma sua própria campanha e coleção.

**Aceite:** alternar conta, primeira abertura, reinstalar, mover biblioteca, importar save antigo e conta sem rede; nenhum progresso de terceiro exposto ou sobrescrito.

### R44 — Local, conta online e Cloud são responsabilidades diferentes

**Proposta para a primeira versão, pendente de aprovação de produto**

| Responsabilidade | Comportamento proposto |
| --- | --- |
| Campanha | Jogável offline. Slots, autosave e backups pertencem ao perfil local do sistema. Atualizar ou reinstalar em outra pasta mantém o progresso quando o perfil é preservado. |
| Depósito de parceiros | Compartilhado entre campanhas do mesmo perfil local. A exclusão de uma campanha preserva os parceiros já depositados. A interface já informa que o depósito fica neste computador. |
| Conta Steam | Distribuição do jogo. Separação de progresso por SteamID e importação de saves locais exigem implementação e teste próprios antes de serem anunciadas. |
| Steam Cloud | Fora do escopo inicial proposto. Para adotar, definir como sincronizar campanha, depósito e registros de exclusão como um conjunto consistente. Manter preferências de hardware fora desse conjunto. |
| Economia online | Fora do escopo inicial proposto. Se adotada, o servidor valida a origem dos parceiros e registra concessões e transferências de forma idempotente. |

**Texto proposto para a loja:** “A campanha e o depósito de parceiros ficam salvos no perfil local deste computador. Você pode jogar a campanha offline.”

**Validação pendente:** abrir uma candidata instalada pela Steam com a rede desligada, verificar atualização e reinstalação e conferir o comportamento ao alternar contas Steam no mesmo usuário Windows. Se Cloud entrar no escopo, testar alterações offline em dois PCs, conflito entre versões, exclusão seguida de sincronização e retomada de upload interrompido. A escolha do jogador em um conflito deve preservar uma cópia recuperável do outro progresso.

**Situação:** decisão de produto; condicional, obrigatório se anunciado.

**Execução:** definir campanha local versus conectada, vinculação Steam, propriedade do banco global e recursos online incluídos. Se houver economia compartilhada, servidor deve arbitrar concessão/transferência e deduplicação; save local editável não é comprovante confiável. Se adotar Cloud, escolher o conjunto de arquivos, política de conflito, exclusão e compatibilidade; não sincronizar preferências de hardware como se fossem progresso.

**Resultado:** modelo de persistência explícito e honesto para o jogador.

**Aceite:** dois PCs, duas contas, offline, conflito e operação interrompida. Troca 1×1, se incluída, exige validação própria de atomicidade, bloqueios, confirmação, expiração e histórico. Não é preciso manter a versão web para isso.

## 7. Menus, controles e acessibilidade

### R45 — Campanha inteira com controle físico

**Avanço:** a nomeação de Rabbito abre com foco em confirmar o nome padrão quando o controle é o dispositivo ativo. O direcional para cima leva ao campo de nome personalizado. A validação com controle físico e a digitação de nome personalizado sem teclado físico permanecem pendentes.

**Situação:** mapeamento/glifos já existem; validar dispositivos; obrigatório para suporte prometido.

**Execução:** percorrer título, nomeação, diálogo, escolhas, exploração, duelo, coleção, classes, ritual, loja, save/exclusão e erros sem mouse. Definir primeiro foco, vizinhos, confirmação, voltar e retorno ao item anterior. Oferecer teclado virtual quando o alvo exigir texto sem teclado físico. Evitar dupla interpretação do mesmo botão entre mundo e menu.

**Resultado:** experiência integral de videogame com os periféricos anunciados.

**Aceite:** Xbox/PlayStation reais conforme suporte, desconectar/reconectar, alternar mouse/teclado e controle, segurar direcional, trocar glifos; nenhuma tela sem saída ou foco invisível.

### R46 — Hierarquia e consistência do kit de interface

**Equipe:** a paginação fica junto à lista, o parceiro ativo é identificado por rótulo e as ações auxiliares usam o estilo secundário do Recorte. O rodapé reúne Voltar e Banco e depósito. Conferido em captura Godot de 1280×720 e nas suítes de título, banco e recompensas. A revisão das demais telas e escalas permanece pendente.

**Situação:** revisão de todas as telas; acabamento.

**Execução:** catalogar componentes existentes e escolher padrão para título, subtítulo, contador, botão, aba, item selecionado e aviso. Diferenciar informação passiva de comando; não dar aparência idêntica ao contador de espécies e ao botão de menu. Reduzir listas gigantes usando agrupamento e detalhe contextual, mantendo funções descobríveis. Aplicar o kit aprovado em vez de criar um tema diferente por funcionalidade.

**Resultado:** jogador reconhece a mesma linguagem em todas as telas.

**Aceite:** comparar HUD, diálogo, loja, coleção, classes, mapa e configurações; ação primária e seleção claras, sem depender de hover de mouse.

### R47 — Estados vazio, bloqueado, cheio, erro e confirmação

**Equipe e depósito:** erro da Equipe com motivo, foco inicial em Tentar de novo e saída para o jogo. O depósito vazio explica como guardar um parceiro elegível e a campanha vazia indica como trazê-lo de volta. Captura em 1280×720 e 114 verificações na suíte de banco.

**Execução em 05/11:** cards/avisos de save refinados e capturados; corrigidos avisos escondidos pelo filme e retry cortado. 35 checks de interface passaram, com regressão de diálogos/menu/saves. Estados das demais funcionalidades continuam pendentes. [Relatório de feedback R42/R47](refinamentos/r42-feedback/README.md).

**Situação:** validar cenários de exceção; obrigatório quando afeta ação/descarte.

**Execução:** desenhar cada estado com motivo e próximo passo: não visto, falta item, classe indisponível, banco cheio, saldo insuficiente e falha de gravação. Manter informações relevantes visíveis durante confirmação; descarte deve identificar exatamente a criatura/item. Não fechar a tela em silêncio quando uma ação falha. Separar indisponível por história de erro técnico.

**Resultado:** o jogador entende o que aconteceu e como seguir.

**Aceite:** forçar cada estado, usar controle e voltar; nenhuma confirmação destrutiva pré-selecionada de modo perigoso, nem texto genérico que esconda perda de dados.

### R48 — Resolução, texto e posicionamento de HUD

**Equipe:** nomes podem quebrar linha em vez de depender de reticências e hover. A suíte de banco gera capturas em janela com texto a 130% em 1280×800, 1920×1080, 2560×1440 e 2560×1080. Inspeção visual desta etapa em 1280×800 e 2560×1080. Fullscreen, escala do sistema e câmeras de exploração continuam pendentes.

**Situação:** projeto expansível 1280×720; validar; acabamento e usabilidade.

**Execução:** testar janela e fullscreen em 720p, 800p, 1080p e 1440p; ultrawide se suportado. Conferir escala do sistema, safe areas, textos longos, nomes personalizados e legendas. Revisar limites de câmera quando expandir viewport; não mostrar bordas inacabadas do mapa. Garantir que retratos e barras não encubram alvos, inimigos ou entradas.

**Resultado:** interface legível e composição controlada nos formatos anunciados.

**Aceite:** capturas comparáveis por resolução, sem corte/overlap ou scroll impossível; mínimo de texto definido pela legibilidade real, e não só pela dimensão no editor.

### R49 — Loading e transições sem telas incompletas

**Exploração:** o mapa anterior fica disponível até a normalização do checkpoint e as gravações de chegada concluírem. Uma falha de gravação mantém a tela anterior e mostra o aviso. O teste injeta falha real na gravação do checkpoint. Passaram 58 verificações entre recuperação, avisos e viagens. A suíte de avisos emitiu alertas de recursos na saída. Carga fria em disco lento e recurso ausente continuam pendentes.

**Situação:** infraestrutura existente a validar; obrigatório se houver entrada inválida/travamento.

**Execução:** listar trocas que carregam mapa, atlas, duelo e conteúdo de save. Mostrar camada de loading quando necessário; só devolver input depois de recursos, posição, câmera e HUD estarem prontos. Consumir o botão que abriu a transição para não pular o primeiro diálogo. Tratar erro de recurso com mensagem e retorno seguro; não usar loading infinito. Não adicionar atraso artificial a cargas instantâneas.

**Resultado:** transição contínua com estado sempre compreensível.

**Aceite:** carga fria/quente, disco lento, recurso ausente e comando mantido; nenhuma tela vazia, spawn incorreto, diálogo invisível ou missão avançada durante loading.

### R50 — Acessibilidade e ajustes persistentes

**Ajustes locais:** falha ao gravar tamanho do texto agora mostra aviso e mantém a seleção anterior. Testes confirmam a leitura de texto a 130%, movimento reduzido, música silenciada e sons de diálogo após recarregar as preferências. Passaram 431 verificações de controles, título e avisos. A auditoria de contraste e das cenas com movimento reduzido permanece pendente.

**Situação:** movimento reduzido já tem cobertura parcial; validar conjunto; acabamento.

**Execução:** revisar tamanho/velocidade do texto, contraste, ícone+texto além de cor, volumes separados, tremor/flashes e vibração. Manter eventos essenciais legíveis com movimento reduzido; substituir animação intensa por estado claro, não remover o acontecimento. Permitir reler objetivo e instruções. Conferir remapeamento com conflitos e restauração do padrão.

**Resultado:** diferentes jogadores conseguem compreender e controlar a mesma campanha.

**Aceite:** leitura lenta sem perda de fala, mute sem perder informação essencial, paleta com contraste limitado, modo reduzido em todas as cuts e ajustes preservados após reiniciar.

### R51 — Pausa, foco e troca de dispositivo

**Desconexão:** apenas a remoção do controle em uso troca os glifos para teclado. Em combate, a desconexão abre a pausa normal, que suspende ações mantidas e oferece Retomar. Foram executadas as regressões de controles, título e história final. Desconexão física, suspensão do sistema e troca de saída de áudio seguem pendentes.

**Situação:** validar transversalmente; obrigatório onde pode causar derrota ou perda.

**Execução:** definir pausa em combate, exploração e cutscene; tratar Alt-Tab, desconexão do controle, tela de sistema, resize e suspensão. Limpar ações mantidas ao perder foco; evitar delta grande ao retomar, que pode saltar movimento ou animação. Preservar estado de áudio e janela, com retorno seguro se o monitor/dispositivo não existir mais.

**Resultado:** interrupção externa não causa ação inesperada nem deixa o jogo preso.

**Aceite:** perder foco com ataque/direcional pressionado, dormir/acordar, trocar saída de áudio e remover controle; nenhuma sequência avança em tempo acelerado nem o jogador toma dano quando deveria estar pausado.

## 8. Áudio, texto e fechamento

### R52 — Música e ambiente por estado da história

**Mix atual:** título e menus usam Vento Menu, e a abertura usa Vento Aventura a partir do passo 2. Configurações preservam a faixa em curso. Exploração usa vento ou folhas conforme a cena, enquanto as demais rotas encerram a música de abertura. Trocas rápidas mantêm até uma faixa atual e uma em fade de saída. O ambiente anterior para antes de iniciar outro. A matriz regional e a escuta dos loops e níveis permanecem pendentes.

**Situação:** auditar conteúdo e mix atual; acabamento.

**Execução:** tabelar cue por região e estado: dia/noite, exploração, ameaça, duelo, vitória, derrota e recuperação. Conferir crossfade, loop e prioridade; garantir que abrir/carregar uma cena não empilhe players. Preservar silêncios com intenção, sem buracos por arquivo faltando. Ajustar ambiente para apoiar lugar/ação sem disputar com efeitos importantes.

**Resultado:** música e som sustentam o arco emocional e o espaço.

**Aceite:** atravessar cenas e carregar repetidamente; sem cortes involuntários, música duplicada, loop com clique ou tema de perigo depois da resolução.

### R53 — Efeitos de ação e mixagem

**Impactos em combate:** cada evento toca um efeito sonoro, com prioridade para quebra da armação, corte da linha, crítico e acerto comum, nessa ordem. A regressão combina os indicadores no mesmo evento para verificar que só o efeito prioritário toca. A escuta em fones e alto-falantes e a revisão das demais ações seguem pendentes.

**Situação:** revisão de cobertura e qualidade; acabamento.

**Execução:** conferir passos, interação, ataque, defesa, dano, cooldown, cura, compra, save, invocação, posse e rugido. Sincronizar com eventos visuais; usar variações discretas para repetição. Normalizar ganho e limitar sobreposição, com buses e controles compreensíveis. Não tratar volume alto como impacto e não esconder informação crítica somente no áudio.

**Resultado:** ação tátil e clara sem cansaço ou clipping.

**Aceite:** alto-falante/fone, volume baixo, vários efeitos simultâneos, duelo longo e mutes individuais; configurações persistem e feedback visual continua suficiente.

### R54 — Revisão editorial de toda a campanha

**Primeiro voo:** instruções de movimento, cruzamento, energia e rodada final descrevem a ação. Os comandos específicos continuam nos indicadores dinâmicos do HUD. As suítes de campanha e controles passaram em 253 verificações. A leitura integral das rotas e sidequests continua pendente.

**Situação:** falas integradas são base de revisão; acabamento.

**Execução:** organizar texto por cena/estado/falante, comparar nomes e fatos com a Bíblia e cortar repetições. Conferir voz de Kael, Tyler, Grampo, Heleana e campeões; NPCs não devem todos falar como tutoriais. Distinguir explicação de regra necessária de narração de movimento. Harmonizar Eremor/aliases, Retalho/nome escolhido, nomes de bairros e comandos realmente mapeados.

**Resultado:** história clara com personalidade e continuidade.

**Aceite:** leitura no jogo em ambas as ordens das sidequests, depois de derrota e após finalização; sem informação prematura, erro de nome ou instrução incompatível com controle atual.

### R55 — Idiomas e texto variável

**Situação:** idiomas de lançamento a decidir; condicional além do português.

**Execução:** declarar idiomas completos por interface, legenda e áudio. Se houver tradução, extrair strings com contexto, placeholders e identidade do falante; evitar concatenar partes que impeçam tradução. Revisar acentos, nomes longos e símbolos, com fonte licenciada e fallback. Não considerar a tradução da página Steam como tradução do jogo.

**Resultado:** cada idioma anunciado tem experiência completa e revisada.

**Aceite:** troca e persistência de idioma, strings maiores, nomes personalizados e fonte em todos os caracteres usados; sem textos de debug ou mistura de idiomas por falta de chave.

### R56 — Créditos, epílogo e pós-jogo

**Situação:** créditos e flor têm implementação; validar apresentação final; acabamento/continuidade.

**Execução:** conferir créditos de pessoas, ferramentas, motor, fontes, áudio e atribuições aplicáveis. Ajustar entrada/saída e opções de avançar/voltar sem perder o marco concluído. Definir o estado pós-título, áreas visitáveis, missões restantes e como reencontrar parceiros/NPCs. Sidequest da flor deve reconhecer presença/ausência do item e entrega anterior, sem transformar o final em propaganda de DLC.

**Resultado:** sensação de conclusão com continuidade deliberada.

**Aceite:** terminar com/sem sidequests, sair nos créditos, reabrir, continuar e falar novamente com elenco; sem recompensas repetidas ou retorno ao estado anterior à vitória.

## 9. Estabilidade, testes e pacote Windows

### R57 — Confirmar a CI Godot e manter falhas visíveis

**Execução iniciada em 05/11:** preparação/importação verificadas em fixture sem cache; runner corrigido. Aguardar CI integral. [Relatório R57–R58](refinamentos/r57-r58/README.md).

**Situação:** workflow web substituído em `b51fd293`; execução remota precisa de resultado confirmado.

**Execução:** verificar instalação oficial/checksum, importação, quinze suítes selecionadas, logs e exportação Windows. Triar timeout da checagem completa de mapas separadamente de falha de geometria. Não substituir teste falhando por job vazio. Se proteção de branch exigir o nome antigo, atualizar o requisito administrativo após existir o novo check. Ampliar cobertura por risco, sem afirmar que quinze suítes são todos os testes do jogo.

**Resultado:** PR bloqueado por regressões relevantes do produto real.

**Aceite:** execução verde vinculada ao commit candidato; falha deliberada de teste produz job vermelho; logs identificam a suíte e o pacote corresponde à mesma origem.

### R58 — Carregamento de recursos na versão exportada

**Execução iniciada em 05/11:** corrigidos título/casa/loja/previews; 58 checks passaram com PCK montado fora da fonte. Exe Windows final e inventário completo continuam pendentes. [Relatório R57–R58](refinamentos/r57-r58/README.md).

**Situação:** risco confirmado por chamadas/alertas de `Image.load_from_file` em recursos internos.

**Execução:** inventariar carregamentos dinâmicos em título, casa, loja, professor, sprites e dados de mapas. Para recursos importados, usar o mecanismo adequado do Godot; manter arquivo cru somente quando necessário e explicitamente exportado. Auditar dependências referenciadas por string e filtros do preset. Criar lista de visita que force carregar cada família de recurso no release, não só na sessão do editor.

**Resultado:** mesma apresentação no executável e no ambiente de desenvolvimento.

**Aceite:** pacote fora do repo e sem cache `.godot` do projeto; nenhuma imagem/JSON/fonte/áudio faltando, fallback invisível ou dependência do diretório atual.

### R59 — Nós, sinais, memória e encerramento

**Execução em 05/11:** teardown do menu corrigido no teste; título passou em 350 checks e cinco ciclos de menu passaram em 55, sem diagnósticos de recursos vivos nem crescimento de nós/órfãos. Campanha longa e demais cenas continuam pendentes. [Relatório R59/menu](refinamentos/r59-menu/README.md).

**Situação:** avisos de instâncias/recursos vivos apareceram em testes anteriores; investigar sem assumir vazamento comercial.

**Execução:** distinguir teardown inadequado do teste de retenção real. Repetir criação/remoção de mapas, diálogos, aliados e batalha, monitorando nós, conexões, players e memória. Desconectar sinais e cancelar tweens/awaits pertencentes à cena encerrada; callbacks não podem atingir objeto liberado ou outra sessão. Validar também falha/cancelamento, não só o caminho feliz.

**Resultado:** sessões longas e troca de cenas não degradam estabilidade.

**Aceite:** ciclos repetidos com contagem estabilizada e logs classificados; saída/reabertura sem crash, input bloqueado ou som órfão. Aviso exclusivamente de teste tem justificativa e correção própria.

### R60 — Instalação limpa e atualização

**Execução em 05/11:** release Windows real passou em 58 checks de recursos e 38 de início/save/reinício/instalação movida, com perfil isolado. Corrigido o acionamento da sonda no template release. PC/VM limpo, Steam e atualização entre versões continuam pendentes. [Relatório R60](refinamentos/r60-windows/README.md).

**Situação:** exportador Windows existe; comprovação externa necessária; obrigatório.

**Execução:** gerar release com engine/templates fixos, exe/PCK, licenças e manifesto. Instalar em máquina/perfil sem Godot, Node ou repositório. Testar usuário comum, biblioteca em outro disco e caminho Unicode. Rodar primeira abertura, prólogo, save/load, cenas de arte dinâmica e final preparado. Atualizar de uma build anterior sem apagar progresso; rollback deve seguir política de compatibilidade, não tentar abrir schema futuro silenciosamente.

**Resultado:** jogo independente da máquina de desenvolvimento.

**Aceite:** instalar, iniciar, verificar arquivos, mover biblioteca, atualizar, reinstalar e desinstalar; save preservado e versão/origem identificáveis.

### R61 — Desempenho medido e requisitos mínimos

**Situação:** requisitos finais não devem ser presumidos; obrigatório para publicação honesta.

**Execução:** selecionar hardware mínimo/recomendado e cenas de maior custo: grupo, chuva, atlas grandes, Eremor e mapas com muita decoração. Medir FPS/frametime, picos, RAM/VRAM e carga fria/quente. Identificar CPU versus GPU antes de otimizar. Reduzir duplicação de textura, trabalho por frame e efeitos desnecessários sem destruir o estilo. Fixar metas com base no produto, não em uma média isolada.

**Resultado:** desempenho previsível nos requisitos anunciados.

**Aceite:** relatório por máquina/configuração e sessão longa, sem crescimento contínuo ou travas na interação; metas registradas e repetíveis. Deck/Proton só entram como suporte declarado após teste próprio.

### R62 — Logs, build comercial e ausência de ferramentas de QA

**Situação:** validar pacote e configurações; obrigatório.

**Execução:** conferir flags de QA, atalhos de história, menus de teste e dados pessoais. Preservar diagnóstico útil de erro com versão/cena/ação, sem tokens ou nomes sensíveis desnecessários. Documentar como o jogador encontra e envia log/save para suporte. Usar a build sem QA para regressões de viagem — os relatórios já mostraram que caminhos exclusivos de debug podem esconder problemas de release.

**Resultado:** produto limpo, diagnosticável e sem dependência de trapaças de desenvolvimento.

**Aceite:** inspecionar pacote e menus; nenhum teleporte/flag de vitória acessível inadvertidamente; erro reproduzível permite identificar build e contexto sem expor credenciais.

## 10. Preparação comercial e entrega pela Steam

### R63 — Branch privada e depot correto do Godot

**Situação:** ferramentas SteamPipe antigas apontam para Electron; Godot precisa de configuração própria; obrigatório.

**Execução:** apontar depot para a pasta release Godot e configurar o executável correto. Conferir package/licença de teste, conteúdo recebido e diferença entre branch privada e padrão. Não reaproveitar caminho de artefato antigo só porque o upload funciona. Instalar pelo cliente em outra máquina e conta autorizada, com versão/hash conferidos.

**Resultado:** Steam entrega exatamente a candidata revisada.

**Aceite:** install/update/verify/uninstall e launch pelo cliente; sem janela de servidor/web, Node ou diretório ausente. Publicação/alteração pública de branch continua uma ação autorizada separadamente.

### R64 — Página da loja e promessas

**Situação:** revisão de produção; obrigatório antes de submissão/publicação.

**Execução:** fechar descrição do que o jogador faz, estrutura da campanha, coleção, combate, idioma, controles e duração somente se medida. Remover menções a recursos não incluídos. Vincular cada feature publicada a uma evidência jogável. Informar necessidade de internet/login conforme decisão real, sem chamar conectado de offline. Definir preço, plataformas e lançamento pelo responsável do produto.

**Resultado:** expectativa do comprador coincide com o executável.

**Aceite:** revisão cruzada página → feature → cena, sem DLC/promessa futura apresentada como conteúdo disponível; requisitos de loja e build conferidos no painel vigente.

### R65 — Screenshots, trailer e identidade comercial

**Situação:** pacote gráfico precisa de fechamento; acabamento comercial.

**Execução:** capturar gameplay da candidata em cenas que mostrem exploração, combate, coleção e narrativa sem spoilers centrais desnecessários. Concept art não substitui screenshot. Produzir logo/key art e adaptar composição aos formatos atuais de loja/biblioteca, sem esticar uma imagem. Trailer deve demonstrar ações reais cedo, com texto legível e áudio equilibrado; não vender cenas mais acabadas que o jogo entregue.

**Resultado:** apresentação reconhecível e representativa do 2D mangá do produto.

**Aceite:** leitura nos recortes pequenos, logo seguro, vídeo sem UI debug e capturas reproduzíveis no jogo; arquivos conferidos contra templates atuais antes do upload.

### R66 — Direitos, atribuições e declarações de conteúdo

**Situação:** há licenças básicas no repo; inventário completo ainda precisa de verificação do responsável.

**Execução:** registrar origem/autoria/licença de arte, áudio, fontes, plugins e contribuições. Conferir que referências externas não estão incluídas por engano como assets do jogo. Completar créditos e atribuições pertinentes. Preparar respostas do Content Survey pelo conteúdo realmente distribuído, incluindo geração de conteúdo quando aplicável; não presumir que uma declaração resolve direitos de terceiros. Questões jurídicas específicas devem ser avaliadas pelo titular e especialista quando necessário.

**Resultado:** pacote e comunicação com procedência rastreável.

**Aceite:** cada família de recurso tem registro; pendências reais resolvidas antes da entrega; painel, jogo e página consistentes. Sem inserir documentos pessoais no repositório.

### R67 — Integrações escolhidas: conquistas, Cloud e Deck

**Situação:** decisão de escopo; condicional.

**Execução:** escolher quais recursos serão anunciados. Conquistas precisam de gatilhos únicos, offline e migração apropriados; Cloud precisa dos conflitos de R44; overlay/input não podem duplicar comandos. Deck requer teste de entrada, texto, teclado virtual, suspensão e desempenho no dispositivo. Nenhum desses itens é automaticamente obrigatório para toda venda Steam; torna-se compromisso se adotado/anunciado.

**Resultado:** integrações pequenas, confiáveis e úteis, sem desviar esforço de campanha/saves.

**Aceite:** teste real de cada marca publicada; falha de inicialização de integração não derruba a campanha; não prometer Verified ou suporte não comprovado.

### R68 — Suporte, hotfix e decisão final de liberar

**Situação:** preparar operação; obrigatório para entrega responsável.

**Execução:** definir contato, instrução de relato, triagem por severidade e responsável por corrigir bloqueios. Manter candidata anterior, política de migração e procedimento de voltar build sem destruir saves. Preparar notas de versão e lista honesta de limitações. Conferir aprovações/requisitos temporais no painel na data real; não agendar usando prazos lembrados de documentação antiga. Congelar novas features ao entrar em RC.

**Resultado:** lançamento com capacidade de responder e atualizar com segurança.

**Aceite:** ensaio de hotfix em branch privada, verificação do pacote recebido, comunicação pronta e aprovação explícita do dono para lançar. Este plano não autoriza merge ou publicação automática.

## Ordem de execução e dependências

| Pacote | Itens | Entrega final |
| --- | --- | --- |
| A — contrato e versão confiável | R44, R57–R60, R62 e isolamento inicial de R38–R43 | Escopo Godot fechado, testes relevantes, pacote executável e saves de teste seguros. |
| B — continuidade jogável | R01–R15, R19/R22, R31/R32 e R38–R43 | Toda a campanha percorrida normalmente, com escolhas/derrotas/interrupções recuperáveis. |
| C — acabamento visual | R16–R28, R46–R50 | Mapas/elenco/câmeras consistentes e interface acabada. Fazer por região/cena, não gerar todos os assets antes de integrar. |
| D — experiência e equilíbrio | R29–R37, R45/R51, R52–R56, R61 | Combate e progressão medidos, controle integral, áudio/texto e encerramento revisados. |
| E — beta e entrega | R63–R68 e regressão dos pacotes anteriores | Instalação Steam privada, feedback externo, candidata final e decisão de lançamento. |

A ordem é uma dependência de fechamento, não proíbe trabalhos independentes em paralelo quando autorizados. Uma arte já aprovada pode ser integrada antes; uma mudança de XP depois do RC exige repetir os trechos afetados. Não atribuir prazo apenas pela quantidade de itens.

## Matriz de testes para cada trecho de história

Para R01–R15, preencher: entrada normal; ação antes do requisito; confirmação; cancelamento; derrota/fuga quando possível; equipe diferente/cheia; banco cheio quando concede mon; fechar antes/durante/depois; carregar; voltar ao local depois de concluir; ordem alternativa de sidequest; movimento reduzido; teclado; controle; executável release.

O fechamento visual exige observar as ações no cenário. O fechamento funcional exige que o estado persistido corresponda ao que foi mostrado. Um não substitui o outro.

## Registro de aceite por item

Usar este modelo ao executar cada refinamento:

| Campo | Preenchimento obrigatório |
| --- | --- |
| Item | Rxx e IDs S/F relacionados quando houver. |
| Base | Commit anterior, save preparado e estado da missão. |
| Problema observado | Passos para reproduzir; se apenas validação, registrar que não havia defeito confirmado. |
| Alteração | Arquivos/dados/arte e comportamento realmente alterados. |
| Resultado final | O que o jogador agora vê, entende e consegue fazer. |
| Testes | Cenários executados e resultado; distinguir sinal simulado, entrada automatizada e partida humana. |
| Evidência | Log, captura e/ou vídeo com commit/build/resolução/configuração. |
| Pendências | O que não foi verificado, dependência de arte/regra/hardware ou exceção aprovada. |
| Estado | Não iniciado, em execução, implementado aguardando validação, aprovado ou depende de decisão. |

Não fechar um item por “parece pronto”. Não reabrir tudo por um relatório histórico desatualizado. O objetivo é uma fila verificável de **68 unidades de refinamento**, com resultado concreto para o jogador e evidência suficiente para aprovar a 1.0.
