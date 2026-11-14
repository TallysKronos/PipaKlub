# Lote ampliado do laboratório v2

14/11/2026. Pronto para a etapa 1 (blockout).

## Coordenadas (células do bairro `bairro-inicial-v2`, mapa `quintal`)

`u` cresce para a direita da planta e `v` para baixo (sul). Na câmera isométrica do jogo, o norte
(v menor) fica para cima e à direita.

| O quê | Valor |
| --- | --- |
| Lote do laboratório | **u 0,5 → 14,0 · v -10,0 → -1,0** (13,5 × 9 células) |
| Frente do lote | a linha v = -1, de frente para a calçada da Rua dos Inventos |
| Entrada sugerida | **(7,25; -1,0)**, no meio da frente |
| Sr. Assis (NPC) | (6,8; -0,65), na calçada, em frente à entrada |
| Altura do terreno | o lote inteiro está no nível alto do bairro (48 px), o mesmo da calçada |
| Vizinhos | casa vizinha a leste em u 15 → 20 (foi afastada 2 células); nada a oeste (borda u = 0) |

No código: `StarterNeighborhood.PROFESSOR_LOT` em `godot/scripts/overworld/starter_neighborhood.gd`
(a borda norte do bairro passou de v = -7 para `StarterNeighborhood.NORTH` = -10).

## Escala

- O Kael mede 70 px na folha; uma célula do bairro tem 64 px de largura na projeção 2:1.
- O lote tem 13,5 células de largura e 9 de fundo: o prédio, a escada e a rampa da frente e o pátio
  cercado da direita (F1 a F9 do brief) cabem nele.
- Deixe ao menos 1 célula livre entre a escada e a calçada (v -2 → -1) para o Kael e o companheiro
  passarem.

## Estado atual

O laboratório antigo continua desenhado no lugar (`building([2,-5,8,-1.7], "professor", ...)`) para o
jogo não ficar com um buraco até a v2 ficar pronta. Na integração, a v2 ocupa o lote inteiro
(`building(PROFESSOR_LOT, "professor", ...)`) e a entrada passa para (7,25; -1,0).

## Imagens

- `lote-celulas.png`: planta do bairro em células, com o lote em vermelho, os vizinhos e a entrada.
- `lote-no-jogo.png`: captura do jogo com o lote ampliado (o laboratório antigo ainda no lugar).
