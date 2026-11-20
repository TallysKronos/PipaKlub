# Mapa de refinamentos de fluxo — 04/11/2026

Base da revisão atual: claude/unificacao no commit 46a6c6cd, que incorpora os refinamentos anteriores. O inventário inicial abaixo foi escrito antes desses 12 commits; a matriz de revisão atual determina o que ainda falta.

Escopo: fluxo de história, encenação, navegação entre áreas e continuidade de saves. Balanceamento fica para uma etapa posterior, por decisão do projeto.

Este levantamento cruza código, Bíblia, testes existentes e capturas já revisadas. Não equivale a uma partida humana integral. “Confirmado” identifica uma lacuna observada no código ou na imagem. “Validar” identifica uma cobertura ainda insuficiente para afirmar um defeito.

## Revisão atual após receber as melhorias

Esta matriz substitui os estados do inventário inicial. “Implementado e testado” cobre o comportamento indicado e não equivale a aprovação visual de toda a cena. “Validar” não afirma a existência de um defeito.

| ID | Estado atual | O que ainda falta |
| --- | --- | --- |
| [F01](#f01) | Implementado e testado | Revisão pela interface do diário e do HUD, nas duas ordens da missão opcional e do laboratório. A separação da missão principal passou. |
| [F02](#f02) | Implementado e testado | Rejogar acolhimento, recusa e banco cheio pela interface com Retalho presente no cenário. A orientação principal já permanece livre. |
| [F03](#f03) | Bíblia e texto corrigidos | Conferir a evacuação A–D em movimento com Tyler, Grampo, Platyx e as três resgatadas. A divergência documental sobre Heleana e Assis foi resolvida. |
| [F04](#f04) | Condições e falas revisadas | Ver as revelações na tela nas duas ordens, incluindo cancelamento e retorno. A lógica de independência e a recompensa da flor passaram. |
| [F05](#f05) | Pendente | Partida contínua dos atos 4–6 sem saltar marcos nem inserir vitórias no save. |
| [F06](#f06) | Cobertura ampliada | Matriz de fechamento e reabertura do aplicativo em todas as cenas. Créditos já têm falha de gravação, nova tentativa e persistência testadas. |
| [F07](#f07) | Validar | Prólogo completo com exploração, nome e retomada. As melhorias recebidas não substituem esse playtest. |
| [F08](#f08) | Validar | Rua, professor, treino, Morro e inscrição com save novo e retorno após derrota. |
| [F09](#f09) | Validar | Nina, Bambuzal, encontro de Tyler, rabiola e promoção em saves novos e antigos. |
| [F10](#f10) | Validar | Percurso e retorno da comporta e passagem Clareira–Veredas em ambos os sentidos. |
| [F11](#f11) | Validar | Apito falso, retorno ao vendedor e apito verdadeiro sem diálogo ou cobrança repetidos. |
| [F12](#f12) | Validar | Câmera frontal do mural, leitura, aparição de Retalho e restauração da exploração. |
| [F13](#f13) | Validar | Transição da derrota prevista para a Pipa-Dragão desatada com as intervenções visíveis. |
| [F14](#f14) | Parcial | Desenvolver a elipse do Varal e da fuga; mostrar a escolha de Retalho e sua reação em vez de depender da explicação. |
| [F15](#f15) | Validar | As duas vertentes de Heleana na casa e na rua, interrompidas e retomadas com o time correto. |
| [F16](#f16) | Validar | Exame Azul e prática de Remar completos, com erro, saída, retomada e concessão única. |
| [F17](#f17) | Validar | Mormaço normal, limiar de 30%, transformação no overworld e segunda fase com Tyler/Rai em sequência contínua. |
| [F18](#f18) | Validar | Primeira subida a pé e ensino de Cavar e Corrente de Ar antes dos obstáculos dependentes. |
| [F19](#f19) | Encenação ampliada no código | Arte aprovada e libertação integradas: linha rompe, voo, fim da tempestade e entrada do Rato antes do diálogo. 28 verificações da sequência passaram nos dois modos. Retomada cobre interrupção antes de concluir o diálogo. Falta ciclo de caminhada próprio do Rato e playtest humano contínuo dos dois duelos. |
| [F20](#f20) | Grupo implementado no código | Reunião com os oito campeões, separação por silhueta, destaque ligado à fala, câmera e retorno integrados. 118 verificações passaram nos dois modos de movimento. Dona Neve usa o professor como mock autorizado; sua arte própria e o playtest humano contínuo permanecem pendentes. |
| [F21](#f21) | Laboratório em três etapas | Validar apresentação da Sentinela, revelação e transição para a noite visualmente. O texto ainda descreve ações que podem precisar de encenação. |
| [F22](#f22) | Guardas e nós implementados | Playtest noturno das barreiras e do galpão; conferir o desaparecimento de cada nó e o desbloqueio das saídas após as conquistas. |
| [F23](#f23) | Torre e emissão integradas | Marco físico, receptor e ativação persistente. Recuperação encenada no Centro e no Condomínio, com retorno ao cume. 25 verificações da integração passaram. Ainda faltam variantes próprias dos Desalmados sem rabiola e refinamento dos cenários urbanos legados. Trovareta já usa o atlas aprovado na torre. |
| [F24](#f24) | Fluxo existente, revisão pendente | Gravar A–D de ponta a ponta com posições, resgates, Platyx a 50%, partida, Gollia, Rato, pedra, Eremor e evacuação. |
| [F25](#f25) | Orientação implementada e testada | Verificar se o jogador encontra as saídas e a viagem pelo mapa sem orientação externa. Chegada ao Mirante já apresenta percurso e Ícaro. |
| [F26](#f26) | Roteiro ampliado e testado | Arte própria dos adversários/Ícaro e playtest da classificação obtida normalmente. A motivação de Ícaro e a indicação do próximo adversário já estão no roteiro. |
| [F27](#f27) | Lobby e reações implementados | Conferir elenco entre rodadas, atualização após vitória/derrota e falas de retorno em tela. Evitar empilhamento e preservar acesso ao atendente. |
| [F28](#f28) | Passagem do título implementada | Conferir Jamile chegando, fita dourada, Rabbito, câmera e comemoração. Pipa TV já está integrada. Retorno cinematográfico ao quarto continua pendente. |
| [F29](#f29) | Entrega e saída encenadas e testadas | Flor entregue no cenário, reação e saída por rotas livres. Falta o interior próprio do laboratório com escada. |
| [F30](#f30) | Validar transversalmente | Chegadas com grupo completo, oclusão, escadas e entradas nos dois sentidos. |
| [F31](#f31) | Validar transversalmente | Preparação, derrota, fuga e revanche de cada família de duelo, preservando suas regras de descanso. |
| [F32](#f32) | Validar transversalmente | Travessias com equipe alterada, empréstimos e retomada após interrupção. |
| [F33](#f33) | Melhorias de orientação integradas | Harmonização completa de nomes e retirada de narração de movimentos, especialmente no epílogo da flor. |
| [F34](#f34) | Validar transversalmente | Encontro aleatório quase disparando ao entrar e sair de cada cena ou travessia. |
| [F35](#f35) | Cobertura local existente | Revisão da campanha inteira com teclado e controle; distinguir simulação de teste com dispositivo físico. |
| [F36](#f36) | Validar transversalmente | Migração e retomada de saves representativos de todos os atos e decisões opcionais. |

### Testes executados nesta revisão

- Tyler opcional, 12 verificações sem falhas.
- Retalho opcional, 14 verificações sem falhas.
- Roteiro do Mirante, 43 verificações sem falhas.
- Epílogo da flor, 25 verificações sem falhas.
- Créditos e nova tentativa após falha de gravação, 9 verificações sem falhas.
- História dos atos finais, 98 verificações sem falhas.

Total de 201 verificações nessas seis suítes. A suíte do Mirante também emitiu avisos de instâncias e recursos ainda em uso ao encerrar. Investigar a limpeza do teste antes de considerar o encerramento técnico dessa suíte totalmente limpo.

Não foi feita uma nova captura visual de todos os cenários alterados nesta revisão. O epílogo foi capturado com movimento ativado. A entrega, reação e saída usam o ateliê atual, sem escada própria.

### Próxima ordem de execução

1. Revisar visualmente F19–F22 e F26–F28, que receberam novos participantes e ações.
2. Encerrar a animação do epílogo F29 e a função física da torre F23.
3. Fazer o percurso contínuo F05, cobrindo F03, F24 e F25 durante a mesma sessão.
4. Revalidar o início F07–F18 e os casos transversais F06 e F30–F36.
5. Atualizar os estados desta matriz por evidência, sem reabrir como ausentes as funcionalidades já implementadas.

## Prioridade 1 — coerência e progressão

| ID | Trecho | Estado inicial | Refinamento e condição de fechamento |
| --- | --- | --- | --- |
| [F01](#f01) | Pipeiro Fantasma e laboratório | Confirmado | A entrada fantasma em BEATS é devolvida por current_beat até pipeiroFantasmaResolvido. Retirar a missão opcional da seleção obrigatória de objetivo, preservar sua recompensa e testar chegar ao laboratório sem fazê-la. begin_lab já aceita esse caminho. |
| [F02](#f02) | Retalho e objetivo principal | Validar | retalho-atelie e retalho-confianca também entram na lista linear de BEATS. Confirmar que recusar, deixar para depois ou estar com banco cheio não mantém a orientação principal presa no arco pessoal. Fechar com saves das três escolhas. |
| [F03](#f03) | Elenco da Câmara do Elo | Confirmado | A Bíblia §7.7 ainda diz que Heleana e Assis seguram a saída. Alinhar ao fluxo aprovado de Tyler e Grampo ajudando na evacuação. Conferir falas, sprites e cenas de retorno, sem colocar a mãe e o professor na caverna. |
| [F04](#f04) | Significado da revelação de Tyler | Validar | A missão do Fantasma revela a identidade, e o laboratório revela sua criação. Revisar as falas nas duas ordens, sem exigir a missão opcional e sem repetir a revelação como novidade. |
| [F05](#f05) | Travessia contínua dos atos finais | Validar | Os testes de história e interface usam estados preparados e resultados simulados. Fazer uma sessão contínua desde a tempestade até o retorno após os créditos, registrando objetivo, porta, save e retorno de cada trecho. |
| [F06](#f06) | Retomada de cenas | Validar | Recarregar antes, durante e depois das cenas de Gollia, Ventos, Eremor e final. A recompensa não pode repetir, e o próximo objetivo precisa continuar acessível. Há testes locais de confirmação/cancelamento; falta a matriz de reinicialização do aplicativo. |

## Prioridade 2 — capítulos e encenação

| ID | Trecho | Estado inicial | Refinamento e condição de fechamento |
| --- | --- | --- | --- |
| [F07](#f07) | Prólogo, Rabbito e saída de casa | Validar | Rejogar TV → mesa → aniversário → Rabiola Antiga → invocação → nome → saída. Conferir liberdade de exploração, retomada, nome vazio e o momento em que o jogo ensina interação. Evitar repetir tutorial para save antigo. |
| [F08](#f08) | Primeiro ciclo e Mikka | Validar | Conferir quarto → rua → professor → treino → Morro → inscrição. O jogador deve reconhecer descanso, retorno para casa e destino após a primeira vitória sem recorrer ao mapa de QA. |
| [F09](#f09) | Nina, Bambuzal e Tyler | Validar | Testar a ordem reorganizada com save novo e antigo. Conferir a entrega da rabiola, a abertura da Clareira após Lohan, o encontro de Tyler e a promoção Verde. |
| [F10](#f10) | Veredas e Beira-Canal | Validar | Conferir como o jogador descobre a comporta, volta a Kleie e identifica a porta das Ruínas. A passagem alta Clareira–Veredas mudou na unificação e precisa de caminhada visual nos dois sentidos. |
| [F11](#f11) | Apito falso e Feira | Validar | Conferir ida à porta, falha do apito, retorno ao vendedor e pista para Grampo. Cada volta precisa produzir informação nova; o objetivo deve acompanhar a etapa correta. |
| [F12](#f12) | Caverna do Mural | Validar | Conferir a câmera frontal, o retorno à câmera de exploração, a posição de Tyler e o que a Rabiola Antiga revela. Retalho ao fundo não deve esconder a leitura do mural nem virar uma interação obrigatória acidental. |
| [F13](#f13) | Galpão e Pipa-Dragão | Validar | Conferir derrota prevista, intervenção de Retalho, chegada de Tyler e transição para a forma desatada. A derrota narrativa deve ser distinta da derrota comum, com retorno correto ao galpão. |
| [F14](#f14) | Retalho, Varal e confiança | Confirmado | A Bíblia registra a ida ao Varal e a passagem da noite como elipse; o Varal livre ainda não existe. Decidir a extensão visual do intervalo e encenar a fuga, preservando aceitação, recusa e espera por vaga. |
| [F15](#f15) | Heleana e Retalho | Validar | Rejogar as duas vertentes com interrupção. Com laço, exigir Retalho no time; após recusa, mostrar o grunhido e a saída para a rua antes da reconexão. Conferir a permanência de Retalho na casa quando volta à mãe. |
| [F16](#f16) | Exame Azul e Remar | Validar | Rejogar como candidato sem Retalho. Conferir instrução, erros, retomada por competência, parceiro de avaliação, empréstimo da capivara e desembarque. A ponte deve continuar utilizável. |
| [F17](#f17) | Mormaço | Validar | Testar luta normal até retirar 30% de HP, volta ao overworld, Carretel Negro, transformação e entrada de Tyler com Rai. Depois, conferir o duelo conjunto e a libertação. As animações precisam manter escala e posição entre as etapas. |
| [F18](#f18) | Serra e habilidades de campo | Validar | A primeira subida precisa funcionar a pé. Conferir o ensino de Cavar, o paredão de Corrente de Ar e a rota de volta após aprender. O jogador deve entender a habilidade antes da passagem obrigatória. |
| [F19](#f19) | Tempestade e Trovareta | Parcial | Chuva e clarões existem. Falta representar claramente a criatura amarrada, a ameaça de Navalha e a aparição do Rato depois da libertação. Trovareta usa arte provisória, e a tempestade precisa ser conferida após recarga e fim da missão. |
| [F20](#f20) | Reunião dos campeões | Confirmado | A etapa tem diálogo e progresso, mas precisa de composição que mostre os campeões reunidos e deixe claro quem fala e o que decidiram. Usar os sprites disponíveis sem colocar todos no mesmo ponto. |
| [F21](#f21) | Laboratório de Assis | Validar | Conferir a preparação da Sentinela, derrota/fuga, revelação de Tyler e a saída para a Noite do Cerol. O jogador deve compreender por que o laboratório está acessível e por que a cidade muda depois da cena. |
| [F22](#f22) | Noite do Cerol e galpão | Parcial | Conferir barreiras, braçadeira, Desalmados, Tainá e os três nós do cadeado. Dar leitura visual às portas fechadas e ao objetivo seguinte; testar retorno de cura sem encerrar a noite ou perder o progresso dos duelos. |
| [F23](#f23) | Torre do Vento | Parcial | Já há quatro posições separadas, idle, liberação visual e luz de amanhecer. Falta uma torre/gerador com função visual clara, a emissão conjunta a partir do marco e a reação da cidade. O retorno ao dia precisa permanecer legível sem depender do texto. |
| [F24](#f24) | Câmara do Elo A–D | Parcial | Há resgates, recusa de Platyx, ida de Grampo, entrada de Gollia, Rato e Eremor. Conferir o conjunto com câmera e elenco completos, escadas, saída dos prisioneiros, pedra atingindo Rato e a preparação antes da interação E com Eremor. |
| [F25](#f25) | Eremor → Mirante → Estádio | Parcial | Objetivos de destino estão integrados. Falta conferir se a saída física e a viagem no mapa são descobertas naturalmente, se a pausa após a crise tem duração adequada e se o jogador entende por que volta ao campeonato. |
| [F26](#f26) | Ícaro | Parcial | Arte própria ainda pendente. Dar presença à ideia de ex-campeão que desconfia da TV e conferir como a conversa muda após a vitória. Testar o duelo normal com qualificação obtida na campanha. |
| [F27](#f27) | Intervalos do campeonato | Parcial | Há falas próprias antes de Grampo, Tyler, Faye e Jamile. Falta encenar os reencontros no lobby e as reações posteriores, especialmente a parceria voluntária de Grampo com Platyx. |
| [F28](#f28) | Vitória final | Parcial | Reunião no lobby, Pipa TV, fala de Jamile, créditos e retorno funcionam em teste. Falta uma apresentação própria de Jamile e da passagem do título, reações desenhadas do grupo e uma conexão cinematográfica com o quarto da abertura. |
| [F29](#f29) | Flor de Cerejeira | Validar | Testar coleta opcional, preservação até o fim e entrega no laboratório. Conferir o caminho sem flor, quando a conversa fica disponível e se o epílogo respeita a decisão de não completar a sidequest. |

## Prioridade 3 — consistência entre todos os capítulos

| ID | Frente | Estado inicial | Refinamento e condição de fechamento |
| --- | --- | --- | --- |
| [F30](#f30) | Chegadas e saídas de mapa | Validar | Revisar os pontos de chegada com a equipe completa. Evitar atores empilhados, personagem atrás de cenário e retorno direto à porta que acabou de atravessar. |
| [F31](#f31) | Preparação para duelos | Validar | Conferir aviso de sequência sem descanso, acesso à bolsa/save antes do desafio e destino após derrota ou fuga. Eremor deve continuar dependendo da aproximação e da interação. |
| [F32](#f32) | Habilidades de campo | Validar | Conferir Planar, Remar, Cavar e Corrente de Ar com parceiro emprestado, parceiro próprio e equipe alterada. O save precisa retomar em local válido após interromper a travessia. |
| [F33](#f33) | Objetivos e nomes | Parcial | Harmonizar nomes de região, parte, marco e personagem entre HUD, mapa, diálogo e Bíblia. Remover descrições narrativas de ações que a cena já mostra e separar objetivos principais de atividades opcionais. |
| [F34](#f34) | Encontros durante história | Validar | Conferir proteção contra encontro aleatório no meio de aproximação, diálogo, resgate, cerimônia e partida de NPC. Validar o retorno com a condição do parceiro preservada. |
| [F35](#f35) | Controles e pausas | Parcial | Confirmação/cancelamento nas novas cenas passou. Falta percorrer o restante com teclado e eventos de controle simulados, verificando foco, fechamento de menu e ausência de movimento durante diálogo. Controle físico requer teste próprio. |
| [F36](#f36) | Save novo e save migrado | Validar | Rodar checkpoints representativos de cada ato com dados anteriores à unificação. Objetivos, portas e itens únicos devem apontar para a mesma etapa após migrar. |

## Ordem sugerida

1. F01–F04, para alinhar missão principal, sidequests e elenco.
2. F19–F24, para fechar a cadeia tempestade → laboratório → noite → Ventos → Câmara.
3. F25–F29, para fechar Mirante, campeonato e epílogos.
4. F07–F18, revisando o início com as regras finais estabilizadas.
5. F05–F06 e F30–F36 como validação contínua de entrega.

## Evidência principal

- godot/scripts/campaign/kronasta_story.gd, BEATS, current_beat e region_objective.
- godot/scripts/campaign/tyler_arcs.gd, begin_lab, finish_ghost e finale_ready.
- godot/scripts/campaign/endgame_story.gd, STEPS e condições de progressão.
- godot/scripts/campaign/front_end.gd, retornos de batalha, confissão, chave e encerramento.
- documentation/historia/BIBLIA-DA-HISTORIA.md, atos 1–6 e decisões sobre Retalho e exame Azul.
- godot/tests/endgame_story_checks.gd, endgame_staging_checks.gd, stadium_checks.gd e suítes de fluxo por capítulo.
- documentation/campaign/refino-atos-finais, capturas e limites dos testes executados.

Existir uma suíte não demonstra aprovação visual nem uma partida integral. Os itens “Validar” não devem ser tratados como bugs confirmados.

## Especificação detalhada dos refinamentos

Esta seção descreve o comportamento pretendido para implementação e revisão. Os detalhes de encenação são propostas de execução dentro das decisões de história já aprovadas. Novas revelações, novos personagens e mudanças nas condições de recompensa exigem uma decisão narrativa específica antes de entrar no jogo. O estado vigente de cada item está na matriz de revisão atual. As tabelas de prioridade preservam o diagnóstico inicial, e esta especificação continua definindo o resultado esperado.

Cada fluxo deve ser entregue com uma captura do início, uma do momento principal e uma do estado posterior. Onde houver movimento, a evidência deve incluir gravação. A validação de save deve usar slots isolados. O controle físico deve ser identificado separadamente da simulação de entrada.

<a id="f01"></a>

### F01 — Pipeiro Fantasma como missão opcional

**Como refinar.** Separar a disponibilidade da sidequest da escolha do próximo objetivo obrigatório. Depois de Leo Antena, o objetivo principal deve permitir seguir ao laboratório. O pedido da Pipa TV fica disponível como atividade secundária identificável no mapa e no diário. Abrir o laboratório não deve marcar a investigação do Fantasma como concluída. A flor só entra no inventário quando a missão que a concede for realmente terminada.

**Resultado final.** O jogador pode investigar o Fantasma antes do laboratório, depois dele ou deixar a investigação para mais tarde, enquanto a campanha principal continua. Quem encontra a flor recebe uma consequência própria no arco de Tyler. Quem a ignora continua entendendo a história principal.

**Validação de fechamento.** Partir do mesmo save após Leo Antena em três percursos, com sidequest feita, ignorada e interrompida. Os três precisam alcançar o laboratório. Apenas o primeiro recebe a flor. Repetir a conversa ou recarregar não pode gerar uma segunda recompensa. Conferir qual objetivo aparece no HUD em cada percurso.

<a id="f02"></a>

### F02 — Liberdade de escolha no arco de Retalho

**Como refinar.** Separar progresso pessoal de Retalho do progresso obrigatório dos bairros e das categorias. Acompanhar os estados de aproximação, cuidado, oferta, recusa, escolha de Retalho, espera por vaga e acolhimento. A recusa do jogador deve permanecer uma decisão válida. Banco cheio precisa oferecer organização do banco e uma forma clara de voltar à oferta. A orientação principal deve continuar mostrando a próxima etapa da campanha.

**Resultado final.** O jogador entende que pode acolher Retalho, adiar a decisão ou recusar. A espera por espaço mantém a escolha de Retalho registrada e o encontro disponível. A recusa preserva a vertente em que ele segue Tyler e reaparece do lado de fora da casa.

**Validação de fechamento.** Usar saves com banco disponível, 30 vagas ocupadas, recusa e oferta interrompida. Conferir objetivo, disponibilidade da conversa, composição do time e reencontro com Heleana. Nenhuma vaga deve ser liberada ou ocupada automaticamente.

<a id="f03"></a>

### F03 — Elenco coerente na Câmara do Elo

**Como refinar.** Atualizar a Bíblia, os textos de resgate e os participantes das cenas para a decisão de Tyler e Grampo ajudarem a retirar os prisioneiros. Conferir as funções de Kael, Rai, Platyx, Gollia, Rato, Nina, Mikka e Jamile em cada sala. Dar a cada personagem um ponto de espera, uma ação e um destino. Remover referências antigas à presença de Heleana e Assis nessa sequência.

**Resultado final.** O jogador consegue reconhecer quem está preso, quem está escoltando e quem está enfrentando o Bando. Ao trocar de sala, a posição do elenco corresponde à última ação vista. Heleana e Assis voltam a aparecer nos contextos posteriores apropriados, sem terem sido transportados para a caverna.

**Validação de fechamento.** Registrar A–D com o elenco completo. Conferir entradas, escadas, resgates, partida de Grampo e Platyx, intervenção de Gollia e evacuação após Eremor. Comparar a lista de atores e todas as falas com a Bíblia revisada.

<a id="f04"></a>

### F04 — Duas descobertas diferentes sobre Tyler

**Como refinar.** Tratar a identidade do Pipeiro Fantasma e a origem de Tyler como informações distintas. As falas devem consultar o que Kael já descobriu. A investigação opcional pode revelar quem atua como Fantasma; o laboratório revela a criação de Tyler. A futura conversa de identidade deve respeitar a diferença entre o conhecimento de Kael e o momento em que Tyler encara sua própria origem.

**Resultado final.** Fazer a sidequest antes do laboratório produz reconhecimento nas falas. Fazê-la depois produz confirmação ou aprofundamento, sem repetir uma revelação como inédita. O jogador que pula a investigação consegue compreender a descoberta central no laboratório.

**Validação de fechamento.** Percorrer Fantasma → laboratório e laboratório → Fantasma. Conferir o texto apresentado, a recompensa, os objetivos e a disponibilidade da conversa da flor. Reabrir um diálogo concluído deve usar uma fala posterior adequada.

<a id="f05"></a>

### F05 — Jornada contínua dos atos 4 a 6

**Como refinar.** Preparar um save legítimo no início do ato 4 e percorrer os objetivos em sequência com as ferramentas normais do jogo. Usar mapa, portas, interações, bolsa, descanso e checkpoints reais. Registrar dúvidas de orientação e voltas sem informação nova. Em cada marco, anotar destino esperado, destino encontrado, tempo de deslocamento e condição da equipe. Ajustes de dificuldade ficam para a etapa de balanceamento.

**Resultado final.** O jogador chega da tempestade aos créditos seguindo as pistas do jogo. Toda etapa obrigatória tem uma entrada acessível, uma ação reconhecível e uma consequência que aponta ao próximo destino. As pausas para explorar ou cuidar da equipe cabem no percurso.

**Validação de fechamento.** Uma gravação contínua, acompanhada do registro dos checkpoints, deve cobrir a cadeia inteira. Resultados de batalha simulados podem apoiar regressão, mas a aprovação desse item exige identificar quais combates e deslocamentos foram efetivamente jogados.

<a id="f06"></a>

### F06 — Retomar sem repetir ou perder cenas

**Como refinar.** Definir o ponto persistente de cada sequência. Separar a conquista registrada da apresentação visual já assistida. Salvar em limites seguros, como antes de iniciar a cena e após sua consequência. Uma animação interrompida deve retomar em um estado que permita concluir ou reapresentar o trecho com segurança. O jogo precisa restaurar câmera, interação e controle.

**Resultado final.** Fechar e reabrir o jogo mantém o sentido da história. O jogador encontra o desafio disponível ou sua consequência concluída. Itens únicos, parceiros e títulos conservam uma única concessão.

**Validação de fechamento.** Interromper antes da confirmação, durante o movimento, após a recompensa e antes do diálogo posterior. Repetir em Gollia, Torre, transformação de Mormaço, Eremor e encerramento. Conferir inventário, elenco, objetivo e possibilidade de continuar.

<a id="f07"></a>

### F07 — Prólogo no quarto e nascimento de Rabbito

**Como refinar.** Organizar o quarto para comunicar TV, mesa de criação e porta. Começar pela final regional de Jamile e Gollia na TV, avançar para a intenção de Kael participar da Liga e mostrar a falta da rabiola na mesa. A entrada da mãe precisa ter percurso e lugar de conversa. Apresentar a Rabiola Antiga no centro da tela, depois sua aplicação e o nascimento de Rabbito. O campo de nome usa Rabbito como referência e explica como confirmar.

**Resultado final.** O jogador entende o desejo de Kael, o aniversário de 15 anos e a singularidade de uma criatura criada por ele. A primeira invocação tem continuidade espacial entre mesa, luz e parceiro. Quando a exploração é liberada, a porta e o próximo destino ficam claros.

**Validação de fechamento.** Testar leitura lenta, avanço rápido, nome vazio, nome editado e retomada nos marcos da abertura. Conferir que a introdução não concede outro Rabbito ao repetir sua apresentação no mesmo save.

<a id="f08"></a>

### F08 — Rua, professor, treino e primeira vitória

**Como refinar.** Conectar a saída de casa ao primeiro encontro com Assis por posicionamento e orientação curta. Distribuir movimento, interação e combate em momentos próprios do treino. Mostrar onde se descansa e como se volta para casa antes de uma sequência maior. No Morro, reforçar a continuidade entre as cinco partes e a chegada à Mikka. A inscrição deve produzir uma mudança compreensível no mapa e no objetivo.

**Resultado final.** Ao concluir o primeiro ciclo, o jogador sabe caminhar, interagir, iniciar um duelo, recuperar a equipe, salvar e encontrar a próxima região. A rua já funciona como um lugar ao qual pode voltar.

**Validação de fechamento.** Jogar com save novo, incluindo uma derrota no treino, retorno à casa e visita a um destino secundário. Conferir que a vitória de Mikka registra o avanço uma vez e que os tutoriais concluídos não voltam a bloquear saves antigos.

<a id="f09"></a>

### F09 — Pedido de Nina, Bambuzal e encontro de Tyler

**Como refinar.** Explicitar o pedido de Nina e a pista que o jogador leva ao Bambuzal. Ao vencer Lohan, atualizar a indicação da Clareira. Mostrar Tyler e Rai no ponto do encontro, com a câmera permitindo reconhecer os três participantes. Conferir a origem da rabiola devolvida nos consumidores atuais e alinhar a Bíblia ao fluxo efetivo, evitando duas entregas do mesmo item de missão. Encerrar com a promoção Verde e a apresentação de Planar.

**Resultado final.** O jogador percebe a relação entre ajudar Nina, atravessar o bairro e conhecer Tyler. A devolução tem um único responsável e um único momento. A promoção abre uma possibilidade visível de exploração.

**Validação de fechamento.** Percorrer a ordem nova e um save antigo que já tenha aceitado o pedido. Testar retorno a Nina antes da conclusão, recarga com o item de missão e devolução repetida. Conferir todas as entradas da Clareira.

<a id="f10"></a>

### F10 — Comporta, Veredas e campeonato de Beira-Canal

**Como refinar.** Fazer o problema da água ser percebido no bairro e relacioná-lo à comporta. A fala que envia Kael às Veredas deve indicar o marco da passagem. Na região, mostrar o percurso até Grampo, Lacertubo e a porta das Ruínas com etapas reconhecíveis. A abertura da comporta precisa mudar o cenário ou produzir uma reação localizada do bairro. Ao voltar, Kleie deve reconhecer o feito.

**Resultado final.** O desvio pelas Veredas resolve um problema que o jogador já viu. A volta a Beira-Canal tem propósito imediato e libera o duelo de forma compreensível.

**Validação de fechamento.** Tentar o campeão antes da comporta, retornar depois e recarregar entre essas ações. Caminhar pelas ligações alta e baixa da Clareira com teclado e clique, conferindo alturas, retorno e orientação.

<a id="f11"></a>

### F11 — Apito falso, vendedor e confronto com Grampo

**Como refinar.** Organizar a cadeia compra → teste na porta → descoberta da falsificação → confronto com o vendedor → pista de Grampo → apito verdadeiro. Cada etapa deve atualizar objetivo e falas. A falha do apito precisa ser percebida por som, reação ou animação curta da tentativa. Ao voltar, o vendedor responde à descoberta já registrada. A saída do confronto deve orientar ao próximo teste da porta.

**Resultado final.** O jogador acompanha uma investigação curta em que cada retorno traz informação nova. Reconhece o apito falso e sabe por que precisa do verdadeiro.

**Validação de fechamento.** Testar falta de moedas, saída após a compra, recarga após o teste, conversa repetida com vendedor e retorno à porta com o item verdadeiro. Conferir a identidade dos itens e a ausência de cobrança repetida indevida.

<a id="f12"></a>

### F12 — Mural, enquadramento e primeira revelação

**Como refinar.** Posicionar Kael e Tyler diante do mural, com Rai e eventuais figurantes fora da área de leitura. A câmera frontal deve começar depois da aproximação e voltar à posição de exploração ao terminar. A Rabiola Antiga responde em um momento visualmente identificável. Se Retalho aparecer ao fundo, sua saída precisa funcionar sem exigir que o jogador o persiga para concluir a revelação.

**Resultado final.** O mural se torna uma descoberta que o jogador consegue observar. O retorno ao mapa preserva posição, direção, interação e compreensão do próximo destino.

**Validação de fechamento.** Conferir a cena em entrada normal e retomada, cancelar quando permitido e abrir o menu logo depois. Verificar texto, desenho do mural, oclusão e restauração da câmera. Confirmar que Retalho não vira uma trava invisível.

<a id="f13"></a>

### F13 — Pipa-Dragão e derrota prevista

**Como refinar.** Preparar visualmente os três vínculos roubados antes do duelo. Definir o evento que encerra a fase impossível e devolve ao overworld. Retalho entra por um caminho livre e protege Kael. Tyler chega, desfaz os nós e a criatura passa a uma forma reconhecível como desatada. Só então abrir a fase vencível. A condição da equipe e os checkpoints devem seguir o tratamento narrativo previsto.

**Resultado final.** O jogador compreende que a primeira fase foi interrompida pela história e que suas ações continuam relevantes. A mudança na criatura explica a possibilidade de vencer a segunda fase.

**Validação de fechamento.** Testar derrota, tentativa de fuga, recarga na transição e vitória na fase desatada. Conferir que a fase impossível não consome repetidamente recursos nem permite receber duas vezes a recompensa narrativa.

<a id="f14"></a>

### F14 — Varal, passagem de tempo e confiança de Retalho

**Como refinar.** Substituir ou desenvolver a elipse atual com uma sequência curta. Mostrar o lugar oferecido para descanso, Retalho mantendo distância e sua ausência percebida depois. A pista deve levar à busca e ao cuidado no Pântano. A conclusão nas Palafitas precisa mostrar Kael deixando a passagem livre, Retalho começando a sair e escolhendo voltar. A decisão do jogador entra depois dessa ação visível.

**Resultado final.** A confiança nasce de uma cadeia de gestos que o jogador presenciou. A aceitação ocupa uma vaga do banco do save quando houver espaço. Adiar e recusar preservam seus caminhos narrativos.

**Validação de fechamento.** Registrar as três decisões e o caso de banco cheio. Conferir que o parceiro equipado está protegido, que a transferência para os slots globais continua explícita e que a escolha de Retalho não se repete após recarga.

<a id="f15"></a>

### F15 — Reencontro de Heleana nas duas vertentes

**Como refinar.** Na vertente do laço com Kael, exigir a presença de Retalho no time e apresentar a emoção de Heleana diante de alguém que já criou outro vínculo. Na vertente da recusa, tocar o grunhido do lado de fora, mostrar Kael e Heleana saindo e revelar Retalho, que seguiu Tyler. O toque de Heleana e a reação de Retalho devem preceder o diálogo de reconhecimento. Depois, seus lugares na casa e no time precisam refletir a escolha.

**Resultado final.** As duas cenas compartilham o passado contado por Heleana, mas têm ações e consequências próprias. A retomada da conversa preserva qual vertente está em curso.

**Validação de fechamento.** Testar Retalho fora do time, no time, recusado e aguardando vaga. Interromper em cada etapa da saída de casa e da conversa. Reabrir o jogo e conferir quem acompanha Kael e quem permanece com Heleana.

<a id="f16"></a>

### F16 — Exame Azul e prática de Remar

**Como refinar.** Apresentar observação, condução e controle como competências de qualquer candidato da Liga. O Carcará de avaliação entra apenas no exercício. Instruções devem explicar o erro e a repetição local. Depois da aprovação, Marisol apresenta a capivara e a prática segura de Remar, com indicação das margens, fôlego e desembarque. O empréstimo tem identificação clara e duração vinculada à prática.

**Resultado final.** O jogador aprende duas coisas distintas, o cuidado avaliado pela Liga e a nova habilidade de travessia. O exame funciona sem Retalho; Remar funciona com a capivara de apoio sem criar outro Platyx.

**Validação de fechamento.** Errar cada competência, sair no meio, retomar, terminar e repetir a conversa de aprovação. No trajeto aquático, interromper antes de embarcar, durante a travessia e ao gravar o desembarque. Conferir certificado, categoria e posição.

<a id="f17"></a>

### F17 — Mormaço, transformação e dupla

**Como refinar.** Começar com Mormaço normal. Ao perder 30% do HP, encerrar essa fase e voltar ao overworld. Posicionar os vilões, lançar o Carretel Negro e reproduzir a transformação normal → intermediária → possuída. Tyler e Rai entram por pontos diferentes de Kael. A conversa distribui a ação da dupla antes de abrir o duelo contra Mormaço sombrio. A libertação posterior retoma a criatura no lugar correto.

**Resultado final.** O jogador acompanha a causa da transformação e entende a participação de Tyler. O lago mantém Mormaço imponente, legível e apoiado na água em todas as formas.

**Validação de fechamento.** Cruzar o limiar com dano pequeno e grande, tentar recarregar na transição, perder e fugir da segunda fase. Conferir que o evento do carretel ocorre uma vez e que o retorno permite preparação e novo desafio.

<a id="f18"></a>

### F18 — Subida da Serra e aprendizado das habilidades

**Como refinar.** Desenhar a leitura da primeira subida para caminhada a pé, com rampas e escadas distinguíveis. Colocar o ensino de Cavar junto de uma aplicação segura. Apresentar Corrente de Ar diante de um paredão que a justifique. O jogador deve observar ou praticar antes da passagem que depende da habilidade. A rota de retorno deve mostrar o ganho de mobilidade sem apagar a subida já percorrida.

**Resultado final.** Cada habilidade responde a um obstáculo que o jogador reconheceu. A Serra passa a ser um lugar diferente depois da aprendizagem.

**Validação de fechamento.** Subir sem habilidades, aprender, voltar e repetir com as habilidades já registradas. Trocar a equipe e retomar o save no topo e na base. Conferir que nenhuma técnica permite atravessar um barranco que parece bloqueado.

<a id="f19"></a>

### F19 — Trovareta, Navalha e tempestade

**Como refinar.** Mostrar Trovareta presa e a ligação negra saindo de Navalha. A chuva, a luz e os sons devem sustentar a tempestade sem prejudicar a leitura da trilha ou das falas. O duelo de Navalha vem antes do confronto com a criatura controlada. Depois da libertação, romper visualmente a linha e revelar Rato em uma posição observável. A recusa de Kael deve acontecer com os participantes presentes no quadro.

**Resultado final.** O jogador entende quem ameaça a criatura, por que luta duas vezes e como o convite de Rato se relaciona à criação de Rabbito. Ao voltar à região, a tempestade já terminou.

**Validação de fechamento.** Conferir as duas derrotas possíveis, retomada entre os duelos, movimento reduzido e retorno após libertar Trovareta. Arte definitiva e recortes precisam manter o porte da criatura e a linguagem do overworld.

<a id="f20"></a>

### F20 — Reunião dos campeões

**Como refinar.** Distribuir os campeões na Praça da Matriz em pequenos grupos com espaço para Kael chegar. Enquadrar o grupo, destacar o interlocutor e usar reações curtas dos demais. Cada fala precisa acrescentar uma decisão ou informação. Encerrar com a decisão de patrulhar e uma indicação clara da avaliação Vermelha, sem teleportar o jogador diretamente para a prova.

**Resultado final.** O jogador reconhece os campeões já enfrentados e percebe a resposta coletiva à ameaça. A reunião altera seu próximo objetivo e justifica a mudança de escala da aventura.

**Validação de fechamento.** Conferir posições, identificação de quem fala, leitura em teclado/controle e retomada após interromper. Depois da reunião, os eventos de avaliação ficam acessíveis e a conversa repetida reconhece que o plano já foi decidido.

<a id="f21"></a>

### F21 — Laboratório, Sentinela e origem de Tyler

**Como refinar.** Dar uma pista reconhecível para a área de estudo de Assis e para o acesso ao laboratório. Antes do combate, mostrar o que ativa a Sentinela. A derrota e a fuga devolvem Kael a um ponto de preparação válido. Após a vitória, apresentar os documentos e a reação dos participantes em uma ordem que separe leitura, descoberta e consequência. Consultar os estados do Fantasma para adequar as falas. A mudança para a noite deve ocorrer ao deixar a sequência em um marco salvo.

**Resultado final.** O jogador consegue explicar o que Kael descobriu, o que Tyler sabe naquele momento e qual ameaça leva a cidade à próxima etapa. A sidequest permanece opcional.

**Validação de fechamento.** Testar as duas ordens das revelações, derrota, fuga e saída após a leitura. Conferir que a Sentinela não volta como obstáculo obrigatório depois da vitória e que a Noite do Cerol começa no momento previsto.

<a id="f22"></a>

### F22 — Noite do Cerol, braçadeira e invasão do galpão

**Como refinar.** Tornar visível a mudança nas ruas por iluminação, ocupação do Bando e reação dos moradores. Cada saída fechada deve ter um bloqueio identificável e uma pista sobre a braçadeira. Ao obtê-la, atualizar acesso e falas. No Condomínio, orientar aos desafios e à Tainá sem perder o objetivo da crise. No galpão, representar os três nós do cadeado e a remoção de cada um após o tenente correspondente. Manter uma saída compreensível para preparação.

**Resultado final.** O jogador entende o alcance da ocupação e vê cada conquista mudar o acesso. Desalmados opcionais podem ser investigados sem esconder a rota necessária. A sequência do galpão tem progresso visível entre os duelos.

**Validação de fechamento.** Tentar atravessar sem e com braçadeira, sair para curar depois de cada nó, perder para cada tenente e recarregar. Conferir que os lugares reabrem depois do gerador e que os confrontos concluídos não voltam a cobrar a mesma etapa.

<a id="f23"></a>

### F23 — Torre do Vento e fim da noite

**Como refinar.** Dar à torre um centro físico reconhecível, com o gerador integrado ao terreno, acesso e lugar para os quatro guardiões. Posicionar Kael e o grupo com silhuetas separadas. Fazer os quatro contribuírem para o mesmo marco visual, seguido pelo funcionamento da torre e pela transição de luz. A confirmação do resultado pode usar reação de personagens ou uma transmissão curta, desde que tenha conteúdo aprovado. Atualizar objetivo e mapa depois do evento.

**Resultado final.** O fim da Noite do Cerol é uma ação que o jogador presenciou. Ele identifica o gerador funcionando e vê que a cidade voltou a abrir. O próximo passo, Copa Relâmpago no Centro, fica disponível e explicado.

**Validação de fechamento.** Confirmar, cancelar e recarregar em torno da ativação. Testar movimento reduzido. Conferir a emissão dos quatro, o desaparecimento dos atores temporários, a luz final, o desbloqueio dos destinos e o objetivo após sair e voltar.

<a id="f24"></a>

### F24 — Corredor de resgates e clímax da Câmara do Elo

**Como refinar.** Tratar A–D como uma sequência com funções claras. Em A e B, aproximar, enfrentar o guarda, soltar o amigo e mostrar seu destino. Em C, entrar no duelo contra Grampo e Platyx; ao retirar 50% do HP de Platyx, voltar ao overworld para mostrar sua recusa. Encostar em Grampo, proteger e decidir ajudar precisam acontecer por ação dos sprites. O diálogo termina antes da saída de Grampo e Platyx para a sala seguinte. Em D, Gollia intervém, Kael enfrenta Rato e, após perder, Rato desperta Eremor. Rato caminha ao ponto do impacto; a pedra cai nele durante o rugido. Depois da cutscene, liberar preparação e aguardar E em Eremor.

**Resultado final.** O jogador acompanha o resgate, a mudança de Grampo, a intervenção de Gollia e a má-fé de Rato numa cadeia espacial contínua. Eremor conserva escala de chefe sem encobrir o elenco todo. A evacuação tem participantes e destinos legíveis.

**Validação de fechamento.** Gravar A–D com equipe completa, derrotas e retomadas. Conferir o limiar de Platyx, o momento de saída, a pedra, a preparação antes de Eremor e o retorno após fuga. Cada personagem ocupa um ponto próprio, inclusive ao mudar de mapa.

<a id="f25"></a>

### F25 — Da crise ao último bairro e ao Estádio

**Como refinar.** Dar ao fim de Eremor uma breve resolução local antes da retomada do campeonato. Mostrar a saída e indicar a recuperação da equipe. O mapa da cidade deve identificar o Mirante como próximo destino. Na chegada ao bairro, apresentar seu percurso e o desafio de Ícaro. Ao vencer, atualizar objetivo e destino disponível no mapa. No Estádio, a entrada e o balcão devem guiar ao atendente sem abrir a luta automaticamente.

**Resultado final.** O jogador entende que a crise foi contida e que resta concluir o campeonato. A viagem entre esses lugares parece uma continuação da jornada, com espaço para preparação e atividades opcionais.

**Validação de fechamento.** Sair das Ruínas, curar, viajar ao Mirante, voltar à cidade e entrar no Estádio usando apenas as indicações do jogo. Conferir destinos antes e depois de Ícaro e retomar o save em cada chegada.

<a id="f26"></a>

### F26 — Ícaro e a conclusão dos bairros

**Como refinar.** Construir a apresentação de Ícaro em torno da desconfiança dele sobre o campeonato vendido à TV, conforme a Bíblia. Os quatro adversários devem preparar a chegada ao topo com falas e marcos próprios. Ícaro precisa reconhecer o que Kael fez na cidade e explicar por que aceita o desafio. Após perder, sua fala deve refletir a luta e concluir o bairro. A celebração do emblema deve indicar claramente o Estádio.

**Resultado final.** Vencer Ícaro tem peso de último bairro e fecha uma questão sobre o campeonato antes da chave final. O jogador distingue sua posição da de Jamile.

**Validação de fechamento.** Chegar sem qualificação, completar os quatro desafios pela campanha, enfrentar Ícaro, perder, voltar e vencer. Conferir emblema, fala posterior e destino liberado. O desenho próprio depende da aprovação de arte, mas a função narrativa precisa estar definida antes.

<a id="f27"></a>

### F27 — Intervalos entre rodadas e reencontros

**Como refinar.** Dar ao lobby um ponto de espera para o adversário da rodada e conservar o atendente como responsável pela entrada. Grampo e Platyx devem mostrar a parceria voluntária conquistada na caverna. Tyler reconhece a jornada compartilhada e reage à luta. Faye recebe uma apresentação suficiente para marcar sua personalidade sem revelar conteúdo de DLC ainda indefinido. Depois de cada resultado, atualizar elenco, chave, próxima fala e objetivo. Permitir salvar e cuidar da equipe entre rodadas conforme as regras existentes.

**Resultado final.** A chave parece um campeonato vivido por pessoas que Kael conhece. O atendente mantém a ordem das lutas; os intervalos dão espaço ao reencontro e à expectativa.

**Validação de fechamento.** Percorrer Grampo → Tyler → Faye → Jamile pela interface. Perder em cada rodada, sair do lobby, recarregar e voltar. Conferir que a chave avança por vitória, Jamile permanece fora dos oito participantes e a próxima luta está corretamente identificada.

<a id="f28"></a>

### F28 — Passagem do título e ligação com o prólogo

**Como refinar.** Posicionar Kael, Rabbito e Jamile num espaço próprio de reconhecimento da vitória. A câmera precisa mostrar a aproximação de Jamile e a reação dos acompanhantes. O símbolo ou gesto usado na passagem do título deve ser definido antes de produzir a animação correspondente. A Pipa TV enquadra Kael como campeão, retomando a transmissão vista no quarto. Um eventual corte ao quarto deve manter o ambiente reconhecível e retornar à cena final sem alterar indevidamente o checkpoint. Encerrar com créditos e uma opção clara de continuar na cidade.

**Resultado final.** O jogador percebe que Kael passou de espectador a participante e campeão. Rabbito tem presença no fechamento. A conquista permanece registrada depois dos créditos.

**Validação de fechamento.** Conferir câmera, escala, visibilidade do grupo e foco do diálogo. Recarregar antes de ver o final e depois dos créditos. Testar falha de gravação ao retornar à cidade, sem perder o título nem deixar os botões bloqueados. A faixa da TV precisa caber nas resoluções suportadas.

<a id="f29"></a>

### F29 — Flor de Cerejeira e epílogo de Tyler

**Como refinar.** Preservar a flor como consequência da investigação opcional. Indicar a disponibilidade da conversa no laboratório quando as condições do epílogo forem atendidas. Separar o que Kael já sabia sobre a origem de Tyler do dilema que Tyler passa a expressar. A entrega da flor precisa ter uma ação visual e uma reação. A frase de Kael sobre ele se importar deve encontrar apoio nas escolhas de Tyler vistas durante o jogo. A saída dos dois encerra a conversa.

**Resultado final.** A flor ganha significado pela história que o jogador escolheu acompanhar. Sem ela, a campanha principal termina normalmente e o jogo mantém o estado adequado para uma conclusão posterior, se a missão continuar disponível.

**Validação de fechamento.** Testar flor coletada, ausente, conversa interrompida e entrega concluída. Conferir o momento de disponibilidade, o consumo único, o registro do epílogo e a ausência de pedido impossível quando o jogador não tem o item.

<a id="f30"></a>

### F30 — Chegadas, saídas e composição do grupo

**Como refinar.** Definir pontos distintos para jogador, acompanhante e NPCs em cada transição. Reservar a faixa da porta e afastar o ponto de chegada do gatilho de retorno. Conferir projeção e altura do chão, oclusão por paredes e cenário e espaço para avançar. Quando o elenco exceder a capacidade do quadro, usar pontos de espera e saída em sequência. Verificar ambos os sentidos de cada ligação.

**Resultado final.** Ao carregar uma área, o jogador reconhece Kael e tem um caminho evidente para sair da entrada. O grupo conserva uma composição legível e as conexões correspondem ao lado de onde veio.

**Validação de fechamento.** Montar uma lista de todas as ligações A↔B↔C↔D, interiores e travessias especiais. Capturar a chegada com o grupo máximo e testar sair imediatamente, abrir menu, virar e retornar. Verificar colisão, altitude e ausência de ciclos involuntários de carregamento.

<a id="f31"></a>

### F31 — Preparação, derrota, fuga e revanche

**Como refinar.** Antes de iniciar um duelo, apresentar adversário, natureza do desafio e eventual sequência sem descanso. Preservar a oportunidade de abrir bolsa, salvar e voltar. Definir o destino de derrota e fuga para cada tipo de encontro, aplicando a condição real da equipe. No retorno, usar fala e objetivo de revanche. Na Câmara, manter o confronto com Eremor dependente de aproximação e E depois da cutscene.

**Resultado final.** O jogador sabe quando está assumindo um desafio e como se recuperar se falhar. A revanche está disponível sem repetir recompensas ou apresentações já consumidas.

**Validação de fechamento.** Exercitar os três resultados de cada família de combate, incluindo guardas, campeões, provas e chefes. Conferir condição do parceiro, posição de retorno, rodada e recompensa. Tentar iniciar com parceiro incapaz de lutar deve orientar ao cuidado disponível.

<a id="f32"></a>

### F32 — Travessias e habilidades de campo

**Como refinar.** Padronizar a leitura do ponto de início, o requisito, a ação de entrada e o desembarque de Planar, Remar, Cavar e Corrente de Ar. Distinguir habilidade aprendida, apoio emprestado e parceiro necessário conforme cada regra aprovada. A câmera deve acompanhar a travessia e voltar ao enquadramento de exploração. Salvar origem e destino seguros para recuperação após interrupção.

**Resultado final.** O jogador reconhece uma oportunidade de mobilidade no cenário e entende o que precisa fazer. Aprende uma vez e depois usa a habilidade com menos interrupções.

**Validação de fechamento.** Usar cada travessia nos dois sentidos quando permitido, com equipe alterada, empréstimo ativo e habilidade já aprendida. Fechar o jogo durante a ação e conferir o retorno seguro. Falha na gravação do desembarque deve permitir tentar novamente.

<a id="f33"></a>

### F33 — Objetivos, nomes e informação entregue ao jogador

**Como refinar.** Definir um nome canônico e seus nomes de exibição para região, parte e marco. Fazer HUD, mapa, falas e registros apontarem ao mesmo lugar. Cada objetivo deve conter uma ação e uma referência encontrável no cenário. Após a ação concluída, atualizar a orientação e as falas de retorno. Separar principal, opcional e repetível. Nas cutscenes, remover frases que apenas narram movimentos já demonstrados.

**Resultado final.** O jogador pode consultar o objetivo, olhar o mapa e encontrar a entrada correspondente. Reconhece quando uma conversa mudou seu destino e quando uma atividade é opcional.

**Validação de fechamento.** Para cada marco da história, registrar objetivo anterior, ação que o conclui, objetivo posterior, nome no mapa e fala de confirmação. Revisar também linguagem, nomes antigos e variantes inconsistentes. Testar o HUD após recarga e viagem.

<a id="f34"></a>

### F34 — Encontros aleatórios durante cenas e retornos

**Como refinar.** Definir em quais estados a distância de encontro pode acumular. Suspender o disparo durante diálogo, câmera de revelação, chegada de NPC, resgate, cerimônia e travessia dirigida. Ao devolver controle, conceder o intervalo de retomada previsto pelo sistema. Evitar que passos de uma cutscene contem como caminhada de exploração. Preservar a condição do parceiro e a posição correta no retorno do encontro.

**Resultado final.** Encontros acontecem na exploração e mantêm o ritmo do mapa. O jogador consegue concluir uma conversa ou observar uma ação antes de voltar à pressão do percurso.

**Validação de fechamento.** Aproximar-se de cada cena com o encontro quase pronto para disparar. Abrir diálogo, cancelar, confirmar e sair. Conferir que não existem duas batalhas concorrentes nem retorno a uma cutscene pela metade. Repetir após vitória, fuga e derrota.

<a id="f35"></a>

### F35 — Controle, foco e devolução da exploração

**Como refinar.** Manter uma única interface responsável pelo comando naquele momento. Ao entrar em diálogo ou menu, interromper a rota de caminhada e guardar o foco esperado. Ao fechar, devolver controle quando as animações realmente terminarem. A ação que confirmou uma escolha não deve vazar para o mapa e iniciar outra interação. Opções de movimento reduzido devem conservar a mesma sequência lógica.

**Resultado final.** Teclado, mouse e controle seguem a mesma ordem de cenas e decisões. O jogador sabe qual botão confirma e volta, e Kael não anda sozinho enquanto uma revelação acontece.

**Validação de fechamento.** Testar avanço rápido, botão mantido, troca de dispositivo, cancelamento, abertura do menu e fechamento durante uma transição. Conferir foco inicial e posterior. Registrar separadamente eventos de controle simulados e teste com dispositivo físico.

<a id="f36"></a>

### F36 — Continuidade de saves novos e antigos

**Como refinar.** Montar uma coleção de saves representativos de cada ato e das decisões opcionais. Definir como flags antigas correspondem às etapas atuais sem concluir missões que o jogador não realizou. Preservar nomes, parceiros, banco do save, slots globais, itens e títulos. Recompensas devem ter identificadores estáveis e gravação consistente. Quando faltar uma informação antiga indispensável, restaurar o marco seguro mais próximo e orientar o jogador.

**Resultado final.** Um save anterior à unificação abre em uma área válida com um objetivo executável. A migração mantém as escolhas já feitas e a distinção entre progresso da aventura e patrimônio global da conta.

**Validação de fechamento.** Carregar cada fixture, executar a próxima ação, salvar, fechar e carregar novamente. Conferir divergências entre posição e missão, itens únicos, Retalho, flor, classificação e chave final. Simular falha de gravação e repetir a operação. O resultado final precisa manter uma única concessão e uma rota de continuação.

## Condição de entrega do pacote completo

O pacote de refinamentos estará concluído quando cada item tiver seu comportamento esperado implementado ou formalmente retirado de escopo, com justificativa registrada. A evidência precisa cobrir uma partida contínua, as vertentes opcionais relevantes e a retomada dos saves. As tabelas devem ser atualizadas com o commit, as capturas, a suíte executada e os limites da revisão de cada item.

Prioridade determina a ordem de trabalho. A presença desta especificação não altera o status de implementação dos itens nem aprova automaticamente os detalhes propostos de encenação.
