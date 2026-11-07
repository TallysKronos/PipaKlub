# R39 — exclusão vinculada e reinício da campanha

05/11/2026. Base 27ae1ee6. Produto Godot; sem alteração da versão web.

## Comportamento entregue

- Novas jornadas recebem `campaignId` persistente no ponto inicial. Autosave e saves manuais copiados dessa jornada mantêm esse vínculo. Nome do jogador, espécie ou posição não servem para agrupar campanhas.
- Excluir um save pela interface prepara a lista dos espaços vinculados e pede confirmação, inicialmente em Cancelar. Informa a perda de história, itens e criaturas desses saves, a preservação dos arquivos externos e a condição para desfazer.
- A confirmação guarda as revisões de todos os participantes. Se qualquer participante mudar ou outra cópia aparecer antes de confirmar, a operação é recusada como desatualizada antes da remoção.
- Os arquivos são copiados e conferidos por hash antes do compromisso de exclusão. O diário imutável autoriza a limpeza apenas depois de todas as cópias verificadas. Exclusão interrompida é concluída ao abrir o armazenamento novamente; saves parcialmente removidos não são liberados para carregar.
- O identificador excluído não pode ser gravado de novo por uma sessão ainda aberta. Começar outra jornada no espaço liberado cria identidade nova, limpa os recibos de recompensa e permite conquistar outro Rabbito com outra identidade de instância.
- Desfazer exige que todos os espaços envolvidos estejam livres. A recuperação tem intenção e conclusão persistidas; uma interrupção no meio das cópias ou na marca final é retomada sem duplicar criaturas nem sobrescrever uma campanha nova.
- Cópias incompletas anteriores ao compromisso não aparecem como exclusões recuperáveis. Arquivos com backup válido continuam recuperáveis mesmo quando o primário arquivado está corrompido.
- A lista oferece “Tentar novamente” para operação interrompida. Quando a exclusão termina, a lista é atualizada sem iniciar acidentalmente uma jornada apagada. O menu permite consultar saves indisponíveis, mesmo que nenhum deles esteja carregável no momento.
- Após concluir a exclusão, as aberturas seguintes consultam marcadores pequenos; não recalculam todos os hashes dos saves arquivados a cada checkpoint.

## Compatibilidade e limites

Arquivos antigos sem `campaignId` usam uma identidade determinística da cópia carregada. Os autosaves/copias gerados a partir dela agora mantêm o vínculo. Não é possível provar que um autosave antigo de outra implementação e uma cópia antiga pertencem à mesma campanha apenas por nome ou `originSlotId`: esses arquivos não são agrupados por adivinhação. A confirmação avisa quando o save escolhido não possui vínculo persistido ou há arquivos ilegíveis. Essa cobertura de legado não equivale a migração certificada de todo arquivo histórico.

O depósito global de 20 criaturas e suas transferências **ainda não existem no Godot**. O teste usa um arquivo sentinela externo à pasta de campanha para provar que a exclusão não o altera; ele não simula nem comprova uma conta real. Implementar o banco 30/global 20 e testar a preservação de criaturas reais fica no R40. Configurações/perfil não são destinos do arquivamento.

O contrato continua sendo armazenamento local de um processo. Há revalidação de revisões/bytes, mas não bloqueio exclusivo entre duas instâncias simultâneas. Flush e renomeação não prometem durabilidade após corte físico de energia. Os arquivos removidos permanecem arquivados para desfazer; não se trata de apagamento definitivo do disco.

## Validação

`campaign_reset_checks.gd`: **216 checks, zero falhas** em perfil isolado. Exercita grupos independentes com o mesmo nome, cancelamento/aceite reais da interface, exclusão/retomada, novo Rabbito, recibos, concorrência por revisão, cópia/diário antes do compromisso, cinco fronteiras de limpeza, falha na marca final, restauração parcial, corrupção da cópia de segurança arquivada, legado, primário corrompido com backup e retry na lista.

As interrupções são falhas injetadas seguidas por outra instância do armazenamento; não foi encerrado fisicamente um processo no exato instante da gravação. Nenhum save do jogador foi usado. A suíte entrou no runner de validação, com rejeição de vazamentos no encerramento.

Captura da confirmação revisada no Godot a 1280×720: [ver imagem](confirmation.png). A suíte de 216 checks passou também nesse renderizador (OpenGL Compatibility/GTX 1650). Não certifica outros viewports/textos ampliados, controle físico, VM limpa, exportação nova ou CI remota.

Regressões executadas, todas sem falhas: resiliência de saves 152; feedback 35; campanha 207; título 350; ciclo de menu 55; autosave/slots 55; recuperação de autosave 13. Total de **1.083 verificações distintas** neste pacote. O runner completo das 22 suítes não foi executado localmente nesta etapa.
