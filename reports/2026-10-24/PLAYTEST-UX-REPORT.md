# PLAYTEST-UX-REPORT — Soulmonsters / PipaKlub

Data: 24/10/2026. Horários em America/Sao_Paulo.

## Condições e limites

**Teste real pela interface**, com cliques, arrastes e teclado na aba `http://127.0.0.1:5194/`. Não consultei código, banco ou implementação nesta missão; não alterei arquivos do jogo, não manipulei progressão e não pulei exercícios. Só escrevi este relatório e salvei capturas.

- Windows, navegador interno, viewport capturado **1254 × 884 px**; mouse e teclado sintetizados, CRT ligado. Sem teste móvel, controle físico, som, FPS ou latência.
- Interações registradas aproximadamente **12:17:22–12:24:50: 7 min 28 s**, incluindo leitura, automação e registro. Não é estimativa do tempo de um humano.
- Conta **Ana Local**, com história no primeiro diálogo, mas nível 2/50 XP e itens de teste preexistentes. A história estava no início; a economia e a coleção **não estavam limpas**. Não atribuo os itens preparados a recompensas desta sessão.
- A tentativa de abrir uma origem separada para sessão limpa foi recusada pela permissão do navegador. Usei a aba já autorizada. Tela de título, login e entrada visitante **não foram reavaliados** nesta missão.
- Já trabalhei na implementação. Não sou participante humano sem conhecimento prévio. Simulei perguntas de iniciante e usei apenas instruções visíveis para resolver tarefas. Notas são avaliações heurísticas, não métricas de pesquisa ou retenção.
- Alcance: transmissão → quarto → montagem inicial → presente → nascimento → nome Ventinho → saída da casa → professor → todas as aulas do primeiro voo e primeiro corte → escolha de Azulão → armação da oficina → primeira tentativa de nó → bloqueio → menus → recarga.
- Não concluí nós, papel, equilíbrio, rabiola, nascimento do segundo parceiro ou campanha posterior. Não contornei o limite com outra conta nem esperei sua janela completa de 15 minutos.

**OBSERVADO:** ação ou conteúdo visto. **HIPÓTESE:** interpretação a validar. **N/T:** não testado. Prioridades descrevem esta execução local; alcance em produção não comprovado.

## A. Resumo executivo

A abertura apresenta uma fantasia específica: dar vida a um desenho de papel e formar uma dupla. O primeiro voo ensina por exercícios e confirmações. **A oficina obrigatória interrompeu essa jornada com uma restrição de tentativas e falha de recuperação.** Não há evidência para avaliar o ciclo completo de batalha de campanha, vitória, recompensa e próximo desafio.

### Cinco problemas mais importantes

1. **P0:** oficina recusou operações, pedindo 15 minutos, após quatro arrastes e uma tentativa de nó. Causa e influência do histórico da conta/IP desconhecidas.
2. **P1:** Salvar novamente não resolveu; retomada falhou; segunda saída carregou o jogo dentro da janela da oficina.
3. **P2:** “Encaixar a última vareta” apenas pega a peça; a ação real e o alvo precisam ser mais explícitos.
4. **P2:** “Saída ao sul” não orienta intuitivamente na câmera isométrica: a porta visível fica no alto à esquerda da sala.
5. **P2:** evolução perde legibilidade e contexto: microtexto na árvore de classes e mudança de nível/XP sem apresentação de ganho observada.

### Cinco aspectos mais bem resolvidos

1. Presente da mãe, projeto de Rabbito e nascimento formam uma sequência causal e emocional.
2. Arraste da vareta funcionou, confirmou “A armação está firme” e trouxe consequência narrativa.
3. O primeiro voo exigiu pilotagem, cruzamento, energia, habilidade, esquiva e rebicada de fato.
4. Missão persistente e seletor de destinos conduziram à casa do professor sem ajuda externa.
5. Parceiros, Mochila, Missões e Dex têm funções distintas; os painéis geralmente retornaram à opção de origem.

## B. Notas por categoria

Notas apenas para o alcance efetivamente observado; não são médias de participantes.

