# Parque → Clareira → Veredas, revisão nativa 2

Atualização 29/10/2026: a parte de Veredas descrita abaixo foi substituída pela reconstrução modular em `../veredas-modular-v5/`. As notas antigas são histórico do protótipo, não a descrição do renderer atual. Jardim e Clareira conservam os consumidores descritos aqui.

Estado: integrado localmente aos três consumidores reais da campanha, em revisão artística. Não publicado. Os mapas de revisão antigos de `overworld/view.gd` continuam separados; a campanha usa `park_route_view.gd` e `park_view.gd`.

## O que mudou

- Jardim das Pipas: largo baixo, coreto com telhado/pilares separados, habitat superior +48 px e rampa de terra de 192 unidades. A implantação do coreto determina os quatro bloqueadores dos pilares, substituindo as cinco colisões antigas nessa instância.
- Clareira do Papel: espaço central aberto, habitat superior +64 px e rampa em outra posição. O professor permanece no Jardim; a placa da Clareira conserva a orientação de encontros.
- Veredas: solo reconstruído em malhas, encosta contínua 0→80→112 px, pátio do Lacertubo, canos, pontes com guarda-corpos e canal abaixo da margem em −24 px. Faces chegam a −32 px; não há água sobre o caminho.
- Piso usa os materiais de grama e terra da planície aprovada, com mistura irregular curta. Árvores usam a mesma família. Barrancos usam terra da vila e rocha do cais. Fonte externa nova não foi gerada.
- Fundo preto azulado independente por cena. Água respeita movimento reduzido. Capim marca os habitats existentes, com distribuição determinística irregular.

Topos, faces, rampas, bases dos props, personagens e projeção de cliques usam `scripts/overworld/park_landscape.gd`. Os pisos do Parque são amostrados em malhas de 16 unidades; fronteiras de material não geram paredes. Nas Veredas, os contornos de sustentação são unidos antes das faces; faces posteriores são omitidas para não rasgar os pisos.

## Campanha e dados

As coordenadas persistidas, os destinos, os pontos de Nina/Lacertubo/rabiola/baús e as regras de recompensas permanecem no domínio existente. A projeção visual aplica a altura; os cliques fazem a transformação inversa nas Veredas. Não requer migração de saves nem de banco. Um save que coincida com um pilar novo é reposicionado localmente para uma posição livre próxima.

O Parque agora bloqueia a travessia direta dos barrancos; jogador e parceiro percorrem a rampa. A navegação das Veredas continua usando as superfícies e obstáculos existentes, revestidos pela geometria nova. As regras de encontros, XP, raridade e missão não foram rebalanceadas.

## Conferência

- Godot 4.7.2 / OpenGL Compatibility, capturas 1280×720: vistas gerais, entrada, patamares, ponte, encosta e pátio.
- Bocas superior/inferior das rampas ampliadas e sem ocupantes; três capturas de geometria sem texturas.
- `tests/park_landscape_checks.gd`: saídas/interações alcançáveis nos dois mapas, duas chegadas de cada rampa, bloqueio dos barrancos e inversão da projeção elevada; sem falhas.
- `tests/park_checks.gd`: 1.510 verificações existentes de colisão e entrada; sem falhas.
- Logs locais em `tmp/park-landscape-review.log`, `tmp/park-landscape-checks.log` e `tmp/park-legacy-checks.log`.

As capturas usam instâncias da campanha com dados fictícios em memória, sem Session, salvamento ou recompensas. Não substituem uma partida completa, teste de todos os controles ou aprovação artística do usuário. A revisão de geometria não é um novo sistema de natação.

## Abrir a prévia caminhável

```powershell
powershell -ExecutionPolicy Bypass -File tools/overworld/open-park-landscape.ps1
```

Os botões Jardim, Clareira e Veredas trocam a área. WASD/setas caminham; Esc pausa. A prévia é independente e não salva progresso nem resolve interações de missão. A campanha normal continua com suas interações/recompensas. Para repetir as capturas, execute Godot com `--path godot --script res://tools/park_landscape_review.gd`.
