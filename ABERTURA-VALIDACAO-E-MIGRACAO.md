# Abertura — revisão após auditoria como comprador

## Comportamento

- O nascimento usa encenação de RPG clássico: luz no projeto sobre a mesa,
  breve transição clara e Rabbito no chão, seguido de aproximação. Nenhum
  desses momentos concede itens. O texto não descreve carinho invisível.
- Nomear continua sendo a única entrega do parceiro, feita pelo PostgreSQL.
  A câmera aproxima a família; o formulário fica em um painel compacto.
- A mãe tem folha chibi de oito frames (quatro direções, parado e passo),
  alinhada à escala de Kael, com pés medidos. Ela entra pela porta e caminha
  pelo chão livre. A Rabiola Antiga aparece centralizada com o cenário
  escurecido; confirmar fecha a apresentação antes de retornar à mesa.
- Após nomear, Kael caminha até a saída do quarto com Rabbito seguindo um
  caminho navegável. A porta representa a conexão à escada do andar de baixo.
- No andar de baixo, após a fala da mãe, WASD, clique e interação E permitem
  caminhar até ela ou sair ao sul. Rabbito acompanha Kael. A saída avança o
  checkpoint; a conversa opcional não avança nem entrega recompensas.
- Assis reconhece a origem do parceiro. O apelido acompanha o primeiro voo.
- Análise opcional permanece desligada até uma escolha em Configurações /
  Privacidade. A escolha não aparece automaticamente durante a história.

## Migração 018

Aplicar `supabase/migrations/018_story_first_collection.sql` após a 017,
antes de publicar esta versão do servidor. Não foi aplicada em produção.

Novos cadastros passam a iniciar sem as quatro pipas do kit anterior. Rabbito
é entregue e equipado uma única vez pela abertura. A migração não apaga,
converte ou recolhe itens: contas existentes, inclusive no meio da abertura,
preservam seu inventário. Uma reprise também não altera a coleção.

O retorno após uma captura usa um parceiro permanente realmente pertencente
à conta (prioriza a básica se houver). Sua espécie, cor e nível devem ser
preservados na simulação. Permissões, travas de negociação/invocação e os
adaptadores de linhas e níveis continuam ativos.

O ambiente local aplica a 018 ao iniciar. Para avaliar o cadastro novo, usar
um slot novo; reiniciar um banco existente não remove seus itens antigos.

## Verificação manual

1. Entrar com conta nova: TV, exploração, montagem e presente da mãe.
2. Observar a luz, primeiro contato e escolha de nome; recarregar no nascimento
   deve retomar a cena sem item duplicado.
3. Descer, caminhar pela sala, conversar com a mãe e alcançar a saída.
4. Conferir a recepção de Assis sem painel de consentimento sobre o diálogo.
5. Abrir a coleção: somente o parceiro da história, com o nome escolhido.
6. Jogar o primeiro voo e conferir o apelido no HUD.
7. Contas antigas mantêm coleção e treino antigo; reprise sem entregas.

Os movimentos reduzidos mantêm os momentos interativos e a luz estática.
Esta revisão usa nova arte de overworld para a mãe. Gestos detalhados de mão
e carinho não fazem parte desta encenação: entrega e vínculo são comunicados
por diálogo, pausa, direção, aproximação e apresentação do item.

## Resultado da revisão de encenação

Suíte completa: 263 testes aprovados. Após os últimos ajustes de aproximação
à bancada, hitbox de conversa e retomada: 25 testes de abertura, primeiro voo
e navegação aprovados. Builds Worker e Pages e validação ESM aprovados.
Teste visual local: mãe entrou pela porta, apresentação da rabiola centralizada,
brilho sobre a mesa, parceiro no chão, nome e caminhada até o andar de baixo.
Capturas em `outputs/abertura-rpg-classico` no diretório de trabalho da tarefa.
Nenhum merge, push ou deploy foi realizado nesta revisão.