| Categoria | Nota | Justificativa / limite |
|---|---:|---|
| Primeira impressão | 7 | Transmissão estabelece competição e criaturas; nota da abertura narrativa. Tela de título N/T. |
| Identidade visual | 8 | Papel, bambu, rabiolas e oficina aparecem na arte e nas ações. |
| Layout | 6 | Hierarquia principal clara; textos de classes pequenos e áreas vazias nos diálogos. |
| Navegação | 6 | Destinos e retornos funcionam; erro de saída deixa jogo aninhado. |
| Clareza dos menus | 6 | Parceiros/Mochila/Missões claros; “Save e bancos” e ajustes sem estado exigem interpretação. |
| Introdução narrativa | 8 | Liga → desenho próprio → herança → nascimento → professor. |
| Qualidade dos diálogos | 7 | Texto com função; referências espaciais e alguns verbos ambíguos. |
| Tutorial | 7 | Primeiro voo concluído; construção obrigatória posterior interrompida. |
| Montagem da primeira pipa | 5 | Rabbito concluído; oficina seguinte clara na armação, mas bloqueada nos nós. |
| Sistema de batalha | N/T | Só exercícios e rodada segura contra Nozinho; não avalio desafio competitivo por isso. |
| Feedback de combate | 7 | Mira verde, crítico, barras e primeiro corte reconhecíveis no treino. |
| Sistema de recompensas | N/T | Vi +100 pontos e escolha de rabiola, sem vitória remunerada de campanha. Pontos não foram tratados como XP. |
| Progressão | 5 | XP/classes consultáveis; origem do ganho e caminho para requisito não ficaram claros. Conta preparada limita avaliação econômica. |
| Ritmo do jogo | 4 | Continuidade até o treino; espera declarada de 15 minutos rompe a etapa obrigatória. |
| Facilidade de aprendizado | 7 | Instruções permitiram concluir aulas; cuidados finais da oficina N/T. |
| Motivação para continuar | 5 | Curiosidade pelo parceiro/classes, mas próximo objetivo leva ao sistema bloqueado. Hipótese de design. |
| Experiência geral | 5 | Início compreensível, jornada obrigatória não concluída na sessão. |

## C. Jornada e registro do jogador

Tempos vêm das capturas, incluindo leitura e registro. Não representam duração pura da tarefa.

