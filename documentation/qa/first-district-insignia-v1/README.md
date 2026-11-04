# Primeira insígnia · Morro do Sol

Integração local. Mikka é a campeã canônica do primeiro bairro conforme `documentation/historia/BIBLIA-DA-HISTORIA.md`. O desafio `morro-5` já existia como boss; agora entrega a primeira insígnia.

## Regra e transação

Vencer Mikka, depois dos quatro desafios anteriores, completa os cinco selos de progresso do Morro. A mesma operação que salva o resultado da batalha inclui:

- `districtEmblems.bairro-01`: **Insígnia do Morro do Sol**, bairro Morro do Sol, chefe Mikka, descrição e data;
- uma unidade não consumível de `insignia-morro-do-sol` na mochila;
- `lastMorro.insignia`, indicando se essa vitória concedeu a insígnia pela primeira vez.

Derrota, fuga, treino com Assis, duelos anteriores e a missão do Lacertubo/Nina não concedem essa insígnia. Revanches mantêm as recompensas normais existentes, preservando uma única insígnia, a data original e a rabiola única. A curva de XP não foi alterada.

## Apresentação

Depois da tela de resultado, Mikka reconhece a conquista e entrega a insígnia pelo banner de 2,5 segundos. Em seguida, o jogador escolhe **Ver porta-emblemas** ou **Continuar explorando**. A primeira opção abre o estojo no espaço 01 com **1/12**. O mundo permanece parado enquanto o estojo está aberto e volta a funcionar ao fechar. A imagem real aparece também no resumo da carteira e na mochila.

O ícone é pixel art nativa de 128×128, com pipa ciano e sol dourado, editável no Aseprite. A arte e o nome são produção nova para a conquista solicitada, sem alterar o design da Mikka. Revisão independente: 8/10, nenhum bloqueio. Observação opcional mantida: o aro creme pode fazer o símbolo lembrar uma joia/bússola; o motivo de sol e pipa permanece legível.

## Interrupção, erro e saves antigos

A conquista já está salva antes do banner. Se o jogo fechar durante a apresentação, ela retoma ao carregar, sem repetir recompensas. A confirmação visual usa recibo próprio. Se sua gravação falhar, o diálogo permite tentar de novo ou voltar ao menu.

Saves anteriores com os cinco desafios vencidos recebem somente a insígnia ausente, em operação idempotente. Não recebem XP, moedas ou outra rabiola. O banner de retomada não traz Mikka para o mapa atual nem obriga a repetir os documentos do treino.

## Verificação

540 verificações aprovadas: nova suíte da primeira insígnia (74), transações do Morro (51), estojo (60), encerramento (43), campanha (206), carteira (78) e banners (28). A suíte nova também confirma tamanho de 128×128, alfa binário e paleta de até nove cores da arte. O fluxo completo foi repetido no renderer nativo após corrigir a restauração de foco: fechar o diálogo que abriu o estojo não deixa uma referência de foco a um botão já liberado.

`first_district_insignia_checks.gd` percorre transações dos cinco desafios com estados terminais simulados, incluindo derrota/fuga de Mikka, conflito de revisão, recompensa atômica, primeira conquista, diálogo, banner, abertura do estojo, retomada de movimento, reinício, revanche e migração de save antigo. Isso verifica integração e persistência, não dificuldade de um playtest humano.

Capturas do renderer nativo em 1280×720 e 1920×1080 foram inspecionadas: [banner](banner-1280x720.png), [primeira insígnia registrada](primeira-insignia-1280x720.png). Os saves são isolados; a imagem mostra a conquista concedida pelo serviço real de resultado do Morro, com vitórias de teste.
