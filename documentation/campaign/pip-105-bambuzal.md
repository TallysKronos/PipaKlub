# PIP-105 — Vila do Bambuzal

Branch: `feature/pip-105-vila-bambuzal`, sobre a fundação PIP-92. Sem push, merge ou deploy.

## Entrega e história

Três mapas conectados: A, praça de chegada e Nara/Dito; B, Célia/Bento, descanso e bambuzal cortado; C, arena elevada do Lohan. Cada parte possui três itens, um escondido. A pista registra `bambuzalCorteDescoberto`. Os quatro secundários foram aprovados pelo dono; não têm parentesco com Kael. Lohan conserva o concept existente na adaptação do novo atlas.

Os cinco duelos usam o combate em rodadas existente, adversários nos níveis 9, 9, 10, 11 e 12. Recompensas de XP seguem espécie/nível; moedas e emblema constam do catálogo. Vitória, qualificação, recompensa, emblema, posse do título e recibo são liquidados juntos. Defesa e reconquista também funcionam no bairro. Os dados antigos do Morro continuam aceitos.

Mikka abre o Bambuzal na tela de Kronasta; B e C são alcançados andando. Conquistar Lohan mantém o bairro explorável, libera a condição do próximo bairro e o acesso à Clareira/Veredas. Beira-Canal continua em breve porque ainda não foi construída como campanha.

## Nina: decisão adicional do dono

O dono pediu reordenar a missão, em vez de preservar o acesso antecipado para novas jornadas. Agora a ordem é prólogo → Mikka → pedido de Nina no Jardim → Bosque → Lohan → recuperação no Lacertubo → devolução a Nina. A fala inicial menciona cerol e pegadas palmadas. Viagem rápida e saída física não permitem saltar Lohan.

Novos pedidos marcam `ninaBambuzalOrder`. Saves anteriores com `ninaAccepted` sem essa marca preservam o acesso já conquistado, sem apagar missões ou recompensas. O Jardim continua explorável antes de Mikka, mas Nina orienta o jogador a disputar o primeiro bairro antes de aceitar a missão.

Isso reordena os segmentos já existentes; NÃO implementa ainda a cena de Tyler/Rai, a devolução por Tyler, o Retalho, o exame de categoria nem o empréstimo do Carcará/Planar. Essas cenas exigem suas demandas próprias. O Lacertubo e a devolução atual continuam sendo a resolução jogável provisória depois de Lohan.

## Verificação

- Bambuzal campanha: 143 verificações, zero falhas. Inclui retomada, perda/fuga, recompensa exibida versus gravada, níveis entre rodadas, defesa/reconquista, nove itens, pista e descanso.
- Nina/ordem: 16, zero falhas; inclui bloqueio da viagem e da saída, além de compatibilidade do pedido antigo.
- Fluxo nativo: 44, zero falhas. Controlador real caminha entre A/B/C e os cinco NPCs, abre diálogo, confirmação e batalha, retorna e grava o resultado. Resultados de combate são preparados pelo teste; isso não equivale a vencer cinco partidas manualmente.
- Navegação: 2544, zero falhas. Caminhante e seguidor em ida/volta dos eventos e de todas as células de rampa.
- Fundação dos bairros: 450/0; Morro transações: 42/0; campanha: 207/0; regiões: 90/0; interface campanha: 25/0.
- Mapas: overworld 343138/0, Morro maps/views 9386/0; Mapa Studio Node 6/0. Permanecem avisos preexistentes de custom_samplers no headless e recursos/objetos em uso ao encerrar a suíte do Morro.

Capturas de jogo em `documentation/qa/pip-105/`. Capturas geométricas, gerais e juntas em `documentation/overworld/bambuzal/captures/{a,b,c}/{geometria,arte}/`. Planos enumerados em JSON nessa pasta. Nenhum personagem cobre as juntas nas capturas de terreno.

## Limites

Selvagem implementado: Mata verde, níveis 7–9, em mato opcional. Bicho-pau de vareta e Joaninha-pião da bíblia ainda não têm espécie/arte de combate aprovada e não foram simulados com outra criatura. Os NPCs têm poses estáticas frente/costas; animação de caminhada não foi produzida, pois permanecem nos seus postos.

Sem certificação online, exportação Steam, controle físico ou partida completa manual. Garantia de recompensas é do save local. Nenhum interior de casa foi criado. As casas são cenário bloqueado, sem porta interativa prometida.
