# Soulmonsters: Elo das Ruínas — leitura dos blueprints

> Registro anterior à implementação. A primeira Oficina das Almas foi desenvolvida posteriormente nesta mesma data; veja `art/workshop-v1/README.md` e `documentation/publicacao-oficina/README.md`. A comparação da seção 4 descreve a base que motivou essa mudança.

Análise de produto, direção visual, animação e viabilidade, em 22/10/2026. Base: os dois desenhos enviados pelo responsável pelo jogo e os consumidores atuais do repositório. Este documento distingue o que o blueprint mostra, o que o código comprova e o que se recomenda desenvolver. Não constitui implementação nem teste completo da campanha.

## 1. A direção que os desenhos estabelecem

O diferencial é **dar corpo a uma alma por meio da construção de uma pipa e explorar o mundo com esse parceiro**. O ciclo completo é:

**Explorar → encontrar → resolver o encontro → obter rabiola e materiais → construir o corpo → ajustar o voo → despertar → criar vínculo → explorar novas possibilidades.**

Isso liga coleção, fabricação, combate e exploração. A oficina deixa de ser uma loja que troca um item por um monstro: ela explica por que essas criaturas têm velas, armações, nós e rabiolas. O jogador participa do nascimento do parceiro. Essa é uma assinatura forte para a franquia.

Os dois desenhos se complementam: o primeiro explica a transformação de recursos em companhia; o segundo explica de onde vêm esses recursos e por que sair novamente. A leitura dos nove ambientes também sugere progressão por capacidades do parceiro, além de progressão numérica. Planar sobre uma corrente é diferente de apenas vencer um inimigo de nível maior.

### O que preservar e o que não interpretar literalmente

- A anatomia de pipa é obrigatória em todo Soulmonster; a linha é o método de manifestação. A oficina deve revelar essa anatomia, sem criar uma forma animal comum separada dela.
- O azul e a grade são linguagem de documentação. Não indicam jogo monocromático, câmera isométrica obrigatória ou substituição da arte colorida aprovada.
- A composição das cenas sugere profundidade, lugares reconhecíveis, companheiro próximo e interação contextual. Não exige redesenhar a câmera atual para reproduzir a perspectiva da ilustração.
- Nomes como Rabbito Celeste, níveis, raridades e os seis atributos da prancha são propostas visíveis, não novos contratos automaticamente aprovados.
- O nome vigente é **Soulmonsters: Elo das Ruínas**. PipaKlub é o clube do universo; os títulos antigos nos blueprints registram sua origem.

## 2. Criação e primeiro voo: leitura dos 16 painéis

