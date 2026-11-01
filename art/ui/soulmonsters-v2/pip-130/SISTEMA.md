# PIP-130 — Mural de Kronasta: sistema base

Direção: [B ilustrada, revisão 2](../pip-128-v2/B-prancha.png), escolhida na [PIP-129](../../../../documentation/hud-v2/DECISAO.md). Primeira versão do pacote de produção: `godot/assets/ui/mural-v1/`. O nome do pacote não se refere à proposta geométrica rejeitada.

## Construção e intensidade

A assinatura combina cartaz impresso de contorno desenhado, dobra/reforço de papel e registro de tinta. Amarrações e presilhas pertencem às peças fixas. As escolhas usam cartazes mais expressivos; superfícies altas de consulta usam borda calma para não repetir rasgos junto aos números. Os ícones são ilustrações próprias com contorno e sombra chapada, não símbolos genéricos substitutos.

Foram produzidos três atlases por ferramenta integrada de imagem: seis suportes/ornamentos, 12 ícones e três painéis altos; depois, uma edição específica da faixa corrigiu seus cantos expansíveis. As artes foram inspecionadas antes do corte. `geracao.json` registra referências e saídas; os três prompts estão nesta pasta. `slice_assets.py` só faz cortes mecânicos, enquadramento por alpha, redução proporcional e padding transparente; não redesenha personagens nem modifica a paleta. As fontes originais permanecem em `fontes/`.

### Famílias de suporte

| Peça | Função e limite |
| --- | --- |
| `paper`, `selected`, `ink` | Cartazes compactos: normal, foco/hover e pressionado. Não usar como grande painel vertical. |
| `title-paper`, `title-sun` | Cabeçalhos de contexto; não usar para todos os números. A presilha da faixa clara fica no canto fixo. |
| `clips` | Ornamento separado, opcional; não esticar junto ao conteúdo. |
| `board-paper`, `board-ink`, `board-sun` | Superfícies grandes, com cantos ilustrados e trechos retos expansíveis. |

O recorte para peças compactas usa margens de textura 28/36/28/28 px (esquerda/cima/direita/baixo), no arquivo reduzido. Painéis altos usam 60 px em cada lado. A faixa clara ativa é `title-paper-v2`: margens 112/55/96/28 px. A presilha e o pequeno registro vermelho ficam inteiros nos cantos superiores fixos; só papel vazio participa da expansão. A peça anterior permanece como histórico, sem uso pelo Theme. O centro acompanha o conteúdo; cantos, ícones e presilhas não são reescalados pelo comprimento do texto. A repetição vertical de rasgos foi reprovada na revisão e removida com o atlas de painéis próprios.

Na revisão da faixa, o dono apontou um detalhe vermelho esticado: o corte direito de 28 px deixava parte dele na área central, e a decoração também atravessava o corte vertical. Foi produzida uma versão específica com o registro restrito ao canto superior e corte direito de 96 px. `title-corners-prompt.txt` e `fontes/title-paper-corners-source.png` preservam a edição. A prova `faixa-larguras.png` compara 400, 760 e 1.200 px; o teste do Theme verifica que os pixels vermelhos ficam fora das duas faixas expansíveis.

## Paleta semântica

As cores continuam centralizadas em `godot/scripts/campaign/ui_tokens.gd`, agora com o namespace `MURAL_*`. Os aliases antigos permanecem para as telas ainda não migradas.

| Token | Valor | Papel |
| --- | --- | --- |
| `MURAL_INK` | `#123442` | Texto, desenho e estrutura |
| `MURAL_PAPER` | `#fff1d2` | Superfície de leitura / texto inverso |
| `MURAL_SUN` | `#ffc53e` | Foco e chamada |
| `MURAL_MINT` | `#77d0bc` | Variação de cartaz / vínculo contextual |
| `MURAL_TEAL` | `#126c76` | Linha e informação positiva sobre papel |
| `MURAL_RED` | `#ad382c` | Erro com rótulo explícito |
| `MURAL_MUTED` | `#496261` | Texto secundário sobre papel |
| `MURAL_GROUND` | `#0c2530` | Fundo de laboratório / véu escuro |

Os rasters têm variação de tinta/grão própria. A análise técnica registra pares dos tokens e amostras centrais das peças em `documentation/hud-v2/pip-130/contraste.json`, sem afirmar certificação de acessibilidade. Ink/paper: 11,76:1; ink/sun: 8,34:1; secundário/paper: 5,86:1. As cores não são o único sinal de estado.

## Tipografia

| Papel / variação de Theme | Fonte local | Base |
| --- | --- | --- |
| `MuralTitle` | Bangers | 38 px; lettering de títulos |
| `MuralHeading` | Barlow Condensed Bold | 28 px; seção e nome |
| `MuralButton` | Barlow Condensed Bold | 25 px; destinos e ações |
| `MuralBody` | Nunito | 20 px; conteúdo e valores |
| `MuralCaption` | Nunito | 18 px; apoio e instrução |

