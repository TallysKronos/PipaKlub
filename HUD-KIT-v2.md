# Soulmonsters · HUD-KIT v2

Guia de implementação Godot da direção **B — Mural de Kronasta**, consolidado em 02/11/2026, na branch `codex/hud-identidade-soulmonsters`. Este arquivo orienta as telas futuras da campanha PIP-91. O [kit anterior](HUD-KIT.md) continua documentando o cliente web; não foi renomeado como se fosse o sistema Godot.

Estado: componentes integrados e guia disponível localmente; o aceite final da PIP-139 depende do relatório da auditoria e do teste humano externo. Não significa aprovação de merge, publicação, hardware ou migração de todos os consumidores antigos. Veja [auditoria final](documentation/hud-v2/pip-139/REVISAO.md) e [decisão B](documentation/hud-v2/DECISAO.md).

## 1. Identidade e dosagem

A HUD é feita de cartazes de bairro, tinta, papel aplicado, linha, vareta, presilha e marcas de oficina. O traço é mangá 2D autoral: contorno expressivo e sombra chapada, sem brilho plástico ou volume 3D. O cenário permanece visível; ornamentos dão personalidade às bordas, não ocupam a leitura.

| Uso | Matéria / intensidade | Evitar |
| --- | --- | --- |
| Exploração | Pequenas placas, parceiro, interação e objetivo; centro livre | Mural grande permanente sobre o mundo |
| Pausa | Destinos ilustrados, ícones que saem do papel, descrição da seleção | Grade de retângulos idênticos sem função visual |
| Varal | Tecido e etiquetas, coleção de vínculos | Repetir o catálogo claro da Dex |
| Dex e evolução | Fichário e pesquisa, trilho do Elo, dados verificáveis | Inventar espécies ou evoluções para preencher a prancha |
| Emblemas | Estojo e doze encaixes, marca conquistada versus espera | Exibir conquistas não presentes no save |
| Diálogo | Retrato autoral e papel de leitura limpo, nome separado | Faixa de campeonato para cada fala |
| Boss | Warning vermelho/preto, retrato, nome; HUD própria | Card amarelo genérico para todo evento |
| Enroscada | Sinal menta e instrução contextual de corte | Confundir oportunidade de ação com aviso de boss |
| Resultado | Manchetes próprias para vitória, derrota e recuo | Reutilizar a mesma festa e cor em todos os resultados |
| Item / insígnia / nível | Momento curto, ícone/arte nativa, informação confirmada | Dar recompensa por animação ou chamar toda obtenção de “Key Item” |
| Transição | Cortina de tinta com recorte, pipa e texto de carregamento | Percentual fictício ou espera mínima sem trabalho real |

O teste de identidade usa capturas sem logo. Uma avaliação do próprio autor não substitui a resposta de alguém que não conhece o projeto. [Conjunto de dez telas](documentation/hud-v2/pip-139/teste-cego/index.html).

## 2. Tokens e fontes

Fonte de verdade em [ui_tokens.gd](godot/scripts/campaign/ui_tokens.gd). Para telas novas, use `MURAL_*`; os aliases Recorte permanecem para compatibilidade, não são uma segunda paleta para misturar livremente.

| Token | Hex | Uso |
| --- | --- | --- |
| `MURAL_INK` | `#123442` | Texto sobre papel e sol |
| `MURAL_PAPER` | `#fff1d2` | Papel / texto claro sobre tinta |
| `MURAL_SUN` | `#ffc53e` | Seleção e chamada positiva |
| `MURAL_MINT` | `#77d0bc` | Elo e acento sobre fundo escuro |
| `MURAL_TEAL` | `#126c76` | Ênfase legível sobre papel |
| `MURAL_RED` | `#ad382c` | Erro sobre papel; warning tem arte própria |
| `MURAL_MUTED` | `#496261` | Texto secundário opaco sobre papel |
| `MURAL_GROUND` | `#0c2530` | Base escura e transição |

Não usar branco como modulação de texto por hábito. `UNTINTED` mantém a cor de um sprite; não representa tinta de interface. O nanquim legado `NANQUIM` tem uso localizado no campo de texto do warning para contraste, sem substituir a direção do resto da tela.

