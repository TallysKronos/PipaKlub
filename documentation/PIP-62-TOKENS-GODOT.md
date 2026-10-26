# PIP-62 — tokens e tipografia Recorte

Implementação local de 26/10/2026, na branch `godot`, a partir de `039157f`.

## Entrega

- Incorporados os oito arquivos de `art/ui/hud-recorte-v1/` da revisão `2e0b80b` de `origin/claude/hud-godot`, sem merge integral da branch.
- Fonte única em `godot/scripts/campaign/ui_tokens.gd`: dez cores aprovadas e `veu` (tinta a 72%), cores semânticas, alpha e recursos de fontes compartilhados. `UNTINTED` é modulação identidade para preservar os sprites originais; não é uma nova tinta branca de interface.
- `hud.gd` mantém seus nomes públicos como aliases, inclusive `DANGER = RABIOLA`. `battle_ink.gd` utiliza a mesma fonte, sem paleta paralela. As placas de rival usam papel legível sobre superfície escura; sinais de perigo usam coral.
- Migrados batalha, treino, HUDs, menus auxiliares, Oficina, minimapa e caixas dos protótipos. A seleção das placas agora usa o papel semântico (`dark`/`danger`), sem deduzir o estado a partir dos canais RGB de uma cor.
- Barlow Condensed 700 nos rótulos/números com `tnum`; Nunito 600/800 no texto; Lilita One 400 nos títulos com shear de 8°; Bangers nas onomatopeias. Mantidas as quatro licenças OFL existentes em `godot/licenses/`.
- A tarefa pede 8°. Um exemplo de estrutura de pastas da especificação menciona 12°; foi seguido o valor explícito da PIP-62 e da tabela de tipografia, sem inclinar o baseline ou os Controls.
- `scripts/sync-recorte-tokens.mjs` deriva o manifesto dos tokens de runtime. O gerador SVG também consome essa fonte para sua paleta e sincroniza o manifesto; desabilitados não introduzem os antigos cinzas esverdeados.
- `godot/tests/ui_tokens_checks.gd` percorre `scripts/`, rejeita construtores de cores literais (hex ou numéricos), cores nomeadas e cargas diretas de fontes. Verifica manifesto, aliases, fontes, inclinação e licenças. Inclui casos de regressão da própria detecção.

## Exceções de arte

O teste contém motivos explícitos para `region.gd` (materiais do terreno) e `illustrated_tree.gd` (sombra da árvore). Na Oficina, só aceita seis instruções exatas de pigmento do papel/bambu/bandeja; feedback de acerto, guias, medidores e texto usam tokens. No protótipo antigo, duas instruções exatas preservam o tratamento visual de baús abertos. Uma cor nova em outra instrução da Oficina continua proibida.

Sprites, pinturas e cores próprias dos Pipamons não foram recoloridos. Esta tarefa não redesenha os assets de tinta, botões de batalha, enquadramento, textos ou estados das demais subtarefas PIP-63 a PIP-78. Cores já pintadas em ilustrações e ícones têm consumidores e revisão próprios.

## Conferência efetivamente realizada

O ambiente não tinha Godot acessível nos caminhos documentados. Foi baixado o runtime portátil oficial 4.7.2 (`ed1daf0bf`) para `tmp/godot-4.7.2/`, com SHA-256 do ZIP conferido contra os metadados da release oficial: `731980f9608d61333e5baf54a2ef17210acc7a538446c0cb9969f002aca1e953`. Sem instalar globalmente; configuração do editor portátil em pasta ignorada.

Importação do projeto e `--check-only` da entrada da campanha, dos dois protótipos e do novo teste concluídos com código 0 após corrigir dois erros de compilação encontrados. Essas verificações compilam dependências; não executam o corpo dos testes.

Laboratório nativo `hud_lab.gd -- --capture` renderizado e inspecionado em 1280×720 e 1024×768, renderer Compatibility/OpenGL, RTX 5070. Logs sem erros de execução nessas capturas. Evidências em `documentation/evidence/pip62/`. Confirmam somente o laboratório; não comprovam todas as telas, gamepad, acessibilidade integral ou paridade do gameplay.

Sem execução do novo teste, das 12 suítes ou de `journey_playthrough.gd -- --with-morro`, respeitando a orientação vigente para não rodar testes sem pedido. Sem exportar executável final, alterar saves, publicar na Steam/Render ou mesclar na main. A PIP-62 permanece em andamento até a validação de aceite.

## Comandos para a validação pendente

```powershell
$runtime = './tmp/godot-4.7.2/runtime/Godot_v4.7.2-stable_win64_console.exe'
& $runtime --headless --path godot --script res://tests/ui_tokens_checks.gd
```

Depois, quando solicitado, executar as suítes listadas na PIP-62: campaign_checks, campaign_view_checks, controls_checks, park_checks, art_direction_checks, binding_window_checks, hud_checks, hud_effects_checks, morro_checks, morro_map_checks, morro_transaction_checks, player_flow_checks e o percurso com `--with-morro`. Não declarar a tarefa Done apenas com sintaxe e capturas aprovadas.
