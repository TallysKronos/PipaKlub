# Theme Recorte · PIP-64

`recorte_theme.tres` é o Theme global do projeto Godot. `Hud.make_theme()` e `recorte_theme.gd` retornam esse mesmo recurso. Cores e fontes são exportadas a partir de `ui_tokens.gd`; não editar as cores numéricas do `.tres` à mão.

## Uso

```gdscript
const Recorte = preload("res://scripts/campaign/recorte_theme.gd")
Recorte.install(self, preferences.reduced_motion)
button.theme_type_variation = "RecorteSecondaryButton"
panel.theme_type_variation = "RecortePaperPanel"
caption.theme_type_variation = "RecortePaperText"
```

Para ações dentro de cards ou painéis, usar `Hud.focus_space(parent)` como Container do botão: o recuo de 4/32 px contém a borda inclinada, a translação e a rabiola. O espaço pertence ao layout, não à decoração. Em linhas de ações, o wrapper recebe os flags de expansão; se o botão for ocultável, sincronizar a visibilidade do wrapper para não deixar colunas vazias (ver `WorkshopView._add_action`).

A instalação adiciona `RecorteUX`, que acompanha novos controles por sinal e monta a decoração fora da medição dos Containers. Não instanciar um controlador por botão. O controlador sobrevive às trocas de tela da campanha e recebe as mudanças de “Reduzir movimento”. Limites `Node2D`, `CanvasLayer` e `SubViewport` recebem o mesmo Theme; não dependem de um skin local.

## Contrato dos estados

- Geometria em `StyleBoxFlat`: botões usam skew `(0.21, 0)` e contorno nativo de 2 px, que acompanha o preenchimento. Painéis, campos, janelas, barras e trilhos são retangulares: aplicar a inclinação a componentes altos deslocava excessivamente suas bordas. Raios zero e sombra sólida `(6,6)` em nanquim a 90%, sem blur. Barras/trilhos e pressionado não usam sombra.
- Normal/hover/foco/pressionado/desabilitado têm as mesmas margens de conteúdo. Hover e foco compartilham o estilo invertido; a rabiola fornece uma forma adicional, não apenas outra cor.
- Foco desloca a apresentação `(24,-5)` em 120 ms `TRANS_QUART/EASE_OUT`. Os alvos lógicos não mudam durante hover, evitando um ciclo de entrar/sair do cursor. Essa opção usa `offset_transform_visual_only` do Godot 4.7; a faixa de interação continua no retângulo original. Em telas de conteúdo, reservar espaço para o deslocamento visual.
- Rabiola entra com atraso de 40 ms; não há pisca-pisca ou Tween em loop. Reduzir movimento cancela o deslocamento ativo, zera a posição e usa apenas fade de 80 ms, mantendo o marcador geométrico.
- Somente painéis usam a moldura da PIP-63 num `NinePatchRect` sem centro, com cantos fixos de 12 px lógicos (escala óptica 0,25). Moldura e preenchimento compartilham a silhueta retangular. Não sobrepor essa moldura retangular aos botões inclinados.
- O painel claro tem margens laterais de 26 px e verticais de 22/24 px. Placas de nome e diálogo usam variações próprias de margens. Nos slots do menu, um MarginContainer reserva mais 32 px à direita da ação para conter o deslocamento e o marcador de foco.

## Variações semânticas

`RecorteSecondaryButton`, `RecorteTabButton`, `RecorteListButton`, `RecorteIconButton`; `RecortePaperPanel`, `RecorteDialoguePanel`, `RecorteNamePanel`, `RecorteBroadcastPanel`, `RecorteBattlePanel`, `RecorteEmptyPanel`, `RecorteTooltipPanel`; `RecortePaperText`, `RecorteMutedText`, `RecorteAccentText`, `RecorteGoldText`, `RecorteWorldText`, `RecorteTitle`, `RecorteLettering`; `RecorteXPBar` e `RecorteEnergyBar`.

`RecortePreviewHover` existe somente para apresentar o estado de hover ao lado de um foco real no laboratório. Não usar essa variação como estado de tela.

Tipos nativos cobertos: Button, Label/RichTextLabel, PanelContainer, ItemList, ProgressBar, TabBar, LineEdit, HSlider/VSlider, CheckButton/CheckBox, ScrollBar/HScrollBar/VScrollBar, TooltipPanel/TooltipLabel, Window, AcceptDialog/ConfirmationDialog e os seletores OptionButton/PopupMenu usados na demonstração.

Os marcadores SVG nesta pasta são somente formas geométricas de controles (losango, toggle e check), derivadas da paleta. Não substituem a família ilustrada de ícones/glyphs da PIP-65.

## Efeitos

- `recorte_splat_spawner.gd`: um evento cria um sprite recolorido pelo token; a sequência por semente não repete a fonte consecutiva. Espelho e rotação usam RNG local. Duração total 600 ms, máximo 12 efeitos visíveis, sem tinta permanente. Reduzir movimento elimina a rotação e usa fades; ligar a opção durante um evento encerra o que já estava ativo.
- `recorte_ink_wipe.gd`: shader com máscara numérica, 450 ms, ou fade de 80 ms. O adaptador `hud_ink_transition.gd` remove somente seu CanvasLayer temporário. A simulação e o input continuam pertencendo à tela.
- `recorte_effects.gd`: cria superfícies para retícula, linhas e wipe com material próprio por instância. As cores dos uniforms vêm dos tokens. A retícula usa `FRAGCOORD` a 45° e passo de 8 px; as linhas têm modos radial e paralelo. Nenhum shader usa `TIME` ou animação contínua. O consumidor limita linhas a 250 ms.

O spawner está demonstrado no laboratório. A integração de respingos em cada evento específico da batalha continua na PIP-69; esta tarefa não muda regras, dano ou recompensas.

## Demonstração e geração

Abrir `../components/demo_kit.tscn` e usar F6. Há alternância de 1280×720/1920×1080, modo reduzido, foco real, controles editáveis/desabilitados, seleção, sliders, barras, tooltip, diálogos e efeitos por evento. A referência de composição do laboratório é 1920×1080 e escala para a janela. O catálogo de fontes de tinta permanece em `../components/ink_catalog.tscn`.

Para reexportar: `node scripts/build-recorte-theme-icons.mjs`, importar o projeto e executar `godot --headless --path godot --script res://tools/build_recorte_theme.gd`. Os estilos nomeados ficam em `styles/`. O builder usa os tokens e quatro fontes OFL existentes; o Theme gerado é portátil e não depende do builder em runtime.