| API em Tokens | Família local | Papel |
| --- | --- | --- |
| `text()` | Nunito | Fala, explicação e leitura longa |
| `label()` | Barlow Condensed Bold, números tabulares | Rótulos, valores, controles |
| `display()` | Lilita One, cisalhamento tipográfico de 8° | Títulos de impacto; não girar a linha de base |
| `lettering()` | Bangers | Onomatopeia pontual; não corpo de texto |

Arquivos e quatro licenças OFL em `godot/assets/campaign/ui-modern/fonts/`. Escalas de preferência: **100%, 115%, 130%, 150%**, via `Preferences.TEXT_SCALES`. Fonte cresce independentemente da arte. O padrão do corpo do diálogo é 24 px antes da escala; opções, 22 px; botões de consulta normalmente 20 px. Preserve as medidas do componente escolhido em vez de impor um tamanho único.

## 3. Theme, propriedade e herança

Theme: [mural_theme.tres](godot/assets/ui/mural-v1/theme/mural_theme.tres). Acesso e cache: [mural_theme.gd](godot/scripts/ui_mural/mural_theme.gd).

Uma raiz Mural declara `set_meta("owns_ui_theme", true)` em `_init()`, antes de entrar na árvore, e chama `Mural.install(self)` em `_ready()`. Isso impede que o decorador de compatibilidade `RecorteUX` injete moldura ou aplique a escala novamente. Instalar o Theme sozinho não marca a propriedade.

Receba `text_scale` e `reduced_motion` do consumidor antes de `add_child`. `Mural.text_scale_for(node)` consulta `hud_text_scale` nos ancestrais; não lê preferências do disco. Não sobrescreva preferências ou pause globalmente em um componente de desenho. O `front_end.gd` coordena navegação, pausa, prontidão e a sessão.

Variações de Theme: `MuralPaperPanel`, `MuralInkPanel`, `MuralSunPanel`, `MuralTitlePanel`, `MuralHudPanel`, `MuralHudInkPanel`; `MuralButton`, `MuralMintButton`, `MuralInkButton`, `MuralSunButton`, `MuralFocusButton`; `MuralBody`, `MuralCaption`, `MuralHeading`, `MuralTitle`, `MuralMutedText`, `MuralInverseText`, `MuralErrorText`, `MuralSuccessText`. Texto em superfície escura precisa da tinta inversa explícita.

## 4. Margens e recortes

O limite externo da ilustração **não** é a área de leitura. Reserve o canto fixo e depois o respiro. [Contrato de área segura](documentation/hud-v2/AREA-SEGURA.md).

| Componente | Regra real |
| --- | --- |
| Papel compartilhado | `Paper.inset(density) = ceil(60 × density + 8)` |
| Papel de batalha, densidade 0,35 | 29 px internos |
| Ações, densidade 0,30 | 26 px internos |
| Menus ilustrados | `MenuArt.padding(family) = ceil(corte × densidade) + 10`, por lado |
| Etiqueta do Varal | Densidade 0,15; cortes próprios |
| Famílias de menu | Densidade 0,24; cortes próprios |
| Loading e botão de pular | 24 px até a borda do viewport lógico |
| Resultado | Layout próprio em `result_art.gd`; não usar o inset genérico |
| Eventos | Área própria em `event_art.gd`; preservar nó e caps laterais |

Os quatro cortes são **esquerda, direita, topo, baixo** em pixels da imagem fonte:

| Família de menu | Cortes |
| --- | --- |
| `cloth` | 300, 220, 170, 240 |
| `dex` | 220, 240, 150, 230 |
| `evolution` | 260, 230, 200, 220 |
| `case` | 220, 220, 170, 170 |
| `tag` | 300, 300, 140, 120 |

Use [menu_art.gd](godot/scripts/ui_mural/menu_art.gd), sem duplicar esses números em uma tela nova. Só o miolo pode expandir. Não alongue presilha, nó, rasgo ou retrato. Meça ascendente/descendente e linhas com a fonte real. Se não couber, reorganize, aumente ou role; não comprima letras junto com o PNG.

