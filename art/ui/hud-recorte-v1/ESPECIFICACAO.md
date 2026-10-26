# HUD "Recorte" v1 — especificação para o Codex (Godot)

**Para quem:** Codex/ChatGPT, que vai produzir os assets e o Theme da interface do Soulmonsters: Elo das Ruínas na versão Godot (`godot/`, Godot 4.7, renderer Compatibility, PC/Steam primeiro, controle e teclado).
**O que se pede:** uma HUD moderna inspirada na **linguagem** de Persona 5 (diagonais, tipografia forte, inversão de cor na seleção, transições em corte), em versão **contida**. Ela deve ser elegante e legível e nunca disputar atenção com o mundo e os personagens.
**Referência visual:** abra [`referencia.html`](referencia.html) no navegador. Ela mostra as cores, as fontes e cinco telas montadas com estas regras. É o alvo de aparência; este documento é o contrato de medidas e de entrega.

> Esta direção substitui o kit "Papel e Bambu" **somente na versão Godot**. O cliente web continua com o kit atual (`HUD-KIT.md`) até decisão do responsável.

---

## 1. A ideia em uma frase

**Papel de pipa recortado a estilete sobre tinta azul-noite: cortes diagonais, letras condensadas e uma única cor de acento que aparece só onde está a sua atenção.**

Persona é a inspiração de **gramática**, não de aparência. Não copie fontes, logos, ícones, máscaras, estrelas, padrões de bolinhas, o vermelho saturado dominante nem composições reconhecíveis de Persona.

### O que pegamos de Persona

| Recurso | Como usamos aqui |
| --- | --- |
| Diagonais fortes | Ângulo único de **12°** em painéis, faixas e cortes, como se o papel tivesse sido cortado com estilete |
| Tipografia como imagem | Títulos grandes, condensados e em caixa alta; o texto funcional fica reto e legível |
| Seleção por inversão | O item focado vira **papel sobre tinta**, com uma lasca de acento. O foco não depende só de cor |
| Sombra sólida deslocada | Uma sombra chapada de 6 px para baixo e para a direita, sem desfoque |
| Transição em corte | Painéis entram deslizando na diagonal, em 140–200 ms |
| Assimetria | Menu à esquerda e conteúdo à direita; retratos saindo da moldura |

### O que deixamos de fora ("não tão chamativa")

- **Uma cor de acento por tela**, ocupando no máximo cerca de 8% da área. O resto é tinta e papel.
- **Sem animação contínua** (pulsar, tremer, girar). O movimento só acontece quando algo muda de estado.
- **Na exploração, a HUD ocupa menos de 10% da tela** e se recolhe depois de 4 s sem uso.
- Sem estilhaços, estrelas, halftone pesado ou letras de "bilhete de resgate" em texto funcional. Texto girado só em títulos curtos, de até 3 palavras.
- Sem gradientes neon e sem brilho externo (glow). Textura de papel só como grão sutil, a 4–6% de opacidade.

### O toque da nossa identidade

- **Losango de pipa** como forma-assinatura: minimapa, moldura de ícone de parceiro, marcadores e cursor.
- **Linha do elo**: um fio fino (2 px, cor Céu) que liga o retrato do parceiro às barras dele e aparece nas transições. É a "linha" que manifesta os Soulmonsters.
- **Rabiola**: três triângulos pequenos que seguem o item selecionado ou fecham títulos. É o único ornamento permitido.

---

## 2. Tokens (fonte da verdade)

Crie estes valores no Theme do Godot e em `manifest.json`. Não invente cores fora desta tabela.

| Token | HEX | Uso |
| --- | --- | --- |
| `tinta` | `#141E29` | Fundo de painéis, contorno, sombra |
| `tinta-2` | `#22303F` | Superfície secundária, trilho de barras, itens não focados |
| `tinta-3` | `#33475A` | Divisórias, estado desabilitado |
| `papel` | `#F4E9D2` | Texto sobre tinta; painel invertido (foco) |
| `papel-2` | `#D8C9AC` | Texto secundário sobre tinta; sombra do papel |
| `rabiola` (acento) | `#E5533B` | Seleção, ação principal, perigo/vida baixa. **Texto em cima dele: `tinta`** |
| `ceu` | `#6CC6D9` | Linha do elo, parceiro, informação, energia |
| `sol` | `#EDB94E` | Recompensa, raridade, XP. Nunca em botões comuns |
| `folha` | `#7FC98A` | Vida cheia, sucesso, confirmação |
| `veu` | `#141E29` a 72% | Fundo escurecido atrás de menus e modais |