| Painel | Intenção e leitura minuciosa | Consequência para o projeto |
|---|---|---|
| 01 · Exploração | Protagonista, parceiro, ponto de coleta, NPC e mapa aparecem juntos. A coleta pertence ao espaço explorável. | O material deve ter origem visível e interação contextual. Evitar que explorar seja apenas atravessar um cenário até abrir menus. |
| 02 · Encontro e batalha | A criatura está manifestada; o carretel e a linha pertencem à ação. Atacar, Habilidade, Item e Poupar expressam escolhas distintas. | Não inferir combate por turnos apenas pelo menu. Integrar escolhas ao combate existente e definir o efeito real de Poupar antes de desenhar sua interface. |
| 03 · Captura da rabiola | O prêmio é a alma vinculada à rabiola, com movimento de captura e confirmação de sucesso. | Distinguir ganhar uma rabiola de já possuir uma criatura manifestada. A animação só confirma uma concessão reconhecida pelo servidor. |
| 04 · Itens obtidos | Rabiola especial ocupa destaque; materiais aparecem em grupos menores. Inventário separa rabiolas, varetas, papéis, linhas, nós e materiais. | Hierarquia de recompensa: alma primeiro, componentes depois. Exibir quantidade e origem; evitar seis categorias vazias na primeira visita. |
| 05 · Oficina das Almas | Um artesão recebe o jogador. Criar, melhorar, reparar, evoluir, desmontar e tutorial pertencem ao mesmo lugar. | A oficina é um espaço narrativo e funcional recorrente. Mostrar primeiro ações disponíveis; evolução e manutenção não precisam estrear juntas. |
| 06 · Espécie e molde | Lista lateral, grande prévia e requisitos quantificados permitem comparar uma decisão. Pequenas vistas indicam construção consistente. | Separar espécie conhecida, molde conhecido, rabiola disponível e exemplar existente. A prévia deve mostrar o mesmo indivíduo visual das etapas seguintes. |
| 07 · Varetas | O corpo começa pelo esqueleto: pontos de conexão e progresso tornam a montagem compreensível. | Usar a armação anatômica da espécie. Um único losango genérico para todas apagaria o diferencial. Mostrar encaixes e suporte antes de pontuar velocidade. |
| 08 · Nós | Um gesto com tempo certo produz nó perfeito, firme ou frouxo. Há causa e resultado visíveis. | Explicar o momento da confirmação com sinais visuais e sonoros. Oferecer alternativa sem precisão temporal e repetição da etapa. |
| 09 · Papel | Recorte segue o molde e recebe avaliação de precisão, excesso e completude. | A silhueta construída precisa corresponder à criatura final. Não exigir desenho livre perfeito no mouse ou toque para acessar um parceiro essencial. |
| 10 · Equilíbrio | Ajuste de amarração afeta estabilidade, com prévia de voo e indicador de 87%. | Mostrar a consequência antes da confirmação: inclinação, resposta ou oscilação. O número sozinho não ensina equilíbrio. |
| 11 · União da rabiola | Vento, tensão e pulsação convergem em Sincronizar. É o encontro entre corpo material e alma. | Reservar o clímax para essa união. Definir quais sinais o jogador controla, quais observa e quando o resultado está confirmado. |
| 12 · Despertar | O modelo final ganha vida e presença. É a recompensa emocional pelo trabalho anterior. | Usar a arte colorida aprovada, expressão e gesto próprios da espécie. Reduzir partículas para deixar o primeiro olhar do parceiro legível. |
| 13 · Resultado | Nome, nível, atributos e qualidade A/92 associam fabricação ao desempenho. | Explicar a contribuição de cada escolha. O bônus ilustrado de +5% precisa de decisão de balanceamento; não o implementar como regra pronta. |
| 14 · Pipádex | Grade, filtros e ficha combinam descoberta, coleção e informação. | Registrar também habitat, materiais, anatomia e possibilidades de exploração. Uma espécie descoberta não equivale a uma alma ou exemplar possuído. |
| 15 · Evolução futura | Rabbito → Rabbito Celeste comunica continuidade do parceiro. O próprio desenho marca futuro. | Conservar identidade e vínculo. Não assumir nível 30 ou espécie final como regra aprovada nem entregar evolução na primeira etapa por obrigação. |
| 16 · Serviços auxiliares | Loja, missões de criação, manutenção e bancada portátil sustentam o retorno ao sistema. | Introduzir conforme necessidade. A bancada portátil deve complementar o artesão e sua história; reparo não deve virar pedágio para continuar jogando. |

### A construção precisa mudar o que vemos

Vareta aparece onde a estrutura suporta uma vela. Papel ocupa a área prevista pelo molde. O nó prende partes reais. A linha encontra um ponto de vínculo definido. A rabiola se liga ao corpo antes de ganhar movimento. Assim, a animação ensina o universo sem uma longa explicação textual.

Os componentes também precisam ter funções compreensíveis. Uma proposta é trabalhar resistência, estabilidade e resposta ao vento como escolhas de fabricação, mas **essas propriedades ainda precisam ser conciliadas com os atributos e classes existentes**. Não criar uma segunda árvore de estatísticas independente sem essa decisão.

### Repetição, acessibilidade e vínculo

A primeira montagem pode ser uma sequência especial. Repetir cinco minijogos completos para cada exemplar tende a transformar descoberta em obrigação. Recomenda-se uma primeira criação guiada, prática gratuita e opção de montagem abreviada após aprender o molde. A versão abreviada não deve apagar escolhas de materiais.

