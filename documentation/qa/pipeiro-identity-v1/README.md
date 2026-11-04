# Carteira de Pipeiro e porta-emblemas

**Entrega revisada:** a apresentação inicial descrita abaixo foi substituída pelos banners sobre a cena e orientação dos menus. Veja `../key-item-banner-v1/README.md`. A carteira completa permanece acessível pela pausa; não abre mais automaticamente após o treino. As capturas desta pasta registram a versão inicial da carteira.

Implementação local no Godot em 31/10/2026. Sem publicação no Git nesta etapa.

## Fluxo

Ao concluir a quinta lição, a mesma operação que salva o treino emite a Carteira de Pipeiro e o Porta-emblemas. Na volta ao ateliê, Kael caminha até Assis, escuta a explicação e recebe os dois objetos com movimento visível. A carteira abre antes da escolha da rabiola; **Guardar e ir à oficina** continua para a seleção/montagem existente.

Fechar o jogo antes de guardar a carteira não perde os documentos. A apresentação retoma ao carregar. O recibo de leitura impede repetição. Saves anteriores recebem os documentos uma vez, conservando cena, checkpoint, XP, moedas e batalha suspensa; não se força uma cerimônia retroativa.

A carteira pode ser aberta em **Pausa → Carteira de Pipeiro**. Voltar/Escape retorna à pausa com foco na mesma opção. Antes do treino, a opção aparece indisponível. Os dois itens têm arte própria e descrições na mochila, na categoria Missão, e não são consumíveis.

## Conteúdo e apresentação

- Nome real do jogador, retrato mangá aprovado de Kael, registro estável emitido nesta jornada e data de emissão.
- Moedas, tempo de jogo salvo, XP e nível do tamer. A fórmula é compartilhada com a HUD de combate; a curva não foi alterada.
- Parceiro equipado e seu nível apresentados separadamente.
- Porta-emblemas com 12 encaixes selecionáveis, contador e detalhes de cada espaço. Encaixes vazios aparecem rebaixados e apagados; conquistas ficam douradas e registram data.

O desenho usa papel claro para o registro, estojo azul escuro, contornos de tinta, pipa como motivo e o kit Recorte existente. O retrato é reutilizado, sem redesenhar Kael. Os novos SVGs são originais: `carteira-pipeiro.svg` e `porta-emblemas.svg`.

## Emblemas de bairro

Treinos, adversários selvagens e Lacertubo não são promovidos a chefes de bairro. Os 12 chefes e suas artes ainda precisam ser definidos no conteúdo; por isso os documentos recebidos começam com **0/12**.

`pipeiro_identity.gd::award_district(player, slot, boss_id, emblem_name)` prepara a conquista para ser incluída **na mesma operação atômica da vitória de um futuro chefe de bairro**, nunca em um botão da carteira. Índices válidos: 0 a 11. Cada espaço só aceita uma conquista e o mesmo chefe não pode ocupar dois espaços. O serviço atual de batalhas não chama essa função para os oponentes da demo. O campo opcional `player.districtEmblems` é validado e persistido no save. As amostras de emblema dos testes usam apenas jornadas isoladas.

## Validação

- `pipeiro_identity_checks.gd`: 76 verificações. Treino/itens atômicos, conflito de gravação, registro estável, cena real de entrega com confirmação automatizada de dois diálogos, retomada, 12 espaços, persistência de conquista de teste, dados inválidos, nomes longos, foco, pausa e Escape.
- `campaign_checks.gd`: 206 verificações aprovadas.
- `demo_completion_checks.gd`: 43 verificações aprovadas; o encerramento da demo continua funcionando com a emissão dos documentos para saves antigos.
- `player_flow_checks.gd`: 7 verificações aprovadas. O runner mantém os avisos anteriores de objetos/recursos em uso ao sair.

Capturas nativas em 1280×720 e 1920×1080, inspecionadas: [720p](carteira-1280x720.png), [1080p](carteira-1920x1080.png). Os valores das imagens são uma jornada de teste, não as recompensas iniciais do jogo. Não houve um novo playtest humano completo nem teste de controle físico.
