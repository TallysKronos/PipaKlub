# R38/R42 — retomar exploração após falha de autosave

05/11/2026. Base 9e486c36.

O frontend pausava o mapa antes de abrir o aviso de erro. O aviso registrava essa pausa como estado anterior e a restaurava ao fechar, impedindo o jogador de voltar a explorar. Removida a pausa redundante: o próprio aviso controla sua pausa temporária, preservando uma pausa que já existisse legitimamente.

## Verificação executada

- Antes da correção: 12 checks, 2 falhas, reproduzindo o travamento e a pausa após retry.
- Depois: 12 checks, zero falhas. Frontend e mapa de exploração reais, falha de escrita injetada, snapshot e hash do arquivo preservados, aviso dispensado, nova tentativa persistida e pausa anterior respeitada. Limpeza de áudio verificada.
- Regressões: feedback de saves (35 checks) e resiliência do armazenamento (152 checks), zero falhas.
- A suíte entrou no runner Godot, inclusive com rejeição de vazamentos no encerramento.

As fixtures usam perfil/pastas descartáveis. Nenhum save real foi alterado. Execução headless; não houve novo playtest visual, disco fisicamente cheio ou teste de periférico físico. O runner completo e a CI remota não foram executados neste pacote.

## Continuação — autosave separado e configuração

Base 0cf141eb. A entrada normal pelo seletor de jornadas ativa a política nova; ferramentas/fixtures que usam Session diretamente mantêm seu contrato de gravação direta até optarem por `separate_autosave`.

- Espaço 0 reservado à retomada automática. Não aparece como destino de novo jogo ou save manual. É exibido na lista de retomada quando existe ou apresenta erro recuperável/diagnosticável.
- Os arquivos manuais 1–3 existentes continuam legíveis, sem migração destrutiva. Novo jogo cria seu ponto inicial no espaço manual escolhido; avanços posteriores vão ao espaço 0, sem alterar esses três arquivos.
- Configurações → Jornada: autosave ligado por padrão, preferência persistida fora da campanha. Desligado, checkpoints/recompensas e recibos de operação continuam em memória, sem escrita automática. Reativar grava no próximo checkpoint seguro, sem forçar gravação no meio de uma cena.
- Pausa → Salvar oferece os três espaços manuais. Substituição exige confirmação, inicialmente em Cancelar; destino ilegível/futuro permanece protegido. A revisão capturada na escolha impede substituição silenciosa se outro processo alterar o arquivo antes da confirmação. Salvamento manual indisponível durante batalha, oficina e movimentação narrativa bloqueada.
- Ao sair com mudanças em memória, é possível cancelar e continuar ou confirmar descarte. Saves manuais e autosave carregam estados independentes, inclusive após reiniciar a sessão.
- Indicador sem foco, acima das transições: gravando, salvo ou falha. Gravações continuam síncronas; a fase gravando pode terminar antes do próximo frame em escritas rápidas. Não há atraso artificial para fingir uma gravação longa. O resultado permanece visível por 2,5 segundos; erro também recebe explicação acionável pelo fluxo existente.
- O aviso de sucesso do mapa não aparece quando autosave está desligado. Abrir menu não sobrescreve mais o arquivo manual.
- Configurações e salvamento manual permanecem acessíveis se a escrita automática falhar: a posição segura é capturada em memória, sem exigir nova gravação automática para abrir essas rotas de recuperação.

### Validação da continuação

Nova suíte `autosave_slots_checks`: **55 checks, zero falhas**, executada no Godot com renderização OpenGL Compatibility/GTX 1650 a 1280×720. Abrange preferência/reabertura, bytes do manual preservados, slot 0, recompensa idempotente em memória, confirmação/cancelamento, descarte, retomadas independentes, revisão concorrente, falha/retry e destino de versão futura. O indicador é conduzido explicitamente também para revisar os estados de interface; a captura não representa uma escrita fisicamente lenta.

Regressões executadas: resiliência 152; feedback 35; campanha 207; título 350; ciclo de menu 55; controles 44; recuperação no mapa 13 — todas sem falhas. A recuperação no mapa agora usa a política separada e o arquivo do espaço 0, verificando também acesso ao salvamento manual durante falha automática.

Capturas revisadas: [configuração](settings.png), [salvamento manual](manual.png), [resultado da gravação](saved.png). Foi corrigido o corte de “Acessibilidade” observado na primeira revisão das cinco abas.

Ainda não verificados: sessão longa atravessando todos os atos com autosave desligado, periférico físico, outros tamanhos de tela/texto, VM limpa, nova exportação e CI remota. A exclusão continua sendo por cópia/slot; vincular exclusão de campanha ao autosave e ao depósito global pertence ao R39, ainda pendente. Este pacote não certifica a prontidão integral do R38 nem da Steam.
