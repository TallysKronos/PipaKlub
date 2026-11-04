# Entrada e HUD de boss

01/11/2026 — Lacertubo, campanha Godot.

Antes do combate, uma faixa diagonal em nanquim, coral e amarelo apresenta o retrato aprovado do guardião e lettering vivo. Retículas, pinceladas e riscos usam a linguagem existente do kit. A introdução dura 3,2 segundos; as pipas ficam ocultas até o fim. Movimento, ataques, dano e cronômetro da luta não avançam durante a entrada. Comandos mantidos pressionados precisam ser soltos antes de disparar. Pausar preserva o tempo da apresentação.

Bosses usam uma barra superior larga e segmentada, com retrato, nome, nível, tempo restante, fase real, linha e armação. As dez divisões são escala visual da linha, não novas fases ou vidas. Os encontros comuns mantêm a HUD atual. Vitória/derrota mantêm as telas compartilhadas.

Movimento reduzido substitui o deslocamento lateral por fade. Textos e valores são desenhados em tempo real; não fazem parte de uma imagem achatada.

## Conferência

- `boss_presentation_checks.gd`: 67 verificações, zero falhas, incluindo 1280×720, 1920×1080 e 800×600, movimento normal/reduzido, bloqueio de comandos, pausa/retomada, HUD dentro da tela e resultados.
- `battle_corner_checks.gd`: 214 verificações, zero falhas.
- `battle_flow_checks.gd`: 797 verificações, zero falhas.
- `campaign_checks.gd`: 206 verificações, zero falhas.
- `reward_layout_checks.gd`: 1.604 verificações, zero falhas.

Capturas nativas a 1280×720 nesta pasta: entrada normal/reduzida e HUD com valores sintéticos de fase 2 (linha 42%, armação 73%). As imagens foram inspecionadas visualmente. Não se trata de uma vitória obtida por playtest humano. Saves de teste isolados.
