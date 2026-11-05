# Soulmonsters — mapeamento de prontidão para a Steam

Revisão: **04/11/2026**. Produto: **Soulmonsters: Elo das Ruínas**, campanha Godot.

Atualização de escopo em **05/11/2026**: o dono confirmou que o produto ativo é **somente Godot**, sem versão web. Os itens de paridade abaixo se referem apenas às funcionalidades que forem escolhidas para o jogo Godot; não exigem manter a versão web funcionando. A substituição do gate web pelo Godot está descrita em [Validação Godot](VALIDACAO-GODOT.md). A necessidade ou não de conexão à conta é uma decisão separada da escolha de engine.

## Parecer e limites

O projeto tem uma campanha extensa implementada e várias sequências refinadas, mas **ainda não há evidência suficiente para classificá-lo como uma versão candidata ao lançamento**. Os riscos principais são exportação e distribuição reais, continuidade integral da campanha, identidade visual ainda provisória em partes do elenco/cenários, equilíbrio da progressão, integridade dos saves e escopo da conta online.

“100% pronto” significa cumprir os critérios de lançamento definidos aqui, com evidências de uma versão identificada. Não significa prometer ausência absoluta de bugs. Quantidade de testes, mapas ou falas não permite calcular uma porcentagem confiável de prontidão.

Base inspecionada: branch `codex/refino-atos-finais`, commit `46a6c6cd`, **mais alterações locais ainda não consolidadas em um novo commit**. Portanto, este documento descreve o workspace; não atesta que tudo já está no GitHub, em main ou em uma build publicada. Não foram feitos merge, push, upload, compra ou publicação nesta auditoria.

Método: leitura de configuração/exportação, fluxo, saves, controles, ferramentas de distribuição, CI e do mapeamento F01–F36; cruzamento com documentação oficial atual da Valve e do Godot. Resultados de testes anteriores são identificados como tais. **Nesta auditoria não foi repetida a suíte inteira, nem realizada uma nova partida integral, nem validada uma instalação pela Steam.** Não foi acessado o painel privado Steamworks, hardware de terceiros ou conta bancária/fiscal.

## Como executar este documento

Cada item identifica o trabalho, o estado conhecido e a comprovação necessária. Os itens de validação não significam que a funcionalidade esteja ausente.

| Marca | Significado |
| --- | --- |
| C | Lacuna ou risco encontrado em arquivo, relatório ou execução anterior identificada. |
| V | Funcionalidade existente ou requisito relevante cuja aprovação final ainda precisa de teste. |
| D | Decisão de produto pendente; não implementar uma interpretação silenciosamente. |
| P0 | Impede liberar a 1.0: perda de progresso, bloqueio, falha de pacote, escopo contraditório ou requisito de publicação. |
| P1 | Necessário para a qualidade comercial pretendida: clareza, acabamento, equilíbrio e consistência. |
| P2 | Melhoria opcional ou posterior; vira compromisso de lançamento se anunciada. |

P0 de validação significa que precisamos obter o resultado antes de liberar, e não que já se comprovou uma falha em todas as situações. Responsáveis indicados abaixo são **papéis sugeridos**, não pessoas atribuídas. Cada fechamento deve registrar commit, build, ambiente, passos, resultado e evidência. Um item só passa para concluído depois de conferir seus critérios no produto que será entregue.

## O que já existe e deve ser preservado

| Área | Evidência | O que isso comprova / limite |
| --- | --- | --- |
| Aplicativo Godot | `godot/project.godot` | Cena principal de campanha, interface 1280×720 expansível e renderizador de compatibilidade. Não comprova outras plataformas. |
| Exportação Windows | `godot/export_presets.cfg`, `godot/Exportar.ps1` | Preset x86_64, exportação release, cópia de licenças e manifesto com hashes. Não comprova instalação limpa ou entrega pela Steam. |
| Saves | `godot/scripts/campaign/save_store.gd`, `state.gd` | Validação, revisão contra escrita desatualizada, temporário, backup e recuperação. O próprio contrato é local e de processo único, sem certificação online ou promessa de resistência a toda queda de energia. |
| Controles | `godot/scripts/campaign/controls.gd` | Ações, teclado remapeável com conflitos, analógico e famílias de glifos Xbox/PlayStation/Switch. Não comprova navegação integral em controle físico. |
| Progressão | `partner_levels.gd`, `progression.gd` | Parceiro limitado a 50; crédito de XP menor para tamer. A curva final precisa de medição de campanha. |
| Campeonato | `ruinas_elo.gd` | Chave textual de oito participantes; Kael enfrenta Grampo, Tyler e Faye, depois Jamile pelo título. Jamile está fora da chave, como definido. |
| Reunião dos campeões | Mapeamento F20 e testes locais | Separação, destaque de quem fala, câmera e retorno implementados; 118 verificações anteriores nos modos normal/reduzido. Dona Neve ainda é mock do professor. |
| Trovareta | F19, importador Soulgen e testes locais | Atlas aprovado integrado, ruptura da linha, voo, tempestade e entrada do Rato; 28 verificações anteriores em ambos os modos. Caminhada própria do Rato e percurso humano ainda pendentes. |
| Torre e recuperação | F23 | Emissão persistente e recuperação encenada da cidade; 25 verificações anteriores. Cenários urbanos legados e variantes sem rabiola ainda pedem arte. |
| Epílogo Tyler | F29 | Entrega da flor, reação e retomada após interrupção; 25 verificações anteriores. Interior próprio do laboratório/escadaria ainda não finalizado. |
| Cobertura automatizada | `godot/tests`, relatórios de refinamento | Muitos testes específicos existem. Parte das vitórias é simulada: isso não mede dificuldade, compreensão do jogador ou uma partida contínua. |

Inventário detalhado de história: [F01–F36](../campaign/refino-atos-finais/MAPA-DE-REFINAMENTOS.md). Este plano amplia aquele documento para lançamento; não apaga suas pendências.

## 1. Contrato da versão 1.0 — produção e direção

### S01 · P0 / D — definir o produto que será vendido