Contraste mínimo: texto corrido 4,5:1 e títulos 3:1. Pares aprovados: papel sobre tinta, tinta sobre papel, tinta sobre rabiola, tinta sobre céu, tinta sobre sol. **Proibido:** papel sobre rabiola em texto menor que 32 px, e céu ou sol sobre papel.

### Geometria

| Regra | Valor |
| --- | --- |
| Ângulo do corte | 12° (inclinação horizontal ≈ 0,21; em Godot `StyleBoxFlat.skew = Vector2(0.21, 0)`) |
| Cantos | Vivos (raio 0). Exceção: barras de vida com raio 2 nas pontas internas |
| Contorno | 3 px `tinta` em painéis sobre o mundo; 2 px em itens de lista |
| Sombra | Sólida, `tinta` a 85%, deslocada **(6, 6)** px, sem desfoque. Itens pequenos: (4, 4) |
| Grade | Unidade de 8 px; margens seguras de **64 px** (laterais) e **48 px** (topo e base) em 1920×1080 |
| Grão de papel | Textura em *tile* 512×512, multiplicada a 5% só sobre superfícies `papel` |

### Tipografia (fontes livres, OFL)

| Papel | Fonte | Peso | Tamanhos em 1080p |
| --- | --- | --- | --- |
| Display (títulos, nomes de área, VITÓRIA) | **Barlow Condensed** | 800, com itálico de 12° via `FontVariation.variation_transform` | 96 · 64 · 48 |
| Rótulos (menus, botões, abas) | **Barlow Condensed** | 700, caixa alta, espaçamento +4% | 34 · 28 · 24 |
| Texto (diálogo, descrições) | **Nunito** (já usada no jogo web) | 600 / 800 | 30 (diálogo) · 26 · 22 |
| Números (HP, XP, preço) | Barlow Condensed | 700, algarismos tabulares | 40 · 28 · 22 |

Mínimo absoluto: 20 px em 1080p. Ao rodar em 1280×720, tudo escala pelo `stretch` e nada fica abaixo de 14 px reais. Todo texto é **texto vivo** (Label/RichTextLabel), nunca desenhado dentro de PNG. A única exceção é o logotipo do jogo.

---

## 3. Como construir no Godot (a parte técnica que mais importa)

**Regra principal:** formas geométricas são **StyleBoxFlat no Theme**, não PNG. A HUD Persona é geométrica: fazê-la em código deixa tudo nítido em qualquer resolução, fácil de recolorir e sem problemas de 9-slice. Use imagem só para o que é ilustração ou textura.

| Elemento | Técnica no Godot |
| --- | --- |
| Painéis, faixas, botões, abas, itens de lista, barras | `StyleBoxFlat`: `bg_color`, `border_width_*`, `border_color`, `skew`, `shadow_color`, `shadow_offset`, `shadow_size=0`, `corner_radius=0` |
| Foco/seleção | `StyleBoxFlat` invertido no estado `focus` e `hover`, mais o nó `RabiolaMarker` (3 triângulos, `Polygon2D`) animado por `Tween` |
| Losangos (minimapa, moldura de parceiro, cursor) | `Polygon2D`/`draw_colored_polygon` ou um shader de máscara simples; contorno com `Line2D` |
| Linha do elo | `Line2D` de 2 px, `ceu`, com `width_curve` afinando nas pontas |
| Grão de papel | `TextureRect` com `paper_grain.png` em *tile*, `CanvasItemMaterial` com blend *mul* |
| Ícones | SVG importados como `Texture2D` (scale 1 a 48 px; também exportar 96 px) |
| Glyphs de botão (Xbox, PlayStation, teclado) | Partir do **Kenney Input Prompts (CC0)**, recolorido com os tokens. Guardar a licença em `LICENSES.md` |
| Retratos e artes de fundo de menu | PNG (ilustração), sempre separados da moldura |
| Animações | `Tween` ou `AnimationPlayer`; respeitar a opção "Reduzir movimento" (só fade de 80 ms) |

Configuração do projeto (já é `canvas_items`): referência **1920×1080**, `aspect = expand`, ancorar cada bloco ao canto que ocupa. Teste também em 1280×720, 1280×800 (Steam Deck), 2560×1080 (21:9) e 1920×1200 (16:10).

Estrutura de entrega:

```
godot/assets/ui/recorte-v1/
  theme/recorte_theme.tres        # Theme único: tipos Button, Label, PanelContainer, ItemList, ProgressBar, TabBar, LineEdit, HSlider, CheckButton, ScrollBar, TooltipPanel
  theme/styles/*.tres             # StyleBoxFlat nomeados (ver seção 5)
  fonts/BarlowCondensed-*.ttf, Nunito-*.ttf, OFL.txt
  fonts/display_italic.tres       # FontVariation com inclinação de 12°
  icons/*.svg                     # lista na seção 6
  glyphs/xbox|ps|kbd/*.svg        # Kenney recolorido
  textures/paper_grain.png        # 512×512, tile sem costura
  components/*.tscn               # cenas reutilizáveis (seção 4)
  mockups/*.png                   # telas aprovadas, 1920×1080
  manifest.json                   # tokens, tamanhos, estados, arquivos
  README.md                       # como usar, prints
  LICENSES.md
```

