# Árvores frutíferas articuladas — Soulmonsters

12 espécies, cada uma com três PNGs independentes: tronco/raízes, copa sem frutos pintados e fruto destacável. Mangueira, jabuticabeira, laranjeira, limoeiro, goiabeira, aceroleira, cajueiro, pitangueira, amoreira, caramboleira, bananeira e coqueiro.

## Editar no Soulgen

Use **Importar projeto** e selecione `art/soulgen/keys/arvores-frutiferas/<espécie>/<espécie>.portable.soulgen.json`. O portátil contém os PNGs. O `.soulgen.json` normal mantém referências às fontes locais; pode ser usado no servidor Soulgen existente. Não é necessário instalar outro editor.

- `idle`: brisa suave, copa ±1,25°; raiz fixa.
- `hit`: impacto e retorno amortecido, sem desprendimento.
- `drop`: estudo da queda de um fruto; os demais continuam presos.

Pivôs e hierarquia são o contrato `soulgen-studio` usado pelos Pipamons, com restrições de proporção, ordem e junta copa/tronco. Frutos não têm restrição de junta permanente porque o desprendimento é intencional. O editor ainda pode recomendar ações de criatura (`flight`, `skill` etc.); elas não se aplicam a estas árvores ambientais.

## Usar na Godot

Instancie `godot/scenes/overworld/fruit-trees/<espécie>.tscn`. A origem é o contato da raiz com o chão. A base proposta de colisão é uma célula 64×32; a copa não amplia o bloqueio de navegação. Ajuste a base no mapa de destino.

Chame `hit()` para reagir ao golpe: a copa balança, um fruto visível é destacado aos 0,14 s e cai com um pequeno quique. O tronco não gira. Um golpe dura 1,2 s; chamadas durante ele são ignoradas. Ao esgotar os frutos visíveis a árvore continua reagindo, sem criar frutos invisíveis ou repô-los automaticamente. A jabuticabeira prende seus frutos ao tronco; as demais usam a copa.

O sinal `fruit_landed(species, world_position)` indica o pouso; não concede item. Não há economia, salvamento, coleta ou calendário de reposição integrados. As árvores ainda não foram distribuídas nos mapas.

## Prévia local

Da raiz do repositório:

```powershell
& ./tools/overworld/open-fruit-tree-preview.ps1
```

O script procura `GODOT_BIN`, Godot no PATH e o runtime local já usado pelo projeto. Na galeria: **Espaço** ou botão para bater; **←/→** para trocar de página; **R** para repor somente nesta prévia; **Esc** para sair. A galeria é isolada e não carrega campanha nem contas.

## Fontes e geração

Arte gerada com a ferramenta integrada `image_gen.imagegen`. Prompts e referências em `fontes/geracao.json`; conceitos completos em `fontes/geradas`; folhas de peças em `fontes/articuladas`. O rascunho da jabuticabeira foi preservado e a versão ativa foi corrigida para retirar frutos pintados na casca.

Normalização determinística: recorte dos três componentes conectados principais pelo alpha, remoção de ruído isolado e redução uniforme. Não há preenchimento de partes escondidas por código: elas foram desenhadas na geração. Os PNGs de repouso em `pecas` são renderizados pelo mesmo sampler do Soulgen, a partir do rig, e servem como fallback estático. O projeto Iso Studio é uma biblioteca de composição estática, sem animações.

## Reproduzir a preparação

1. `python tools/overworld/build_fruit_rigs.py`
2. `node tools/overworld/export_fruit_rigs.mjs`
3. `python tools/overworld/build_fruit_library.py`
4. `node --input-type=module -e "import {buildPieceScenes} from './tools/import-overworld.mjs';buildPieceScenes();"`

O exportador usa o Canvas local já utilizado pelo Soulgen. Não executa suíte de testes. Evidências visuais em `documentation/overworld/frutiferas-v1`.