Separar qualidade de punição: permitir refazer uma etapa e informar consequências antes de consumir recursos raros. Para o online, avaliar normalização ou limites do benefício de precisão manual. Jogadores com dificuldade motora não deveriam começar em desvantagem permanente por não acertarem um indicador de tempo.

## 3. Exploração: leitura dos nove ambientes

| Ambiente | Papel e recursos no desenho | Experiência própria e animação sugerida |
|---|---|---|
| Vila inicial | Hub com artesão, loja, NPCs, missões e quadro. | Fazer o bairro ensinar o ciclo completo. Bandeirolas, pipa de vitrine, roupas no varal e reação de NPC criam vida cotidiana; portas, placas e pontos interativos precisam manter leitura. |
| Floresta dos Ventos | Início explorável, comuns/incomuns, folhas especiais, galhos leves e fibras do vento. Desafio de corrente de vento. | Folhas e capim antecipam a rajada; uma corrente tem começo, percurso e destino claros. O parceiro participa da travessia. Coleta deve reforçar observação, sem encher cada tile de brilho. |
| Montanhas Celestes | Ilhas flutuantes, criaturas do ar raras/épicas, papel celeste, cristais de corrente e linhas leves. Rota de planagem. | Animação de velas e rabiola mostra sustentação, preparação e pouso. Parallax discreto e nuvens revelam altura. Prever queda, retorno e legibilidade das plataformas antes de investir no espetáculo. |
| Região Costeira | Praia, recifes e arquipélagos; aquáticos comuns/raros; conchas, algas resistentes e papel à prova d’água. Pesca de rabiolas. | Ondas, boia e tensão comunicam a pesca. Distinguir uma rabiola recuperada de uma criatura retirada da água. A margem animada deve combinar com colisão e área acessível. |
| Mundo Subaquático | Ruínas submersas, marinhos raros/lendários; pérolas, algas luminosas e fragmentos antigos. Quebra-cabeças e segredos. | Correntes, algas e organismos luminosos orientam rotas. Definir como papel e manifestação funcionam submersos; o papel resistente mostrado na costa pode preparar essa transição. É outra necessidade de navegação, não apenas um filtro azul. |
| Cavernas Subterrâneas | Minas, cristais e sombras; terra/sombra incomuns/épicos; cristais de pedra e minérios antigos. Escavação. | Cristal responde à proximidade, poeira denuncia atividade e luz revela marcas. Evitar tornar a navegação escura a ponto de esconder saídas. Escavação precisa de leitura de acerto, recompensa e limite de repetição. |
| Deserto Escaldante | Dunas, ruínas e tempestade; criaturas raras/épicas; areias especiais, papel térmico e varetas resilientes. Coleta durante evento. | Rajadas e silhuetas de abrigo comunicam risco e oportunidade. Preservar jogador, caminhos e interação sob partículas. Não introduzir desgaste punitivo contínuo só para justificar o clima. |
| Região Nevada | Gelo, montanhas e lagos; gelo incomuns/raros; cristais de gelo, papel polar e linhas resistentes. Quebra-cabeça em lago congelado. | Rachaduras e sons devem antecipar alteração do piso. Neve nos galhos pode reagir localmente. Explicar regras de deslizamento/quebra e retorno seguro; não reutilizar visualmente a chuva com partículas brancas. |
| Ilhas Antigas / Ruínas | Templos, tecnologia antiga, lendários, fragmentos antigos e papel arcano. Templo das Almas ligado à história principal. | Conexões entre nós, inscrições e mecanismos tornam o Elo visível. Presença de Eremor pode ser sugerida por sombra, som, deslocamento de poeira e escala da arquitetura. Revelação exige arte adicional quando a perspectiva muda. |

### Como evitar o efeito de colagem

Cada região precisa de uma gramática própria de terreno, construção, vegetação e materiais, com escala e luz compartilhadas. Uma pedra rara, um objeto de coleta e um marco de navegação devem ter hierarquias distintas. Os nove painéis repetem a estrutura de HUD para comparação; isso não pede nove barras laterais permanentes cobrindo o jogo.