---

## 4. Telas e componentes

As medidas abaixo são em 1920×1080. "Âncora" é o canto do `Control`.

### 4.1 Exploração (HUD mínima)

| Componente | Âncora / tamanho | Comportamento |
| --- | --- | --- |
| **Placa de área** | topo-esq., 560×88, faixa inclinada `tinta` com nome em Display 48 e sub-rótulo 22 (ex.: "VEREDAS DO ENCANAMENTO" / "Mirante") | Entra em corte ao mudar de área, fica 3 s e recolhe para um **chip** 280×44 |
| **Objetivo** | abaixo da placa, até 520 px de largura, 2 linhas | Ícone losango `rabiola` + texto 22. Some depois de 4 s; volta ao abrir o menu ou mudar o objetivo |
| **Minimapa** | topo-dir., losango de 220×220 | Moldura 3 px `tinta` + borda interna `papel-2`; norte marcado com um triângulo `rabiola`; o jogador é uma seta `papel` |
| **Parceiro** | base-esq., 360×120 | Retrato em losango 104 px, nome, Nv., barra de vida (`folha`→`sol`→`rabiola` abaixo de 50% e 25%), barra de vínculo `ceu`. A linha do elo liga o retrato às barras |
| **Prompt de interação** | base-dir., até 440×72 | Glyph do botão + **verbo** (ABRIR, CONVERSAR, ENTRAR) em rótulo 28 + nome do alvo 22. Aparece só perto do alvo, em corte de 140 ms |
| **Avisos (toast)** | base-dir., acima do prompt, 420×64, no máx. 3 empilhados | Faixa `tinta-2` com lasca de cor: `folha` (salvo), `sol` (item), `rabiola` (erro). Duram 3 s |
| **Botão de menu** | só em toque | Losango 72 px |

### 4.2 Diálogo

- Caixa na base: 1600×240, cortada a 12° nas duas pontas, `tinta` com contorno 3 px e sombra. Texto em Nunito 30, até 3 linhas, a uma largura de 60–70 caracteres.
- **Placa do nome**: 360×64, inclinada, `papel` com texto `tinta` em Display 34, presa no canto superior esquerdo da caixa e ultrapassando a borda em 24 px.
- **Retrato**: busto de 520 px de altura atrás da caixa, à esquerda (falante) ou à direita (interlocutor). Quem não fala fica 35% mais escuro, sem desfoque.
- Indicador de avançar: losango 20 px `rabiola`, que desce 4 px a cada 600 ms (é a única exceção de movimento contínuo, e para com "Reduzir movimento").
- **Escolhas**: tiras de 640×64 empilhadas à direita, inclinadas, com a selecionada invertida e com rabiola. Até 4 opções.

### 4.3 Menu de pausa (tela principal de menus)

- Fundo: o jogo congelado com `veu` e um grande **corte diagonal** `tinta` cobrindo 45% da tela à esquerda.
- **Lista principal** à esquerda, itens 520×76 em Display 40, com recuo progressivo de 18 px por item (escada diagonal): MOCHILA, PIPA DEX, PARCEIROS, MISSÕES, OFICINA, SALVAR, CONFIGURAÇÕES, SAIR.
- Item focado: faixa `papel` com texto `tinta`, deslocada 24 px para a direita, rabiola na ponta e ícone do item à esquerda.
- **Painel de conteúdo** à direita: 1080×820, `tinta-2` com contorno, título em Display 64 que extrapola o painel em 32 px.
- Arte do Kael e do parceiro ao fundo, à direita, em silhueta tonal (`tinta-3` a 60%). Ilustração, não moldura.
- Rodapé de comandos: glyphs + verbos (CONFIRMAR, VOLTAR, ABA), base-esquerda, 22 px.

### 4.4 Telas de conteúdo (Mochila, Pipa Dex, Missões, Oficina, Salvar)