| Horário / etapa | Vejo / acredito que devo fazer | Tentei / resultado observado | Atrito, impacto e melhoria |
|---|---|---|---|
| 12:17:22 TV | Final entre campeões; conhecer ambição de Kael. | Li duas falas do locutor e avancei para Kael. | Identidade competitiva clara; ainda não é tutorial de controle. |
| ~12:17:35 quarto | Projeto na mesa; ir até ele. | Cliquei no chão diante da mesa: comentário sobre desenhos. Cliquei no papel: abriu bancada. | Um alvo identificado teria evitado a tentativa errada; causa do hotspot não investigada. |
| 12:17:47 vareta | Pipa quase pronta e peça solta. | Botão “Encaixar” pegou a peça; um arraste posterior ao centro concluiu. | Rótulo promete resultado antes da segunda ação; destacar ponto de encaixe. |
| 12:18:20 presente | Mãe entrega lembrança para usar no desenho. | Guardei rabiola e usei “Ver projeto”. | Bom destaque ao item; verbo pouco específico para aplicar rabiola. |
| 12:18:34 nascimento | Kael cai, Rabbito ganha vida. | Li três momentos e nomeei Ventinho. | Vínculo surge da minha ação anterior; quero descobrir como ele voa. |
| ~12:18:50 saída | Escada/porta “ao sul”. | Cliquei na escada desenhada à esquerda; esperei descida; cliquei na porta externa. | Desenho resolveu; orientação textual exige traduzir eixos sem bússola. |
| 12:19:39 professor | Missão manda visitar Sr. Assis. | Selecionei destino; entrei automaticamente; cliquei no professor. | Caminho claro. Ele reconhece mãe e parceiro nomeado. |
| ~12:19:45 pilotagem | Círculo “Voe até aqui”. | Cliquei no alvo; chegada reconhecida. | Aprender fazendo funciona. Clique no céu também gasta energia por ser ataque. |
| 12:20:00 ataque | Faixa tracejada e mira verde. | Espaço acertou; etapa confirmou. | Instrução e feedback conectados. Precisão temporal não medida. |
| ~12:20:15 energia | Soltar ataque e recuperar. | Aguardei sem atacar; aula concluída. | Exercício simples e específico. |
| ~12:20:25 ferramentas | Habilidade em 2 s; Shift; segurar/soltar R. | Primeira combinação Q/Espaço não concluiu; reposicionei e refiz com sucesso. Shift funcionou. R ~0,7 s não concluiu de imediato; botão Rebicada ~0,9 s concluiu após trajetória. | Não afirmo tecla R defeituosa: posição, foco e tempo podem influenciar. Dar estado de prontidão/recarga mais contextual. |
| 12:21:07 primeiro corte | Rodada segura com Nozinho. | Reposicionei e segurei Espaço ~3,5 s; corte, +100 pontos e confirmação. | Feedback claro; não representa tensão de adversário agressivo. |
| ~12:21:15 escolha | Quatro rabiolas com estilos. | Comparei Carcará/Azulão e escolhi proteção de Azulão. | Conselho explica diferença apesar dos atributos base iguais. |
| 12:21:30 oficina | Quatro alvos, varetas, 0/4. | Dica → quatro arrastes corretos → Nós, 1/5 cuidados. | Contador e alvos mais claros que montagem no quarto. |
| 12:21:59 bloqueio | Nós e faixa verde. | Primeiro clique segurado ~0,7 s: “Muitas tentativas. Aguarde 15 minutos”. Salvar novamente não resolveu. | Bloqueio técnico com impacto de UX; o nó não foi validado como sucesso. |
| 12:22:23 recuperação | “Não foi possível retomar”. | Saí, reabri, saída repetida carregou jogo dentro do contêiner da oficina. | Não prova perda do save: o carregamento falhou. Recuperação não confiável. |
| 12:22:43 opções | Lista extensa, CRT com estado. | Desliguei, reabri Menu → Opções, confirmei desligado e religuei. | Alternância fecha tela. Comparação visual contaminada pela instância aninhada. |
| 12:23:11 classes | Ventinho equipado; árvore bloqueada. | Selecionei Condutor: nível 15 e recuperação ≥18,4. | Microtexto; falta caminho próximo para aumentar atributo. |
| ~12:23:30 mochila/missões | Rabiolas e próxima tarefa. | Abri/voltei dos painéis; missão mantém oficina. | Separação funcional clara; missão não reconhece indisponibilidade da etapa. |
| 12:23:53 Dex | Carcará ausente, mas obtenção diz recebido na conta. | Li Visão geral/Como obter. | Contradição nesta conta; validar sem fixture antes de generalizar. |
| 12:24:11 perfil/linhas | Nv.3, 60/87 XP e cosméticos com saldo 0. | Consultei sem comprar nem editar avatar. | Progressão consultável; não vi anúncio do ganho. Loja esclarece que não muda desempenho. |
| 12:24:50 reentrada | Professor, parceiro e missão preservados. | Recarreguei; saiu da instância aninhada. | Abertura não se repetiu. Retomada da oficina após expirar limite N/T. |

**Mapa:** TV [contexto] → quarto [alvo ambíguo] → montagem [ação] → presente/nascimento [vínculo] → saída [direção ambígua] → professor [continuidade] → voo [aprendizado] → escolha [autonomia] → oficina [clareza] → nós [BLOQUEIO] → recuperação [falha] → menus [consulta] → recarga [campanha preservada].

**HIPÓTESE de abandono mais forte:** oficina obrigatória, depois do investimento em história e treino. Troca-se a promessa de criar por uma espera sem resolução imediata. Não há taxa de abandono medida.

## D. Problemas encontrados

Esforços abaixo são estimativas sem diagnóstico de implementação nesta missão.

### UX-01 — Oficina limitada durante uso normal observado

- **Sistema:** Oficina, Armação → Nós. **Gravidade: P0 nesta sessão**; alcance em produção desconhecido.
- **Descrição/evidência:** “Muitas tentativas. Aguarde 15 minutos. Use Salvar novamente; seus comandos estão preservados.” [Captura 09](playtest/09-oficina-limite.png).
- **Passos:** concluir voo → escolher Azulão → bancada → dica → quatro varetas → dica dos nós → segurar primeiro nó → Salvar novamente. Trilha observada, não gatilho garantido em conta limpa.
- **Impacto:** não consegui avançar na etapa obrigatória. Não testei recuperação após 15 minutos.
- **Solução:** investigar cadência legítima, escopo do limitador e salvamentos automáticos; preservar proteção contra abuso e comandos pendentes. Mostrar prazo restante e recuperação que respeite a janela, sem mandar repetir inutilmente.
- **Esforço:** médio, dependente da causa. Histórico da conta/IP pode contribuir; hipótese não investigada.

