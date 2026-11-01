# Integração da auditoria de margens · 31/10/2026

Branch local: `codex/integracao-bosque-kronasta`.

Importados de `origin/claude/unificacao`:

- `e50db00b` — revisão de margens, placas, texto e respiro da HUD; auditor automático.
- `4484def7` — abertura síncrona do parque nas fixtures, preservando os avisos da captura.

Antes da integração, o trabalho local foi preservado em `cbc9c146` (atlas de Kronasta, encerramento da demo, documentos, banners e porta-emblemas). O merge `5dda965f` entrou sem conflitos nos dois arquivos compartilhados: `front_end.gd` e `player_audit_fixtures.gd`.

## Ajustes da integração

- Removidas três sobrescritas que voltavam o espaçamento novo de 32 px para 20/24 px em configurações e controles.
- A ferramenta de captura prepara documentos nas cópias visuais em memória e abre o parque sincronamente. Ela continua sem criar/gravar saves.
- Capturas estáticas ignoram input da janela, para que a posição do cursor no desktop não abra um tooltip ou efeito de hover incidental sobre a tela auditada. A decoração Recorte também respeita essa propriedade do viewport. `--reduced-motion` é opcional na ferramenta e não altera as preferências persistidas do jogador.
- Acrescentadas duas verificações de validade do quarto após movimentos assíncronos da abertura: trocar/fechar a cena durante esses movimentos não acessa um quarto já liberado.

## Verificações executadas

Saves e preferências isolados em `tmp/playtest-humanlike/appdata`.

| Verificação | Resultado |
| --- | --- |
| `dialogue_hud_checks.gd --quick`, renderer nativo | 94 verificações, zero falhas |
| `exploration_hud_checks.gd --quick`, renderer nativo | 163 verificações, zero falhas |
| `emblem_case_checks.gd` | 60 verificações, zero falhas |
| `pipeiro_identity_checks.gd` | 78 verificações, zero falhas |
| `key_item_banner_checks.gd` | 28 verificações, zero falhas |
| `demo_completion_checks.gd` | 43 verificações, zero falhas |
| `campaign_checks.gd` | 206 verificações, zero falhas |

Total: **672 verificações aprovadas**. As duas suítes de HUD usaram o modo rápido (1280×720); não se trata de reauditoria de todas as resoluções. As execuções headless dessas suítes que dependem de carregamento/encenação foram interrompidas e substituídas pelo renderer nativo; não foram contadas no total. Alguns runners mantêm avisos de recursos em uso ao finalizar.

Verificação adicional `recorte_theme_checks.gd`: 197 de 198 verificações aprovadas. A falha é a regra estática que proíbe `Theme.new(` em `pier_play.gd`, já presente no commit local anterior ao merge (`cbc9c146`). Essa cena de demonstração do cais não foi alterada nesta integração. O resultado se repete com e sem renderer; não é registrado como sucesso da suíte.

Capturas nativas em 1280×720, inspecionadas:

- [Mochila](mochila-1280x720.png): auditor encontrou 22 textos e zero problemas.
- [Configurações](configuracoes-1280x720.png): 17 textos e zero problemas.
- [Veredas](veredas-1280x720.png): abertura, título longo, objetivo e cartão do parceiro conferidos visualmente. O scanner atual ignora a árvore Node2D/SubViewport dessa HUD e reporta zero textos; esse resultado não é usado como prova automática de margens do parque. A suíte específica de exploração cobre sua geometria.

Integração local concluída. Nenhum push foi solicitado ou executado. Os dois executáveis locais do Godot permanecem fora dos commits.
