# Implementação no projeto atual

## Reaproveitar infraestrutura

O destino de produção atual é Godot. Antes de substituir estilo, leia os consumidores e as provas existentes:

| Arquivo/família | Reutilizar ou conferir |
| --- | --- |
| `godot/scripts/campaign/ui_tokens.gd` | Paleta semântica, papéis de fonte e carregamento local |
| `godot/scripts/campaign/recorte_theme.gd` | Theme, StyleBoxes, estados e controles compartilhados |
| `godot/scripts/campaign/hud.gd` | Composição, ícones e helpers atuais |
| `godot/scripts/campaign/controls.gd` | Ações, prompts e famílias de controle |
| `godot/scripts/campaign/front_end.gd` | Navegação real e fluxo de overlays; não criar pilha paralela |
| `godot/scripts/campaign/hud_exploration.gd` | Exploração e informação contextual |
| `godot/scripts/campaign/encounter_view.gd`, `morro_battle_view.gd` | Batalhas selvagens, boss e bairro |
| `godot/scripts/campaign/battle_corner_hud.gd` | Dados persistentes do combate |
| `godot/scripts/campaign/hud_dialogue.gd` | Diálogo e foco |
| `documentation/HUD-RECORTE-GODOT.md`, `HUD-RECORTE-AUDITORIA.md` | Histórico do kit e diferenças verificadas |
| `godot/tests/hud_checks.gd`, `hud_effects_checks.gd`, `lobby_checks.gd`, `identity_layout_checks.gd` | Base de checagens de layout e comportamento |

Confirme os caminhos no checkout antes de editar; o mapeamento não substitui ler o consumidor. Descubra demais telas com `rg --files godot/scripts/campaign` e busque seus testes correspondentes.

Fontes hoje centralizadas: Nunito, Barlow Condensed, Lilita One e Bangers, com licenças locais. São recursos candidatos ao reaproveitamento, não a escolha tipográfica obrigatória da direção nova. Não adote fontes de terceiros sem origem/licença.

`HUD-KIT.md`, `src/hud-skin.js` e `assets/ui/hud-papel-bambu-v1/manifest.json` documentam contratos úteis de recortes no legado web. Não trate uma tela HTML como implementação Godot. Em contradição com instrução antiga de preservar a direção Recorte, o pedido explícito deste novo épico autoriza redesenhar a linguagem, preservando a infraestrutura útil.

## Contratos que sobrevivem ao redesenho

- Cantos/pontas em 3-slice/9-slice ficam fixos; apenas trechos apropriados crescem. Nó, folha, carretel e ilustração não deformam com a largura do texto.
- Texto e valores variáveis continuam nativos, com fonte local e espaço medido. Decoração não rouba foco nem hitbox.
- Use Containers, âncoras e áreas seguras para conteúdo. Coordenadas de atlas e geometrias desenhadas continuam válidas; não refatore só para eliminar qualquer número absoluto.
- Preserve foco inicial, vizinhos direcionais, retorno, seleção, pausa e bloqueio do input de exploração/batalha sob overlays.
- A interface observa os dados reais e os eventos confirmados; não concede itens, emblemas ou XP em animações. Preserve atomicidade e retomada dos saves.
- Meça antes de alterar polling ou ciclos existentes. Não é necessário reescrever a arquitetura para trocar a linguagem visual.

## Telas com exigências próprias

**Exploração e Kronasta:** cenário respirável, objetivo/interação contextuais, pontos acessíveis e futuros apagados sem parecer bug. Informação crítica permanece disponível mesmo se uma faixa recolhe.

**Batalha:** Linha, Armação, recurso, alvo e ação legíveis em movimento. Intro do campeão em VS deve sair antes de liberar o combate e respeitar pausa/pular/reduzir movimento. Enroscada precisa de estado, orientação e feedback próprios; leia a regra real no motor antes de inventar um indicador. Não copie os recortes e poses de Black/White.

**Diálogo:** retrato autoral, texto legível, avanço sem consumir o comando da cena, fala longa e interlocutor identificável. Efeito de escrita pode ser acelerado/desligado.

**Menus:** Pipa Dex, quadro de evolução, Varal e 12 emblemas têm tarefas distintas e navegação coerente. Explique o que ainda não existe nos dados em vez de criar números fictícios no produto final.

**Resultado e grandes momentos:** só animar recompensa confirmada. Vitória, derrota, evolução, item e emblema não recebem a mesma duração e intensidade por padrão.

**Transições e sons:** entrada/saída com prontidão real da cena; loading não é espera falsa. Sons e motion reforçam seleção, vínculo e impacto sem mascarar leitura nem bloquear comandos necessários.

Produza artes como peças reutilizáveis, nunca um screenshot gigante com todos os rótulos. Raster: use a skill imagegen disponível, inspecione alpha, cortes, repetição e escala. Mantenha prompt, fonte e versão.