Há uma orientação anterior de campanha solo conectada à conta e recompensas online, enquanto a descrição da exportação atual diz “campanha offline”. Definir explicitamente: campanha local, campanha conectada ou modo híbrido; necessidade de login; funcionamento sem rede; quais funções entram na Steam. **Recomendação:** fechar primeiro uma campanha Godot local confiável; só anunciar conexão/economia compartilhada se a integração estiver validada. Essa recomendação não substitui a decisão do produto.

Resultado: uma lista assinada de funcionalidades incluídas/excluídas e regras offline. Aceite: descrição, primeiro acesso, menu e comportamento sem internet concordam, sem pedir um servidor inexistente. Dependência de saves, conta e página da loja.

### S02 · P0 / D — fechar plataformas e modalidade de lançamento

Recomendo Windows x86_64 como alvo inicial comprovável. Definir 1.0, demo ou Early Access; não chamar uma versão incompleta de 1.0 para contornar os critérios. Linux nativo, macOS e Deck exigem suas próprias validações se anunciados.

Resultado: matriz de sistemas, idiomas, periféricos e requisitos mínimos prometidos. Aceite: cada marca publicada corresponde a uma configuração testada; nenhuma obrigação implícita de lançar mobile, DLC ou todos os mapas experimentais.

### S03 · P0 / C — consolidar uma fonte reproduzível

As últimas melhorias estão misturadas a alterações locais e reimportações de assets. Separar trabalho intencional de churn de importação e artefatos de teste; revisar dependências e commits pequenos. Não reverter conteúdo alheio automaticamente.

Resultado: revisão integrada, tag candidata e manifesto correspondente. Aceite: checkout limpo consegue gerar a mesma versão funcional com instruções documentadas, sem depender de arquivos exclusivos da máquina atual. Hash binário não precisa ser idêntico se o exportador não for determinístico; a origem e os recursos precisam ser rastreáveis.

### S04 · P1 / D — regras finais de conteúdo e nomes

Fixar Bíblia e catálogo publicado: Eremor como nome atual, aliases antigos preservados quando necessários em saves; grafia Heleana, Platyx, nomes de regiões, classes e itens. Diferenciar gancho de DLC de missão incompleta.

Resultado: glossário e matriz de marcos/atores/itens. Aceite: diálogo, missão, mapa, batalha, créditos e coleção usam a mesma identidade; IDs antigos continuam carregando.

## 2. História, encenação e progressão — roteiro, gameplay e QA

Para cada linha abaixo, realizar vitória, retorno, derrota quando aplicável, fechamento/reabertura e revisão visual com as configurações de movimento normal/reduzido. Os IDs F são a especificação detalhada já existente.

| ID / prioridade / estado | Refinamento necessário e resultado final | Critério de fechamento |
| --- | --- | --- |
| S05 · P0/V · F05–F09 | Prólogo até o primeiro bairro: TV, aniversário, rabiola antiga, nascimento/nome do Rabbito, saída de casa, professor, treino e inscrição. A pessoa entende o objetivo sem instrução externa. | Save novo, nome padrão/personalizado, cancelamentos, tutorial perdido e retomada; filmagem contínua sem inserir flags ou vitórias. |
| S06 · P0/V · F09–F11 | Bambuzal, ordem da missão Nina, Tyler, comporta, apitos e conexões de bairros. Gates respeitam a ordem aprovada e não exigem refazer conteúdo já concluído. | Ida/volta, apito falso/verdadeiro, dinheiro insuficiente, vitória sobre Lohan e saves antigos; não cobrar nem conceder duas vezes. |
| S07 · P1/V · F12–F14 | Mural com câmera frontal, encontro Retalho, Pipa-Dragão e fuga do Varal. Substituir elipses importantes por ação legível, com devolução do controle. | Câmera restaura; derrota prevista não parece game over; fuga e decisão são mostradas; não há fala narrando uma ação que o jogador deveria ver. |
| S08 · P0/V · F02/F15 | Duas vertentes Retalho/Heleana. Aceito: parceiro no time, novo laço/nome mantido. Recusado: grunhido fora da casa, seguido de saída e reconexão com a mãe. | Sem usar emblema como gatilho; testar banco/time cheio, Retalho fora do time, nome alterado, pausa e reload; sem duplicar ou apagar parceiro. |
| S09 · P0/V · F16/F18/F32 | Exames, Remar, Cavar e Corrente de Ar: ensino antes do obstáculo, empréstimo coerente, retorno sempre possível. Platyx não vira montaria genérica. | Erro, desistência, parceiro removido/trocado, time vazio e load do outro lado do obstáculo; sem aprisionamento geográfico. |
| S10 · P0/V · F17 | Mormaço: duelo normal com Kael; 30% de dano ativa corte ao overworld; carretel e transformação; Tyler/Rai chegam; segunda fase sombria. | Limiar cruzado por dano pequeno/grande, vitória/derrota e reload em cada transição; transformação só no overworld, ajuda presente e sem recompensa duplicada. |
| S11 · P1/C+V · F19 | Trovareta: conservar a sequência já implementada; completar caminhada do Rato e conferir dois duelos reais, libertação e clima. | Sem fala de vitória na fuga/derrota, sem Rato oculto no barranco, sem fechar a missão antes do diálogo final persistir; gravação sem atalhos. |
| S12 · P1/C+V · F20 | Reunião dos oito campeões: arte própria de Dona Neve e harmonização das gerações de sprites. Separação e indicação de falante já existem. | Todos identificáveis, entrada/saída sem sobreposição e controle restaurado; testar aproximação por diferentes lados e resolução menor. |
| S13 · P0/V · F04/F21/F22 | Laboratório e noite: revelação Tyler separada da sidequest Pipeiro Fantasma; barreiras e nós comunicam o objetivo. | Fazer main/side em ambas as ordens e com side ignorada; portas corretas e noite não persistente por erro; revelações sem contradição. |
| S14 · P1/C+V · F23 | Torre e recuperação urbana: manter ativação/emissão; mostrar criaturas e bairros recuperados com arte apropriada. | Voltar do cume sem mover o save indevidamente; retorno posterior preserva recuperação; distinguir vitória opcional da cura efetiva. |
| S15 · P0/V · F03/F24 | Caverna do Elo A–D: guardas, resgates, Platyx a 50%, reconciliação e saída com Grampo, Rato derrotado, despertar Eremor, pedra no vilão e evacuação. | Conversa acontece antes da partida; Platyx demonstra a recusa; Rato anda até o impacto; mãe/professor ausentes; Eremor só começa ao interagir após a cutscene, com tempo para preparar/salvar. |
| S16 · P0/V · F25–F27 | Último bairro libera campeonato; qualificação, Mirante, atendente e chave de oito participantes. Manter três rodadas de Kael e Jamile depois da chave. | Ver chave atualizar com os outros resultados, lobby entre rodadas, derrotas e rematches sem reiniciar indevidamente; jogador encontra o próximo passo sem guia. |
| S17 · P1/C+V · F28/F29 | Vitória Jamile, passagem de título, Pipa TV e encerramento com retorno emocional ao início. Flor de cerejeira opcional no epílogo Tyler. | Créditos e continuação disponíveis; final válido sem flor; entrega única e retomável com flor; nenhum gancho opcional bloqueia encerrar a campanha. |
| S18 · P0/V · F01/F06/F30–F36 | Continuidade transversal: todas as cenas possuem estados antes/durante/depois e retorno após interrupção. | Executar a matriz de saves abaixo, incluindo escolhas opostas; ações concluídas não repetem recompensas e ações incompletas não ficam impossíveis. |

