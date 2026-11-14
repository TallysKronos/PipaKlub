# R42 — encerramento real do processo durante persistência

05/11/2026. Produto Godot; nenhuma alteração de regra ou pausa introduzida no jogo.

## Implementação

`godot/ValidarInterrupcoes.ps1` cria fixtures novas, inicia um Godot para preparar os dados, outro para escrever e encerra **somente esse filho**, pelo handle de processo, quando o worker publica uma barreira. Dois processos novos, separados, verificam recuperação e estabilidade. Cada processo tem APPDATA descartável; os arquivos da campanha ficam na pasta exclusiva do caso. Pasta existente é recusada.

O worker `godot/tests/process_save_worker.gd` usa os serviços reais de save, sessão, banco, recompensa e arquivo de campanha. Uma subclasse exclusivamente de teste pausa nas fronteiras já existentes. Não devolve erro artificial em lugar do encerramento: o pai realmente chama `Process.Kill` enquanto o filho está parado na fronteira. Timeout e limpeza atuam apenas nos processos iniciados pelo teste. Logs e `results.json` são preservados.

## Matriz de 16 casos

| Operação | Interrupções | Resultado exigido |
|---|---|---|
| Save | Antes/depois do temporário, após backup, antes/depois de publicar o primário | Estado anterior exato ou novo estado publicado; parceiros preservados; nova gravação possível. |
| Save, lacuna Windows | Primário removido antes do rename | Recuperação pelo backup. A remoção desta lacuna é **emulada explicitamente** na fixture; o encerramento é real. |
| Depósito global | Intenção publicada, campanha publicada, conclusão publicada | Um parceiro global, removido uma vez da campanha, identidade/atributos preservados; repetição do recibo não duplica. |
| Recompensa com banco de campanha cheio | As mesmas três fases transacionais | 30 parceiros e uma recompensa pendente com identidade original; recibo de origem único. |
| Exclusão de campanha | Diário publicado, primeiro arquivo removido | Remoção concluída nos slots relacionados 0/1/2; campanha alheia no slot 3 preservada. |
| Desfazer exclusão | Primeira cópia temporária, primeiro arquivo publicado | Restauração dos três slots com conteúdo original; campanha alheia preservada. |

## Executar

PowerShell 7, checkout importado com Godot 4.7.2:

```powershell
./godot/ValidarInterrupcoes.ps1 -GodotPath 'C:/caminho/Godot_v4.7.2-stable_win64_console.exe'
```

A CI executa este gate após as suítes normais e publica os resultados junto aos logs. É um gate separado de `Validar.ps1`; rodar só esse runner não executa os encerramentos.

## Evidência e limites

16 casos aprovados, incluindo duas reaberturas independentes por caso. Artefatos locais em `outputs/r42-process/run-3`, fora do repositório. Não houve necessidade de modificar a implementação de produção.

Não verificado: perda física de energia/fsync, disco cheio real, dois escritores simultâneos, ACLs e usuários reais distintos, SteamID/Cloud, migração de uma coleção representativa de saves de todos os atos, nem percurso visual integral em executável exportado. As barreiras são determinísticas e ficam entre chamadas de arquivo; não demonstram encerramento em cada byte ou em toda instrução interna da engine. R42 permanece parcial por esses limites.