- Abas no topo do painel: `TabBar` com abas inclinadas 220×56; a ativa fica invertida; LB/RB trocam de aba.
- **Lista + detalhe**: lista à esquerda (itens 480×72, ícone 48, nome, quantidade em número tabular) e detalhe à direita (arte, descrição, ações).
- **Cartão de Pipa Dex**: 300×380, retrato num losango grande, número `#012` em Display, nome e tipo em chips. Os não vistos ficam como silhueta `tinta-3`, sem texto.
- **Slots de save**: faixas 1000×120 com miniatura 16:9, área, hora de jogo e data. O automático é marcado com um chip `ceu`.
- Estados de lista obrigatórios: vazio (mensagem + ação), carregando (3 losangos piscando em sequência), erro (mensagem + TENTAR DE NOVO).

### 4.5 Batalha: duelo de pipas em tempo real

**A batalha é ação, não turno.** As pipas voam livres no céu presas a carretéis no chão. Um **corte** acontece quando a sua linha cruza a do rival dentro da faixa válida. O jogador está com os olhos na pipa o tempo todo. Por isso a regra muda em relação às outras telas: **o que decide a luta aparece no céu, junto das pipas; os cantos só guardam o estado**. Uma informação que exige leitura não deve aparecer no meio do combate.

As regras abaixo vêm do motor atual (`src/engine.js`) e são as que a HUD precisa mostrar. Os nomes e valores já existem: não invente mecânica.

| Mecânica | Regra no motor | O que a HUD mostra |
| --- | --- | --- |
| **Linha** (vida da rodada) | Cada corte desgasta; zerou, a pipa cai e perde a rodada. No fim do tempo, vence quem tem mais linha | Barra grande do parceiro e do rival |
| **Armação** | Estrutura da pipa, persiste entre rodadas e encontros | Barra fina abaixo da Linha |
| **Energia** | Gasta por esquiva (18), manobras (20–32) e golpe especial (35–40); recupera com o tempo | Barra em **blocos de 10**; ao segurar uma ação, os blocos que ela vai gastar ficam marcados |
| **Corte e qualidade** | Ângulo aberto (limpo), pipa em movimento (relada) e cruzamento no **centro dourado** da linha rival (52–68%) | Mira no ponto de cruzamento e **3 marcadores**: ÂNGULO · RELADA · CENTRO. Os três acesos dão crítico |
| **Esquiva** | 0,28 s, custo 18, recarga 2,2 s. **Esquiva perfeita** no instante do puxão do rival devolve energia, e o próximo acerto em 2 s é crítico | Anel de tempo no rival que está puxando; após a perfeita, um marcador de CONTRA-ATAQUE com 2 s na sua pipa |
| **Manobras de linha** | Puxão, Chicote, Estilingue, Laço, Folha solta, Duplo toque: **segurar para carregar** (até 1,2 s) e soltar | Anel de carga em volta do botão e da sua pipa; a janela de acerto pisca uma vez |
| **Habilidade do tipo** | Puxão preciso, Dash lateral, Linha firme ou Foco, conforme a pipa | Botão próprio, com a duração como barra que esvazia |
| **Guarda (Linha firme)** | 0,5 s, recarga de 20 s | Botão com recarga longa e halo na pipa enquanto ativa |
| **Golpe especial** | Ex.: Pulo do Elo, Nó de Vendaval. Preparação de 1,4–1,65 s, com alcance em volta do alvo | **Aviso no alvo**: círculo do alcance que se fecha até o golpe. É a hora de esquivar |
| **Escudo de entrada** | 2,5 s sem dano no começo da rodada | Halo translúcido na pipa, que some quando acaba |
| **Rodadas** | 3 s de contagem ("JÁ!"), 60 s de rodada, 3,2 s de intervalo, vence quem chegar ao número de rodadas | Relógio no topo, vitórias em losangos e faixas de fase |
| **Clima** | Ventania, linha encerada, garoa, neblina (Céu do dia) | Chip de clima abaixo do relógio, com o vento como seta |

#### Camada 1: no céu (segue as pipas, em espaço de mundo)

