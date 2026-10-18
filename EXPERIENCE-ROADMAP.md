# PipaKlub — Mapa de maturidade visual e experiência de jogo

18/10/2026 · Referência: versão local da branch feature/ui-kit-consistente.

## Escopo e nível de evidência

Este é um backlog de direção de arte, interface e experiência. Não é uma certificação de console. Consolida telas observadas localmente, a organização atual do código e riscos a validar jogando com controle. A matriz anterior de 105 casos verifica geometria; não prova qualidade artística, legibilidade na TV, usabilidade ou satisfação. Não houve uma sessão nova completa de todos os sistemas para elaborar este documento.

Evidência: **O** = observado nas revisões locais; **C** = identificado na estrutura do código; **V** = precisa de validação em sessão de jogo. Prioridade: **P0** = bloqueia direção ou entendimento; **P1** = necessário para uma primeira experiência convincente; **P2** = aprofunda personalidade e acabamento. Prioridade não é prazo nem estimativa de esforço.

## Direção que deve guiar todas as telas

A cidade e seus personagens são o jogo; menus dão suporte à aventura. Papel e bambu são materiais, não uma obrigação de emoldurar cada texto. Informação passiva, destino selecionável e ação imediata devem ter linguagens distintas. O cenário não deve depender de uma cópia desfocada para completar a janela. A descoberta e o apego ao parceiro têm precedência sobre a apresentação simultânea de todas as funcionalidades.

## Inventário de melhorias

