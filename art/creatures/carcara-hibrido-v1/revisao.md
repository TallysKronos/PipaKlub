# Revisão — Carcará identidade v2

2026-11-13. Crítica independente `/root/animation_pixel_critic`: R1 escolhida DEPOIS, 7,5/10, sem BLOCKING atual. O usuário reprovou a prancha-v1; a nota anterior não foi suficiente para detectar perda de identidade. Esta versão volta à fonte canônica e não herda sua aprovação.

Aseprite headless: duas camadas,20 quadros,4tags. Corpo/rosto/bico/losango/varetas/nós/rabiola preservados por máscara explícita e conferência pixel a pixel. `core-pixel-audit.json`: zero diferenças nos20quadros. `auditoria-aseprite.json`: exportação ASE/PNG idêntica. `validacao.json`: zero erros mecânicos.

Movimento deliberadamente discreto, limitado às asas originais, com pouca amplitude. É um compromisso de fidelidade, não uma atuação ampla. Textura/penas/padrões são os da fonte; a articulação em grade introduz mudanças pequenas de contorno nas asas. Foram removidos32pixels residuais desligados (10 na limpeza inicial e22 na R1 pontual do crítico), somente em camadas de asa, sem tocar a máscara protegida. Idle não desloca corpo, cabeça, rabiola ou centro.

Sem novas gerações ImageGen, sem vídeos, sem mudanças de runtime ou Git. A comparação final de amplitude continua sendo decisão visual do usuário.


## Rodada pontual R1

O crítico encontrou ilhas adicionais acima das asas em walk SW3/4 e NW3/4, apesar do QA mecânico inicial aceitar grupos maiores que2pixels. Os22pixels listados pertenciam às novas poses de asa, em posições transparentes na fonte/core; foram retirados exclusivamente da camada de asas. Snapshot PNG/ASE/GIF em `antes-r1/`. O crítico comparou antes/depois e escolheu a correção: ilhas removidas, asas ligadas, identidade conservada. Sem novo polimento.

A aprovação do usuário permanece separada da nota do crítico. O teste no renderer será feito pela integração.

Conferido no Godot ap�s aplica��o:4.042checks anima��o e334checks gr�ficos sem falhas nas su�tes espec�ficas. Capturas e GIFs em tmp/overworld-pranchas-lote-03/carcara-fix/. Inspe��o confirmou corpo e escala no cen�rio; n�o certifica aus�ncia de deslizamento nem aprova��o visual pelo usu�rio. PNGs do runtime s�o c�pias exatas da nova fonte. A vers�o rejeitada permanece apenas como hist�rico.
