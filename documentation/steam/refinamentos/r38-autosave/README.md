# R38/R42 — retomar exploração após falha de autosave

05/11/2026. Base 9e486c36.

O frontend pausava o mapa antes de abrir o aviso de erro. O aviso registrava essa pausa como estado anterior e a restaurava ao fechar, impedindo o jogador de voltar a explorar. Removida a pausa redundante: o próprio aviso controla sua pausa temporária, preservando uma pausa que já existisse legitimamente.

## Verificação executada

- Antes da correção: 12 checks, 2 falhas, reproduzindo o travamento e a pausa após retry.
- Depois: 12 checks, zero falhas. Frontend e mapa de exploração reais, falha de escrita injetada, snapshot e hash do arquivo preservados, aviso dispensado, nova tentativa persistida e pausa anterior respeitada. Limpeza de áudio verificada.
- Regressões: feedback de saves (35 checks) e resiliência do armazenamento (152 checks), zero falhas.
- A suíte entrou no runner Godot, inclusive com rejeição de vazamentos no encerramento.

As fixtures usam perfil/pastas descartáveis. Nenhum save real foi alterado. Execução headless; não houve novo playtest visual, disco fisicamente cheio ou teste de periférico físico. O runner completo e a CI remota não foram executados neste pacote.

## Ainda pendente

Este pacote fecha a recuperação da falha, não todo o R38. O slot 0 exclusivo, a opção de autosave ligada por padrão e o indicador de gravação precisam de implementação própria. O formato e os três slots existentes permanecem como estavam.
