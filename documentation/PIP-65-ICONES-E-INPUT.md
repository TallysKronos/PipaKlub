# PIP-65 · Ícones Recorte e símbolos de entrada

Revalidação de 26/10 na branch `tallysroberto/pip-66-65-textos-icones-glyphs`. Suítes e percurso completo executados com autorização explícita do pedido anexado. Sem merge ou deploy. A identificação e as rotas de controle foram exercitadas por eventos normalizados; não houve controle físico conectado.

## Família visual

70 ícones originais em `godot/assets/ui/recorte-v1/icons/`, com SVG em grade de 48 px, PNG de 96 px e variantes `world/` com borda externa de papel. Paleta obtida dos tokens da PIP-62. Formas chapadas, contorno nanquim, uma cor de acento e pequeno brilho; símbolos abertos têm miolo de papel para não desaparecerem sobre tinta. Não existe texto pintado nos ícones de jogo. Localização e setas da rajada substituem os símbolos de texto no minimapa e na bancada. Prancha também em `godot/mockups/icones.png`, no caminho solicitado.

A lista inclui navegação, inventário, opções, recursos, ações de batalha, Pulo do Elo, Nó de Vendaval e Ruptura dos Canos. A busca solicitada na versão web confirmou quatro tipos de combate em `src/engine.js:23`: Precisa, Ágil, Guardiã e Técnica. `src/dex-client.js` apresenta os mesmos tipos por `eng.types[entry.color]`; não existe tabela de seis elementos no manual nem nesse consumidor web. Foram desenhados os quatro tipos existentes, sem inventar regras ou nomes elementais. A referência a seis elementos na especificação precisa de definição de produto se representar conteúdo futuro.

`recorte_icons.gd` resolve aliases legados para essa família; `Hud.icon()` e `BattleInk.icon()` deixaram de carregar os SVGs antigos. Listas do inventário usam símbolos Recorte; as ilustrações de itens na área de detalhe continuam como arte de conteúdo, separadas dos ícones de interface. A abertura de novas jornadas usa uma pipa, não o carretel ampliado.

Para ícones maiores que 48 px, usar `Hud.icon(id, true)`, que carrega o derivado de 96 px. Para símbolos diretamente sobre o mundo, usar `Hud.Icons.texture(id, true)`. SVG não é texto nem área de interação; controles nativos continuam recebendo foco e cliques.

## Glyphs de entrada

155 derivados vetoriais do **Kenney Input Prompts 1.5A**, CC0, obtido da página oficial: <https://kenney.nl/assets/input-prompts>. Licença original preservada em `godot/licenses/kenney-input-prompts-CC0.txt`; caminhos de origem e hashes por SVG no manifesto de glyphs. Foram recoloridos e receberam keycap de papel/contorno nanquim. SVGs em `glyphs/{kbd,xbox,ps,switch}/`; os PNGs auxiliares `png64/` são usados só nas pranchas.

- Teclado: teclas remapeadas, letras, números, funções e teclas especiais disponíveis no pacote. Se um código não tiver figura pronta, o texto real da tecla continua disponível; não é apresentado o símbolo antigo de outra tecla.
- Xbox: A/B/X/Y, ombros, gatilhos, analógicos, View e Menu.
- PlayStation: símbolos próprios; Select/Share/Create e Start/Options conforme a geração identificada.
- Switch: Pro Controller e Joy-Cons pareados. Interagir e confirmar usam A à direita; esquiva e voltar usam B embaixo. Corte continua à esquerda, com glyph Y; habilidade continua em cima, com glyph X. Inclui L/R, ZL/ZR, +/− e analógicos. Isso adiciona suporte ao controle, não um port para o console.

Mapeamento posicional conferido na documentação da versão 4.7: <https://docs.godotengine.org/en/4.7/classes/class_@globalscope.html#enum-globalscope-joybutton> e no driver SDL da versão exata: <https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/sdl/joypad_sdl.cpp>. Godot recebe índices normalizados por posição: 0 embaixo, 1 à direita. A inversão Nintendo ocorre nos bindings da aplicação, não na base SDL. `configure_device()` instala bindings por dispositivo antes de seu primeiro comando; a conexão física alimenta esse método por `get_joy_name()/get_joy_info()`. Teclas, setas, eixos e bindings de outros controles são preservados. `ui_accept` e `ui_cancel` recebem a mesma convenção.