### UX-02 — Recuperação e saída falham no caminho de erro

- **Sistema:** Oficina/retorno ao mundo. **Gravidade: P1**.
- **Evidência:** salvar não resolveu; reabrir mostrou “Não foi possível retomar”; segunda saída abriu uma AXWebArea do jogo dentro de “Oficina das Almas — montagem salva na conta”. [Captura 10](playtest/10-retomada-bloqueada.png); árvore de acessibilidade registrada na conversa.
- **Passos:** após UX-01, sair → reabrir pelo professor → sair novamente.
- **Impacto:** jogador perde referência da tela ativa; duplicação pode afetar foco e efeitos. Não comprovei perda definitiva de dados.
- **Solução:** saída robusta para instância externa mesmo sem inicialização completa; distinguir “salvo”, “comandos pendentes” e “não foi possível verificar”. Evitar garantia incondicional no título da saída.
- **Esforço:** médio.

### UX-03 — “Encaixar” significa primeiro pegar

- **Sistema:** montagem inicial no quarto. **Gravidade: P2**.
- **Evidência:** botão pega vareta e só depois instrui setas/Enter; arraste posterior concluiu. [Captura 02](playtest/02-montagem.png).
- **Passos:** examinar projeto → clicar Encaixar a última vareta.
- **Impacto:** expectativa errada e descoberta de gesto por tentativa.
- **Solução:** “Pegar vareta”, encaixe com contraste e instrução perto da peça. Preservar o arraste, que tem valor de autoria.
- **Esforço:** baixo.

### UX-04 — Referência “sul” ambígua na câmera isométrica

- **Sistema:** escada/saída da casa. **Gravidade: P2**.
- **Evidência:** porta externa desenhada no alto à esquerda, instruída como “ao sul”; encontrei escada pelo desenho.
- **Passos:** após nomear parceiro → ler instrução → descer → ler saída.
- **Impacto:** traduzir eixos sem bússola em vez de seguir objetivo.
- **Solução:** “porta ao lado do sofá”, “escada à esquerda” ou marcador temporário, sem refazer mapa.
- **Esforço:** baixo.

### UX-05 — Mesa e desenhos não identificam imediatamente o alvo

- **Sistema:** exploração do quarto. **Gravidade: P2**, confiança moderada: uma ocorrência.
- **Evidência:** clique no chão em frente à bancada trouxe fala sobre desenhos; clique no papel abriu montagem.
- **Passos:** objetivo Termine seu projeto → aproximar-se pelo chão → observar ação → clicar no papel.
- **Impacto:** tentativa extra e incerteza sobre o objeto examinado.
- **Solução:** nome do alvo ao aproximar-se, feedback visual da mesa ativa e validação da separação entre hotspots. Não presumo erro de colisão sem reproduzir mais vezes.
- **Esforço:** baixo/médio.

### UX-06 — Ganho de nível/XP sem origem percebida

- **Sistema:** HUD/perfil/progressão. **Gravidade: P2**.
- **Evidência:** Nv.2/50 XP antes; Nv.3/55 XP ao retornar; depois perfil 60/87 XP e HUD 60 XP. Não observei apresentação que atribuísse o ganho a uma ação. +100 do treino eram pontos. [Perfil](playtest/14-perfil.png), [reentrada](playtest/15-segunda-entrada.png).
- **Passos:** comparar HUD antes do professor, depois da oficina e perfil.
- **Impacto:** crescimento sem compreensão da causa ou consequência.
- **Solução:** feedback compacto de origem do ganho e nível atingido; esclarecer semântica dos números em HUD/perfil; repetir com conta limpa.
- **Esforço:** médio. Não afirmo valor incorreto ou causa do ganho; a fixture limita a conclusão.

### UX-07 — Classes com microtexto e requisito sem caminho de ação

