# PIP-68 / PIP-69 — revisão da batalha no Godot

Branch: `tallysroberto/pip-68-69-battle-hud`. Implementação local; nenhum push ou alteração no Linear nesta etapa.

## Base sincronizada

Integrada a branch remota `tallysroberto/pip-66-65-textos-icones-glyphs`: especificação Recorte, tema, tinta, textos e glyphs configuráveis. `origin/godot` não tinha commits novos. As atualizações separadas de mapas, Bairro e Parque não foram incorporadas nesta etapa de combate.

## Barra de ações — PIP-68

- Área da barra limitada a 12% da altura durante a luta; escala uniforme de uma referência 112×128, com botão comum de 88×88 e especial em losango de 112.
- Rótulo fixo **Especial**, independentemente do nome específico da habilidade. Botão, arte, custo e legenda compartilham o eixo central.
- Seis ilustrações flat de mangá, geradas pelo image_gen integrado: corte de linha, vórtice de papel, esquiva, carretilha e mão, defesa de papel reforçado e salto do Rabbito. Fontes e prompts em `art/ui/battle-actions-manga-v1`; PNGs 256×256 no runtime em `godot/assets/campaign/battle-ink/actions-painted-v1`.
- Conforme correções pedidas pelo responsável, foram descartados os símbolos vetoriais e removidos respingos de fundo e blocos de custo que pareciam carga externa. Custo numérico com raio dentro do botão; preenchimento de carga/recarga geometricamente recortado no contorno. Não houve repintura por código das imagens geradas: apenas recorte alfa, escala uniforme e margem transparente.
- Número inteiro da recarga e legenda em regiões separadas; glyph do comando configurado, pouca energia, bloqueio, contorno ativo e breve brilho de disponibilidade.
- O componente é compartilhado pela batalha selvagem, Morro, Lacertubo e lição de voo. Dicas de ação ficam na pausa/lição. Painel de resultado volta a seguir o conteúdo, com faixa de resultado em escala própria: o limite de 12% vale durante o combate.

## Sinais e efeitos — PIP-69

- `contact_hint()` expõe interseções de ângulo fechado para uma mira inválida; `contact()` continua preservando os limites que autorizam dano, incluindo a regra do Azulão. `cut_quality()` é puro e compartilhado pela regra de dano e pela apresentação.
- Mira, faixa do centro da linha, três indicadores de qualidade, marca do jogador, contra-ataque, carga e halos. Avisos e anel de esquiva recebem prioridade sobre a mira.
- `signature_profile()` fornece alcance e tempo do especial ao modelo e ao desenho: Lacertubo 95 / 1,5 s, Rabbito 85 / 1,4 s, lição 78 / 1,65 s. O círculo é projetado pelo mesmo enquadramento da arena, ficando elíptico quando os eixos usam escalas diferentes. Segmentos próximos de outras pipas são omitidos, sem deslocar o alcance.
- `attack_notice()` publica a preparação atual dos rivais a partir do foco e dos critérios da IA existente; a HUD não inventa uma contagem nem calcula dano. Também cobre Mata Verde e rivais do Morro.
- Eventos confirmados fornecem ponto do cruzamento, crítico e cor do atacante; esquiva e bloqueio emitem feedback sem dano fictício.
- Respingos pequenos/médios/grandes com variação de fonte, gotas, rastro de esquiva, TCHAC!, TOC!, VUPT! e CRAAC!. No máximo três eventos numéricos. Textos usam caixas completas para procurar espaço e evitar outras pipas por 40 px e outros textos; se não houver espaço, são omitidos. Avisos importantes suprimem efeitos secundários.
- Pintura expira em 600 ms mesmo na pausa; números em 500 ms. Reduzir movimento usa fade de 80 ms sem deslocamento, gotas ou linhas de concentração. Transição de mancha na cor do vencedor ao apresentar o resultado.
- Corrigido um defeito encontrado nas rodadas: a forma inclinada das barras de status podia cruzar a si própria perto de zero. Agora o recorte é limitado pela largura e permanece convexo, incluindo energia quase vazia.

## Evidências executadas

- `battle_recorte_checks.gd`: **7.994 verificações**, zero falhas, incluindo 46 contatos reais, seis estados, quatro resoluções (1280×720, 1280×800, 1920×1080, 2560×1080) e contenção dos preenchimentos.
- `battle_signal_checks.gd`: **2.635 verificações**, zero falhas, com 1.200 posições de teste, contatos, alcance projetado, afastamento de textos, expiração e triangulação de barras quase vazias.
- Regressões: `art_direction_checks.gd` 11, `hud_effects_checks.gd` 18, `campaign_checks.gd` 206 e `morro_checks.gd` 377; zero falhas. A campanha usa armazenamento isolado.
- Capturas dos seis estados em todas as quatro resoluções, nos três tipos de batalha, mais seis exemplos de sinais: `mockups/revisao/batalha-acoes-*.png` e `batalha-sinais-*.png`.
- **Três rodadas completas**, com todos os comandos mapeados e movimento por entradas de joypad injetadas no Godot. Mata Verde 20,5 s, primeiro round do Morro 22,7 s, Lacertubo 30,5 s. Nenhum dano, vida, relógio ou vencedor foi forçado; o roteiro de comandos pode vencer ou perder. Foram geradas 45 capturas e rastros de estado, sem erros do renderer.
- Revisão interativa das sequências: `mockups/revisao/rodadas/index.html`. Relatório e rastros: `report.json`. Os intervalos entre prints são menores ao aparecerem avisos; a sequência não é um vídeo contínuo.

