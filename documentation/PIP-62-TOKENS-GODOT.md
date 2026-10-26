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

Na primeira entrega, os testes de aceite ficaram pendentes. Após o pedido de continuação, executados o teste de tokens, as 12 suítes e `journey_playthrough.gd -- --with-morro`, todos com código de saída 0. Não foi necessário corrigir a implementação durante essa rodada. Logs sem `SCRIPT ERROR`, `ERROR`, `WARNING` ou falhas de asserção.

| Verificação | Resultado |
| --- | --- |
| ui_tokens_checks | 73 verificações, 0 falhas |
| campaign_checks | 206 verificações, 0 falhas |
| campaign_view_checks | 30 verificações, 0 falhas |
| controls_checks | 19 verificações, 0 falhas |
| park_checks | 1510 verificações, 0 falhas |
| art_direction_checks | 11 verificações, 0 falhas |
| binding_window_checks | PASS, cut=84 |
| hud_checks | 58 verificações, 0 falhas |
| hud_effects_checks | 18 verificações, 0 falhas |
| morro_checks | 377 verificações, 0 falhas |
| morro_map_checks | 9386 verificações, 0 falhas |
| morro_transaction_checks | 51 verificações, 0 falhas |
| player_flow_checks | 7 verificações, 0 falhas |
| journey_playthrough --with-morro | 209 verificações, 0 falhas; 8700 unidades percorridas |

O percurso automatizado percorreu campanha, exploração e batalha com entradas reais dos controladores, confirmou a vitória do boss, a devolução da rabiola de Nina, persistência após recarregar e reparo pelo professor. A execução headless não substitui uma avaliação visual completa ou teste físico com controle. Os testes usam diretórios isolados; o save do jogador foi preservado. Logs de aceite em `documentation/evidence/pip62/acceptance/`.

Sem exportar executável final, publicar na Steam/Render, fazer push ou mesclar na main. Critérios de aceite da PIP-62 cumpridos localmente na branch `godot`.

## Reprodução da validação

```powershell
$runtime = './tmp/godot-4.7.2/runtime/Godot_v4.7.2-stable_win64_console.exe'
& $runtime --headless --path godot --script res://tests/ui_tokens_checks.gd
```

As demais suítes usam o mesmo comando, substituindo o nome do script. O percurso usa `--script res://tests/journey_playthrough.gd -- --with-morro`. Nesta rodada, cada processo recebeu também `--log-file` com caminho absoluto isolado em `tmp/`.
