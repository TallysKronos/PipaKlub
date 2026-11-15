# Portão independente — 15/11/2026

A folha fixa foi removida do construtor da casa. O componente está em
`godot/scenes/overworld/props/kael_gate.tscn`, com comportamento e geometria
em `godot/scripts/overworld/kael_gate.gd`.

- Pivô fixo na dobradiça (u 3,58; v 18,2); folha de 1,63 célula, abertura de 90° para o jardim.
- Quadro completo, lâminas, puxador e espessura; azul na paleta já aplicada na casa.
- Giro isométrico no espaço do mundo, sem esticar uma imagem ou girar o sprite na tela.
- Tween de 0,65 s, reversível, com desaceleração suave; poses geométricas atualizadas em 24 passos.
- Aproximação a menos de 2,5 células abre; ambos além de 3,3 células fecha. O companheiro mantém a passagem aberta.
- Folha fechada bloqueia a passagem; a colisão libera quando o giro já deixa a passagem livre.
- Profundidade dinâmica local para oclusão do Kael e companheiro, sem reconstruir o atlas estático do bairro.
- `set_open(bool, instant=false)`, sinais `opened` / `closed` e `automatic` permitem uso independente.

Validação: **51 verificações, zero falhas**, com slot descartável, sem tocar saves pessoais.
Inclui abertura e fechamento intermediários, inversão durante o movimento, colisão,
aproximação, retenção pelo companheiro, fechamento após afastamento, travessia nos dois
sentidos e entrada/retorno da casa. Capturas reais em `portao-fechado.png`,
`portao-abrindo.png`, `portao-aberto.png` e `portao-animado.gif`.

Comando de reprodução: Godot local com `--path godot --script res://tools/casa_kael_v2_integracao.gd`.
O gravador salva 56 capturas temporárias em `.local/qa/kael-gate-record/`; o GIF de revisão
usa 20 fps e paleta comum sem dithering. Não é um spritesheet de produção: a folha é animada no Godot.