| ID | Prioridade / evidência | Área e problema | Intervenção | Critério de conclusão |
|---|---|---|---|---|
| DIR-01 | P0 O | Linguagens de painel, atlas e cenário coexistem sem regra de composição | Definir cenas, menus, diálogos e avisos como famílias distintas | Uma prancha aprovada exemplifica cada família; nenhuma tela inventa uma quinta linguagem |
| DIR-02 | P0 O | Excesso de cantos ornamentados | Reservar ornamentos a ações e superfícies principais; reduzir molduras aninhadas | Cada tela possui um foco dominante; informação passiva não parece botão |
| DIR-03 | P0 O | Alterações sucessivas de CSS acumulam decisões contraditórias | Consolidar regras finais em componentes e remover overrides superados | Cada componente possui uma fonte de estilo; kit não depende de sequência de remendos |
| DIR-04 | P0 V | Tamanhos de fonte e detalhe pensados perto de um monitor | Criar escala para distância de TV e opção de texto maior | Objetivo, comandos e descrição lidos a 2–3 m numa TV de teste; sem corte com escala maior |
| DIR-05 | P1 V | Cores e formas podem não distinguir estados | Definir normal, foco, pressionado, selecionado, bloqueado, indisponível e carregando | Todos os estados distinguíveis por forma/texto além da cor |
| ENT-01 | P1 C/V | Entrada orientada a conta antes de vínculo com a aventura | Separar título, entrar/continuar e início narrativo | Jogador entende como começar e retomar sem percorrer páginas de conta |
| ENT-02 | P1 V | Falha de conexão pode quebrar o clima e deixar dúvidas | Desenhar carregamento, tentativa, indisponibilidade e retorno | Nunca existe tela muda; ação segura e estado do progresso ficam claros |
| ENT-03 | P1 C/V | Experiência de visitante e de membro pode misturar promessas | Definir apresentação explícita do modo de demonstração | Visitante entende o que pode experimentar e o que exige conta, antes de entrar |
| INI-01 | P0 C/V | Muitas atividades antes do primeiro vínculo | Roteirizar chegada → professor → parceiro → treino → primeira vitória → quintal | Jogador novo descreve seu próximo objetivo em cada etapa sem ajuda externa |
| INI-02 | P1 V | Escolha inicial pode parecer formulário | Encenação curta com aproximação, reação e confirmação do parceiro | Escolha mostra personalidade e explica permanência e obtenção futura dos demais |
| INI-03 | P1 C/V | Tutorial pode explicar várias ações de uma vez | Uma habilidade por situação, tentativa segura e retorno claro | Jogador executa cada ação sem depender de leitura longa ou comando não ensinado |
| INI-04 | P1 V | Saída, repetição e retomada podem confundir | Definir retomada do primeiro voo e repetição voluntária | Interromper e reabrir continua no ponto correto; repetir não duplica recompensa |
| QUI-01 | P0 O | Bordas do quintal denunciam imagem encaixada; preenchimento desfocado | Projetar enquadramento com áreas seguras e estratégia explícita para proporções | 16:9 e 16:10 sem faixa, cópia desfocada ou destinos cortados; ultrawide com solução deliberada |
| QUI-02 | P0 O | Etiquetas disputam atenção com arte e criaturas | Mostrar rótulo completo principalmente no destino focado; sinalização ambiental discreta | Um destino tem destaque por vez; professor e parceiros permanecem visíveis |
| QUI-03 | P0 O | Informação passiva já confundiu com botão | Compor nome, objetivo e população como HUD informativo próprio | Jogador identifica todos os elementos clicáveis sem tentativa e erro |
| QUI-04 | P1 C/V | Menu e locais físicos duplicam caminhos | Definir função do quintal e mapa de navegação global | Jogador sabe onde voltar e encontra coleção, cidade e amigos por caminhos consistentes |
| QUI-05 | P1 V | Quintal é bonito, mas pode parecer apenas cenário de menu | Reações leves dos parceiros e interação contextual com professor | Uma interação curta reforça vínculo sem bloquear acesso às atividades |
| MAP-01 | P0 O | Mapa já passou por composição de recorte e fundo duplicado | Refinar atlas único, escala e relação entre mapa e legenda | Arte e legenda parecem uma tela desenhada em conjunto; nenhuma cópia desfocada |
| MAP-02 | P1 O | Insígnias e nomes cobrem a ilustração | Diminuir marcadores e expandir detalhes na seleção | 12 locais reconhecíveis; marcadores e nomes não se sobrepõem nos tamanhos-alvo |
| MAP-03 | P1 O/C | Bairros futuros e bloqueados competem com os disponíveis | Diferenciar descoberto, bloqueado, concluído, título perdido e não lançado | Jogador entende o que jogar agora e o requisito real de desbloqueio |
| MAP-04 | P1 V | Conquista e perda do título precisam de narrativa visual | Insígnia, rival, desafio pendente e resultado de defesa | Antes de aceitar, jogador entende o risco; depois sabe o estado do bairro |
| MAP-05 | P2 V | Bairros podem se reduzir a cinco botões de batalha | Introdução curta, identidade e presença do campeão | Cada bairro tem atmosfera reconhecível e um encontro de apresentação |
| BAT-01 | P0 V | Ataque pode ser percebido sem explicar acerto ou erro | Fechar linguagem de preparação, rebique, contato, crítico e recuperação | Jogador distingue ataque realizado, bloqueado por recarga, erro e acerto |
| BAT-02 | P0 V | Origem de dano e relação entre linhas podem não ser claras | Sinalizar ponto de contato e direção do perigo | Em teste, jogador consegue explicar por que sofreu o último dano |
| BAT-03 | P1 C/V | HUD e habilidades disputam atenção | Hierarquizar sobrevivência, habilidade, adversário e objetivo | Indicadores essenciais lidos durante movimento; sem depender só da cor |
| BAT-04 | P1 V | Feedback pode ficar excessivo com muitas criaturas | Limitar brilho, partículas e sobreposição; opção de efeitos reduzidos | Colisões e silhuetas continuam legíveis no confronto mais carregado |
| BAT-05 | P1 C/V | Começo, pausa, vitória e derrota precisam formar um ciclo | Transições curtas, resumo causal e próxima ação evidente | Revanche, continuar e sair não se confundem; derrota oferece pista útil |
| COL-01 | P1 C/V | Visto, possuído, equipado e invocável precisam de leitura imediata | Sistema único de selos com explicação e legenda | Jogador distingue os quatro estados sem abrir todos os cartões |
| COL-02 | P1 O/V | Retratos pequenos e detalhes competem em listas | Escala consistente, seleção forte e detalhes progressivos | Nomes e criaturas legíveis com controle; foco nunca desaparece ao filtrar |
| COL-03 | P2 V | Coleção pode ser catálogo sem apego | Descrições, comportamento, origem e detalhes do exemplar | Favorito tem identidade além de atributos; descoberta incentiva exploração |
| INV-01 | P0 C/V | Ritual consome item e abandono tem consequência | Confirmação clara antes do compromisso e saída deliberada | Item, alvo, tentativas e risco compreendidos antes do uso; sem descarte acidental |
| INV-02 | P1 V | Desenho pensado para mouse/toque pode falhar no controle | Prototipar entrada de feitiço própria para controle | Ritual completo executável confortavelmente sem cursor de mouse simulado |
| INV-03 | P1 C/V | Preparação, magia e resultado precisam parecer o mesmo ritual | Compor NPC, criatura, rabiola, gesto e revelação com transições | Sempre fica claro o estágio atual e o próximo comando; falha e sucesso inequívocos |
| TRO-01 | P1 C/V | Espetáculo pode esconder o que será transferido | Comparação clara dos exemplares e confirmação por participante | Nome, aparência e condições conferidos antes de confirmar; mudança de oferta perceptível |
| TRO-02 | P1 C/V | Espera, cancelamento, expiração e conexão precisam de linguagem própria | Estados ilustrados e mensagens curtas, com ação segura | Jogador sabe se pode sair e qual é o resultado confirmado da transação |
| TRO-03 | P2 O/V | Animação merece polimento de ritmo e som | Sincronizar transformação, cruzamento, recebimento e revelação | Recebimento tem clímax; efeitos reduzidos preservam a compreensão |
| FAZ-01 | P1 C/V | Fazenda e quintal podem parecer duas versões da mesma atividade | Definir diferença ou integrar caminhos de apresentação | Jogador explica o propósito de cada espaço sem consultar documentação |
| FAZ-02 | P2 V | Passeio pode virar demonstração sem interação | Pequenas reações, observação de parceiro e mudança clara de grupo | Coleção grande continua compreensível; nenhum grupo parece desaparecido |
| ESC-01 | P1 O/C | Escola ainda lembra lista de comandos | Organizar lições como treinamento acompanhado pelo professor | Lição mostra objetivo, habilidade e conclusão; saída e repetição previsíveis |
| SOC-01 | P1 C/V | Amigos e salas ainda podem expor fluxo de formulário web | Convite em etapas, código legível e estado dos participantes | Criar, compartilhar, entrar e reconhecer amigo são claros com controle |
| SOC-02 | P1 C/V | Perfil e histórico têm caráter administrativo | Resumo de jornada e resultados com hierarquia visual | Informações importantes visíveis primeiro; editar conta não compete com jogar |
| ECO-01 | P1 C/V | Banca, moedas, itens e eventos têm convenções próprias | Unificar moeda, saldo, custo, aquisição, falta de recursos e recibo | Antes de comprar jogador sabe o que ganha e o custo; depois reconhece o saldo confirmado |
| DIA-01 | P1 C/V | Desafio diário e recompensas podem virar checklist externo | Apresentar atividade no mundo com objetivo e retorno claros | Recompensa disponível, pendente e recebida têm estados distintos |
| CTL-01 | P0 V | Foco em botões não garante navegação de console | Testar jornada completa apenas com controle | Login suportado, menus, ritual, batalha, erro e saída sem mouse; foco sempre visível |
| CTL-02 | P0 V | Voltar, confirmar e atalhos podem variar entre telas | Contrato único de comandos e preservação de foco | Voltar retorna ao contexto anterior; confirmar não aceita ação destrutiva inesperada |
| CTL-03 | P1 V | Texto e comandos podem depender de teclado | Glyphs pelo dispositivo, remapeamento e troca de entrada | Nenhuma instrução de tecla errada permanece; comandos remapeados refletidos |
| CTL-04 | P1 V | Perda de foco e desconexão do controle | Mensagens e recuperação adequadas ao modo de partida | Solo pode pausar; online informa continuidade e oferece recuperação sem mentir sobre pausa |
| AUD-01 | P1 V | Som ainda precisa reforçar identidade e causa | Inventariar seleção, confirmar, voltar, erro, rebique, impacto e descoberta | Ações centrais têm resposta sonora consistente; volumes independentes disponíveis |
| AUD-02 | P2 V | Ambientes podem soar iguais | Ambiência do quintal e temas por bairro, com transições | Mudança de lugar percebida sem corte brusco ou sobreposição de faixas |
| ACE-01 | P1 V | Leitura, movimento e efeitos podem impedir acesso | Escala de texto, contraste, movimento reduzido e intensidade de flashes | Preferências persistem; menus e combate continuam compreensíveis sem efeito intenso |
| ACE-02 | P1 V | Informações podem existir só em som ou cor | Redundância visual e textual nos eventos relevantes | Recarga, perigo, acerto e conclusão identificáveis sem áudio e sem depender de cor |
| TEC-01 | P1 V | Falha de assets e espera podem mostrar tela quebrada | Placeholders coerentes, progresso real quando disponível e retry | Nenhuma imagem quebrada; ação principal preservada ou indisponibilidade explicada |
| TEC-02 | P1 V | Acabamento pode prejudicar fluidez | Medir composição, efeitos e carregamento nos equipamentos-alvo | Meta de desempenho definida por plataforma antes da aprovação; sem travamento perceptível na primeira ação |

