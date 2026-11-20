# Integração e reimportação Godot

O botão **Exportar Godot** baixa um projeto completo para abrir no Godot 4. A bancada web continua sendo o editor principal. A cena exportada é executável e mantém os pixels, volumes, animações, colisões e eventos.

## Conteúdo

- `layout.json`: documento top-down completo e portátil.
- `catalog.json`, `assets/`: assets nativos e importados, pivôs e animações.
- `autotile/`: texturas, 47 encaixes, camadas pré-calculadas e dados para regeneração.
- `main.tscn`, `lab.gd`: bancada nativa de verificação.
- `area_bridge.gd`: entrada de runtime com posição de Kael, eventos e sinal `interaction_requested(event)`.
- `integration/area.overworld.json`: adaptador lógico para `overworld-godot-1`.
- `integration/area.topdown.json`: fonte top-down preservada.

O adaptador preserva IDs, materiais e metadados de colisão. Ele usa as coordenadas lógicas do contrato existente; o desenho top-down deve ser montado pela ponte, não projetado pelo renderer isométrico antigo. O adaptador foi carregado pelo `godot/scripts/overworld/map_model.gd` real em um projeto de teste separado.

## Revisar antes de atualizar

Execute na raiz do repositório, trocando o arquivo e o ID:

```powershell
node tools/plant-lab/reimport-godot.mjs --layout meu-mapa.json --area bosque-a
```

Isso prepara `exports/studio-generated/bosque-a/reimport-review.json` com arquivos adicionados, alterados, iguais, removidos da proposta e conflitantes. Sem `--apply`, não substitui os arquivos gerados.

Depois da revisão:

```powershell
node tools/plant-lab/reimport-godot.mjs --layout meu-mapa.json --area bosque-a --apply
```

A atualização usa hashes de `manifest.json`. Uma mudança manual em arquivo gerado bloqueia **toda** a substituição, sem sobrescrever essa mudança. `area-overrides.json` fica fora da pasta `generated` e não é reescrito; é um local para registrar ajustes e decisões de integração. Esses overrides não são aplicados silenciosamente ao mapa: o consumidor da campanha deve interpretá-los.

Arquivos que saem de uma proposta são relatados e conservados no disco. Isso evita apagar ajustes ou recursos durante a revisão. Recursos sem referência não entram no catálogo do mapa atualizado; a limpeza física deve ser uma ação deliberada posterior.

## Montar em uma pasta de outro projeto

Os recursos de um projeto independente usam caminhos `res://`. Para preparar uma versão aninhada sem quebrar esses caminhos:

```powershell
node tools/plant-lab/stage-embedded.mjs --area bosque-a
node tools/plant-lab/stage-embedded.mjs --area bosque-a --apply
```

O comando cria uma **prévia isolada** em:

```text
exports/studio-generated/bosque-a/embedded-preview/
  project.godot
  studio-generated/bosque-a/
    main.tscn
    area_bridge.gd
    layout.json
    assets/...
```

Scripts e cenas passam a apontar para `res://studio-generated/bosque-a/`. A montagem tem revisão e manifesto próprios; também recusa sobrescrever alterações manuais. Abra o `project.godot` dessa prévia para verificar antes de integrar.

Quando a área for autorizada para a campanha, a pasta `studio-generated/bosque-a` pode ocupar o mesmo namespace dentro do projeto Godot. Instancie um Node2D com o script `area_bridge.gd`. Ele inicia em modo de jogo, oculta a interface de edição e carrega a fonte exportada, sem assumir a propriedade do save da campanha.

Conecte `interaction_requested` ao sistema já existente de diálogos, encontros, itens e transições. A ponte oferece `get_player_position()`, `set_player_position(point)` e `get_area_events()`. Saídas para outras áreas são decisões do gerenciador da campanha; a bancada web já testa saídas entre projetos locais.

Nenhum desses comandos escreve em `godot/` ou faz merge da campanha. Eles preparam uma integração concreta para revisão.

## Bancada nativa

Tab alterna edição/teste. WASD/setas anda, Shift corre e E interage em teste. A bancada preserva círculos, retângulos e polígonos de colisão e reproduz spritesheets próprios e a caminhada do Kael.

F5 grava uma cópia local em `user://jardim-<id>.json`; o identificador do projeto separa cópias de áreas diferentes. R restaura `layout.json`. A ponte de runtime sempre começa pela fonte exportada; o save permanente da campanha continua a cargo dela.

A edição nativa é de apoio: a interface completa de projetos, formas, rampas orientáveis, carimbos e gerenciador de assets está no navegador.

## Reproduzir a verificação

```powershell
node tools/plant-lab/prepare-advanced-fixture.mjs
node tools/plant-lab/prepare-godot.mjs --layout documentation/plant-lab-v1/cases/advanced-integration.json
godot --headless --path tools/plant-lab/godot-preview --editor --import --quit
godot --headless --path tools/plant-lab/godot-preview --script check_runtime.gd
godot --headless --path tools/plant-lab/godot-preview --script check_autotile.gd
node tools/plant-lab/reimport-check.mjs
```

`reimport-check.mjs` cria uma pasta exclusiva de teste, verifica o modo de revisão, preservação de overrides e bloqueio de conflitos, e prepara um teste do adaptador. O caminho resultante fica em `captures/reimport-check.json`.