- **Sistema:** Parceiros → Classes. **Gravidade: P2**.
- **Evidência:** legendas/itens muito pequenos em 1254 × 884; lista trunca nomes. Condutor exige nível 15 e recuperação base ≥18,4, atual 18,00, sem ação adjacente explicando como obter. [Captura 12](playtest/12-parceiros-classes.png).
- **Passos:** Menu → Parceiros → Classes → Condutor.
- **Impacto:** bloqueio legível em conceito, mas difícil de ler e planejar.
- **Solução:** aumentar textos úteis e coluna lateral; reduzir decimais; ajuda “Como aumentar recuperação base?” vinculada ao sistema correto. Testar CRT ligado/desligado.
- **Esforço:** médio.

### UX-08 — Obtenção de Carcará contradiz estado da conta

- **Sistema:** Dex. **Gravidade: P2**, validar em conta nova sem fixture.
- **Evidência:** “Ainda não está na sua coleção” junto de “Recebida ao criar sua conta. Sua pipa básica é permanente.” [Captura 13](playtest/13-dex.png).
- **Passos:** Dex → Carcará → Visão geral/Como obter.
- **Impacto:** impressão de criatura perdida ou promessa não cumprida.
- **Solução:** coerência com fluxo atual e estado da conta; distinguir escolha oferecida, rabiola recebida e criatura construída.
- **Esforço:** baixo.

### UX-09 — Ajuste fecha configurações

- **Sistema:** Opções/CRT. **Gravidade: P3**.
- **Evidência:** alternar CRT voltou ao cenário; precisei abrir Menu → Opções para conferir estado. Religar repetiu fechamento. [Captura 11](playtest/11-opcoes.png).
- **Passos:** Menu → Opções → Filtro de TV.
- **Impacto:** cliques extras para comparar preferências. Persistência do rótulo funcionou.
- **Solução:** manter tela aberta/foco no controle e atualizar rótulo imediatamente. Som/Qualidade poderiam informar estado; suas alternâncias N/T.
- **Esforço:** baixo.

### UX-10 — Vocabulário e verbos pressupõem contexto

- **Sistema:** menus/Dex/narrativa. **Gravidade: P2** para aprendizagem; nome de Save isolado é polimento.
- **Evidência:** “Save e bancos”, “almáticas”, Pipamon, Soulmonster, alma e parceiro aparecem sem explicação observada que relacione todos os termos. “Ver projeto” continua uso da rabiola.
- **Passos:** ler início e visitar Opções/Dex/professor.
- **Impacto:** confundir nomes do universo com sistemas separados; não antecipar ação.
- **Solução:** explicação de uma frase na primeira ocorrência e verbos específicos. Renomear Save conforme função real, por exemplo “Salvamentos e parceiros guardados”. Preservar linguagem própria do universo.
- **Esforço:** baixo/médio.

## E. Problemas de fluxo

- **Ruptura principal:** primeiro corte → escolha → construção → restrição de 15 minutos. Erro técnico afeta ritmo; não prova que construir seja uma atividade ruim.
- **Recuperação circular:** salvar não resolve, retomar falha, sair cria instância aninhada. Instruções existem, resolução confiável não foi observada.
- **Ações ambíguas:** Encaixar primeiro pega; Ver projeto aplica passo narrativo. Revisar verbos reduz descoberta por tentativa.
- **Diálogos:** não observei blocos excessivos. Presente/nascimento justificam o texto. Não recomendo cortar essas falas só por duração.
- **Aulas:** cada uma alterna explicação, avanço, exercício e confirmação. É seguro e explícito. Fadiga pelo número de avanços é hipótese para validar com humanos, não achado demonstrado.
- **Oficina após Rabbito:** pode parecer uma segunda montagem, mas acrescenta cuidados. Hipótese: explicar “agora uma montagem completa” diferencia os momentos. Não remover antes de testar sem erro.
- **Ajustes:** fechar após cada alternância cria retorno desnecessário.

## F. Melhorias de UX/UI

