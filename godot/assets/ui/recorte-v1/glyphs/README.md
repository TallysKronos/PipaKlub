# Glyphs de entrada · PIP-65

Derivados CC0 do Kenney Input Prompts 1.5A. Fonte, versão e hashes por arquivo no `manifest.json`; licença original em `godot/licenses/kenney-input-prompts-CC0.txt`. Adaptação: caminhos recoloridos pela paleta Recorte e keycap de papel com contorno nanquim.

Famílias: `kbd/`, `xbox/`, `ps/`, `switch/`. Os identificadores de controle são posicionais (`south`, `east`, `west`, `north`), não letras de Xbox reutilizadas em outros controles. `controls.gd` resolve a ação e a tecla remapeada. A escolha manual de família fica em Configurações para identificação genérica/Steam Input.

Nintendo confirma/interage com A à direita (`east`) e volta/esquiva com B embaixo (`south`). Corte à esquerda mostra Y; habilidade em cima mostra X. As rotas de UI e campanha são instaladas por dispositivo, preservando teclado e outros controles.

Usar `Hud.input_hint(parent, action, caption)` em controles nativos ou `Controls.glyph(action)` para desenho no Canvas. Hints escutam `Controls.events.changed`; não criar um poll de input por widget. Não embutir nomes de duas plataformas no mesmo prompt.

Prancha `../mockups/glyphs.png`; laboratório `../components/demo_icons.tscn`. PNGs em `png64/` são auxiliares da prancha e excluídos do pacote final. A prévia de cada família não equivale a validação com controle físico.