## Assets e entregáveis necessários

| Pacote | Reaproveitar | Produzir ou revisar | Depende de |
|---|---|---|---|
| Direção de interface | Kit Papel e Bambu, ícones existentes | Pranchas de composição, escala tipográfica, estados e regras de densidade | DIR-01 a DIR-05 |
| Quintal | Ilustração e sprites atuais | Enquadramento com áreas seguras, extensões de arte se necessárias, marcadores ambientais e HUD informativo | Composição aprovada antes de gerar imagens |
| Atlas | Cidade e insígnias existentes | Escala de marcos, legenda, estados de conquista e detalhe selecionado | MAP-01 a MAP-04 |
| Primeiro parceiro | Sprites existentes | Poses/reações faltantes, encenação e celebração curta | Roteiro da chegada |
| Professor e rivais | Artes e sprites disponíveis, sujeitos a inventário | Expressões e poses necessárias ao roteiro; identificação consistente | Lista de cenas e falas |
| Batalha | Rebique e atlas existentes | Matriz de feedback e efeitos faltantes por estado, não um efeito novo por criatura sem necessidade | BAT-01 e BAT-02 |
| Invocação e troca | Efeitos e spritesheets existentes | Transições, falha/abandono, revelação e sincronização sonora | Entrada com controle e estados confirmados |
| Áudio | Trilhas já existentes, a verificar | Auditoria de arquivos, sons de interface, sinais de combate e ambiências ausentes | Sem presumir que publicação implica integração correta |
| Conteúdo da campanha | Bairros e líderes já implementados | Inventário dos bairros restantes, cenários, rivais e cenas realmente ausentes | Escopo jogável confirmado |

