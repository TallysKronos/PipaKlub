# Playtest dos companheiros de overworld v2

Teste gráfico executado em 12/11/2026 no parque Veredas, com o caminho e a física de acompanhamento usados pelo jogo. Save isolado; nenhum progresso do jogador foi alterado.

## Amostra e resultado

| Soulmonster | Altura visível | Caminhada e corrida | Distância máxima do Kael |
| --- | ---: | --- | ---: |
| Farpim | 41 px | Passou | 0,80 célula |
| Papisco | 55 px | Passou | 0,80 célula |
| Azulfazo | 70 px | Passou | 0,80 célula |
| Capibaluarte | 84 px | Passou | 0,80 célula |
| Trovareta | 84 px, silhueta larga | Passou | 0,80 célula |

O percurso de aproximadamente dez células por criatura cobriu ida andando e volta correndo, com vistas nordeste e sudoeste. O companheiro permaneceu visível, com escala 1 e apoio consistente. As quatro orientações diagonais e o espelhamento também receberam verificações programáticas.

- Teste visual automatizado: **1.675 verificações, zero falhas**.
- Regressão dos companheiros: **518 verificações, zero falhas**.
- Oclusão no percurso: objetos atingiram opacidade 0,45 quando necessário.

## Correção encontrada

A oclusão usava um retângulo fixo de 40 × 42 px para o companheiro. O teste anterior registrou quatro falhas ao simular uma copa sobre a parte superior dos sprites maiores.

O renderer agora usa os limites opacos da vista atual, respeitando espelhamento, apoio e escala. Esses limites são calculados ao equipar o companheiro e reaproveitados no posicionamento e na transparência dos obstáculos. Testes adicionais com pequenas copas sintéticas verificam o topo, as extremidades laterais e a recuperação da opacidade após afastamento.

## Evidências e limites

- [Capturas do percurso](percurso.png).
- GIFs: [Farpim](farpim.gif), [Papisco](papisco.gif), [Azulfazo](azulfazo.gif), [Capibaluarte](capibaluarte.gif), [Trovareta](trovareta.gif).
- [Resultado estruturado](resultado.json) e [falhas anteriores](antes.json).
- Harness: `godot/tests/overworld_visual_playtest.gd`.

As capturas usam janela 1280 × 720, câmera em zoom 1 e filtro CRT desligado para avaliar os pixels nativos. Isso não valida todas as combinações de resolução, zoom fracionário e CRT. O teste executa comandos pelo caminho de produção; não simula entrada humana de teclado. As provas de copa superior e lateral são sintéticas, além dos obstáculos reais encontrados no percurso.

Os sprites dos companheiros ainda são poses estáticas durante o deslocamento. O próximo trabalho visual é criar idle e caminhada, preservando o apoio e o volume das duas vistas. Os logs também contêm avisos preexistentes de identidades de NPC (Cauê/Celina); estes resultados não equivalem a uma auditoria completa da campanha.
