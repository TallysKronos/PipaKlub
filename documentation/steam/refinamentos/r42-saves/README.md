# R42 — falhas de gravação e recuperação de saves

05/11/2026. Godot 4.7.2 stable; base `7fc263a0` mais este lote.

## Trabalho executado

A fundação já possuía temporário, validação, backup e recibos de recompensa. Este lote amplia a comprovação; **não foi encontrado um novo defeito de perda/duplicação nos cenários exercitados**.

Foram isoladas duas fronteiras privadas do filesystem (`_replace_file`, `_copy_file`), mantendo a mesma ordem e as mesmas operações reais em produção. Somente a subclasse em `tests/save_resilience_checks.gd` injeta os erros; ela não entra no release pelo filtro de exportação. Não foi acrescentado um modo de falha acessível pelo jogador.

## Matriz executada

| Cenário | Resultado conferido |
| --- | --- |
| Falha ao escrever o temporário principal | Memória/disco continuam no último estado confirmado; só sinal de erro é emitido. |
| Falha ao escrever o temporário do backup | O temporário novo não é promovido; primário permanece íntegro. |
| Falha ao substituir backup | Primário preservado e recompensa não marcada como recebida. |
| Falha ao substituir primário | Reabertura mantém o último commit. |
| Primário removido antes de rename interrompido | Backup válido recupera o estado anterior; temporário órfão não é assumido como commit. |
| Falha em preservar primário danificado | Fonte danificada e backup bom ficam intactos; retry bem-sucedido preserva a cópia `.damaged-<hash>`. |
| Retry da mesma recompensa em todos os seis pontos | Concede uma vez; repetição retorna `already_applied`; nova sessão lê o estado confirmado. |
| Erro de leitura em primário/backup | Retorna `io_error`, sem rollback silencioso nem sobrescrita; memória permanece igual. |
| Falha no primeiro save | Nenhuma jornada é anunciada em memória; retry funciona e não permite overwrite depois. |
| `.tmp`/`.bak.tmp` incompletos ou órfãos | Não substituem automaticamente uma gravação confirmada. |
| Schema/content/rules desconhecidos | Leitura/gravação bloqueadas; bytes originais preservados. Backup com schema futuro também bloqueia downgrade silencioso. |
| JSON corrompido nas duas cópias | Status `corrupt`, sem tratar arquivo ocupado como slot novo. |
| Primário maior que 8 MiB, moedas negativas ou slot trocado | Rejeitado; backup validado é escolhido sem modificar o arquivo danificado na leitura. |
| Travessia de caminho no ID do slot | Recusada. |

Os comparativos de disco usam a representação serializada de JSON, pois números retornam como floats. A memória anterior à falha é comparada diretamente, sem normalizar ou ocultar alterações.

## Resultado

- **152 checks de resiliência, zero falhas.**
- **207 checks da campanha existente, zero falhas**, reexecutados após a pequena separação das operações de arquivo.
- 359 verificações no total; logs em `resilience.txt` e `campaign.txt`, resumo em `results.json`.
- Nova suíte incluída no runner/CI Godot, com perfil e diretório de teste isolados.

## Limites e estado do item

**R42: cobertura local ampliada e aprovada para esta matriz**, sem declarar o item inteiro encerrado. Falhas de acesso/escrita/cópia/rename foram injetadas de forma determinística; arquivos inválidos e a ausência do primário foram realmente produzidos nas fixtures. Isso não demonstra queda física de energia, esgotamento real de disco, ACLs de outro usuário ou concorrência simultânea entre processos.

Permanecem: migração com amostras de todas as versões/atos, comportamento de duas instâncias realmente concorrentes, apresentação dos erros/recuperação pela interface em todos os contextos, instalação Steam e Cloud caso adotado. Autosave, exclusão de campanha e depósito global têm itens próprios; não foram alterados.

Nenhum save do jogador foi acessado ou alterado. Não houve merge ou publicação.
