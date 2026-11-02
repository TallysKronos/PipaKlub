# Retalho escolheu acompanhar você

## 1. Arquivos e comportamento

- `godot/scripts/campaign/retalho_trust.gd` e `godot/assets/campaign/retalho-care-v1/trust.json`: sequência ordenada de confiança, com recibos por etapa e concessão única.
- `front_end.gd`, `retalho_care.gd`, `park_checkpoint.gd`, `kronasta_story.gd`, `kronasta_atlas.gd`, `hud_kronasta_map.gd` e `bosque_campaign.gd`: diálogos, objetivos, presença e viagem conforme a história.
- `state.gd`: cenas novas e contrato restrito do encontro `retalho-rescue`.
- `encounter_view.gd`, `morro_battle_view.gd`, `park_view.gd`, `encounters.gd` e consumidores no front-end: Retalho usa seu próprio atlas como parceiro, sem substituição visual por Rabbito.
- `tools/mapa-studio/desenhar-palafitas-resgate.mjs`, brief, três `.tmj`, três mapas compilados e índice: percurso A/B/C do resgate. Reutiliza explicitamente a planta e o kit aprovados do Cais; não é a construção completa do bairro 7.
- Testes `retalho_trust_checks.gd` e `palafitas_walk_checks.gd`; ajuste do teste de orientação Azul para o novo objetivo pessoal posterior.

Após o cuidado no ateliê, Kael oferece um descanso livre no Varal. A ida e a passagem da noite são uma elipse narrativa. Retalho foge; Kael o encontra doente na margem de A do Pântano, recolhe o material do remédio em B e volta a cuidar dele. Nas Palafitas, protege-o dos valentões num duelo. A derrota e a fuga permitem nova tentativa, sem apagar etapas anteriores; há um descanso gratuito em B.

Vencido o confronto, Kael deixa a saída livre. Retalho começa a partir e retorna por vontade própria. A cena registra a escolha antes da concessão. Se o banco estiver cheio, o vínculo permanece pendente, inclusive após recarga. Uma tela permite escolher um parceiro para liberar, com confirmação separada e possibilidade de cancelar. O equipado não pode ser liberado por essa tela. Nenhum parceiro é substituído automaticamente.

Retalho entra no banco local deste save no nível 22, com origem `retalho-trust-partner-v1`, certificação local não verificada e registro de aquisição pelo serviço existente. Há limite de 30 para essa concessão; esta entrega não implementa um novo limite geral para todos os métodos de ganho nem o banco global de 20 da conta. O parceiro ativo permanece o mesmo até o jogador selecionar Retalho.

## 2. Conferência automática da planta

Saída do gerador, antes da montagem da campanha:

```text
kronasta-palafitas-a
CONFERÊNCIA ZERO QUEBRA: SEM ERRO · 0 erros · 0 avisos
Platô 55.4% · 3 itens (1 escondidos) · 8 células de rampa · 0 inalcançáveis · 0 degraus soltos
kronasta-palafitas-b
CONFERÊNCIA ZERO QUEBRA: SEM ERRO · 0 erros · 0 avisos
Platô 57.9% · 3 itens (1 escondidos) · 8 células de rampa · 0 inalcançáveis · 0 degraus soltos
kronasta-palafitas-c
CONFERÊNCIA ZERO QUEBRA: SEM ERRO · 0 erros · 0 avisos
Platô 60.0% · 3 itens (1 escondidos) · 16 células de rampa · 0 inalcançáveis · 0 degraus soltos
```

Relatórios detalhados: `kronasta-palafitas-{a,b,c}-audit.json`. O Pântano mantém seu terreno original; os dois pontos de missão foram conferidos contra o grafo real e a cota de interação.

## 3. Capturas

`mapas/kronasta-palafitas-{a,b,c}/{geometria,arte}/`: 418 capturas nativas em 1280×720, seguindo os manifestos em `planos/`. Incluem área inteira, enquadramentos de jogo, pés e chegadas de escadas, cantos, pontas de mureta, margens e cabeceiras. Sem personagens encobrindo juntas.

