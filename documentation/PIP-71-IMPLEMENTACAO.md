# PIP-71 — Lição de voo com HUD compartilhada

Implementação local; sem publicação no Git ou mudança de status no Linear.

- Arena ocupa toda a janela, usando a mesma projeção e limites da batalha.
- Cinco lições reutilizam as placas dos cantos, energia em blocos, sinais de contato e cartas de ação.
- Balão de Sr. Assis recolhe durante a ação; Dica mantém a explicação aberta.
- Avanço bloqueado com cadeado até concluir o objetivo. Ao concluir, recebe foco.
- Salvar fica na pausa, junto de Retomar, sem ocupar a arena durante o exercício.
- Destaque dourado inicial identifica o alvo ou comando e respeita movimento reduzido.

## Verificação

- lesson_hud_checks: 520 verificações, zero falhas, incluindo renderização e capturas.
- battle_corner_checks: 214 verificações, zero falhas após extrair a projeção compartilhada.
- campaign_checks: 206 verificações, zero falhas; regras das cinco lições preservadas.
- campaign_view_checks: 30 verificações, zero falhas.
- battle_flow_checks: 797 verificações, zero falhas.

Capturas em mockups/revisao/pip71: 1280×720, 1280×800, 1920×1080 e 2560×1080, com ação, conclusão e movimento reduzido. Conferência visual adicional em 16:10 e ultrawide. Os estados concluídos das capturas são preparados por fixtures isoladas; não representam um playtest humano completo nem alteram saves reais.