Definir uma família de chão e suas transições antes de povoar o mapa. Validar quinas convexas e côncavas, continuidade do muro, base de árvore, contato dos objetos e direção funcional de bancos e portas. Animar uma copa não corrige um tronco desconectado. Uma margem em movimento também não deve esconder uma emenda de tiles.

Os nove ambientes são uma visão de expansão. A demo deve provar a experiência no bairro e no parque. Não é necessário construir nove biomas para demonstrar a promessa de um mundo maior.

## 4. Distância entre intenção e implementação

Inspeção do código atual; existência de código não equivale a validação visual de todas as telas nem garante que toda variante esteja habilitada em produção.

| Sistema | Evidência atual | Distância até o blueprint |
|---|---|---|
| Exploração com campanha | `src/world-road-client.js:1–5` instala o Morro de cinco áreas como campanha padrão. `src/world-client.js:7` declara as cenas. | Há base concreta. Os nove biomas desenhados não estão comprovados por essa implementação. |
| Parceiro no overworld | `src/world-client.js:127` desenha companheiro com direção e movimento, com fallback de arte. | Acompanhamento existe. Reações a coleta, capacidades de travessia e gestos sociais exigem comportamento e assets específicos. |
| Encontros selvagens | `src/rpg-client.js:13–21` considera área segura, distância caminhada, transição e solicitação de encontro ao servidor. | O encontro está implementado. Não significa que já exista captura de toda espécie, todo drop do desenho ou coleta de materiais. |
| Rabiolas e invocação | `src/summon-client.js:18–25` organiza NPC, catálogo, rabiola e constelação; `src/summon-pattern.js:1–8` resolve o traçado. | Parcial: corresponde ao chamado da alma, não à montagem física completa de varetas, papel, nós e equilíbrio. |
| Prática e consumo | `src/summon-client.js:9` oferece ensaio sem consumo; `:21` informa consumo e dano por interrupção; `:118` descreve perda por falha. | O ensaio é aproveitável. Consumo e interrupção precisam ser reavaliados para uma oficina longa e para proteção de recursos raros. |
| Reenvio seguro da tentativa | `src/summon-client.js:124–128` conserva um identificador ao reenviar tentativa. | Padrão útil para futura fabricação; não comprova que uma transação de materiais já exista. |
| Dex | `src/dex-client.js:1–18` separa consulta de concessão e exibe origens de rabiolas; `:48–65` reúne habitat, história, posse e animações. | Base boa. Há textos de drops previstos/em breve: não apresentar toda origem ilustrada como funcional. Separar claramente os estados de descoberta, receita, alma e exemplar. |
| Rig colorido em combate | `src/soulgen-rig-client.js:1–6` declara integração experimental habilitada por `?rig`; `:13–27` lê estados de ação; `:29–43` compõe partes. | Existe caminho de integração. Não é conversão geral de todos os monstros nem sistema pronto de animação ambiental. O comentário antigo do guia que diz “apenas prévia” deve ser lido com essa evolução experimental. |
| Editor e amostragem | `tools/soulgen-studio/model.mjs:1–4` define canais de transformação e interpolação; `:25–35` valida recortes, pivôs, faces e parentesco. | Reaproveitável para objetos articulados, mas fontes permitidas, bindings ambientais, estados e importação precisam ser adaptados. Um projeto de árvore não está automaticamente aceito no mundo. |
| Chão e profundidade | `src/world-art.js:97–98` usa cache de chão; `src/world-map.js:124` calcula transparência de elementos que ocluem o ator. | Preservar essa base. Novas copas móveis precisam manter pé, colisão e ordenação corretos. Não colocar movimento dentro de um cache que só é calculado uma vez. |

## 5. Como ampliar o modelo de animação

O rig recortado resolve **movimento articulado de uma vista preparada**. Ele pode servir para criatura, folhagem, bandeira, mecanismo e personagem, desde que cada um tenha peças e pivôs adequados. Não resolve por si só rotação em perspectiva, uma boca vista de outro ângulo ou deformação complexa de água.

### Quatro famílias de movimento