Fontes carregadas pelos tokens existentes; licenças OFL locais preservadas. Não há nova fonte proprietária. Valores, nomes e falas continuam nativos; letras desenhadas nos concepts não são assets de texto. O laboratório usa texto ampliado a 150%, redistribuição e rolagem; não reduz toda a tela por escala uniforme para caber.

## Ícones

`team`, `bag`, `missions`, `emblems`, `identity`, `workshop`, `save`, `settings`, `dex`, `evolution`, `varal`, `puxao`: 12 PNGs RGBA de 256×256. Optical area até 224×224, com redução filtrada e mipmaps. Após a revisão do dono sobre ícones pequenos, os botões usam uma ilustração independente de **96×96 px** (aproximadamente 84 px de desenho visível), saindo cerca de 10 px à esquerda e 6 px acima do papel. Contorno claro e sombra curta destacam o recorte. Texto começa a 92 px, sem ocupar a ilustração. As divisões do atlas seguem seus gutters reais, com correções na primeira linha para não incluir fragmentos dos vizinhos. Os nomes e rótulos ficam fora das imagens.

O recorte grande não é o `Button.icon` nativo, que diminuía conforme a altura do conteúdo. É um TextureRect sem captura de input. A parte exposta continua clicável por `_has_point()`. Reserve ao menos 12 px à esquerda e 8 px acima do cartão para o desenho/sombra; o ancestral de layout não deve recortar esses limites. ScrollContainer continua recortando somente nos limites do viewport, como esperado. A navegação, confirmação e foco continuam pertencendo ao Button.

O ícone de emblema é a categoria de menu, não define nem concede uma das 12 insígnias. O retrato pequeno da identidade é um ícone ilustrado; telas de perfil continuam devendo usar o retrato canônico apropriado. O desenho de evolução não adiciona uma evolução aos dados.

## Estado e interação

- Normal: cartaz claro, menta ou escuro, conforme a variação semântica.
- Hover: cartaz amarelo, sem roubar o foco do teclado.
- Foco: cartaz amarelo e marcador estático em forma de pipa. Não exige animação para comunicar seleção.
- Pressionado: cartaz escuro e texto claro, inclusive quando o ponteiro permanece sobre ele.
- Indisponível: leitura atenuada, rótulo explícito e remoção da navegação. Mudanças de disponibilidade usam `set_available()`.
- Erro e carregamento: mensagens nativas explícitas; exemplos rotulados no laboratório, sem simular um serviço real.

Linha é fio contínuo com ponta; Armação tem nervuras diagonais; Energia tem células. Cada recurso mantém nome e valor. A classe de medidor deriva de Range e limita valores a 0–100. Estes medidores usam superfície clara; uma futura aplicação sobre fundo escuro deve fornecer a variante inversa apropriada, não reaplicar a tinta escura sem análise.

Teclado, controle e mouse passam pelos controles nativos. O código de prompts/bindings existente é reaproveitado. O laboratório não implementa uma pilha paralela de menus, sessão ou salvamento de campanha. Redução de movimento mantém a mesma leitura porque o foco desta fundação é estático; entrada/saída e sons serão tratados nas etapas de tela/PIP-137.

## Theme e adoção

`godot/tools/build_mural_theme.gd` gera `mural_theme.tres` reutilizando a cobertura do Theme anterior e sobrescrevendo a semântica Mural. A fachada `scripts/ui_mural/mural_theme.gd` compartilha a instância e os ícones. Variações novas incluem botões, foco, superfícies, títulos, texto inverso/erro e barras. Botões nativos, campos, abas, listas, popups e barras têm overrides de base; variantes Recorte antigas não são a API de arte nova.

Esta entrega é **opt-in**. Não altera o Theme global no projeto, cenas da campanha, navegação de jogo, recompensas ou saves. O laboratório está em `godot/scenes/mural_lab.tscn`; as tarefas de tela aplicarão o sistema progressivamente. A PIP-131 trabalha marca/título; PIP-132 a PIP-137 fazem as migrações por família.

## Reprodução

Da raiz do repositório:

```powershell
python art/ui/soulmonsters-v2/pip-130/slice_assets.py
godot --headless --path godot --editor --import --quit
godot --headless --path godot --script res://tools/build_mural_theme.gd
godot --headless --path godot --script res://tests/mural_theme_checks.gd
godot --path godot res://scenes/mural_lab.tscn
```

O corte requer Pillow; o laboratório só requer Godot. `tools/mural_lab_capture.gd` requer renderização real (não `--headless`) e produz 20 capturas nas quatro resoluções. As configurações de importação dos ícones com mipmaps fazem parte do pacote versionado.