## 3. Mapas e level design — cenário, navegação e câmera

### S19 · P1 / C — interiores e bairros ainda provisórios

Fila visual confirmada: laboratório com interior/escada próprios, Centro e Condomínio com identidade urbana coerente, arte da torre e transições de apresentação legadas. O Condomínio precisa comunicar o lugar luxuoso solicitado, em vez de depender de fundo reaproveitado de feira. Revisar também casa, loja e professor em sua versão atual exportada, sem assumir que toda reestilização anterior se perdeu.

Resultado: cada destino importante tem exterior/interior e entradas que se correspondem. Aceite: planta geométrica aprovada, escala pelo Kael atual, captura integral e na câmera real, portas/escadas com continuidade. Nenhum objeto usado para esconder uma junta quebrada.

### S20 · P0 / V — certificação geométrica de todas as áreas publicadas

Aplicar as regras de construção do repositório: rampas subindo para o fundo u-/v-, barranco com face/borda/base, acessos livres, nenhuma parede órfã, corredor funcional e caminho aparente caminhável. Verificar pathfinding e movimento manual, não apenas conectividade abstrata.

Resultado: catálogo por mapa/parte com entrada, saídas, material, cota, rampas, itens, encontros e pontos de história. Aceite: varredura de alcance, ida/volta entre partes e teste manual de cada boca de rampa, escada, ponte e mureta. Capturas sem personagem cobrindo as juntas. Regras específicas como quantidade de itens/platôs dependem do brief daquela região, não devem ser impostas a todo interior.

### S21 · P1 / V — composição, orientação e exploração

Revisar por rota crítica: bairro inicial → bairros da campanha → áreas de mobilidade → laboratório/cidade → Elo → Mirante/estádio. Criar marcos, áreas de respiro, caminhos opcionais recompensadores e vegetação com transições; corrigir repetições evidentes e áreas grandes sem propósito. Aplicar Wang/terrenos com bordas e cantos coerentes, sem ruído decorativo sobre as passagens.

Aceite: jogador novo identifica saídas e objetivo; atalhos reduzem retorno; encontros não ficam sobre portas/cuts obrigatórias; os cenários mantêm o 2D mangá isométrico simples do projeto. Comparar referência, blocagem e captura real, não aprovar somente a concept art.

### S22 · P0 / V — atores, oclusão e câmera

Validar posição por pés, cota, profundidade e reservas de espaço em toda entrada/cutscene. Garantir enquadramento dos falantes e criaturas grandes; paredes/chefes não escondem a ação central. Não resolver empilhamento apenas aumentando afastamento na tela sem verificar o chão.

Aceite: Kael, aliados e NPCs não nascem na mesma célula; subir/descer não os faz sumir; Eremor permite reconhecer o elenco; câmera frontal e cinematográfica devolvem limites/zoom/seguimento; movimento reduzido continua legível.

### S23 · P1 / C — eliminar divergência gerador–mapa

Existe falha anterior de `montanha.test.mjs`: expectativa “Mirante do cume” diverge do JSON integrado ligado a Tufano/corte. Resolver qual é o contrato correto, depois alinhar fonte geradora, JSON e teste; não trocar a expectativa só para ficar verde.

Aceite: regenerar não destrói ajustes aprovados, testes passam e transições reais permanecem corretas. Exportar somente mapas da versão; prévias industriais, pantanosas, glaciais ou submarinas não são obrigação automática da campanha 1.0.

## 4. Personagens, criaturas e animação — arte e integração

### S24 · P1 / C — fechar o elenco provisório

Pendências conhecidas: Dona Neve usa o professor, Faye não tem arte overworld no lobby, Ícaro/adversários da qualificação precisam de arte própria conforme F26. Fazer inventário adicional de cada NPC que o pacote efetivamente apresenta; o professor foi mock autorizado, não acabamento comercial definitivo.

Resultado: planilha ator → concept aprovado → retrato → idle/walk direcional → cenas. Aceite: nenhum personagem importante usa identidade visual de outro; nomes e proporções permitem reconhecê-lo na câmera do jogo. Um figurante pode reutilizar uma base deliberadamente, sem representar duas pessoas nomeadas como se fossem a mesma.

### S25 · P1 / C+V — padronizar a linguagem do Kael atual

Auditar Tyler, Rai, mãe, Grampo, Gollia, Rato e grunts, campeões e convidados. Conferir traço, mãos/cabeça, volumes, contorno, luz, escala e pivô; preservar corpulência e exageros dos concepts. Não gerar nova arte para tudo antes de verificar o que já está correto.