1. **Estrutural:** copa em relação ao tronco, vela em relação à vareta, braço em relação ao ombro, placa em relação ao suporte. Pivô fixo na conexão; movimento dentro de limites que preservem a sobreposição.
2. **Secundário:** rabiola, ponta de tecido, folhas ou cabelo acompanham a ação com atraso e menor amplitude. Atraso por material; não fazer tudo pulsar em sincronia.
3. **Superfície e atmosfera:** reflexo na água, poeira, pétalas, brilho de cristal, sombra de nuvem. Usar quadros preparados, partículas ou composição apropriada; não esticar um PNG de água para simular qualquer onda.
4. **Evento e atuação:** coleta, encontro, fabricação, reação de parceiro, golpe, dano e descoberta. A ação tem preparação, instante de consequência e recuperação. Precisa responder ao estado real do jogo.

### Aplicação prioritária

| Elemento | Preparação necessária | Movimento e significado | Erro a impedir |
|---|---|---|---|
| Árvore | Tronco/base estáveis; copa com raiz coberta e pivô no suporte. | Ramos cedem à rajada; parte superior reage mais. | Tronco subir do chão, buraco no encaixe ou colisão acompanhando a copa. |
| Bandeirolas e varal | Fixações documentadas; segmentos com sobra de arte. | Orientação do vento; oscilações diferentes por comprimento. | A corda soltar dos postes ou triângulos mudarem de escala sem tensão plausível. |
| Capim | Base fixa; poucos grupos de movimento visíveis. | Vento e passagem do ator. | Todo tile pulsar igual e revelar a grade. |
| Fonte e água | Bacia estática; superfície e emissão separadas. | Fluxo contínuo, pequenas ondas e reflexos locais. | Água atravessar borda, reinício abrupto ou reflexo com luz contraditória. |
| Oficina | Varetas, papel, nós, linha e rabiola com poses registradas. | Construção visível e despertar da mesma criatura. | Peças teleportarem, sombra variar entre etapas ou substituir o modelo final. |
| NPC | Pose de rotina e de interação; vista consistente. | Artesão ajusta um nó, vendedor organiza objetos, morador reage. | Multidão balançar como bonecos iguais ou animação esconder pista de missão. |
| Soulmonster | Rig da espécie, faces registradas, ações com duração e impacto. | Curiosidade, esforço, satisfação e vínculo além da batalha. | Face desalinhada, parte cruzar olho, loop saltar ou golpe visual prometer acerto inexistente. |
| Ruínas | Partes móveis, inscrições e pontos de energia separados. | Elo conecta mecanismos; sinais precedem a revelação. | Efeitos constantes tornarem qualquer objeto comum tão importante quanto o boss. |

### Direção do vento como linguagem comum

Recomenda-se um estado ambiental compartilhado por cena: direção, intensidade e rajada, desacoplado de qualquer mudança nas regras do combate online. Folhas, bandeiras, rabiolas e partículas respondem ao mesmo vento com pesos e atrasos diferentes. Assim, o mundo parece obedecer a uma causa comum.

Não aplicar o mesmo seno a tudo. Alternar repouso, pequena perturbação e rajada; variar fase de cada objeto sem contradizer a direção dominante. Objetos pesados quase não reagem. Movimento local por passagem ou interação pode sobrepor-se ao vento, retornando de forma contínua.

### Integração na engine atual

- Manter terreno e arquitetura imóveis no cache existente; compor partes animadas na passagem correta de objetos e atores.
- Usar tempo decorrido e um relógio de cena; suspender ou reinicializar a referência temporal ao pausar ou ocultar a aba. Evitar um timer independente por folha.
- Preservar âncora do chão, nível, colisão e ordem de profundidade. A faixa visual móvel precisa entrar no cálculo de visibilidade sem alterar a posição física do objeto.
- Renderizar somente objetos relevantes à câmera; reutilizar texturas e limitar partículas. Medir o custo antes de animar vegetação em massa.
- Declarar eventos como `collect`, `interact`, `hit` e `awaken` como proposta de contrato; mapear aos eventos atuais antes de implementar. Não criar um segundo sistema que decida recompensas pelo término da animação.
- Movimento reduzido deve diminuir oscilação, flashes e deslocamentos. Direção, confirmação de interação e resultado continuam disponíveis por desenho, texto ou som.
- O pipeline precisa de uma família de rigs ambientais e bindings para o mapa. O editor atual demonstra transformações e parentesco, mas isso não equivale a uma ferramenta ambiental concluída.