| Elemento | Aparência | Quando |
| --- | --- | --- |
| **Marca da sua pipa** | Losango `ceu` de 14 px abaixo da pipa e a sua linha com contorno `ceu`. A linha do rival fica `rabiola` | Sempre. "VOCÊ" escrito só nos 3 s iniciais da primeira rodada |
| **Mira de cruzamento** | Losango de 28 px no ponto onde as linhas se cruzam: contorno `papel` (corte válido), `sol` (centro dourado) ou `tinta-3` tracejado (fora da faixa ou ângulo fechado) | Só quando as linhas se cruzam |
| **Faixa dourada** | Trecho de 52–68% da linha rival levemente aceso em `sol` a 50% | Quando a sua linha está a menos de 160 px da do rival |
| **Marcadores de qualidade** | 3 pequenos losangos sob a mira: ÂNGULO · RELADA · CENTRO, acesos em `papel` | Junto com a mira; os três acesos ficam `sol` |
| **Números de desgaste** | −18 em rótulo 28 `papel` com contorno `tinta`; crítico em 40 `sol` | Sobem 24 px e somem em 500 ms. No máx. 3 ao mesmo tempo |
| **Palavras de impacto** | CRÍTICO! (`sol`), ESQUIVA PERFEITA (`ceu`), BLOQUEOU (`papel`), CORTOU! (`rabiola`) em Display itálico 72–96 com contorno 6 px `tinta`, perto da pipa | **Uma por vez**; 120 ms de entrada, 500 ms parada, 160 ms de saída |
| **Aviso de golpe** | Círculo de alcance `rabiola` tracejado em volta da sua pipa, preenchendo até o golpe, mais um "!" em losango sobre o rival | Durante a preparação do golpe especial ou da carga do chefe |
| **Anel de esquiva perfeita** | Anel `ceu` que se fecha na sua pipa até o instante ideal | Quando o rival inicia um puxão que pode acertar você |
| **Carga da manobra** | Arco `ceu` em volta da sua pipa, que enche em 1,2 s | Enquanto o botão da manobra está seguro |
| **Halos** | Escudo de entrada: `papel` a 30%; Guarda: `ceu` a 50% com contorno | Enquanto durarem |

Tudo no céu fica sem moldura, sem painel e sem sombra deslocada, para não tapar as pipas. Contorno `tinta` de 3–6 px garante leitura sobre o céu claro e sobre as nuvens.

#### Camada 2: cantos (estado, para olhar de relance)

| Componente | Âncora / tamanho | Conteúdo |
| --- | --- | --- |
| **Pipeiro (você)** | topo-esq., 400×96 | Retrato do pipeiro, nome, Nv. e **vitórias de rodada em losangos** (◆◆◇) |
| **Rival** | topo-dir., 400×96, espelhado | O mesmo; no selvagem, "Soulmonster selvagem" no lugar do nível do pipeiro |
| **Relógio** | topo-centro, losango 120 px | Segundos em Display 52 e "RODADA 2" em 20 abaixo; nos últimos 10 s o losango fica `rabiola` (uma vez, sem piscar) |
| **Clima/vento** | abaixo do relógio, chip 200×36 | Ícone do clima, nome e seta de vento |
| **Seu parceiro** | base-esq., 460×132 | Retrato losango, nome e Nv., **Linha** (360×20, com o número), **Armação** (360×8) e **Energia** em 10 blocos (360×12) |
| **Parceiro rival** | topo-dir., abaixo do rival, 400×64 | Linha e Armação. **O rival não mostra energia nem recargas** (regra atual) |
| **Barra de ações** | base, à direita do seu parceiro, botões de 88×88 em fila inclinada, com 12 px entre eles | Ver a tabela abaixo |
| **Fugir** (só no encontro selvagem) | base-esq., acima do parceiro, chip 220×40 | "Segure F para fugir"; precisa segurar 1 s com anel de progresso, para evitar clique sem querer |

Com 4 jogadores (partida rápida), os rivais viram uma coluna compacta no topo-direito, 320×56 cada: nome, losangos de rodada e Linha.

**Botões da barra de ações** (na ordem, da esquerda para a direita):

| Botão | Conteúdo | Estados |
| --- | --- | --- |
| Esquiva | Ícone + glyph | Pronto · recarga (2,2 s) · sem energia |
| Manobra 1 e 2 | Ícone da manobra escolhida, glyph e custo em blocos | Pronto · **carregando** (anel) · recarga · sem energia |
| Habilidade do tipo | Ícone do tipo | Pronto · **ativa** (barra de duração) · recarga |
| Guarda | Ícone de escudo | Pronto · ativa · recarga (20 s) |
| Golpe especial | Losango maior, 112 px, à direita | Pronto (contorno `sol`) · preparando · recarga |

Estados visuais, iguais em todos os botões:
- **pronto:** `tinta` com ícone `papel`; ao ficar pronto, um único brilho de contorno `papel` de 120 ms;
- **recarga:** varredura diagonal de `tinta-3` que se retrai e segundos inteiros em rótulo 24 no centro;
- **sem energia:** ícone `tinta-3` e custo em `rabiola`;
- **ativo/carregando:** contorno `ceu` de 3 px.

O glyph mostra a tecla ou o botão do controle que estiver configurado, nunca um texto fixo.

#### Camada 3: faixas de fase (centro, entre as rodadas)

Faixas diagonais de lado a lado, como no resultado, só **fora** do tempo de luta:
- **RODADA 2**, com a contagem 3 · 2 · 1 · **JÁ!**; o "JÁ!" usa `rabiola` e fica 400 ms;
- **CORTOU!** / **RODADA PERDIDA** / **EMPATE** no fim da rodada, com o placar em losangos;
- **ÚLTIMOS 10 s**: só um chip abaixo do relógio, sem faixa, porque a luta está acontecendo.

