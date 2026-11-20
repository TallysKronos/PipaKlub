# Família Alvacordo — pré-evoluções em 3/4

Entrega: Farpim (bebê), Papisco (criança) e Velcão (jovem), preservando os concepts aprovados. Cada um tem idle, walk, victory e defeat; 8 quadros por ação, 32 por direção. Right é espelho horizontal exato de left, por célula. As fontes e atlases ficam nas subpastas de cada criatura. Alvacordo adulto aprovado aparece na comparação sem alteração dos seus assets.

## Escala

Todas as células são64×64, com pivô proposto (32,62), sem trim ou zoom individual por estágio. Retângulos da pose neutra medidos nos PNGs (máximos exclusivos):

| Estágio | Caixa opaca neutra | Altura |
| --- | --- | --- |
| Farpim | x17–48, y23–56 | 33px incluindo fio; cabeça/orelhas28px |
| Papisco | x19–45, y24–63 | 39px |
| Velcão | x3–62, y11–63 | 52px incluindo cauda elevada |
| Alvacordo | x3–61, y2–63 | 61px |

Farpim flutua e termina a derrota mais perto do solo. Seu walk é deslocamento aéreo sem pernas. Papisco é bípede criança com pulinho de vitória. Velcão é quadrúpede, com alternância de patas, cauda alta e velas de pipa. A largura maior do jovem vem da estrutura quadrúpede; ele não recebe a mesma altura vertical do adulto.

## Arquivos

- ../farpim/overworld-anim-64-v1/: farpim-left/right-atlas.png + .json e fontes farpim-overworld*.aseprite.
- ../papisco/overworld-anim-64-v2/: papisco-left/right.png + .json e fontes papisco-left/right-64.aseprite, com rig esquerdo separado.
- ../velcao/overworld-anim-64-v1/: velcao-left/right.png + .json, fontes .aseprite, base gerada, prompt e revisão.

index.html permite comparar mesma ação, escala e direção. Vitória e derrota seguram o término; o botão Repetir reinicia. GIFs ampliados existem em cada subpasta. A galeria usa Canvas2D local e não depende de fetch ou servidor; foi verificada por inspeção do código e caminhos, sem teste de navegador nesta entrega.

## Conferência

validar_familia.py lê os exports finais e confirma 32células64×64 por atlas, alpha binário e zero divergências nos espelhos das três pré-evoluções. validacao.json registra caixas e tempos de todos os frames. Revisão independente por filmstrips: Farpim8/10; Papisco7,5/10 após correção localizada de quadril/pernas em idle3–5/walk8 e baseline victory2; Velcão8,1/10. Nenhum bloqueador restante. Revisão estática não substitui playtest de ritmo e velocidade.

Assets preparados para avaliação e futura integração. Nenhum código do jogo, rig Soulgen aprovado ou manifesto de runtime foi substituído. Sem push nesta tarefa.

## Correção após o alerta de recortes

O usuário identificou cortes transparentes que a primeira auditoria não detectou. Reconstruída a anatomia escondida sob as translações de partes: Velcão recebeu492pixels em17quadros (sem alterar os opacos originais); Alvacordo recebeu correções de95pixels em11quadros nos punhos e resíduos de braço. Fontes, atlases e animações regenerados; espelho do Velcão revalidado. Snapshots/comparativos claros e magenta preservados nas pastas revisao-recortes de ambos.

Nova revisão independente em fundos contrastantes: Velcão7/10, Alvacordo8/10, sem recortes bloqueantes restantes. O preenchimento fecha as junções; ainda existem linhas internas rígidas no Velcão, registradas pelo crítico. A revisão antiga não serve como evidência de ausência desses defeitos.

A prévia agora tem avanço/recuo de quadro e fundo magenta, além dos fundos claro e escuro. verificar_recortes.py e validacao-recortes.json registram as diferenças reais e checam os pontos corrigidos. Conectividade de alpha é complementar: um arco pode manter braço e mão conectados enquanto o punho está cortado.