## 6. HUD e composição

Os desenhos dão prioridade ao mundo e ao parceiro. A miniatura do mapa ajuda a localizar; ícones de interação guiam ações próximas; fichas detalhadas aparecem quando há uma decisão. Esse princípio deve orientar a tradução para a HUD existente, mantendo os contratos de `HUD-KIT.md`.

No overworld, manter objetivos e interação legíveis sem mostrar todos os detalhes de materiais, encontros e inventário permanentemente. Na oficina, usar lista de moldes, palco de montagem e requisitos como três áreas claras. Durante uma etapa, destacar uma instrução e seu resultado; esconder controles sem função naquele momento.

A animação da interface deve explicar estado: material encaixou, nó confirmou, equilíbrio mudou, resultado chegou. Evitar card, marcador e botão oscilando continuamente. Na captura e no despertar, reservar um intervalo de atenção para a criatura; permitir pular apresentações repetidas sem pular a confirmação do resultado.

## 7. Decisões de design que os blueprints ainda não fecham

1. **Obtenção da alma:** capturar após lutar, poupar, receber de evento ou recuperar no ambiente são caminhos distintos. A prancha não define chance, consentimento narrativo, repetição ou concessão por vitória. Não pressupor que toda derrota de um selvagem produz uma alma.
2. **Identidade da rabiola:** o que é individual e o que é de espécie? Qual o destino da alma ao desmontar? Resolver antes de permitir duplicações e receitas repetidas.
3. **Qualidade e atributos:** o +5% ilustrado vale para quais atributos e modos? Como se relaciona com classes e progressão atuais? Definir sem penalizar acesso ou precisão motora.
4. **Consumo e retomada:** quando materiais são reservados e consumidos? Queda de conexão não deveria destruir o parceiro. A política atual de ritual interrompido não deve ser estendida automaticamente à oficina.
5. **Exploração com capacidades:** habilidades de planagem, pesca e travessia são específicas, compartilhadas por grupos ou equipamentos? Evitar exigir uma espécie rara sem rota alternativa para continuar a história.
6. **Manutenção:** reparo precisa enriquecer cuidado e personalização; desgaste obrigatório pode destruir o prazer de explorar. Demonstrar benefício antes de criar obrigação.
7. **Física e fantasia:** manifestação subaquática, papel térmico e voo em correntes precisam de regras do universo consistentes e ensinadas pelo jogo.

Esses pontos são decisões para a evolução do produto, não erros confirmados nem bloqueios à análise. As recomendações deste relatório não alteram suas regras em produção.

## 8. Próximo recorte recomendado para a demo

### Prioridade 1 — provar o ciclo no bairro e no parque

Uma missão curta liga artesão, área de exploração, encontro e retorno. Apresentar uma origem de rabiola claramente definida e poucos materiais contextualizados. Um molde usa a anatomia aprovada de um parceiro. Uma primeira montagem guiada mostra estrutura, cobertura, ajuste e despertar; a simplificação da demo deve ser explícita, sem vender etapas ausentes como concluídas.

Concluir com o companheiro acompanhando o protagonista e uma interação útil no parque. Essa utilização fecha o ciclo: o parceiro recém-criado muda a experiência de exploração. Só uma sequência de crafting seguida de uma tela de atributos deixa a promessa incompleta.

### Prioridade 2 — um pequeno kit de cenário vivo

Aplicar primeiro a uma área representativa: uma árvore articulada, bandeirolas, um grupo de capim e um elemento de água ou fonte. Usar o mesmo vento e validar junto de NPCs e parceiro. Comparar lado a lado com a versão imóvel na escala real da câmera.