Durante a luta, nada cobre o centro da tela além da camada 1.

#### Regras de leitura em ação

- **Regra de 1 segundo:** tudo nos cantos precisa ser entendido num relance. Nada de frases durante a luta; só números, barras e ícones.
- **Sua cor é `ceu`, a do rival é `rabiola`.** Linha, marca e halos seguem isso. Em partidas de 4, os outros rivais usam a cor de jogador atual (P1–P8), com contorno `tinta`.
- **Prioridade quando muita coisa acontece:** aviso de golpe > anel de esquiva > mira > palavras de impacto > números. Se dois disputarem o mesmo lugar, o de menor prioridade espera ou some.
- **Nenhum elemento da camada 1 a menos de 40 px de outra pipa** que não seja a dele. Afaste o texto na direção oposta.
- **Linha abaixo de 25%:** a barra fica `rabiola` e a borda da tela recebe uma vinheta `tinta` de 6% (sem vermelho e sem pulsar).
- **Reduzir movimento:** números e palavras aparecem e somem com fade de 80 ms, sem subir nem girar.

#### Como montar no Godot

- **Camada 1** dentro do mundo: nós `Node2D` filhos de cada pipa e um nó `CrossingMarker` posicionado pelo ponto de cruzamento que o motor já calcula. Desenho com `_draw()` (losangos, arcos com `draw_arc`) e `Label` com `LabelSettings` de contorno.
- **Camadas 2 e 3** num `CanvasLayer` acima do mundo, com o Theme.
- **Recargas:** `TextureProgressBar` com máscara losango e `fill_mode` em varredura, ou um shader de 10 linhas com o ângulo de 12°.
- **Fonte dos dados:** a HUD só lê o estado da partida (`hp`, `hull`, `energy`, recargas, `signatureWindup`, `evade`, `counter`, fase, rodada e tempo), nunca calcula dano.

### 4.6 Resultado

- VITÓRIA / DERROTA em Display itálico 128, faixa diagonal atravessando a tela (vitória `papel` sobre `tinta`; derrota `tinta-3` sobre `tinta`, sem vermelho).
- Barra de XP `sol` animada uma única vez; "SUBIU DE NÍVEL" como chip `sol`.
- Recompensas em cartões 220×260 que entram em sequência a cada 90 ms. Os raros têm contorno `sol`, sem brilho.

### 4.7 Título, carregamento e confirmação

- **Título:** logotipo (único texto em imagem) e menu de 4 itens com o mesmo estilo da pausa. "PRESSIONE START" em rótulo 28, piscando a 1 Hz (para com "Reduzir movimento").
- **Carregamento:** fundo `tinta`, dica em Nunito 26 e uma pipa-losango atravessando em diagonal como indicador.
- **Modal de confirmação:** 760×320 centralizado, inclinado, com CONFIRMAR (`rabiola`) e CANCELAR (`tinta-2`). O foco começa em CANCELAR quando a ação é destrutiva.

---

## 5. Kit de componentes (estados obrigatórios)

Cada item abaixo vira um `StyleBoxFlat` nomeado e um tipo do Theme. Estados: **normal · hover · focus · pressed · disabled**. Focus e hover são iguais em aparência; o foco do controle precisa ser visível sem mouse.

| Componente | Normal | Focus/hover | Pressed | Disabled | Tamanho mín. |
| --- | --- | --- | --- | --- | --- |
| `BotaoPrimario` | `rabiola`, texto `tinta`, sombra 6 | `papel`, texto `tinta`, lasca `rabiola` 8 px à esquerda, desloca −2,−2 | sem sombra, desloca +4,+4 | `tinta-3`, texto `papel-2` 60% | 240×64 |
| `BotaoSecundario` | `tinta-2`, contorno 2 `papel-2`, texto `papel` | invertido (`papel`/`tinta`) | igual ao primário | igual ao primário | 200×56 |
| `BotaoIcone` | losango 64 `tinta-2` | losango `papel`, ícone `tinta` | sem sombra | 50% | 64×64 |
| `ItemLista` | transparente, texto `papel` | faixa `papel` inclinada, texto `tinta`, rabiola | — | texto `tinta-3` | 72 de altura |
| `Aba` | `tinta-2`, texto `papel-2` | `papel`/`tinta` | — | — | 180×56 |
| `Barra` (vida/xp/energia) | trilho `tinta-2` com contorno 2 `tinta`; preenchimento inclinado | — | — | — | altura 10/18 |
| `Interruptor`, `Caixa`, `Slider` | trilho `tinta-2`; marcador losango `papel` | marcador `rabiola` | — | 50% | 48 de altura |
| `Campo de texto` | `tinta-2`, contorno 2 `tinta-3` | contorno 3 `ceu` | — | — | 56 de altura |
| `Tooltip` | `papel`, texto `tinta` 22, sombra 4 | — | — | — | — |
| `Chip/Badge` | 32 de altura, inclinado, cores semânticas | — | — | — | — |

