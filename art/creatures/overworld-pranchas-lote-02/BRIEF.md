# Lote 02 — teste de fluxo enxuto

Cinco modelos: Alvacordo, Papisco, Velcão, Gambalhote e Alvaneve. A identidade vem exclusivamente dos sprites já aprovados. Dados e diferenças anatômicas estão em `batch.json`.

## Contrato comum

Uma geração por vista/ação: caminhada com seis poses SW/NW, seguida de idle com quatro poses SW/NW condicionado no mestre exportado da caminhada da mesma vista. Não inventar redesigns ou anatomia. Alturas preservadas: 84, 55, 70, 55 e 84 px, respectivamente; célula112×112, apoio56,100, SW na linha superior/NW na inferior, runtime escala1. Paleta da fonte, alpha binário, contornos e detalhes legíveis.

Importação/finalização em Aseprite com scripts reutilizáveis, escala comum por folha e correção somente de defeitos concretos. Registrar pinturas individuais separadamente de ajustes de grade/paleta/alpha. Não voltar a deformações regionais para fingir movimento nem retomar a fila de vídeos.

Uma revisão visual conjunta das cinco criaturas, com verificação própria de cada uma. Crítica independente >=7/10 e nenhum bloqueio para publicar localmente. Corrigir apenas os achados; preservar os demais modelos/poses. Uma rodada de testes do lote no Godot depois da integração. A geometria e as métricas não substituem avaliação visual da cadência ou certificam ausência de deslizamento.

## Arquivos e execução

- `prompts-walk.json` e `prompts-idle.json`: pedidos exatos do ImageGen integrado; fontes geradas preservadas nas pastas individuais.
- `scripts/overworld-xprite-v2/prancha-batch.py`, `prancha-import.lua`, `prancha-review.py`: importação e revisão comuns.
- Cada `<id>-prancha-v1/`: PNGs, GIFs, Aseprite, manifest, validação, revisão e cópias `antes-*` do runtime.
- `scripts/overworld-xprite-v2/hybrid-review.py`: validação e cópia exata para runtime depois da revisão.
- Testes: `overworld_animation_checks.gd` e `overworld_visual_playtest.gd -- --models=alvacordo,papisco,velcao,gambalhote,alvaneve --evidence=tmp/overworld-pranchas-lote-02/playtest`.

Entrega: uma galeria, uma síntese e o estado real dos cinco. Não afirmar economia percentual de tokens sem medição comparável. Sem merge ou push.
