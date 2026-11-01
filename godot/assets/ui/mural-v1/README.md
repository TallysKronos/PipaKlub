# Mural de Kronasta — fundação PIP-130

Sistema ilustrado opt-in. Guia: `art/ui/soulmonsters-v2/pip-130/SISTEMA.md`. Cenas atuais do jogo mantêm o Theme anterior até as tarefas de migração.

```gdscript
const Mural = preload("res://scripts/ui_mural/mural_theme.gd")
const MuralButton = preload("res://scripts/ui_mural/mural_button.gd")

func _ready() -> void:
    Mural.install(self)
    var button := MuralButton.new()
    button.text = "Oficina"
    button.icon_id = "workshop" # configure antes de adicionar à árvore
    button.variant = "MuralMintButton"
    $Destinos.add_child(button)
    button.pressed.connect(abrir_oficina)
    # Para mudar disponibilidade em runtime e manter a navegação coerente:
    button.set_available(false)
```

Variações de botão: `MuralButton`, `MuralMintButton`, `MuralInkButton`, `MuralSunButton`; foco usa `MuralFocusButton`. `MuralButton` é um Button real, não uma imagem clicável: mantém sinais, input e hitbox nativos. Não instalar `RecorteUX` sobre a mesma subárvore Mural, pois ele acrescenta a decoração antiga.

Painéis: `MuralPaperPanel`, `MuralInkPanel`, `MuralSunPanel`, `MuralTitlePanel`. Ao usar superfície escura, escolha texto `MuralInverseText`. Não colocar ícones ou presilhas no trecho expansível de um slice.

Fontes: `MuralTitle`, `MuralHeading`, `MuralBody`, `MuralCaption`; textos semânticos `MuralMutedText`, `MuralInverseText`, `MuralErrorText`, `MuralSuccessText`. Os nomes das variações são de Theme para controles nativos.

`manifest.json` contém recortes, dimensões e hashes. Originais/prompts: `art/ui/soulmonsters-v2/pip-130/`. Este pacote não é o HUD-KIT v2 final da PIP-139.