### Prioridade 3 — atuação e consistência de apresentação

Consolidar o rig do parceiro escolhido em batalha, acompanhamento, resultado e ficha, com consumidores próprios para cada escala e vista. Adicionar reação curta a descoberta, coleta e interação. Corrigir divergências de rosto, escala e atlas antes de aumentar o número de animações.

### Prioridade 4 — expansão com propósito

Depois de demonstrar o ciclo completo, escolher um ambiente novo por sua contribuição mecânica e narrativa. Cavernas e ruínas podem aproximar a campanha do tema de Eremor; floresta e correntes ensinam travessia. A escolha depende da progressão pretendida, não da quantidade de cenários ilustrados.

## 9. Regras de auditoria para a próxima produção

### Arte e encaixe

- Comparar o rig montado com o modelo aprovado, incluindo paleta, silhueta e material.
- Inspecionar todos os extremos: nenhuma abertura em raiz de peça, parte solta ou rosto duplicado.
- Árvores mantêm contato com o solo; copas não movem troncos. Objetos têm apoio, sombra coerente e direção funcional.
- Terrenos e muros passam por montagem repetida em linhas, cantos e áreas, antes de receber decoração. Testar a escala real, não apenas a folha isolada.

### Movimento e leitura

- Ciclos fecham sem salto; mudanças de estado retornam de forma coerente. Checar também a variação de velocidade na emenda.
- Dano, golpe e vitória usam expressões alinhadas à ação, com retorno ao neutro; usar a disciplina já registrada no guia de rigs.
- Vento é consistente entre objetos; amplitudes e atrasos refletem material e fixação.
- Jogador, saída, ponto interativo e aviso de risco continuam legíveis com todos os efeitos ligados.
- Validar fundo claro/escuro, câmera de jogo, pausa, aba oculta, movimento reduzido e taxas de quadros diferentes.

### Gameplay e persistência

- A animação reage ao evento reconhecido, sem decidir acerto, gasto ou prêmio.
- Materiais e rabiolas não são concedidos duas vezes por repetição de clique, retorno de rede ou retomada da tela.
- Interrupção da oficina tem política explícita e mensagem consistente com o resultado persistido.
- A criação guiada é concluível por teclado e por alternativa acessível aos gestos de precisão.
- Ao terminar, o exemplar é o mesmo na coleção, no acompanhamento e no combate; salvar e recarregar preservam o resultado.

### Desempenho

- Registrar uma linha de base no dispositivo alvo, mesma câmera e quantidade de atores. Comparar tempo de quadro e picos, memória e carregamento antes/depois; não prometer 60 fps sem medida.
- Não reconstruir o chão estático a cada quadro para animar poucas plantas.
- Validar visibilidade, ordenação e pausa com vários objetos, não somente um rig no centro de uma prévia.

## 10. Fontes e rastreabilidade

Imagens originais enviadas pelo responsável, copiadas sem edição para manter este estudo consultável:

- [Criação e voo](criacao-e-voo.png). Origem: `C:/Users/user/Downloads/0802/Blueprint do Pipamon_ Criação e Voo.png`. SHA-256: `8b15e979ba997a51d64c79870792902006cc2a0191945940bae259db85c7428c`.
- [Exploração](exploracao.png). Origem: `C:/Users/user/Downloads/0802/Blueprint de Exploração do Pipa Klub.png`. SHA-256: `28de65f09bc4bcab0aefc35a6d0fdf6b5e7dde0ab7d4ffa9edce8be6d36faea1`.

Contratos e evidências complementares: `DIRECAO-DE-ARTE.md`, `MANUAL-DE-ASSETS.md`, `HUD-KIT.md`, `art/soulgen/DIRETRIZES-RIG-COLORIDO.md` e os arquivos de código citados na seção 4. Os números de linha correspondem à revisão inspecionada nesta data e podem mudar com novas edições.

**Escopo desta entrega:** análise dos dois blueprints, comparação com implementação e proposta de evolução. Não foram criados biomas, alteradas regras de fabricação, aplicadas migrações ou publicados novos assets nesta atividade.