O jogo pode usar stretch de canvas. Diferencie pixels do viewport lógico das dimensões físicas do PNG. As capturas de campanha registram ambos. A auditoria responsiva dos componentes também exercita viewports sem stretch para conferir os quatro layouts explicitamente.

## 5. Componentes reais e consumidores

| Função | Implementação | Contrato |
| --- | --- | --- |
| Destino ilustrado | [mural_button.gd](godot/scripts/ui_mural/mural_button.gd) | `icon_id`, `variant`, `set_available`; Button nativo |
| Opção limpa com foco | [dialogue_option.gd](godot/scripts/ui_mural/dialogue_option.gd) | `text_scale`, `font_base`, `density`, `selected`; ponteiro estático e texto nativo |
| Etiqueta do Varal | [hanging_tag.gd](godot/scripts/ui_mural/hanging_tag.gd) | Herda Option; arte e padding de `tag` |
| Superfície medida | [menu_surface.gd](godot/scripts/ui_mural/menu_surface.gd) | PanelContainer com margem nativa; `family` ou `variant/density` |
| Texto em canvas | [paper_layout.gd](godot/scripts/ui_mural/paper_layout.gd) | `content`, `height`, `label`, auditoria opt-in; elipse consciente |
| Exploração | [hud_exploration.gd](godot/scripts/campaign/hud_exploration.gd) | Consulta mundo/parceiro; emite ação, não altera o modelo |
| HUD de batalha | [battle_hud.gd](godot/scripts/ui_mural/battle_hud.gd) | Regiões, barras e leitura do combate; energia rival não é inventada |
| Enroscada | [enroscada.gd](godot/scripts/ui_mural/enroscada.gd) | Disponibilidade derivada de contato/energia/recarga reais |
| Warning / VS | [boss_presentation.gd](godot/scripts/campaign/boss_presentation.gd), [champion_vs.gd](godot/scripts/ui_mural/champion_vs.gd) | Texto ampliado, skip e bloqueio coordenado pelo encontro |
| Diálogo | [hud_dialogue.gd](godot/scripts/campaign/hud_dialogue.gd) | Retrato, paginação, escolhas, confirmar/cancelar uma vez |
| Coleção / Dex / evolução | [partner_album.gd](godot/scripts/ui_mural/partner_album.gd) | `mode` e player/content; emite equipar/cuidar; não concede nada |
| Doze emblemas | [hud_emblem_case.gd](godot/scripts/campaign/hud_emblem_case.gd) | Conquistado/pendente, filtro, detalhes e contagem do save |
| Resultado | [hud_result_header.gd](godot/scripts/campaign/hud_result_header.gd), [hud_reward_card.gd](godot/scripts/campaign/hud_reward_card.gd) | Três manchetes; prévia explícita, confirmar e persistir no consumidor |
| Item / emblema / nível | [hud_key_item_banner.gd](godot/scripts/campaign/hud_key_item_banner.gd) | `moment`, nome e textura; não grava recompensa |
| Loading | [hud_scene_loading.gd](godot/scripts/campaign/hud_scene_loading.gd) | `await cover()` → construir → primeiro frame → `await reveal()` |
| Revelação curta | [hud_ink_transition.gd](godot/scripts/campaign/hud_ink_transition.gd) | Possui apenas a sua camada temporária |

### Ícones salientes

`MuralButton` desenha a ilustração em camada própria de **96×96**, na posição **(-16,-12)**. Reserve espaço fora do card; o texto tem recuo de 92 px no Theme. Não recorte a ilustração com `clip_contents` num ancestral sem gutter. A área exposta é clicável; a TextureRect filha ignora input. Use `set_available(false)` para sincronizar aparência, foco e disponibilidade. Não troque o sprite por emoji.

IDs: `team`, `bag`, `missions`, `emblems`, `identity`, `workshop`, `save`, `settings`, `dex`, `evolution`, `varal`, `puxao`. As imagens ficam em `godot/assets/ui/mural-v1/icons/`.

## 6. Input, foco e modal

Controles funcionais são Button, ScrollContainer, Range e Label nativos. Toda decoração ignora mouse e foco. Conecte sinais às operações existentes no consumidor; não execute operações de save ou combate em `_draw()`.