Aceite: prancha comparativa na mesma escala e chão; oito direções sem inversões indevidas de acessórios; pés estáveis; recorte sem halo; igual identidade entre diálogo, caminhada e cena. Retalho e Eremor têm escala grande intencional, sem tapar a ação.

### S26 · P1 / C+V — matriz de animações realmente usadas

Rato ainda pode transladar com poses direcionais sem ciclo próprio de pernas. Completar walk onde existe locomoção visível; idle orgânico, reação, virada, interação e ações exclusivas quando a cena exige. Não exigir oito direções de uma ação que só aparece numa direção planejada.

Aceite: nenhum deslize de pés nas cenas principais; transição idle/walk/ação sem salto de âncora; atlas, metadados, FPS, loop e eventos conferidos no jogo. Verificar Mormaço normal/intermediário/possuído, Eremor fóssil/despertar/rugido, Platyx/Grampo e Retalho normal/mascarado.

### S27 · P1 / C — variantes de criaturas ainda representadas por substitutos

Desalmados sem rabiola ainda reaproveitam atlas de combate. Trovareta já tem arte própria, mas há apresentação associada ao modelo mecânico Raio: documentar deliberadamente ou separar dados para não deixar a identidade apenas no nome.

Aceite: coleção, batalha e overworld correspondem ao mesmo ser/estado; máscara, posse, cura e fossilização têm leitura inequívoca. Não duplicar Platyx único como encontro comum. Silhuetas de classes não liberadas são intencionais; não confundir com arte ausente de classes já jogáveis.

### S28 · P1 / V — efeitos, iluminação e escala de produção

Revisar partículas, sombras de contato, golpes, invocação, evolução, clima e luz: manter estilo desenhado, sem foto/3D deslocado, brilho quadrado ou transparência suja. Não esconder feedback relevante no modo reduzido.

Aceite: captura normal e reduzida, plano claro/escuro e chefe grande; leitura de dano/ação sem depender exclusivamente de cor ou flashes. Inventário de assets limita geração a lacunas aprovadas.

## 5. Combate, coleção e economia — sistemas e balanceamento

### S29 · P0 / V — vitória, derrota, fuga e preparação

Fechar o contrato por família: selvagem, capanga, campeão, exame, derrota roteirizada, parceiro emprestado, combate em dupla e chefe de fases. Estado de HP, inventário, posição, missão e recompensa deve combinar com o resultado.

Aceite: vitória legítima, KO simultâneo, fuga permitida/negada, recuperação sem dinheiro, retorno com time ferido, encerrar durante transição e rematch; nunca vitória por sair da tela nem softlock sem cura/saída. Alertar e permitir preparação antes de compromissos importantes.

### S30 · P1 / V — ritmo de combate e legibilidade

Medir ataque, rebicar, skills, cooldown, colisões, alvos, hit feedback, IA, assistência e interrupção de fases. Conferir feedback de entrada aceita versus ação em recarga e dano aplicado. Os testes de apresentação não comprovam uma luta divertida.

Aceite: sessões reais com iniciante e jogador experiente; ataques e perigos explicáveis pelo que se vê; sem IA presa, alvos inválidos ou invulnerabilidade permanente; duração e picos de dificuldade registrados por chefe.

### S31 · P1 / V — progressão de XP e grind

Validar intenção tamer 100 / parceiros 50, XP proporcionalmente menor do tamer, incentivo à coleção e progressão sem farm obrigatório excessivo. O limite 50 existe em `partner_levels.gd`; os caps numéricos de tamer precisam ser reconciliados com a curva e a interface.

Aceite: curva documentada nível a nível, simulação de campanha com time concentrado/diverso, XP em nível máximo, migração e recompensas repetíveis. Medir tempo até cada marco; não exigir atingir nível 100 para terminar a história se isso não for a intenção. Skills futuras do tamer devem estar claramente fora da promessa ou completas.

### S32 · P0 se incluído / D+V — classes e evolução no Godot

Não presumir que a implementação antiga JS está integrada à campanha atual. Fazer rastreamento de dados, interface e efeito real em combate: constelação, requisitos por nível/status/item, desbloqueio, consumo, troca e persistência. Rabbito: duas linhas com evoluções posteriores e Rabbitknight especial terminal, sem exclusividade por conta.

Aceite: cada classe liberável na 1.0 tem arte/descrição/efeito e pode ser obtida naturalmente; item não some em falha; requisito não pode ser burlado; mudança não duplica parceiro nem perde XP. Se adiada, remover promessa e entradas incompletas em vez de vender silhuetas eternamente inacessíveis.

### S33 · P0 se incluído / D+V — invocação e obtenção

Conferir no Godot NPC → espécies vistas → cards com disponível/bloqueado → escolha de rabiola → usar → ritual de até três tentativas → nome/acolhimento. Consumo na utilização; abandono danifica e só permite descarte. Aceitação de rabiola alternativa é infraestrutura, sem espécies habilitadas até decisão contrária.

Aceite: banco cheio resolvido antes de perder recompensa, erro/saída/load sem multiplicar tentativas ou itens, aquisição por drop/loja/evento somente quando realmente incluída. Espécies únicas de história seguem suas regras próprias.

### S34 · P1 / V — encontros e recompensas

Mapear bioma, raridade, nível, drop de rabiola, encontros de rascunho e graça após batalha/transição. Garantir variedade sem interromper conversas e portas. Separar itens de missão de itens vendáveis/descartáveis.

Aceite: todas as recompensas anunciadas têm origem e uso; nenhum item essencial depende de sorte sem proteção; retornos não prendem o jogador em cadeias de encontros; tabelas e chances verificáveis.

### S35 · P0 se online / D+V — trocas, loja e conta compartilhada

Inventariar quais funções web — troca 1×1, fazenda, eventos, compra e perfil — pertencem à versão Steam. Busca nos scripts examinados não comprovou uma integração Supabase/Steamworks equivalente. Isso exige rastreamento do fluxo, não conclusão apenas pelo nome dos arquivos.

