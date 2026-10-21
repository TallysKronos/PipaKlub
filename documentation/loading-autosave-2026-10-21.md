# Carregamento e salvamento automático

## Carregamento

A apresentação inicial, recuperação da conta/campanha, introdução, cenários do overworld, mapa da cidade e abertura dos destinos do clube usam uma cobertura de carregamento. O cenário aguarda chão, Kael, NPCs essenciais e parceiro equipado. A cobertura só fecha após dois quadros de renderização. Teclado e controle não movimentam o personagem durante essa espera.

As operações têm identificadores independentes: uma resposta antiga não pode encerrar o carregamento de outra cena. Erros e espera superior a 25 segundos oferecem recuperação; não há porcentagem fictícia. Recursos já em cache podem produzir uma transição praticamente imediata. A carga não simula uma pausa da partida online.

## Slots e configurações

- **Slot 0:** posição automática, independente do manual.
- **Slot 1:** posição manual, pelo menu Save e bancos.
- **Opções → Salvamento automático:** ligado por padrão, preferência persistida por conta.
- A entrada retoma a posição mais recente dos dois slots. Ambos também têm botões explícitos de continuação.
- Após carregar um cenário, o automático tenta registrar uma posição segura após 1,5 segundo. A cada 30 segundos tenta novamente, se a posição mudou e o personagem está parado.
- Não grava durante carregamentos, abertura da história, partidas, diálogos/menus bloqueantes, nem operações concorrentes de banco. O servidor também rejeita batalhas, trocas e invocações ativas.
- O indicador mostra **Salvando…**, depois **Salvo · slot 0** somente após confirmação. Falhas são informadas e uma próxima tentativa pode ocorrer no próximo intervalo seguro; fechar o aplicativo não é uma confirmação de gravação.
- Reiniciar a campanha apaga as posições dos dois slots, preserva a preferência de automático e mantém os Pipamons globais escolhidos. Slots de posição não são cópias independentes do progresso/economia: a campanha é única por conta.

## Banco de dados

Aplicar `019_campaign_saves.sql` e, em seguida, `020_campaign_autosave.sql`, nessa ordem, antes de publicar o código. A migração 020 é transacional, adiciona campos do slot 0 e da preferência e mantém a mesma assinatura da RPC `player_campaign`. As ações novas são `autosave` e `settings`.

A função interna anterior perde todas as permissões públicas. O novo invólucro mantém autenticação, ordem de bloqueio por jogador, validações de checkpoint, revisão otimista e condições de segurança da função original. O automático nunca altera o checkpoint ou a data do manual.

O servidor local aplica as migrações no banco isolado. Nenhuma migração foi aplicada à produção por este trabalho.

## Verificação

`loading.test.mjs` cobre operações sobrepostas, quadros de renderização, respostas antigas, tempo limite e repetição. `first-flight.test.mjs` cobre bloqueio enquanto imagens estão pendentes, falha recuperável, estado visual do automático e preservação de transferências pendentes. `campaign.test.mjs` executa as migrações em PostgreSQL/PGlite e verifica separação entre slots, preferência, permissões e limpeza no reinício.