Não gerar todos os assets antes de aprovar composição e enquadramento. Evitar recriar peças existentes apenas porque ainda não foram integradas.

## Ordem de execução

1. **Fechar direção:** pranchas definitivas de quintal, atlas, diálogo e batalha. Aprovar família informativa versus interativa, proporções e navegação. Entrega: comparação das telas e regras reutilizáveis.
2. **Construir a primeira jornada completa:** chegada, escolha, treino, primeira vitória e retorno. Priorizar clareza de ação e apego ao parceiro. Entrega: roteiro e fluxo jogável contínuo, com retomada.
3. **Validar controle e combate:** completar uma sessão sem mouse, corrigir foco e comandos; consolidar linguagem de ataque/dano. Entrega: evidência por etapa e registro de dificuldades.
4. **Aplicar a direção aos sistemas:** coleção, Dex, amigos, trocas, invocação, banca, fazenda e recompensas, com todos os estados relevantes. Entrega: inventário de telas e estados aprovado.
5. **Polir atmosfera e robustez:** transições, som, acessibilidade, desempenho e apresentação da campanha. Entrega: sessão externa de observação e correções das falhas encontradas.

## Protocolo de aprovação

Para cada tela: verificar entrada, normal, foco, seleção, vazio, carregamento, erro, bloqueio e saída quando aplicáveis. Para atividades econômicas: acrescentar confirmação, espera, sucesso confirmado, falha e interrupção. Não marcar um sistema como concluído apenas por uma captura bonita de seu estado inicial.

Testar desktop 1280×720, 1440×900, 1920×1080 e ultrawide com política de enquadramento definida; janela menor como compatibilidade. Testar texto ampliado e efeitos reduzidos. Testar TV e controle físicos; emulação de viewport não substitui esses testes.

Sessão externa: apresentar a um jogador sem explicar os menus. Registrar onde hesita, erra, pede ajuda, perde o foco, não entende dano ou não sabe para onde seguir. Perguntar ao final: quem é seu parceiro, qual é seu próximo objetivo e o que você quer descobrir amanhã? Não usar a resposta do desenvolvedor como evidência de que o jogador entendeu.

## O que este mapeamento não afirma

Não afirma prontidão para Nintendo Switch, certificação ou port. Não estima prazo sem dimensionar roteiro, assets e plataforma. Não substitui teste real das regras econômicas. Não transforma os 105 casos geométricos anteriores em uma aprovação integral da experiência. Não altera o jogo ou publica conteúdo: organiza a próxima implementação.