Animação de foco: deslocar 24 px na diagonal e inverter as cores em **120 ms**, `TRANS_QUART`, `EASE_OUT`. A rabiola entra com 40 ms de atraso.

---

## 6. Ícones (SVG, grade 48 px)

Estilo: **chapado em duas cores** (`papel` + uma lasca de `tinta` ou acento), sem contorno fino, cantos vivos, inclinação de 12° quando fizer sentido. Área útil de 40 px centralizada. Precisam ser legíveis a 24 px.

Lista mínima: mochila, pipa-dex, parceiros, missões, oficina, salvar, carregar, configurações, sair, mapa, voltar, confirmar, fechar, info, alerta, moeda, linha (carretel), rabiola, vida, energia, xp, nível, tempo, bau, chave, presente, troca, amigos, ranqueada, treino, céu-do-dia, cadeado, check, mais, menos, filtro, ordenar, buscar, som, música, vibração, idioma, controle, teclado, acessibilidade. Mais os 6 tipos elementais existentes no jogo (confirme os nomes em `MANUAL-DE-ASSETS.md`).

Nomes dos arquivos: `icons/<nome>.svg` em minúsculas com hífen. Exporte também `icons/png96/<nome>.png`.

---

## 7. Ordem de trabalho e pontos de aprovação

1. **Mockups (para aprovação, nada de produção):** quatro telas em 1920×1080: exploração com prompt, diálogo com escolhas, menu de pausa com a Mochila aberta e **batalha no momento de um corte crítico**. Pode gerar com imagem a partir dos prompts da seção 8 e depois **corrigir as medidas no Godot**. Entregar em `mockups/` e esperar o "ok" do responsável.
2. **Theme e componentes:** `recorte_theme.tres`, os StyleBoxFlat da seção 5, fontes e a cena `components/demo_kit.tscn`, que mostra todos os componentes e estados lado a lado, com um botão para alternar 1280×720/1920×1080.
3. **Telas:** exploração, diálogo, pausa, conteúdo, batalha e resultado como cenas em `components/` (ex.: `area_plate.tscn`, `interact_prompt.tscn`, `dialogue_box.tscn`, `pause_menu.tscn`, `battle_hud.tscn`), com sinais claros e sem lógica de jogo embutida.
4. **Ícones e glyphs**, por último. Até chegarem, use um losango no lugar.
5. **Revisão:** prints das telas nas 5 resoluções da seção 3, com teclado e com controle, salvos em `mockups/revisao/`.

---

## 8. Prompts para gerar os mockups (ChatGPT imagem)

Use **só para os mockups da etapa 1**. Imagem gerada não serve como asset final de moldura: medidas, texto e cortes saem imprecisos. O resultado final é montado no Godot com o Theme.

**Base (cole antes de cada tela):**

```
Mockup de interface de jogo 2D de aventura, 1920x1080, estilo moderno inspirado na gramática do Persona 5
(diagonais de 12 graus, tipografia condensada em caixa alta, seleção por inversão de cores, sombra sólida
deslocada), porém sóbrio e elegante, sem excesso. Tema: papel de pipa recortado a estilete sobre tinta
azul-noite. Paleta restrita: azul-noite #141E29 e #22303F, papel creme #F4E9D2, um único acento
coral-vermelho #E5533B usado só no item selecionado, toques mínimos de ciano #6CC6D9 e dourado #EDB94E.
Cantos vivos, sem brilho, sem neon, sem estrelas, sem halftone, sem textura pesada; grão de papel sutil.
Forma-assinatura: losango de pipa (minimapa, molduras de retrato, marcadores) e três pequenos triângulos
de rabiola marcando a seleção. Textos em português do Brasil, legíveis. Não usar logotipos, fontes,
personagens ou elementos reconhecíveis de Persona. Fundo do jogo: cena isométrica ilustrada de um
bosque brasileiro com trilha de terra e riacho, estilo anime 2D, cores em massa.
```

