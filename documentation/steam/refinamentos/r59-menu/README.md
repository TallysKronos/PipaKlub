# R59 — encerramento do teste de menu e regressão de ciclo de vida

05/11/2026. Godot 4.7.2 stable, base `bfac009c` mais este refinamento.

## Diagnóstico

O teste do título passava em 349 checks funcionais e, imediatamente após `front.free()`, encerrava o motor. O log verbose identificou seis objetos ligados aos playbacks OGG/WAV e dois recursos ainda em uso, incluindo música do menu e confirmação da UI.

Experimentos locais: apenas aguardar dois frames não eliminou os avisos. Permitir a liberação assíncrona do mixer antes de encerrar removeu os diagnósticos. Isso caracteriza o problema observado no teardown deste teste; não demonstrou crescimento permanente de memória na campanha. Há [registro oficial de comportamento semelhante ao encerrar áudio ativo](https://github.com/godotengine/godot/issues/76745), usado como referência de investigação, sem atribuir automaticamente todo aviso a um bug do motor.

Não foi mantida a tentativa de alterar o diretor de som: ela não eliminava os avisos. O código de gameplay/áudio permanece com o mesmo comportamento.

## Alterações

- O teste do título acompanha os streams por referências fracas e espera sua liberação com prazo de dois segundos, verificando o resultado. Não há espera ou atraso adicional no jogo.
- Nova suíte `menu_lifecycle_checks.gd`: cinco ciclos reais de criar frontend, abrir menu/configurações/título, tocar música/confirmar e destruir. Acompanha frontend, sessão, diretor, players e streams por referências fracas. Confere retorno da contagem de nós e ausência de crescimento de órfãos após aquecimento.
- O runner Godot inclui as duas suítes e rejeita diagnósticos de vazamento/recursos vivos nesses logs, mesmo que os asserts e o processo retornem zero. Não silencia nem filtra esses avisos para passar.

## Evidência

| Prova | Resultado |
| --- | --- |
| Título antes | 349 checks funcionais; 6 instâncias e 2 recursos nos diagnósticos de saída. |
| Título depois | **350 checks, zero falhas**, incluindo liberação dos streams; sem os diagnósticos anteriores. |
| Ciclos | **55 checks, zero falhas**, cinco ciclos; baseline 2 nós, 0 órfãos, sem crescimento. |
| Runner PowerShell | Sem erro de sintaxe. |

Excertos dos logs em `before-excerpt.txt`, `title-after-excerpt.txt` e `cycles-after-excerpt.txt`; resumo em `results.json`. O número de checks da suíte de ciclos pode variar com as vozes UI efetivamente criadas: todas as instâncias observadas são verificadas.

## Estado e limites

**R59, recorte de título/menu/configurações: corrigido e validado localmente.** Permanecem fora desta conclusão o ciclo completo de mapas/batalhas/cutscenes, sessão longa, hardware de áudio físico e o encerramento do executável comercial. Também não foi reexecutado todo o conjunto de suites nesta mudança; a CI fará a regressão selecionada. Não há alteração de save ou nova gravação de campanha.
