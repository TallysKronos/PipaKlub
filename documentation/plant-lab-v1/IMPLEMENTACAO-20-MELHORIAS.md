# Soulmonsters Studio — 20 melhorias implementadas

Entrega local de 06/11/2026. Escopo: todos os itens ST-01 a ST-20 do [mapeamento](MAPEAMENTO-DE-MELHORIAS.md). A bancada permanece top-down, com tiles de 32 px e exportação Godot. Não houve merge nem publicação na campanha.

| Item | Implementação disponível | Evidência principal |
|---|---|---|
| ST-01 | Prévias de piso, parede, relevo, rampa, cachoeira e colagem; motivo textual para locais inválidos | `brush-preview.test.mjs`, `geometry-preview.test.mjs`, `preview-ui-check.mjs` |
| ST-02 | Foco por cota com atenuação e trava; preferências separadas do documento | `level-focus.test.mjs`, `level-focus-ui-check.mjs` |
| ST-03 | Barra contextual, Terreno/Paredes/Cachoeiras separados, biblioteca sincronizada | `preview-ui-check.mjs`, `material-panels-ui-check.mjs` |
| ST-04 | Vários projetos nomeados, salvamento IndexedDB, backup pendente e 20 versões recuperáveis por projeto | `projects-audit-ui-check.mjs` |
| ST-05 | Validação com avisos localizáveis, exceção decorativa e alerta de rota de NPC interrompida | `map-audit.test.mjs`, `projects-audit-ui-check.mjs` |
| ST-06 | Pincel redondo, linha, retângulo, elipse e laço; confirmação por gesto e um desfazer | `regions.test.mjs`, `regions-ui-check.mjs` |
| ST-07 | Seleção/cópia de pisos, alturas, paredes, rampas/escadas, água, variantes e objetos; altura absoluta ou relativa | `regions.test.mjs`, `variation.test.mjs`, `regions-ui-check.mjs` |
| ST-08 | Nascente e destino geram canal, queda válida e poço escavado; prévia e desfazer único | `advanced-tools.test.mjs`, `advanced-ui-check.mjs` |
| ST-09 | Rampas e escadas N/S/L/O, largura de 1–4 tiles; patamares validados e trânsito nos dois sentidos | `ramp-directions.test.mjs`, `final-workflows-ui-check.mjs`, paridade Godot |
| ST-10 | Carimbos nomeados persistentes em IndexedDB, reutilizáveis entre projetos com assets próprios | `regions-ui-check.mjs` |
| ST-11 | Colisão de círculo, retângulo e polígono, com deslocamento da base; preservação em JSON e Godot | `advanced-tools.test.mjs`, `advanced-ui-check.mjs`, `check_runtime.gd` |
| ST-12 | Spawn, saída entre projetos, NPC/diálogo, encontro, gatilho, item, condições, uso único e patrulha por pontos | `advanced-tools.test.mjs`, `advanced-ui-check.mjs`, `final-workflows-ui-check.mjs`, `check_runtime.gd` |
| ST-13 | Exportação independente, adaptador da campanha, diferença antes de reimportar, conflitos e montagem em namespace | `reimport-check.mjs`, `check_adapter.gd` em projeto isolado, `check_runtime.gd` |
| ST-14 | Coleções de bioma, favoritos, recentes, busca e biblioteca de assets importados | `advanced-ui-check.mjs`, filtros de `biomes-scatter.mjs` |
| ST-15 | Variantes A/B/C com pesos e semente; distribuição de vegetação com densidade/pesos; prévia/aplicar/cancelar | `variation.test.mjs`, `advanced-tools.test.mjs`, `final-workflows-ui-check.mjs` |
| ST-16 | Água com três graus de profundidade, correnteza N/S/L/O e quedas animadas de três larguras | `water.test.mjs`, `waterfalls.test.mjs`, UI e paridade Godot com água funda |
| ST-17 | Minimap com posição de Kael, eventos e janela de câmera; clique navega | `advanced-ui-check.mjs`, capturas finais |
| ST-18 | Kael idle/caminhada em duas vistas, espelhamento e teste no ponto apontado; colisões visíveis no editor | `advanced-ui-check.mjs`, atlas `art/characters/kael/overworld-walk-v1`, execução Godot |
| ST-19 | Importação PNG/spritesheet, grade, pivô, frames/FPS, colisão inicial, biblioteca persistente e JSON portátil | `import-integration.test.mjs`, `advanced-ui-check.mjs`, `check_runtime.gd` |
| ST-20 | Mapas até 64×64, prévia das perdas ao reduzir, repintura por índices/colunas, caches limitados e culling | `incremental-raster.test.mjs`, `import-integration.test.mjs`, `final-workflows-ui-check.mjs`, benchmark |

## Verificação realizada

- 86 testes Node passaram na rodada completa: geometria, 47 encaixes, isolamento por cota, cópia, colisões, eventos, variantes, água, assets, exportação e raster incremental.
- Fluxos em Chromium isolado: prévias/contexto, foco, projetos/versões, seleção/carimbos, importação, colisão, eventos, caminhada, rio, variantes, distribuição, resize e saída entre projetos.
- Capturas revisadas em 1440×900, 1280×720, 1920×1080 e 844×390. A interface estreita usa painéis roláveis; desktop continua sendo a área de trabalho recomendada.
- Godot 4.7.2: importação, execução, atlas próprio com colisão, patrulha, ponte de área e adaptador aceito pelo `map_model.gd` real da campanha.
- `check_autotile.gd`: raster dinâmico idêntico ao exportado, incluindo quatro direções de rampa, escadas, variantes e água funda. A asserção original do ponto de chão permaneceu intacta.
- Reimportação testada com uma edição manual real: o processo recusou a substituição e preservou o arquivo. Ajustes em `area-overrides.json` sobreviveram à atualização.

As evidências ficam em [captures](captures/), especialmente `final-workflows.json`, `reimport-check.json`, `performance-benchmark.json` e as imagens `final-studio-*`, `stairs-wide-studio.png` e `river-guided-preview.png`.

## Limites definidos da entrega

- O construtor guiado desenha rios da nascente para um destino ao sul. Poços precisam ficar dentro do mapa para fechar as margens. Quedas independentes continuam disponíveis.
- Os NPCs são marcadores funcionais com diálogo e patrulha; não foi inventada uma nova biblioteca de arte de personagens. Rotas são segmentos explícitos; o validador avisa se cruzam água ou barranco, sem prometer navegação automática.
- Encontros, itens e saídas enviam metadados/sinais para a campanha. Conectar esses sinais ao combate, inventário e narrativa depende da integração da área, não altera esses sistemas automaticamente.
- `area.overworld.json` é um adaptador lógico para o contrato isométrico existente. O desenho top-down é preservado por `area_bridge.gd`; não se deve usar a projeção antiga para mostrar a arte nova.
- A medição de desempenho é CPU local do raster Node, não uma promessa de FPS em qualquer máquina. O limite ficou em 64×64; não foi aumentado além do que foi medido.
- PNGs importados: até 2048×2048, 64 frames, 32 assets por mapa, 8 MB de fontes no JSON e 16 milhões de pixels acumulados. Até 1.500 objetos e 500 eventos.

Guia de uso: [MANUAL-DO-STUDIO.md](MANUAL-DO-STUDIO.md). Integração: [INTEGRACAO-GODOT.md](INTEGRACAO-GODOT.md).