**Exploração:** `+ HUD mínima sobre o jogo: no topo à esquerda uma faixa diagonal azul-noite com "VEREDAS DO ENCANAMENTO" e "Mirante" menor; abaixo, uma linha de objetivo "Leve a rabiola até a Nina". No topo à direita, um minimapa em forma de losango. Na base à esquerda, retrato do parceiro (criatura-pipa) num losango, nome "Carcará Nv. 12", barra de vida verde e barra de vínculo ciano ligadas por uma linha fina. Na base à direita, prompt "[E] ABRIR · Baú do mirante". O resto da tela fica limpo.`

**Diálogo:** `+ caixa de diálogo larga na base, cortada em diagonal nas pontas, azul-noite; placa de nome inclinada creme com "NINA" em letras condensadas; busto de uma garota de 12 anos atrás da caixa, à esquerda; texto: "Atravessou a ponte? O mirante tem um baú. A rampa fica perto do mato alto."; à direita, três opções empilhadas em tiras inclinadas, a do meio selecionada em creme com triângulos coral: "Vou até lá", "Onde fica a rampa?", "Depois".`

**Pausa + Mochila:** `+ tela de menu: o jogo escurecido ao fundo; um grande corte diagonal azul-noite à esquerda com a lista em escada diagonal "MOCHILA, PIPA DEX, PARCEIROS, MISSÕES, OFICINA, SALVAR, CONFIGURAÇÕES, SAIR", com MOCHILA selecionada (faixa creme, texto azul-noite, triângulos coral); à direita um painel com o título "MOCHILA" grande extrapolando a borda, abas inclinadas "ITENS · LINHAS · RABIOLAS · CHAVE", lista de itens com ícones e quantidades e um painel de detalhe; no rodapé, comandos "Ⓐ CONFIRMAR  Ⓑ VOLTAR  LB/RB ABA".`

**Batalha:** `+ duelo de pipas em tempo real num céu claro de praia brasileira: duas pipas-criatura voando presas a linhas que descem até carretéis no chão; a linha do jogador em ciano, a do rival em coral, cruzando-se no centro da tela, com um pequeno losango creme no ponto de cruzamento e três losanguinhos embaixo ("ÂNGULO · RELADA · CENTRO", dois acesos). Perto da pipa rival, a palavra "CRÍTICO!" em letras condensadas itálicas douradas com contorno azul-noite. Nos cantos superiores, placas inclinadas azul-noite: "Kael Nv. 3 ◆◇" à esquerda e "Pipa de rua · Soulmonster selvagem ◇◇" à direita, com a barra de linha do rival; no topo ao centro, um losango com "42" e "RODADA 1". Na base à esquerda, o parceiro "Raio de Sol Nv. 3" com barras de Linha, Armação fina e Energia em blocos; ao lado, uma fila de botões quadrados inclinados com ícones e teclas (Esquiva, Puxão, Chicote, Foco, Guarda) e um losango maior dourado para o golpe especial, um deles em recarga com varredura diagonal e "3". O centro do céu fica livre.`

---

## 9. Checklist de aceite

- [ ] Nenhuma cor fora dos tokens; acento em no máximo ~8% da tela; uma cor de acento por tela.
- [ ] Todo texto é Label/RichTextLabel; nenhum PNG com texto, exceto o logotipo.
- [ ] Molduras são StyleBoxFlat; PNG só para ilustração, textura, ícone e glyph.
- [ ] 1280×720, 1280×800, 1920×1080, 2560×1080 e 1920×1200 sem cortes, sobreposições ou texto abaixo de 14 px reais.
- [ ] Navegação completa só com controle e só com teclado; foco inicial definido em todas as telas; Voltar sempre funciona; o foco volta ao item de origem.
- [ ] Textos 30% mais longos cabem (teste com "CONFIGURAÇÕES AVANÇADAS DE ACESSIBILIDADE").
- [ ] Estados vazio, carregando e erro em todas as listas.
- [ ] "Reduzir movimento" troca cortes por fade de 80 ms e para o pisca-pisca.
- [ ] Contraste conferido (4,5:1 em texto, 3:1 em títulos).
- [ ] Fontes e glyphs com licença registrada em `LICENSES.md`.
- [ ] Prints de revisão em `mockups/revisao/` com a resolução no nome do arquivo.
- [ ] Batalha: as pipas e o cruzamento das linhas nunca ficam cobertos pela HUD dos cantos; a mira, os avisos e as palavras de impacto seguem a ordem de prioridade; testado numa rodada inteira com controle, e não só em captura parada.
- [ ] Nada copiado de Persona: comparar lado a lado e trocar qualquer elemento reconhecível.

## 10. Fora do escopo

Integração com o cliente web, mudanças de regras de jogo, contas e economia; música e efeitos sonoros (deixe só os sinais `focus_changed`, `confirmed` e `cancelled` para o áudio entrar depois); e merge ou deploy sem autorização do responsável (PIP-49).