`Controls.observe()` acompanha o último dispositivo usado, distingue família pelo nome/ID do fabricante e atualiza apenas quando a apresentação muda. Só o ID do fabricante é consultado no dicionário de informações do controle; nada é gravado sobre o hardware. `input_events.gd` notifica os hints por sinal, incluindo alterações de teclas. A batalha já redesenha por frame e consulta o cache de texturas.

Configurações oferece `Símbolos do controle`: Automático, Xbox, PlayStation ou Nintendo Switch. Essa preferência é local e separada dos slots. Serve também para Steam Input/dispositivos genéricos que não expõem a identidade real. Não muda os bindings. Falha ao gravar restaura a escolha anterior e mostra o aviso existente.

## Integração e revisão

Símbolos integrados em menus, pausa, configurações/controles, botões de batalha e prompts de interação das áreas de exploração. `RecortePromptPanel` reserva espaço para a figura sem alterar a medição do texto ou sua área de clique. Detalhes de composição mais amplos das telas continuam nas respectivas tarefas do épico.

- Importação e compilação no Godot 4.7.2 oficial, Compatibility/OpenGL.
- Prancha `mockups/icones.png`: todos os ícones em 24/48/96 px sobre tinta e céu claro. `mockups/glyphs.png` deriva os botões das rotas reais de `controls.gd`, exportadas em `input-routes.json`, sem duplicar um mapeamento manual.
- Laboratório `components/demo_icons.tscn`: prévia por família, remapeamento de Corte para Z e opção para ouvir entrada real. Não cria campanhas nem grava preferências. As capturas por CLI são **prévias de apresentação**, não comprovam reconhecimento de hardware físico.
- Quatro capturas do laboratório; a de teclado mostra Corte remapeado para Z. Metadados registram família, rótulo e ID do glyph.
- Oito telas da campanha renderizadas em 1280×720 e 1920×1080, usando fixtures e armazenamento isolados: menu, configurações, controles, starter, batalha, mochila, parque e Morro. Sem erros de execução nos logs. O instrumento reportou somente linhas parcialmente visíveis em listas roláveis de Controles e Mochila; os itens continuaram alcançáveis por foco.

Revalidação autorizada: `controls_checks.gd` passou com 44 verificações, incluindo identificação Xbox/PS/Switch/genérico, glyph de tecla remapeada, eventos no InputMap e A à direita/B embaixo no Nintendo. `recorte_icons_checks.gd` passou com 227 verificações, cobrindo SVGs, PNGs 96 px, bordas de mundo, aliases e licença. O teste usa eventos normalizados e perfis simulados; não comprova transporte USB/Bluetooth ou Steam Input. A suíte de HUD e o percurso completo com Morro também passaram. Logs finais em `documentation/evidence/pip66/revalidation-20261026/tests/`.

Pranchas e laboratório são excluídos do preset de exportação, assim como os PNGs de glyphs usados apenas na revisão, para não carregar esses arquivos de apresentação no pacote final. O preset foi editado, mas nenhum build de distribuição foi executado nesta tarefa.

## Reprodução dos assets

1. Extrair o ZIP oficial Kenney no diretório ignorado `tmp/pip65/kenney`.
2. Executar `node scripts/build-recorte-icons.mjs` e `node scripts/build-recorte-glyphs.mjs`.
3. Importar o projeto Godot; executar `--headless --path godot --script res://tools/export_recorte_icon_png.gd` para gerar os PNGs e rotas da prancha.
4. Executar `python scripts/build-recorte-icon-board.py` (Pillow).
5. Abrir `res://assets/ui/recorte-v1/components/demo_icons.tscn` e usar F6. Para captura visual isolada: `--capture --family=switch`; para teclado remapeado: `--capture --family=kbd --remap-cut=z`.

Fontes, licença e alterações ficam junto aos manifestos. Capturas de campanha e logs são arquivados em `documentation/evidence/pip65/`.