## Reprodução e limites

### Pausa, lição e modo de movimento reduzido

Passagem adicional: `battle_flow_checks.gd`, **754 verificações sem falhas**. Corrigida a propagação da preferência de movimento reduzido para a lição e seus botões; removido o halo duplicado antigo da defesa. A pausa limpa os comandos pendentes imediatamente, mesmo quando pausa e retorno acontecem no mesmo frame. Após retomar, ações mantidas pressionadas aguardam soltura e novo acionamento. A falha de salvamento impede o avanço do modelo mesmo se outro chamador não tiver marcado pausa. Na pausa de batalha, a condição do parceiro é calculada a partir do combate atual em uma cópia de apresentação; o save só recebe o dano pelo fluxo de combate normal. Texto da pausa identifica o contexto de batalha, em vez de sugerir exploração ou reparo no meio da luta.

Também passaram `controls_checks.gd` (44) e `campaign_view_checks.gd` (30). Capturas adicionais: 48 imagens das cinco lições e da pausa, com e sem redução de movimento, nas quatro resoluções, em `mockups/revisao/fluxos`. Os registros ficam em `documentation/battle-reports`. Passagem seguinte: a lição passou a usar toda a largura disponível para a arena. O fundo recebe recorte proporcional, personagens mantêm proporções, status ficam nas extremidades e instruções e comandos compartilham a linha superior do rodapé. Mouse, linhas e sinais usam a mesma projeção; a área-alvo também é projetada. As cinco lições foram capturadas nas quatro resoluções, com e sem redução de movimento. Isso não declara todos os demais requisitos da PIP-71 concluídos.

Para revisão manual direta, `godot/Revisar-Batalha.ps1` aceita `-Tipo Selvagem`, `-Tipo Morro`, `-Tipo Chefe` ou `-Tipo Treino -Licao 1` (até 5), além de `-ReduzirMovimento`. Cria um slot e preferências isolados, começa pausado e permite teclado ou controle, sem pular etapas ou alterar saves reais. O carregador `battle_review.gd -- --smoke` foi verificado nos cinco pontos de entrada representativos.

Execute verificações isoladas explicitamente com Godot `--headless --path godot --script res://tests/<nome>.gd`. Para capturas com renderer, execute `res://tests/battle_recorte_checks.gd -- --capture` ou `res://tools/battle_round_capture.gd`, sem headless. Depois, `node scripts/build-battle-round-review.mjs` prepara o visualizador.

O gravador cria um slot isolado válido antes de capturar e completa a metadata ausente dos fixtures visuais (id, retorno e cena). Isso evita interpretar um fixture estático sem slot como falha real de salvamento. Ele não altera o save do jogador nem flexibiliza sua validação.

Os testes cobrem o caminho de entrada de controle por simulação, **não um controle físico**. Ainda falta a sessão manual com o responsável para aprovar legibilidade e sensação em movimento, especialmente no Steam Deck. A auditoria geral de HUD e todas as demais telas continuam no escopo da PIP-78; não estão certificadas por estas verificações de batalha. As artes geradas ficam registradas para avaliação visual. Regras, recompensas e schema de saves foram preservados.

## Revisão na janela nativa — 27/10

Corrigida a sobreposição do botão interno Retomar com salvar/sair: ele participa da linha de status durante a pausa, preservando o foco do menu modal. As verificações incluem separação dos botões e retenção do foco.

Em sessão isolada na janela Windows, foram observados: retomada do combate pelo botão, derrota e retorno ao parque, retomada do treino e acionamento da habilidade pelo card, com energia em 79% e recarga visível dentro da forma. O pressionamento curto de Q pela automação não produziu evidência visual suficiente para confirmar esse comando nesta sessão; não é declarado aprovado manualmente. O teclado/joypad continua coberto pelas verificações isoladas, sem equivaler a controle físico.

## Padronização visual — treino e orientação

O treino agora usa battle_ink.status, com as mesmas molduras, retratos, tipografia e barras de Linha/Armação/Energia das demais batalhas; o centro identifica a lição. A projeção reserva espaço sob os cards para não esconder os personagens. Retomar usa o destaque primário no menu de pausa, com margem para o foco.

