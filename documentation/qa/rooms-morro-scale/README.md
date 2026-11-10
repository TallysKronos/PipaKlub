# Interiores e Morro do Sol

Revisão no Godot 4.7.2 a 1280 × 720, com cenas de teste e sem abrir os saves do jogador.

Foram medidas as oito vistas da mãe, do professor e dos seis rivais do Morro, mais os quatro quadros de caminhada da mãe em cada direção. A amostra contém 96 poses. No Morro, as 48 mudanças de direção foram verificadas pelo método de interação da campanha.

A mãe e o professor mantêm as proporções de adultos, respectivamente 1,08 e 1,12 vezes a altura visível do Kael. Os rivais jovens ficam próximos da altura do protagonista. Tião mantém a proporção de adulto.

A Mikka ainda usava um recorte antigo de maior resolução. Foi criada e integrada uma folha isométrica pixel art de oito vistas, preservando os elementos da personagem. A revisão também corrigiu o apoio dos pés da mãe entre repouso e caminhada.

- [Mãe e Kael em casa](home.png)
- [Professor e Kael no ateliê](professor.png)
- [Quadro da caminhada da mãe](mother-walk.png)
- [Zeca](morro-1.png), [Bia](morro-2.png), [Juninho e Lia](morro-3.png), [Tião](morro-4.png) e [Mikka](morro-5.png)

Executar `godot/tools/rooms_morro_scale_review.gd` em modo gráfico para repetir a medição e as capturas. Os dados por personagem ficam em `measurements.json`. A caminhada durante as sequências da casa é exercitada por `godot/tests/mother_walk_checks.gd`.
