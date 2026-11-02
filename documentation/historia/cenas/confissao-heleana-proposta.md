# Heleana e Retalho · cena integrada

Definição do dono: o encontro depende de Retalho e da decisão de Kael, nunca de um emblema.

## Kael aceitou o laço

O jogador precisa levar Retalho como parceiro ativo até Heleana, dentro de casa. Retalho no banco não inicia a conversa. Heleana reconhece o nó, chora e conta sobre a expedição e a rabiola. O novo laço transcreveu o anterior: Retalho não voltará a lembrar de Heleana. O nome escolhido pelo jogador permanece intacto; a cena não altera parceiros, XP ou itens.

## Kael recusou explicitamente

Ao voltar para casa, um grunhido de Retalho vem de fora. Kael e Heleana decidem sair. A transição leva à entrada real da casa na Vila, com Heleana e Retalho presentes. Retalho seguiu **Tyler** sorrateiramente mesmo depois da recusa: algo dentro dela a trouxe até ali. Heleana se emociona, toca a rabiola, as lembranças retornam e as duas tornam-se parceiras novamente. Retalho não entra no banco de Kael e não pode ser reivindicada depois.

Adiar a decisão não equivale a recusar. Aceitar com banco cheio registra aceitação pendente, sem remover outro parceiro; também não equivale a recusar.

## Persistência e encenação

Cada fala confirmada possui recibo. A decisão de vínculo fica fixada na primeira fala. A saída da casa é salva junto da segunda fala, para que recarregar não faça o jogador reaparecer dentro dela. Diálogo bloqueia movimento; cancelar permite retomar. Não há pré-requisito de emblema. A referência à foto só aparece se ela foi lida.

A mãe usa o mesmo sprite direcional dos interiores. O grunhido é áudio sintetizado provisório no barramento SFX. O toque, as lágrimas e a reconexão ainda são descritos no diálogo; não há animações específicas nem dublagem final. A saída usa transição de tela, sem caminhada encenada pela porta.

## Validação

- `heleana_confession_checks.gd`: duas rotas, ausência de emblema, banco versus parceiro ativo, proximidade, ordem das falas, retomada e conclusão idempotente, sem renomear/duplicar/conceder parceiros.
- `heleana_native_flow.gd`: retorno à casa inicia a rota recusada, cancelamento libera controles, diálogo atravessa a transição exterior e conclui sem captura.
- `retalho_trust_checks.gd`: resgate, banco cheio, falha de escrita e adoção permanecem protegidos.

Não foi validado em build exportada nem com controle físico. O carregador preexistente da casa ainda emite avisos de imagens não importadas para exportação.
