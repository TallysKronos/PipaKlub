# Tramadraco 64×64 — continuidade do corpo

Correção da impressão de partes flutuantes apontada pelo autor no piloto v1. A camada `estrutura-articulacoes`, abaixo das placas, desenha a continuidade do pescoço, ombros, abdome e quadril em todos os oito frames. As onze camadas anteriores foram preservadas; não foi feita redução nem nova geração do concept.

A versão anterior já formava um único componente de alpha por causa da capa e dos contatos entre bordas. Isso não garantia continuidade anatômica: o vazio sob o peitoral separava visualmente peito e pernas. A correção trabalha esse volume, em vez de usar apenas uma contagem de componentes como aceite.

- Fonte: `tramadraco-64.aseprite`, 64×64, 12 camadas editáveis.
- Preview: `preview-6x.gif`, ampliado por nearest-neighbor.
- Pose: `tramadraco-64.png` e `preview-6x.png`.
- Atlas: `tramadraco-idle.png` e `.json`, oito frames, tag `idle-se`, 1.200 ms.
- Uma direção e idle; não é caminhada nem integração no jogo.
- Paleta e desenho externo preservados. A versão anterior permanece em `../pixel-64-v1/`.
