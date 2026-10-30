# Distrito Industrial — prévia independente

Região aprovada pelo dono como exploração independente, sem campeão, história nova ou ligação automática à campanha. Três partes: `kronasta-industrial-a` (Pátio de Cargas), `-b` (Canal das Caldeiras), `-c` (Usina do Vento). Todas aparecem no seletor da prévia.

Abrir `godot/scenes/overworld_preview.tscn` ou executar Godot com `--path godot res://scenes/overworld_preview.tscn -- --area=kronasta-industrial-a --art-preview`. Navegação por setas/WASD ou clique; E interage. Não altera conta, save ou recompensas.

Gerador: `node tools/mapa-studio/desenhar-industrial.mjs`. Testes: `node --test tools/mapa-studio/industrial.test.mjs tools/mapa-studio/model.test.mjs`; Godot `res://tests/industrial_map_checks.gd` com ambiente `INDUSTRIAL_AREA=kronasta-industrial-a` (ou b/c). `KRONASTA_GEOMETRIA=1` para blocagem. Capturas usam `res://tools/bosque_region_capture.gd -- --area=<id> --plan=res://../documentation/overworld/industrial/planos/<id>.json --out=<pasta>` e opcional `--terrain-only`. Manifesto de imagens: `node tools/mapa-studio/verificar-capturas-industrial.mjs`.

Assets/fontes/QA em `art/overworld/kits/industrial-v1/`; contrato em `godot/assets/overworld/kits/industrial-v1/kit.json`. [Entrega e limites](relatorios/entrega.md). Estas são áreas novas; não existe comparação com um mapa industrial anterior.