Aceite se incluído: autenticação e autoridade no servidor, transferência atômica, propriedade e bloqueios de negociação/partida, dupla confirmação resetável, expiração/cancelamento/histórico, idempotência/reconexão; sem importar inventário local editável como recompensa online confiável. Se excluído: menus e loja não prometem acesso a essas funções.

### S36 · P1 / V — balanceamento de lançamento

O balanceamento foi adiado nos refinamentos anteriores; agora precisa de uma etapa própria. Medir economia, cura, captura, variedade de classes, chefes e time mínimo viável. Evitar uma espécie obrigatória por vantagem invisível.

Aceite: planilha de parâmetros, amostra de runs reais e registro de ajustes; dificuldade crescente sem saltos injustificados; derrotas ensinam uma alternativa e permitem recuperação. Telemetria pode ser local/manual: não exige coleta online.

## 6. Saves, banco e conta — integridade antes de acabamento

### S37 · P0 / V — salvar, carregar e excluir

Preservar o armazenamento protegido existente e testar slots manuais, autosave no slot 0 ligado por padrão, símbolo enquanto grava e opção desligada. Excluir campanha precisa explicar exatamente o que permanece no banco global.

Aceite: salvar durante exploração, após luta e após cut; mudar slot, overwrite, cancelar exclusão, reiniciar campanha e receber novo Rabbito conforme regra. Indicação visual só declara sucesso após gravação; falha mostra recuperação possível sem destruir backup.

### S38 · P0 / D+V — 30 por save e 20 globais

Definir de forma implementável a separação: banco da campanha com 30 e depósito global da conta com 20; identidade de cada criatura e transferência de ida/volta. Um arquivo local chamado conta não comprova vínculo a uma conta online/Steam.

Aceite: testar 29/30/31 e 19/20/21, duplicatas legítimas, transferência interrompida, duas campanhas, exclusão de origem, parceiros essenciais/equipados e escolha de descarte. A transferência preserva atributos e nunca duplica/perde a instância. Se rede existir, servidor arbitra propriedade; não basta dois arquivos locais.

### S39 · P0 / V — falhas, migração e concorrência

O contrato atual é de processo único. Definir proteção contra duas instâncias, validar disco cheio/sem permissão, primário truncado, backup corrupto, schema futuro e falha entre passos. Preservar cópia antes de migrar; informar incompatibilidade sem sobrescrever.

Aceite: injeção de falhas e encerramento abrupto em pontos definidos, saves representativos dos atos e escolhas; após cada caso o jogador recupera estado válido ou recebe erro recuperável. Não prometer fsync/power-loss absoluto sem ensaio e implementação apropriados.

### S40 · P0 / V — privacidade de perfis e reinstalação

O diretório atual é `user://campaign`, sob diretório customizado PipaKlub. Testar duas contas Steam no mesmo usuário Windows, reinstalação, nomes Unicode e perfis do sistema diferentes. Definir se dados serão isolados por SteamID e como importar saves locais existentes sem misturar contas.

Aceite: nenhum jogador recebe progresso de outra conta inadvertidamente; desinstalar/atualizar não apaga save; erro de perfil tem mensagem clara. Nunca incluir saves pessoais, tokens ou contas de teste no depot.

### S41 · P2 ou P0 se prometido / D+V — Steam Cloud

Escolher API ou Auto-Cloud, escopo e comportamento de conflito. Cloud não é banco online nem mecanismo antifraude; não sincronizar caches e preferências específicas da máquina indiscriminadamente.