- Instale ações pelo [controls.gd](godot/scripts/campaign/controls.gd); use prompts/glyphs dessa API, sem escrever A/B ou Enter fixos por tela nova.
- Foco inicial deve alcançar a ação esperada. Tab, Shift+Tab e direcional têm caminho de volta. `follow_focus` mantém o alvo dentro do scroll.
- Navegar, hover e seleção não podem equipar ou comprar por si sós. Confirmação emite a intenção uma vez.
- Fechar modal restaura a origem se ela ainda existir. Escape/cancelar não dispara movimento ou golpe por baixo.
- Botões indisponíveis não viram foco inicial. Cor é complementar: marcador, cadeado, texto ou estado explícito permanecem sem animação.
- O dono da cena decide pausa e desbloqueio. Loading bloqueia input até a revelação; transição curta decorativa não captura input.

## 7. Movimento, tempo e som

Texto funcional não treme, gira nem respinga. Reduced motion mantém as informações, não reduz seu tempo de leitura.

| Evento | Modo normal | Movimento reduzido |
| --- | --- | --- |
| Loading | Fecha 140 ms; sai à esquerda em 320 ms após prontidão | Fade 80/100 ms, símbolo estático |
| Revelação curta | 280 ms | Fade 100 ms |
| Dano | Efeito até 600 ms | Número estático até 800 ms; fade final de 200 ms |
| Item | 2,5 s | Mesma informação, sem impacto/deslocamento |
| Insígnia | 3 s | Mesma informação, sem impacto/deslocamento |
| Nível | 1,7 s, após gravação | Mesma informação, sem impacto/deslocamento |
| Intro de boss/campeão | Pode ser pulada; combate aguarda término e liberação do input | Aviso continua disponível, sem exigir movimento |

Som: [sound_director.gd](godot/scripts/campaign/sound_director.gd), [catálogo](godot/assets/audio/sfx-v1/catalog.json). Buses Master, UI, SFX, Ambience, Music. O controle zero silencia; sliders convertem ganho ao mixer. Não restabeleça volume do jogador ao terminar um efeito.

`ui.focus/confirm/cancel` identificam navegação; `world.transition` é feedback de UI a −5 dB, sobrevive à troca e não se repete em menos de 650 ms. Salvar checkpoint sozinho não toca viagem. Um lote de recompensas usa o jingle de maior prioridade: nível, missão, tutorial, objetivo, descoberta, item, XP, moedas. `progress.save_error` cancela comemoração pendente. Som importante sempre tem informação visual.

Não use `play_event` para esconder um estado ausente no modelo. Não duplique o jingle no observer e no banner. As amostras não são certificação da mixagem em hardware.

## 8. Dados e persistência

Uma tela consulta `session.snapshot()` ou uma fixture. Nomes, dinheiro, XP, emblemas e coleção derivam desse dado. Imagem gerada nunca contém texto variável ou define nova regra de progresso.

Resultado de batalha pode mostrar a recompensa prevista, marcada como prévia. O ato de continuar passa pela operação de settlement existente. Nível só comemora depois do save confirmado. Duplo clique, tecla segurada ou retorno ao encontro não pode dar recompensa novamente. Falha deixa recuperação acessível e impede uma falsa celebração.

Conservar os IDs/operações atômicas do modelo. Não ajustar XP, encontros ou economia para o texto caber no painel.

## 9. Criar uma tela para PIP-91

1. Identifique a tarefa do jogador, consumidor real, dados, vazio/cheio, indisponível, loading e erro. Escolha uma família pela função, não pela cor favorita.
2. Declare a propriedade de Theme no `_init`, instale o Mural e receba escala/movimento antes da árvore.
3. Monte conteúdo em Containers e safe areas. Para consulta, `MenuSurface` mede as bordas; para canvas, use o layout da família correspondente.
4. Conecte intenções ao fluxo existente. Prove foco inicial, retorno, pausa, input sob overlay e scroll.
5. Capture quatro resoluções, texto 100/150%, strings longas e estados relevantes. Testes headless não demonstram leitura visual.
6. Atualize o inventário do consumidor, proveniência da arte, galeria e relatório. Separe aprovação visual, verificação automática e publicação.