| Tela | Mudança específica | Problema que resolve |
|---|---|---|
| Quarto | Nome do alvo e marcador no encaixe | Mesa/desenhos e peça faltante pouco explícitos |
| Vareta | Pegar vareta + instrução junto à peça | Expectativa errada do botão |
| Casa | Referência visual da saída | Sul sem bússola |
| Primeiro voo | Estado contextual de habilidade pronta, prazo de 2 s e recarga | Distinguir erro de tempo/posição de comando não reconhecido; proposta, não diagnóstico de tecla |
| Oficina | Salvo/pendente, prazo regressivo e saída robusta | Recuperação sem falsa garantia |
| Classes | Texto maior, menos decimais e ajuda de requisito | Planejamento legível |
| Dex | Obtenção coerente com história/conta | Promessa contraditória |
| Opções | Alternar sem fechar; estado de cada ajuste | Conferência com menos cliques |
| Missões | Orientação específica quando oficina indisponível | Evitar repetir caminho bloqueado |
| Perfil/HUD | Origem do XP e números explicados | Tornar crescimento perceptível |

Não há evidência para refazer toda a identidade, câmera ou menus. A escolha de rabiola ajuda a comparar estilos; a loja distingue cosméticos de desempenho. Trocas, compras e customização efetiva de avatar não foram executadas.

## G. Melhorias de game design

1. **Aprendizado:** preservar exercícios que exigem ações reais. Chegar a alvo e acertar cruzamento ensinam mais que uma lista de comandos.
2. **Construção:** manter vínculo manual com o parceiro; tornar alvo e correção do erro explícitos. Só observei armação e uma tentativa de nó, sem base para julgar profundidade dos cuidados seguintes.
3. **Combate:** antes de mudar dano/velocidade, testar iniciante contra rival ativo, derrota e nova tentativa. Este treino não justifica rebalanceamento nem prova diversão competitiva.
4. **Vitória:** primeiro corte tem mensagem e pontos. Dar moeda/XP ao tutorial não é recomendação automática; primeiro comunicar o que já existe e o próximo passo.
5. **Progressão:** aproximar requisito de classe da atividade que o cumpre. Número sem caminho estimula tentativa aleatória.
6. **Motivação:** nome próprio e nascimento criam contexto para vínculo; classes sugerem futuro. Hipótese: uma prévia contextual do que vem depois da oficina sustenta continuidade sem antecipar todos os sistemas.
7. **Exploração:** manter missão/destinos; testar orientação a pé sem seletor. Não testei a barreira ao passar da casa do professor, pois segui o objetivo.

## H. Priorização

### FAZER AGORA

- Reproduzir restrição com conta/IP limpos; diagnosticar limitador/cadência sem desligar proteção indiscriminadamente.
- Corrigir saída/retomada em falha e diferenciar comandos pendentes de save confirmado.
- Repetir caminho obrigatório até nascimento e primeira recompensa de campanha antes de convidar público amplo.

### FAZER EM SEGUIDA

- Ajustar verbo/alvo da primeira montagem e direções dentro da casa.
- Revisar obtenção da Dex no fluxo novo.
- Feedback de nível/XP, ajuda para requisitos e legibilidade da árvore de classes.

### POLIMENTO FUTURO

- Ajustes permanecem abertos; estados de Som/Qualidade explícitos.
- Explicar termos na hora certa e revisar Save e bancos.
- Validar CRT/texto em telas menores; não presumir problema móvel sem teste.

## I. Dez mudanças de maior impacto

| # | Problema | Mudança | Benefício esperado | Prioridade | Esforço |
|---:|---|---|---|---|---|
| 1 | Oficina interrompida por limite | Diagnosticar e adequar cadência/escopo para uso legítimo | Concluir onboarding | P0 | Médio |
| 2 | Recuperação falha/jogo aninhado | Saída externa robusta e retomada confirmada | Recuperar erro sem perder referência | P1 | Médio |
| 3 | Encaixar apenas pega | Pegar vareta + encaixe destacado | Entender gesto seguinte | P2 | Baixo |
| 4 | Sul ambíguo | Referência visual/marcador | Achar saída sem traduzir eixos | P2 | Baixo |
| 5 | Mesa pouco identificada | Nome do alvo e separação dos hotspots | Menos tentativas no objeto errado | P2 | Baixo/médio |
| 6 | Ganho sem causa percebida | Confirmação de origem do XP/nível | Crescimento compreensível | P2 | Médio |
| 7 | Classes pequenas/requisito opaco | Texto maior e ajuda vinculada à atividade | Planejar evolução | P2 | Médio |
| 8 | Obtenção contraditória | Texto sensível ao fluxo/estado da conta | Evitar sensação de recompensa perdida | P2 | Baixo |
| 9 | Ajuste fecha a tela | Atualização no próprio menu | Comparar preferências com menos cliques | P3 | Baixo |
| 10 | Termos pressupõem contexto | Explicações curtas na primeira ocorrência | Aprender sem perder identidade | P2 | Baixo/médio |