Revisão visual realizada nas três vistas gerais com arte, geral geométrica de A e amostras ampliadas de escada, canto e ponte em ambas as versões. As 418 imagens foram geradas; **não houve inspeção individual de todas elas**. A planta é herdada sem alteração geométrica; isso não equivale a aprovar uma identidade visual inédita para Palafitas.

`fluxo/`: sete capturas da oferta de descanso, dos três estados no Pântano, escolha de Retalho, banco cheio e Retalho na coleção. A paginação da equipe foi ajustada para não cortar o card nem empilhar verticalmente o número da página ao exibir 30 parceiros.

## 4. Percurso e testes

- `palafitas_walk_checks.gd`: **403 verificações, zero falhas**. O controlador real percorreu rotas de clique da entrada aos eventos e aos pés/chegadas das escadas e de volta, nas três partes. Entrada de teclado/controle físico não foi simulada.
- `retalho_trust_checks.gd`: 99 verificações na execução gráfica final e 92 headless, zero falhas. Verifica ordem, localização, falha de escrita na oferta/concessão/vitória, retomada, cancelamento, derrota, fuga, descanso, escolha pendente, confirmação de liberação e proteção do equipado. A execução gráfica exercita a aproximação por tween e seu cancelamento. Resultados de combate são fixtures, não prova de balanceamento.
- `retalho_care_checks.gd`: 35 verificações, zero falhas.
- `blue_preparation_checks.gd`: 29 verificações headless, zero falhas; o objetivo seguinte é o arco pessoal, não aprovação na Liga.
- `kronasta_atlas_checks.gd`: 193 verificações, zero falhas.
- `overworld_checks.gd`: 500790 verificações, zero falhas.
- `morro_map_checks.gd`: 9386 verificações, zero falhas.
- `node --test tools/mapa-studio/model.test.mjs`: seis testes, todos passaram.

Testes usam saves isolados. O relatório de geometria reescrito pelos testes foi revertido; nenhum `kit.json` alheio foi alterado.

## 5. Itens, pistas e revelações

Três materiais por parte das Palafitas, com um escondido, herdados do contrato costeiro. O material para o remédio é estado exclusivo da missão: não é consumível de batalha nem item vendável. O resgate não corta rabiola, não captura Retalho e não permite farmar XP do duelo. A aquisição aplica somente o crédito único de espécie do serviço existente.

Não revela a identidade ligada a Heleana, não remove Retalho no futuro, não concede emblema do bairro 7, estágio, vaga global ou categoria Azul. O Pântano abre para a busca após a fuga; Palafitas abre após o tratamento. Não implementa confronto com Mormaço nem o campeonato de Caio Garça.

## 6. Integração

O pedido inclui explicitamente a mecânica de conquista; por isso a integração de campanha/save/batalha foi feita junto da montagem dos eventos. Nada foi alterado em Supabase, servidor, conta online, main, deploy ou merge. Os contratos de operação atômica e backup continuam os existentes.

## 7. Dúvidas

Nenhuma decisão necessária à conquista ficou pendente. Identidade arquitetônica própria e campeonato completo de Palafitas são trabalhos futuros, não concessões implícitas desta entrega.

## 8. O que não foi verificado

Não houve uma partida completa desde o prólogo, teste com controle físico, exportação distribuível ou balanceamento manual do duelo de nível 24. A região industrial mantém a política anterior de prévia; este teste inicia com seus pré-requisitos históricos concluídos. A liberação do Pântano para a missão foi verificada com QA desligado.

O descanso no Varal é narrado, sem um novo mapa livre do Varal. Retalho ainda usa os assets aprovados disponíveis e uma aproximação por tween na cena; não foi criado rig Soulgen nem animação inédita de doença/repouso. Os valentões não receberam concepts ou nomes novos nesta etapa; o confronto é apresentado pelo diálogo e pelo Soulmonster existente.

Permanecem avisos preexistentes de carregamento das imagens do ateliê para exportação e recursos remanescentes no encerramento de algumas suítes. `overworld_checks.gd` também imprimiu uma condição do compilador de shader no renderer de piso existente, apesar de suas verificações passarem. Não interpretar os resultados como validação de exportação sem erros.