Padrão mínimo de raiz:

```gdscript
extends Control
const Mural = preload("res://scripts/ui_mural/mural_theme.gd")
const Surface = preload("res://scripts/ui_mural/menu_surface.gd")
const Option = preload("res://scripts/ui_mural/dialogue_option.gd")
var text_scale := 1.0
var reduced_motion := false
signal closed

func _init() -> void:
    set_meta("owns_ui_theme", true)

func _ready() -> void:
    text_scale = maxf(text_scale, Mural.text_scale_for(self))
    Mural.install(self)
    # Containers, margem externa e dados são definidos pela tela consumidora.
    # Surface.family = "dex" escolhe a superfície; Option.text_scale recebe
    # a escala antes de add_child. O consumidor conecta closed e faz o retorno.
```

Isso é um padrão de integração, não uma tela pronta nem autorização para trocar qualquer consulta pelo catálogo da Dex. Prefira reutilizar um componente completo da tabela quando ele já resolver o caso.

## 10. Antiexemplos e revisão

| Incorreto | Correto |
| --- | --- |
| Escalar PNG inteiro para caber no botão | Preservar caps e expandir o miolo |
| Texto encostado no limite do losango/papel | Área segura calculada depois dos ornamentos |
| Aplicar RecorteUX e Mural na mesma subárvore | Propriedade explícita e uma aplicação de escala |
| Usar amarelo para boss, seleção, emboscada e vitória | Funções com silhuetas e matérias distintas |
| Exigir hover para ler dado essencial | Mostrar informação ou permitir consulta por foco |
| Fazer item raro aparecer porque a animação terminou | Gravar no modelo e só depois apresentar |
| Esconder texto longo reduzindo fonte | Reflow, rolagem e elipse apenas onde consciente |
| Contar texto invisível sob scroll como vazamento | Medir recorte real; foco cortado continua falha |
| Aprovar a HUD inteira porque um laboratório passou | Capturar consumidores reais e registrar lacunas |

## 11. Auditoria e estado de adoção

Matriz de referência: 1280×720, 1920×1080, 1024×768 e 1280×800; 100/150% de texto; teclado, mouse e controle simulado. Nenhuma resolução comprova Switch/TV ou controle físico. Meta interna: texto comum 4,5:1; contraste medido nas regiões reais, não só hexadecimais. [Resultados de contraste](documentation/hud-v2/pip-138/contraste.json).

Comandos nativos de campanha:

```powershell
& ./godot/Godot_v4.7.2-stable_win64_console.exe --path godot `
  --script res://tools/capture_campaign.gd --rendering-method gl_compatibility `
  -- --shots=live,boss,victory,team,dex --width=1024 --height=768 --audit --reduced-motion
& C:/pinokio/api/comfy.git/app/env/Scripts/python.exe tools/run_mural_final_audit.py
```

O caminho do Python acima é o ambiente disponível nesta máquina; em outra máquina use um Python com Pillow. O runner não baixa nem versiona o executável do Godot. `capture_campaign.gd` usa armazenamento temporário isolado; não altera o save do jogador. Os relatórios separam controles nativos, glifos instrumentados de canvas e famílias de desenho manual.

Implementações Mural: título, exploração, Kronasta, combate, diálogo, lobby, Varal/Dex/evolução, estojo, resultado e transições. Existem consumidores de compatibilidade com desenho próprio ou Recorte, incluindo identidade, bolsa, configurações, controles, oficina e lição. Sua existência não autoriza declarar toda a migração visual concluída. [Inventário e destino das tarefas antigas](documentation/hud-v2/ABSORCAO-PIP-61.md) e [relatório final](documentation/hud-v2/pip-139/REVISAO.md) registram o que foi observado e o que ainda exige aceite.

Arte-fonte e prompts: `art/ui/soulmonsters-v2/`. Assets de runtime: `godot/assets/ui/mural-v1/`. Preserve originais, versões aprovadas, hashes e licenças; não apague a proveniência ao substituir uma peça.
