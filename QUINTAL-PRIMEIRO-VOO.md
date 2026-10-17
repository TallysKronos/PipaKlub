# Quintal do Clube — primeiro percurso jogável

Implementado em `feature/quintal-primeiro-voo`, sobre o pacote de arte da cidade. Nenhum merge ou deploy automático.

## Experiência

Após autenticar, o jogador entra no Quintal do Clube: cenário 2D completo, Sr. Assis e Nozinho presentes, espécies da coleção passeando e destinos posicionados no próprio ambiente. O login de visitante e os convites de sala continuam usando o fluxo existente. Um convite não é interrompido pela introdução; ao sair da partida, a conta volta ao quintal.

O quintal leva diretamente à coleção, cidade, invocação, banca de linhas e salas com amigos. O menu por Esc reúne os outros destinos em grupos curtos: clube, jogo/treino e opções. Tab/Enter funcionam nos destinos; setas navegam no menu, na seleção do parceiro e no mapa. O mapa usa insígnias, não a lista amarela de seleção da prévia. Interfaces de conta, Dex e briefing passam a ocupar telas completas. A apresentação prioriza PC; integração de controle/gamepad e empacotamento Steam não fazem parte desta etapa.

## Conta nova

1. Chegada e conversa curta com o professor.
2. Comparação dos quatro parceiros iniciais por aparência, personalidade e habilidade; sprites animados quando movimento reduzido não está ativo.
3. Confirmação online da escolha: reutiliza uma cópia do conjunto inicial já concedido pelo cadastro, marca essa cópia como permanente e a equipa. Não cria outro item. Mantém o conjunto inicial existente e a pipa básica de segurança; não remove itens nem muda a regra histórica do cadastro.
4. Cinco momentos de prática com Nozinho no motor real: movimento até o alvo, primeiro acerto válido, recuperação de energia, habilidade e corte. O professor orienta em uma caixa discreta. Nozinho é um parceiro de treino e não é capturado.
5. Retorno ao quintal e convite para a cidade. Não há tour obrigatório por todas as funcionalidades.

O treino não dá moedas, XP, rabiolas ou vitórias de campanha e não consome itens. Pode ser interrompido, retomado no último passo salvo ou pulado após escolher o parceiro. Os checkpoints são de apresentação, não prova de uma vitória premiada; são separados dos recibos verificados de Trilhas da migração 014.

## Contas existentes

A migração marca perfis existentes como apresentação concluída. Inventário, equipamento, XP, moedas, estrelas, rabiolas e histórico permanecem como estavam. O Sr. Assis permite repetir a apresentação e experimentar os iniciais no treino, sem equipar outro item na conta, duplicar o parceiro ou reiniciar progresso. O Nozinho do professor não entra na coleção.

## Navegação e cidade

O mapa incorpora o cenário e as doze insígnias produzidas no pacote anterior. Os três bairros atuais levam às quinze etapas existentes e respeitam os desbloqueios salvos na conta. Fechar um briefing retorna ao mapa; sair de uma partida retorna ao quintal. Os outros nove bairros aparecem como expansão em preparação, sem botão para iniciar um encontro inexistente. Defesa/reconquista de títulos, sessenta confrontos e final municipal continuam pendentes, conforme `CAMPANHA-CIDADE.md`.

Passar por uma tela de invocação continua usando as regras existentes de consumo e dano da rabiola ao abandonar o ritual. O quintal não contorna essas regras.

## Persistência e instalação

Aplicar `015_first_flight.sql` depois de 014 no banco do projeto e publicar a versão correspondente do servidor pelo processo habitual. O ambiente local aplica a migração somente no PGlite isolado. A publicação exige também os três PNGs adicionais copiados pelo build: quintal, mapa e insígnias.

`player_journeys` mantém `phase`, `lesson` e a escolha inicial por conta. RLS e revogações impedem acesso direto; `player_journey` deriva identidade de `auth.uid()`. A escolha usa bloqueio do perfil e é idempotente: repetir a mesma chamada não concede outra cópia; trocar o modelo depois da confirmação é recusado. Não permite escolher durante uma partida, troca aberta ou ritual ativo. Somente os quatro modelos iniciais são elegíveis.

O cliente protege respostas atrasadas por proprietário e geração da sessão. Uma falha ao confirmar mantém a seleção aberta, sem entrar no treino. Falha ao salvar um checkpoint mantém o botão disponível para tentar novamente; reconectar não fabrica uma escolha ou recompensa. Progresso da escola antiga permanece separado e salvo como antes.

Não apagar a tabela para rollback. Se voltar à interface antiga, preservar os registros e as permissões; a versão antiga simplesmente não usa os checkpoints. Uma escolha já confirmada permanece permanente.

## Arte e desempenho

Novo cenário gerado com `image_gen` integrado, usando o Morro do Sol como referência. Prompt e origem em `assets/backgrounds/quintal-clube-v1.json`; PNG original preservado. Professor, Nozinho, parceiros iniciais, mapa e insígnias reutilizam assets existentes.

O quintal usa o mesmo agendador do jogo, limitado a 30 fps; não cria um segundo ciclo de animação. Suspende desenho atrás de outra tela e quando a página fica oculta. Coleções grandes aparecem em grupos de até doze espécies, alternados durante o passeio. Preferência de movimento reduzido inicia o passeio pausado; o jogador pode retomá-lo. Imagens são servidas pela lista explícita de assets, com cache e hash.

## Validação

Testes PostgreSQL: preservação de conta antiga, autenticação/permissões, parceiro inválido, bloqueio durante partida, escolhas concorrentes, repetição sem duplicação, equipamento e permanência, ordem de checkpoints e ausência de prêmios.

Testes do motor: cinco momentos completos com cada um dos quatro parceiros; esperar sem atacar não conclui as lições de combate. Interface: resposta atrasada de outra conta ignorada, falha de confirmação mantém a seleção aberta, checkpoint retomado, bairro bloqueado/indisponível e retorno do briefing ao mapa. Testes antigos da apresentação foram atualizados para acesso explícito; ela não disputa mais a abertura automática com o novo percurso.

Conferência local no navegador: chegada, seleção, treino com Nozinho, parceiro salvo após recarregar, mapa, bloqueios e destinos do quintal. Capturas e registro final da suíte acompanham a entrega.

Ainda é necessária a observação de uma pessoa sem experiência prévia para medir se o primeiro corte e a ida ao Morro acontecem sem instrução externa. Isso orientará o ajuste de ritmo e dicas; o tempo de cinco a oito minutos é uma meta de design, não uma medição concluída.

Resultado final: 126 testes aprovados; builds Worker/Pages e validação do artefato concluídos. No navegador, a banca e a invocação abriram diretamente pelo cenário; o briefing voltou ao mapa; a conta Beto manteve Raio de sol equipado e entrou sem repetir a introdução; visitantes mantiveram apenas as opções permitidas. Sem erros no console durante a conferência.
