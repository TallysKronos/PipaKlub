# HUD Recorte · leitura e aplicação em Soulmonsters

Referência integral: HUD-Recorte-referencia.html, fornecida pelo usuário. O HTML
foi lido como referência visual; seus scripts não foram executados. Ele próprio
se apresenta como mockup e cita ESPECIFICACAO.md, que não acompanhou o arquivo.
As medidas do mockup são para 1920×1080, não coordenadas absolutas da campanha.

## Direção própria e artes produzidas

Papel vivo, varetas, amarrações e rabiolas fazem a ligação com as criaturas.
Contornos escuros, recortes assimétricos, cores chapadas e pouca sombra evitam
uma interface metálica ou tecnológica. A interface continua calma no mundo;
respingos aparecem nos resultados. O ciano identifica o jogador e o coral o rival
ou uma ação principal. Dourado fica reservado a recompensas e críticos.

Foram produzidos 26 SVGs originais editáveis e uma prancha PNG com quatro adornos
ilustrados gerados por image_gen. Prompts integrais, autoria/origem, dimensões,
cortes e critérios estão em godot/assets/campaign/ui-recorte/manifest.json.
A prancha original foi preservada, usando quatro AtlasTextures independentes.
O canal alpha foi inspecionado e a composição conferida dentro do Godot.

## Matriz da referência

| Parte do documento | Aplicação e contrato |
| --- | --- |
| Dez cores e papéis semânticos | Centralizados em hud.gd; contrastes de leitura verificados. |
| Lilita One | Títulos e resultados; fontes locais com OFL. |
| Barlow Condensed | Ações, rótulos, teclas e placares. |
| Nunito | Falas, descrições e mensagens; peso variável explícito. |
| Bangers | TOC/TCHAC ligados ao evento de dano efetivamente aplicado; sem chamar qualquer golpe de crítico por suposição. |
| Diagonais de 12° | Pontas desenhadas dos botões e cunha da pausa. Texto permanece reto. |
| Moldura de nanquim | Três materiais em nove partes, cantos fixos de 24px. |
| Sombra sólida | Desenhada na camada da moldura e nas pontas do botão. |
| Foco com pincelada | Papel, faixa coral e contorno ciano; geometria/margens constantes. |
| Hover e pressionado | Materiais próprios com cortes idênticos. |
| Desabilitado | Fonte/superfície com contraste mínimo 4,5; não reproduz a baixa legibilidade do mockup. |
| Botão secundário | Tinta/papel, preservando coral para a ação principal. |
| Abas | Categorias da mochila; seleção exclusiva persiste além do foco. |
| Interruptores em losango | Artes próprias ON/OFF de 84×40, sem escala por largura. |
| Glyph de teclado/controle | Mostra a ação realmente vinculada; não copia teclas fictícias do mockup. |
| Placa da região | Recolhe após 3s nas áreas de exploração. |
| Objetivo | Recolhe após 4s no parque/Morro. |
| Prompt de interação | Aparece por proximidade; removida a faixa permanente de movimento. |
| Minimap em losango | Esquema do terreno próximo, posição central; nenhum baú/NPC/segredo revelado. |
| Retrato no diálogo | Fora da caixa, atrás da composição, proporcional. |
| Plaquinha de nome | Papel sobre a borda da caixa de tinta, independente do texto. |
| Escolhas de diálogo | A campanha atual usa diálogos e confirmações existentes; não foram criadas escolhas narrativas inexistentes. |
| Adesivos de emoção | Não anexados automaticamente: dependem de emoção escrita para a fala. |
| Pausa em cunha | Overlay escurecido, recorte diagonal e navegação deslocada em escada. |
| Conteúdo da pausa | Retomar, Equipe, Mochila, Configurações e Salvar/menu funcionais. Não exibe PipaDex/missões/oficina fictícios. |
| Mochila em duas partes | Categorias, lista rolável e detalhe com quantidade/descrição. |
| Usar/descartar | Não foram inventados efeitos ou descarte de itens de missão. Rabiolas orientam ao ateliê existente. |
| Cores dos participantes | Linha ciano/coral com contorno escuro; terceiro participante preserva sua identificação. |
| Barra de energia | Dez segmentos; valores vêm do modelo real. |
| Ações de combate | Ícones próprios, tecla atual, custo, máscara diagonal e contador de recarga. |
| Energia insuficiente | Marca coral adicional; não depende apenas de reduzir a opacidade. |
| Guarda/telegráficos | Estados reais do combate mantidos, sem alteração de alcance ou tempo. |
| Escudo de entrada de 2,5s | Não implementado como mecânica nova por ser apenas exemplo no HTML. |
| Retícula | Camada decorativa com passo fixo, não textura esticada com o painel. |
| Respingos | Asset branco tingível e usado atrás da faixa de resultado. |
| Linhas de impacto/SFX | Eventos nos dois modelos de combate; dano numérico, traços de 250ms e lettering; orçamento de dez impactos simultâneos e descarte em 650ms. |
| Vitória/derrota | Faixas proporcionais próprias, adornos, respingos e letras separadas; compartilhadas entre encontros e Morro. |
| Personagens no resultado | Mantêm frames reais de vitória/derrota das criaturas. |
| XP/itens | Prévia sem escrita, com as regras reais do encontro, progressão, moedas, estrelas e rabiolas; crédito respeita nível máximo. |
| Wipe de tinta de 450ms | Reveal em camada independente, borda diagonal e respingos; não bloqueia input nem altera tempo da simulação. Não reaparece a cada fala do mesmo diálogo. |
| Contagem animada de XP | Uma vez por apresentação do resultado, 1,1s com desaceleração, barra e níveis atravessados; continuar permanece disponível sem esperar. |
| Reduzir animações | Preferência persistente: XP imediato, resultado sem zoom, impactos sem deslocamento/linhas e transição discreta de 120ms. |

