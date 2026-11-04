# PIP-70 — Implementação local

Data: 27/10/2026. Branch: tallysroberto/pip-68-69-battle-hud. Sem novo push ou alteração de status no Linear.

## Apresentação

battle_corner_hud.gd é compartilhado por encontro selvagem, Lacertubo, Morro e treino do professor. Placa de identidade do tamer no topo esquerdo; rivais compactos à direita. O rival só fornece nome, Linha, Armação e rodadas ao desenho: rival_summary exclui energia e cooldowns. Morro usa coluna com dois rivais e placar em losangos; o professor é identificado como Sr. Assis no treino.

Parceiro à esquerda na base, com Linha em cor folha/sol/rabiola nos limiares de 50%/25%, Armação e dez blocos de energia. O custo da ação mantida pressionada recebe contorno nos blocos. Relógio em losango, etiqueta de rodada separada do vento. Vento consultado por wind_strength(), função também usada pela simulação; não há clima fictício. Últimos dez segundos em rabiola com chip, sem piscar. A vinheta de baixa Linha ocupa 6% da borda, estática e desenhada antes dos painéis.

A projeção vertical do plano de voo mede pelo menos 70% da altura em todas as quatro resoluções de aceite. As pipas mantêm proporções. Botão de pausa deslocado para baixo da identidade; placas, chips e ações ficam separados.

## Entrada e fases

Fuga usa o comando de interação configurado (E / botão sul por padrão), pressionado por um segundo. F permanece Especial. Chip aceita mouse mantido; soltar cancela a carga e pausa exige soltura antes de rearmar. Ao completar, emite o snapshot normal com outcome=fled e segue o salvamento/resultado existente. Não aparece no Morro.

Fases centrais usam lettering e pinceladas: contagem até três, JÁ por 400 ms, CORTOU/RODADA PERDIDA/EMPATE e losangos no intervalo do Morro. Transição de tinta no intervalo, respeitando reduzir movimento. Intro de Lacertubo com faixa e concentração fora do tempo de luta. O treino mantém suas instruções e mostra o mesmo componente de status acima delas.

## Verificação

- battle_corner_checks: 214 verificações sem falhas. Inclui separação geométrica, alcance vertical >=70%, ausência de energia/cooldowns rivais, limiares e fuga com soltura/pausa/snapshot único.
- battle_recorte_checks: 7.994 sem falhas.
- battle_flow_checks: 797 sem falhas.
- battle_signal_checks: 2.635 sem falhas.
- art_direction_checks: 11 sem falhas; limites atualizados para a nova distribuição.
- morro_checks: 377 sem falhas; controls_checks: 44 sem falhas.
- reward_layout_checks: 716 sem falhas, preservando a tela de resultado anterior.

Capturas com renderer em mockups/revisao/pip70: batalha, chefe, Morro, baixa vida/últimos segundos, intros e placar intermediário em 1280×720, 1280×800, 1920×1080 e 2560×1080. Capturas de treino em mockups/revisao/fluxos. Logs em documentation/battle-reports/pip70-*.log.

Verificações automatizadas e capturas locais não equivalem a aprovação visual do responsável, controle físico nem teste em Steam Deck. As regras de combate, recompensas e schema de save não foram alterados; wind_strength apenas centraliza a expressão já existente.
