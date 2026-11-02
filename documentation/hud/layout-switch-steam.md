# HUD: layout para Nintendo Switch e Steam

Contrato de margens, espaçamento e texto de todas as telas. O código está em `godot/scripts/campaign/hud_layout.gd`. A linguagem visual (diagonais de 12°, seleção invertida, nanquim, respingos dosados) continua a da especificação `art/ui/hud-recorte-v1/ESPECIFICACAO.md`.

## Por que assim

O jogo renderiza numa base de **1280×720** (stretch `canvas_items`, aspect `expand`). Todas as medidas abaixo são nessa base.

| Aparelho | Resolução | Como a base aparece | Perfil |
| --- | --- | --- | --- |
| Switch portátil (6,2" a 7") | 1280×720 | 1:1, tela pequena na mão | portátil |
| Switch na base (TV) | 1920×1080 | ×1,5, TV a 2 ou 3 m | TV |
| Steam Deck | 1280×800 | 1:1 mais 80 de altura (16:10) | portátil |
| PC 1080p ou 1440p | 1920×1080 ou 2560×1440 | ×1,5 ou ×2 | TV |
| PC ultrawide | 2560×1080 ou maior | largura extra | TV, HUD em coluna 16:9 |

O caso mais difícil é o **Switch portátil**: a base aparece sem ampliação numa tela de 6,2". Por isso o texto mínimo é 15 e o perfil portátil soma 2 aos textos menores que 26.

## Regras

1. **Um retângulo seguro para todos os cantos:** `Layout.safe_rect(size)`.
   - Portátil: margem de 36 nas laterais e 28 em cima e embaixo.
   - TV: margem de 56 e 36, para o overscan.
   - Ultrawide: a HUD fica numa coluna 16:9 central, para os cantos não irem para a periferia da visão.
2. **Espaçamento só da escala** `Layout.space()`: xs 4, s 8, m 12, l 16, xl 24, xxl 32. Tamanhos e posições alinhados à grade de 4 (`Layout.snap`).
3. **Texto só da escala** `Layout.type()`: display 34, title 26, heading 22, label 20, body 18, small 16, micro 15. Nenhum texto funcional abaixo de micro.
4. **Ícone do botão do aparelho ativo** em toda ação: `Controls.glyph(acao)`. No Switch, confirmar é A (à direita) e voltar é B. Nunca escrever só o nome da tecla do teclado.
5. **Exploração ociosa abaixo de 10% da tela.** Objetivo e ferramentas do mouse se recolhem depois de 4 s.
6. Toda tela nova passa por `godot/tools/capture_campaign.gd --audit` em 1280×720, 1280×800, 1920×1080 e 2560×1080, sem problemas.

## Onde cada peça fica

| Tela | Canto superior esquerdo | Canto superior direito | Canto inferior esquerdo | Inferior central e direito |
| --- | --- | --- | --- | --- |
| Exploração | Área (título 26) e objetivo (corpo) | Minimapa 128 e, com mouse, ferramentas | Card do parceiro 328×100 e moedas | Correr (centro); interação e avisos (direita) |
| Batalha | Piloto 300×64 e Pausar | Rival(is) 300×104 | Parceiro 400×112 e "Segure para fugir" | Relógio e vento (centro, em cima); golpes (direita, até 12% da altura) |
| Diálogo | Retrato saindo da borda | — | — | Caixa de 3 linhas presa à margem; nome e Continuar como abas na borda de cima |
| Pausa | Título e menu em escada (degraus de 12, mesma largura) | — | Dicas de botão | Card da jornada à direita |

## Perfil manual

`Layout.profile_override` aceita `"handheld"`, `"tv"` ou `"auto"`. O automático escolhe portátil em telas de até 800 linhas. Testes e uma futura opção nas configurações podem fixar o perfil.