Aceite: dois PCs, sessão offline, upload interrompido, conflito de versões, exclusão/reinício, troca de usuário e rollback de build; backup não pode ressuscitar campanha excluída silenciosamente. [Documentação oficial de Cloud](https://partner.steamgames.com/doc/features/cloud).

## 7. Menus, HUD, controles e acessibilidade — UX e QA

### S42 · P0 / V — fluxo inteiro com controle físico

Controles e glifos já existem. Validar do título aos créditos, incluindo nome de parceiro, inventário, constelação, diálogos, escolha, salvar/excluir, ritual e mensagens de erro sem mouse. Resolver teclado virtual se entrada de texto fizer parte desse alvo.

Aceite: foco inicial visível, ordem previsível, voltar consistente, restaurar seleção, nenhum controle oculto captura foco; desconectar/reconectar e alternar teclado/controle não prende nem duplica comandos. Testar Xbox e PlayStation reais; família Switch não equivale a publicação no Switch.

### S43 · P1 / V — kit de UI consistente

Inventariar telas e remover aparência de painel web: hierarquia clara, informação passiva distinta de botão, prompts contextuais, grade com detalhe de seleção e navegação adequada. Conferir HUD de duelo, coleção, configuração, loja, missão, mapa e diálogos.

Aceite: o jogador sabe o que está selecionado/ativável/bloqueado; sem scroll gigante obrigatório e sem ações importantes fora da área; estados vazio, cheio, erro e confirmação têm layout final. Usar o kit já existente, sem redesenhar o jogo inteiro por capricho.

### S44 · P1 / V — loading e transições

Conferir todas as trocas de mapa/cena, atlases e batalha: não revelar tela incompleta, não aceitar entrada que avance diálogo invisível, não ficar em loading eterno em falha de recurso. Evitar atraso artificial em transições já instantâneas.

Aceite: instalação fria/quente, disco lento e falha controlada; interface responde, há saída de erro, posição de chegada e música corretas. Registrar tempos reais antes de fixar metas de otimização.

### S45 · P1 / V — resoluções e legibilidade

Testar 1280×720, 1280×800, 1920×1080, 2560×1440 e ultrawide se suportado, janela redimensionada e escala do Windows. O `expand` atual demanda QA de limites e layout.

Aceite: textos e botões sem corte, HUD não cobre ação, câmera não revela fora do cenário e legendas não invadem prompts; conteúdo de tela inteira mantém safe area. Registrar limitações reais na matriz de suporte.

### S46 · P1 / V — acessibilidade prática

Conferir tamanho/velocidade do texto, contraste, informações por ícone+texto além de cor, controle de volumes, movimento reduzido, flashes, vibração e ações repetitivas. Permitir rever objetivo e instruções.

Aceite: pessoas com leitura lenta avançam sem perder fala, modo reduzido preserva eventos e clareza; ajustes persistem e não exigem precisão desnecessária de timing. Não anunciar recursos de acessibilidade sem teste específico.

### S47 · P2 / V — Steam Deck e Proton

Não é bloqueio universal para vender na Steam, mas é um alvo valioso se adotado. Testar dispositivo real: controles, OSK, suspensão/retomada, saves e desempenho no padrão. Os critérios atuais de compatibilidade incluem interface e entrada adequadas; não assumir que janela 720p ou emulação de controle equivale a Verified.

Aceite: relatório de hardware/Proton/configuração e problemas conhecidos; só marcar compatibilidade que foi comprovada. [Critérios oficiais](https://partner.steamgames.com/doc/steamhardware/compat).

## 8. Áudio, texto e apresentação final

### S48 · P1 / V — áudio de toda a jornada

Auditar música por região, silêncio intencional, transições, ambiente, passos, ataque, falha, recompensa, invocação, posse e rugido. Confirmar não há placeholders sem licença, clipping, repetição irritante ou música duplicada após load.

Aceite: mapa de cues e buses, volume normalizado por escuta/métricas, ducking onde ajuda a narrativa, mute/volume persistentes e troca de dispositivo funcional; nenhuma informação essencial só por som. Dublagem completa não é exigência de lançamento.

### S49 · P1 / V — revisão editorial e idiomas

Revisar português final, nomes, concordância, tom das vozes, instruções e recapitulação de missão. Extrair texto para localização quando necessário; definir idiomas da 1.0. Inglês pode ampliar alcance, mas não presumir que já está aprovado como escopo obrigatório.

Aceite: leitura no contexto, sem IDs/texto de debug; strings longas, acentos e nomes personalizados não quebram HUD; página Steam declara corretamente interface/legendas/áudio de cada idioma. Traduzir a loja não prova tradução do jogo.

### S50 · P1 / V — fechamento e pós-jogo

Acabar créditos, agradecimentos, licenças, tempo de encerramento, continuar após créditos e confirmação do título. Deixar claro o que o jogador ainda pode explorar sem prometer um DLC pronto.

Aceite: final satisfatório em caminho principal e com sidequests; retornar ao título e carregar não repete premiação; conteúdo inacessível é deliberado e comunicado, não menu sem função.

## 9. Engenharia, exportação e desempenho — desenvolvimento e build

### S51 · P0 / C — recursos carregados como arquivos crus

Foram encontradas chamadas `Image.load_from_file` em `house_modern.gd:134`, `shop_modern.gd:15/25`, `front_end.gd:256/262`, `hud_title_menu.gd:21` e `pixelgen_sprites.gd:24/44`. O teste anterior de HUD gerou alerta de incompatibilidade na exportação. Isso é **risco concreto**, não comprovação de que cada chamada já falha no preset atual.

Trabalho: usar carregamento de recursos importados onde apropriado ou comprovar inclusão e leitura intencional do arquivo cru. Aceite: versão release fora do repositório visita casa, loja, professor, título, todas as criaturas e cenas de dados dinâmicos sem recurso faltante. [Aviso oficial de Image](https://docs.godotengine.org/en/stable/classes/class_image.html).

### S52 · P0 / C — CI não certifica ainda a campanha Godot

O workflow examinado, `.github/workflows/demo.yml`, roda build/testes Node/web. Criar etapa Godot com engine/templates fixos, importação limpa, suites relevantes, validação de recursos e exportação Windows. Manter os testes web úteis, sem tratá-los como substitutos.

Aceite: uma regressão GDScript/recurso bloqueia a candidata; artefato é identificável por commit; logs acessíveis e sem dependência de caminhos absolutos do desenvolvedor. Rodar os checks de overworld/Morro/modelo e suites de campanha pertinentes numa base consolidada.

### S53 · P0 / V — pacote comercial limpo

Revisar filtros de exportação de JSON/fontes/atlas, recursos referenciados por string, exe+PCK, licenças, ícone, versão e descrição. O preset ainda usa versão 0.1.0.0. Empacotar só runtime: sem editor, saves pessoais, testes, credenciais, protótipos e referências de terceiros não destinadas à distribuição.

Aceite: iniciar em Windows sem Godot/Node/repo, usuário comum sem privilégio de administrador, caminho com espaços/acentos; instalar, atualizar, verificar arquivos, mover biblioteca e desinstalar; nenhum arquivo de runtime depende da pasta de trabalho do shell. [Exportação Godot](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html).

### S54 · P1 / C+V — erros e encerramento de recursos

Execução anterior de `dialogue_hud_checks.gd`: 629 checks sem falha, porém alertas de imagem e objetos/recursos vivos ao encerrar. Classificar vazamento de teste versus runtime e corrigir o que cresce por visita, em vez de declarar tudo limpo porque os asserts passam.

Aceite: repetição de mapas, lutas, diálogos e cutscenes não acumula nós, sinais, áudio ou memória; saída e nova sessão sem crash. Erros conhecidos triados, com justificativa registrada quando exclusivamente de teardown do teste.

### S55 · P0 / V — desempenho e requisitos mínimos reais

Não publicar requisitos de hardware por palpite. Medir frio/quente, pior chefe, grupo dos campeões, chuva/partículas, atlas e mapa pesado. Definir orçamento de FPS, frametime, RAM/VRAM, tempo de load e tamanho instalado para o hardware escolhido.

Aceite: perfil em máquina mínima e recomendada, sessões prolongadas, sem congelamento na interação; limites de qualidade e VSync/fullscreen funcionais. Meta proposta de 60 fps no PC recomendado precisa ser validada; suporte Deck usa sua própria avaliação. Medir percentis e picos, não só FPS médio.

### S56 · P1 / V — pausa, janela e suspensão

Definir o que pausa exploração, combate e cena; testar Alt-Tab, perda de foco, resize, fullscreen, múltiplos monitores, gamepad desconectado e sleep/resume.

Aceite: jogador não toma dano inesperado durante menu quando deveria estar pausado; delta grande não pula passos de cena; áudio/dispositivos e input voltam sem ação presa; autosave respeita estados seguros.

### S57 · P0 se conectado / V — segurança e falhas de rede

Se S01 incluir online: revisar segredos no cliente, autoridade, permissões, rate limits, propriedade, expiração, sincronização e indisponibilidade de backend. Se estritamente local, focar validação robusta de arquivo e privacidade, sem implementar anticheat invasivo desnecessário.

Aceite: rede desligada/instável e servidor em erro têm comportamento definido; nenhum segredo privilegiado em pacote/log; reconciliação não apaga progresso local nem credita recompensa duas vezes. Política de suporte a edições locais não pode ser confundida com fraude em economia compartilhada.

## 10. Steamworks, loja e lançamento — produção e publicação

As regras abaixo foram consultadas em 04/11/2026 e devem ser conferidas novamente no painel antes de agendar. O estado administrativo da conta **não foi auditado**.

### S58 · P0 / V — onboarding e calendário

Confirmar AppID, direito de publicação, onboarding, pagamento por produto e informações administrativas pelo titular. A página oficial consultada informa espera de **21 dias** para os primeiros títulos e Coming Soon público por **pelo menos duas semanas**; não usar lembranças antigas para marcar data. O painel e os requisitos vigentes na data da submissão prevalecem.

Aceite: requisitos administrativos e temporais confirmados pelo produtor, sem colocar documentos pessoais no repositório. [Onboarding oficial](https://partner.steamgames.com/doc/gettingstarted/onboarding).

### S59 · P0 / C+V — depot Godot, branch privada e instalação Steam

`desktop/scripts/steam-vdf.mjs` gera configuração de preview apontando para `dist/steam/PipaKlub-win32-x64`, legado Electron. Não é prova de depot da versão Godot. Preparar configuração específica para o diretório release correto, executable/launch options, packages e branch privada.

Aceite: outra máquina recebe a build correta pela Steam; inicia pelo cliente/Big Picture, mantém saves ao atualizar e pode voltar a uma build anterior compatível. Nenhum upload automático ou `setlive main/default` sem autorização de publicação. Credenciais ficam fora do repositório.

### S60 · P1/P2 / D+V — integrações Steam escolhidas

Definir conquistas, Cloud, rich presence, overlay e Steam Input. Não é necessário implementar toda a API Steamworks/GodotSteam para distribuir um jogo. A busca nos scripts examinados não localizou integração nativa explícita; confirmar arquitetura antes de estimar implementação.

Aceite de cada recurso escolhido: inicialização/falha/offline sem crash, callbacks e desligamento corretos, progresso sem conquistas duplicadas, glifos não conflitantes. **Achievements, DRM, multiplayer, Workshop e Cloud não são bloqueios universais da Steam.** Não marcar funcionalidades na loja antes de estarem funcionando.

### S61 · P0 / V — página da loja fiel à build

Preparar nome, descrição curta/longa, gênero/tags, idiomas, controles, requisitos medidos, suporte e preço definido pelo produtor. Capturas precisam mostrar gameplay real; concept de mapa não deve ocupar o lugar de screenshot do produto.

Aceite: cada promessa tem uma cena funcional demonstrável na candidata; a página não vende features futuras como presentes. Loja e build têm revisões próprias; reservar margem para correções. [Processo oficial de revisão](https://partner.steamgames.com/doc/store/review_process).

### S62 · P1 / V — pacote gráfico de loja e biblioteca

Produzir key art/logo e variantes próprias para cada formato; não apenas esticar uma captura. Conferir templates atuais: header 920×430, pequena 462×174, principal 1232×706 e vertical 748×896, além dos assets de biblioteca/ícones conforme o painel.

Aceite: logo legível no tamanho pequeno, arte representa o jogo, crops respeitam áreas seguras e arquivos atendem às regras atuais; trailer de gameplay recomendado para apresentação comercial, sem exigir cinema pré-renderizado. [Assets oficiais](https://partner.steamgames.com/doc/store/assets/standard).

### S63 · P0 / V — conteúdo, classificação e uso de IA

Preencher o Content Survey conforme o conteúdo real entregue, incluindo geração de arte/narrativa/áudio/localização quando aplicável. Inventariar o que é pré-gerado; geração ao vivo, se existir, tem exigências adicionais. Não presumir que declarar IA resolve direitos de terceiros.

Aceite: respostas consistentes com jogo/página, classificação e disponibilidade regional verificadas pelo responsável no painel; procedência dos assets rastreável. Ferramentas de programação não devem ser confundidas automaticamente com conteúdo gerado consumido pelo jogador. [Content Survey](https://partner.steamgames.com/doc/gettingstarted/contentsurvey).

### S64 · P0 / V — direitos e créditos do pacote

Já existem licenças Godot, fontes e prompts Kenney em `godot/licenses`. Auditar também arte gerada, áudio, fontes extras, código, plugins, contribuições do time e referências. Concepts de Pokémon/Digimon/Dofus servem à direção e não devem virar material de terceiros distribuído por acidente.

Aceite: registro por recurso com autoria/origem/licença e atribuição quando exigida; créditos acessíveis; autorização para contribuições comerciais confirmada pelo produtor. Dúvidas reais de direitos são resolvidas antes de empacotar, com avaliação profissional quando necessária; esta auditoria não é parecer jurídico.

### S65 · P0 / V — privacidade e suporte

Documentar dados efetivamente coletados, login, diagnósticos, contato e procedimento de exportar save/log para suporte. Sem coleta online, não inventar rastreamento só para cumprir uma checklist.

Aceite: jogador sabe onde estão seus dados e como pedir ajuda; logs não contêm credenciais; responsáveis definem tratamento de solicitações e política pertinente às regiões oferecidas. Verificação legal específica fica com o titular, sem presumir obrigação de um fluxo que o jogo não utiliza.

### S66 · P0 / V — operação do dia do lançamento

Preparar runbook: candidata aprovada, depot correto, backup do pacote anterior, compatibilidade de save, notas da versão, revisão Valve, comunicação e responsável por monitorar problemas. Congelar features quando entrar em RC.

Aceite: ensaio em branch privada de instalar/atualizar/voltar; canal de suporte disponível; bugs graves têm responsável e procedimento de hotfix. O lançamento e qualquer mudança pública de branch continuam exigindo autorização expressa; este documento não os executa.

## 11. Matriz mínima de validação da candidata

Os testes devem usar **o mesmo exe/PCK que irá para a Steam**, com hash no relatório. Saves de posicionamento ajudam a regressão de cenas, mas não substituem as partidas contínuas.

| Sessão | Cobertura | Evidência exigida |
| --- | --- | --- |
| Q01 — primeira compra | Instalação limpa, iniciar, configurar, prólogo e primeiro ciclo de batalha/salvar/retomar. | Vídeo e observações de jogador sem acesso ao roteiro. |
| Q02 — campanha principal | Início aos créditos sem edição de flags, teleporte de teste ou vitórias injetadas. | Registro de marcos, tempo, time, níveis, derrotas e problemas. Pode ser dividida em sessões normais pelo próprio save. |
| Q03 — escolhas | Retalho aceito/recusado, no time/fora, side Tyler antes/depois/ignorada, flor entregue/ausente. | Matriz de saves, resultado narrativo e inventário antes/depois. |
| Q04 — perdas | Derrota e fuga de cada família, sem cura/dinheiro, time alterado, empréstimos, banco cheio. | Retomada jogável sem recompensa indevida ou impossibilidade de avançar. |
| Q05 — interrupções | Fechar antes/durante/depois de recompensa, cut, transição e gravação; backup, arquivo corrupto e schema futuro. | Estado recuperado, mensagem de erro e ausência de duplicação/perda. |
| Q06 — controles | Teclado remapeado e controles reais; nomeação, ritual, todas as abas, hotplug e pausa. | Percurso sem mouse e sem foco preso, dispositivos identificados. |
| Q07 — audiovisual | Todos os mapas da 1.0, eventos principais, câmera/oclusão, áudio e modo reduzido. | Capturas reais comparadas com padrão Kael/2D mangá e lista de exceções aprovadas. |
| Q08 — hardware | PC mínimo/recomendado, resoluções, sessão prolongada, instalação fria e perda de foco. | Perfis, FPS/frametime, memória, load e logs de crash. |
| Q09 — Steam | Branch privada, segunda conta/máquina, update/reinstalação, offline, overlay/Cloud quando escolhidos. | BuildID, hash, pacote recebido e saves preservados. |
| Q10 — migração | Saves antigos de cada ato e variante, versão anterior → candidata e rollback definido. | Nenhuma sobrescrita silenciosa incompatível; backup e mensagem apropriada. |
| Q11 — regressão automatizada | Campanha, save, batalha, controles, mapas/geradores e validação de recursos. | Relatórios do commit candidato, sem selecionar apenas testes verdes. |
| Q12 — revisão externa | Pessoas que não montaram os mapas e não leram a Bíblia. | Onde se perderam, o que entenderam, frustração, qualidade percebida; problemas priorizados e retestados. |

## 12. Ordem de execução e dependências

| Pacote | Trabalho | Saída verificável |
| --- | --- | --- |
| 1 — contrato e base | S01–S04, S03 e inventário dos sistemas antigos; iniciar S58 administrativo em paralelo quando autorizado. | Escopo 1.0 aprovado e origem consolidada. |
| 2 — executável confiável | S51–S54, S37–S40, S52 e teste inicial S55. | Release Windows fora do repo, saves protegidos, CI Godot e manifesto. |
| 3 — campanha fechada | S05–S18, S20/S22, S29 e Q02–Q05. | Nenhum bloqueio de história, escolha ou retorno. |
| 4 — qualidade jogável | S19/S21/S23–S28, S30–S36, S42–S50. | Elenco/cenários finais, controles integrais, equilíbrio medido e apresentação consistente. |
| 5 — beta distribuída | S59–S65, testes externos e hardware, recursos Steam escolhidos. | Instalação Steam privada, página e conteúdo fiéis à versão. |
| 6 — candidata e lançamento | Q01–Q12 finais, correções e S66. | Relatório de aceite, revisões exigidas e decisão humana de liberar. |

Não estimar prazo pelo número de linhas deste documento: S35 online, S38 banco global e S32 classes podem ter tamanhos muito diferentes conforme S01. Balanceamento deve acontecer antes do RC, mesmo que tenha sido corretamente adiado na fase de implementação.

## 13. Definição objetiva de pronto

- Escopo e promessas fechados; toda funcionalidade anunciada está disponível e testada.
- Sem P0 aberto ou sem evidência; P1 de identidade e usabilidade resolvidos, ou exceção explícita que não comprometa o produto vendido.
- Campanha concluível normalmente, escolhas coerentes, final satisfatório e recuperação de derrota funcionando.
- Nenhum caso conhecido de perda/duplicação de progresso; migração e backup validados.
- Nenhum personagem importante ainda representado por mock alheio; mapas e animações aprovados na câmera de jogo.
- Navegação integral nos dispositivos anunciados, interface legível e ajustes persistentes.
- Desempenho/requisitos medidos; pacote instalado fora do ambiente de desenvolvimento e pela branch privada.
- Resultados vinculados a uma build candidata; documentação de atualização e suporte pronta.
- Loja, assets, direitos, declarações e revisões Steam concluídos pelo responsável.
- Aprovação explícita de lançamento depois da apresentação do pacote final.

## O que não foi verificado

Estado real do Steamworks/AppID/depot/pagamentos/revisões; instalação da candidata pela Steam; campanha completa em execução humana nesta revisão; balanceamento estatístico; todos os mapas e animações quadro a quadro; controles físicos e Deck; PC mínimo; comportamento real de Cloud e backend; direitos comerciais de cada contribuição; condições jurídicas regionais. Esses pontos permanecem trabalho de validação ou decisão, **não foram declarados concluídos**.

Este mapeamento é a base de fechamento da 1.0. Atualizar estado e evidências ao encerrar cada item, sem transformar uma melhoria opcional em bloqueio novo e sem apagar um risco apenas porque a cena isolada funcionou.