Estimativas de esforço podem mudar após diagnóstico técnico.

## J. Veredito final

1. **É fácil de entender?** Caminho até professor e primeiro voo foi compreensível; direções e algumas interações exigiram interpretação adicional.
2. **Primeira experiência divertida?** Há ações com propósito e conquista autoral. Sustenta interesse de design; não substitui relato de diversão de humano iniciante.
3. **Tutorial funciona?** Primeiro voo foi concluído pelas instruções visíveis. Tutorial completo, que exige nascimento na oficina, não foi concluído.
4. **Montagem satisfatória?** Primeira vareta tem consequência narrativa e oficina tem alvos claros. Resultado completo N/T pelo bloqueio.
5. **Batalhas incentivam novas partidas?** N/T: não houve rival de campanha, derrota ou revanche.
6. **Recompensas motivam?** Escolha de rabiola oferece direção; economia/itens por vitória N/T, e conta preparada não permite validar recompensa inicial limpa.
7. **Interface profissional?** Identidade e componentes coerentes; microtexto, informação contraditória e recuperação defeituosa reduzem confiança.
8. **Maior prejuízo?** Bloqueio obrigatório e saída/retomada que não entregam a recuperação prometida.
9. **Maior potencial?** Transformar uma pipa construída e nomeada pelo jogador em parceiro de exploração e duelos, com identidade cultural própria.
10. **Pronto para jogadores novos?** Não recomendaria convite amplo com esta execução local bloqueando a oficina. Confirmar causa/alcance, corrigir caminho e repetir em sessão limpa e ambiente publicado.

**Voltaria amanhã?** Como avaliação de design, há curiosidade por parceiro e classes. O motivo observado para encerrar foi a oficina indisponível. Priorizaria novo teste após entender/corrigir esse bloqueio; não é retenção medida.

### Segunda sessão e análises pendentes

A recarga preservou a etapa da campanha e o parceiro, sem repetir a abertura, e removeu a instância aninhada. Isso testa retorno imediato; **não é segunda sessão após concluir o onboarding nem teste no dia seguinte**.

Pendentes: tela inicial/login/visitante em conta limpa; oficina após expirar limite; nós/papel/equilíbrio/rabiola/nascimento; batalha de campanha, derrota, revanche, vitória e recompensas; desbloqueios, exploração e evolução adquirida; compras/trocas/multiplayer; móvel, gamepad físico, som e desempenho. Modos de partida rápida, céu do dia, amigos, treino livre e exploração/campanha estavam visíveis, mas não foram usados para contornar a etapa obrigatória.

### Evidências e cobertura de menus

- 15 capturas em [playtest](playtest/): 01–08 percurso; 09–10 erro; 11–14 menus; 15 reentrada.
- **Menus usados:** principal, Opções, Parceiros/Visão geral/Classes, Mochila, Missões, Dex/Visão geral, Clube, Meu perfil, Banca de linhas; submenu Jogar consultado.
- **Apenas identificados, sem avaliação funcional:** save/bancos, fazenda, trocas, duelos anteriores, eventos, escola adicional, mapa/campanha posterior, demais abas. Não presumir ausente o que não foi aberto.
- Contagens confiáveis: uma tentativa de arraste para a vareta de Rabbito, quatro arrastes para armação da oficina, uma tentativa de nó, uma tentativa de Salvar novamente e uma tentativa de reentrada que falhou. Houve outras ações de navegação/teclado; não há contagem total exata consolidada.

**Conclusão:** preservar narrativa, prática guiada e autoria artesanal. Primeiro tornar a oficina obrigatória concluível e recuperável; depois testar desafio, recompensa e continuidade sem atalhos. **Nenhuma melhoria foi implementada nesta missão. Aguardo autorização para alterar o jogo.**