Folhas de Rabbito, Nozinho e Lacertubo voltadas à direita são espelhadas para encarar o alvo na arena; o retrato rival de Lacertubo encara o centro. A inversão mantém posição e pivô e não altera a física. As verificações de fluxo passaram com 797 checks; as de batalha Recorte passaram com 7.994. Não foi feito novo push nesta passagem.

### Botões e configurações

Adicionado contrato compartilhado navigation_button para altura mínima, ícones e tratamento de texto. Aplicado na navegação geral, treino, pausa e resultado; salvar/fugir usam aparência secundária e continuar/retomar mantêm destaque primário. Configurações receberam painéis Recorte, espaçamento e seletor com altura consistente; o rótulo Especial também aparece nos controles.

Auditoria renderizada de configurações, pausa, vitória, derrota e lição 4 em 1280×720 e 1280×800: 10 capturas, sem ocorrências de corte ou sobreposição no medidor. Evidências em mockups/revisao/menus. Campaign view: 30 verificações sem falhas; fluxo: 797 sem falhas. Escopo desta passagem não certifica todas as telas do jogo.

### Resultado central com capacidade de equipe

Referências: Persona 5 Royal (galeria 4Gamer 056, separação de XP/moedas/itens) e Pokémon Sword/Shield (lista individual de progressão). Painel limitado a 900 unidades, duas colunas, altura de 320–420 unidades, banner reduzido e botão central de 280. Conteúdo excedente rola dentro de cada coluna; a ação de retorno fica fora da rolagem.

additional_recipients aceita participantes adicionais com nome, XP e barra opcional baseada em progress/threshold fornecidos pelo produtor. Não distribui XP nem cria recompensas: o preview atual continua concedendo apenas ao parceiro ativo. O cenário capacidade-previa usa dados sintéticos explicitamente nomeados para dois mons e tamer; não salva esses dados. reward_layout_checks: quatro resoluções, vitória/derrota/capacidade. Artes de itens existentes são reutilizadas.

### Resultado v2 — tamer, três espaços de time e saques

Redesenho seguindo o rascunho fornecido: tamer com retrato e XP à esquerda, três cards fixos de Soulmonsters ao centro, moedas e lista de itens à direita. O preview agora simula Progression.award em cópias e expõe o ganho real de tamer, antes omitido. A curva de nível do tamer usa 20*n+3*n*n, igual a src/engine.js. Reservas sem participação recebem zero XP. Espaços vazios não inventam novos parceiros. Capacidade-previa usa equipe sintética de três integrantes apenas para apresentação, sem gravar o estado.

Arte gerada via image_gen: result-frame-v1.png, fonte/proveniência em art/ui/battle-results-v2. A decoração é escalada uniformemente e fica atrás da área quieta de leitura; retratos, barras, números e botões continuam separados. Sem novo push. Testes: hud_effects_checks 20, battle_flow_checks 797; capturas de layout nas quatro resoluções pelo reward_layout_checks.

### Contorno orgânico sem máscara retangular

Removida a placa ciano que encobria a ilustração. A base agora é NinePatchRect com escala uniforme de 0,32 nos recortes fixos (380/380/180/170 de origem), estendendo apenas as regiões apropriadas de fundo. A rolagem externa deixa de cortar os ornamentos no resultado; a lista interna de recompensas mantém a rolagem. Texto do tamer centralizado na área quieta. Título separado do contorno superior. reward_layout_checks ampliado para 68 verificações, incluindo escala uniforme, ausência de clipping no ancestral e contenção do quadro ilustrado na tela.

### Harmonia interna do resultado

Mantida a moldura aprovada. Cards e faixa do tamer compartilham hud_result_plate.gd: recorte de papel com área quieta, sombra e pequenos acentos. Não usa o frame retangular genérico. Retratos do time aumentados, dados do tamer agrupados e botão Continuar de 240×48 com amarelo da vitória e estados de hover/pressionado. Capturas em 16:9, 16:10 e ultrawide pelo teste de layout. Passaram 68 verificações de layout, 797 de fluxo e 20 de efeitos/recompensas.

### Auditoria de textos e respiro

Corrigida sobreposição do subtítulo por ornamentos: cabeçalho próprio em z=5, faixa quieta para o subtítulo, separada dos strokes. Títulos de seção ganharam placas discretas. Padding superior 44 e direito 52; textos menores passaram a 14 unidades lógicas; legenda XP foi encurtada para evitar quebra redundante. Auditoria ampliada verifica altura de linhas, tamanho de fonte, visibilidade dos textos fora de listas roláveis, camada de cabeçalho e nomes longos de tamer/mon. Foram 716 verificações sem falhas com --long-text, mais capturas normais em quatro resoluções. A inspeção visual confirmou a leitura do subtítulo e das seções em 1280×720 e 1280×800. Não equivale à aprovação visual do responsável.