## Montagem e legibilidade

Molduras altas crescem pelo centro e pelos trechos retos. Não se aplica skew à
altura inteira: isso faria a borda invadir o texto. Botões têm cortes de
26/12/26/12 em todas as variantes. Ornamentos têm dimensão própria, proporção
preservada e não contribuem para o mínimo do Container; ignoram o mouse e não
recebem foco. A posição dos adornos foi elevada na revisão para não cobrir falas.

Os minimaps são visuais locais e não navegação automática. A meta de menos de
10% de HUD em exploração é diretriz do mockup, não medição comprovada em todos
os estados: placas e objetivos transitórios ocupam mais espaço na entrada.

## Verificação desta entrega

- Importação Godot sem erros de script/recurso.
- 58 verificações de contraste, medidas, estados, recortes e foco.
- 29 verificações de integração, incluindo pausa, mochila durante batalha e
  retorno sem perder posição/retomar o combate automaticamente.
- Jornada isolada com parque e cinco mapas do Morro: 198 verificações, zero falhas.
- Jornada com os recursos do PCK exportado: 201 verificações, zero falhas; o
  executor e suas fixtures ficam fora da distribuição. HUD do PCK: 58/58.
- Capturas em 1280×720: menu, diálogo, rua, controles, oficina, treino, parque,
  Morro, mochila, pausa, batalha, vitória e derrota.
- Capturas adicionais 1024×768: diálogo, batalha, pausa, mochila e Morro;
  1920×1080: menu. Capturas são conferência visual, não prova de controle físico.
- Fontes com licenças locais; prompts e procedência das artes preservados.

Esta integração local não publica na Steam nem no Git. Saves reais não foram
usados nos testes. O processo antigo aberto não foi encerrado.

## Continuação · 26/10/2026

Segunda passagem dedicada à animação. Novos executores isolados: hud_effects_checks
(18 verificações), campanha visual (30), transações do Morro (51, incluindo
comparação prévia/liquidação), domínio da campanha (206), regras do Morro (377)
e contratos de HUD (58). Zero falhas nessas verificações. Capturas reais adicionais
da transição no meio e ao terminar, impacto confirmado e resultados em 1024×768.

As prévias nunca creditam itens, XP ou moedas. Somente o botão de continuar chama
a transação existente. Não se adicionou hit-stop, tremor de câmera ou áudio nesta
passagem. Capturas de impacto usam fixture sintética com dano aplicado pelo mesmo
modelo e são congeladas para inspeção; não são gravação de uma luta completa.
