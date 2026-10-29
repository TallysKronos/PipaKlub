# Pixelgen Studio 2 — evidências

## Verificações executadas

- Oito testes do modelo: migração v1 → v2, composição e extração sem alterar a imagem, bloqueio, ordem das camadas, transformações reversíveis, inserção/exclusão, reprodução e validação de dados.
- Fluxo DOM com canvas simulado: biblioteca, novo projeto, reabertura, seleção, camadas, bloqueio, histórico, propagação de pose, quadros, ping-pong e exportação. Não valida o layout visual.
- IndexedDB via fake-indexeddb isolado: transações, recuperação anterior, preservação da fonte, catálogo, atualização pelo mesmo ID, gravações concorrentes serializadas e reabertura por outra instância.
- Aseprite real 1.3.18.6 (Steam), modo batch: abriu arquivo indexado com corpo, cabeça e uma camada-guia oculta/bloqueada. A folha reexportada foi comparada byte a byte com os pixels RGBA do projeto; a guia ficou fora da composição. Durações 140/110/140/110 e tag walk-left ping-pong preservadas.
- Godot real 4.7.2, projeto mínimo isolado: importou o PNG, carregou o .tres como SpriteFrames e conferiu seis posições de ping-pong, durações relativas e região AtlasTexture 48×64. Não executou a campanha nem alterou o jogo.
- Aseprite AI Artist 0.8.2: servidor MCP conectado e preflight headless respondeu READY, Aseprite 1.3.18.6, sem sprite aberto.

Arquivos de referência nesta pasta: kael-layered.aseprite, aseprite-sheet.png, aseprite-data.json, kael-sheet.png, frames.tres e verify.gd. O .tres desta evidência aponta para res://kael-sheet.png; copie os dois para a raiz de um projeto de teste para abri-lo. Não é uma integração na campanha.

## Limites da revisão

A inspeção interativa no navegador está bloqueada pela opção Local browser use do Work. Os testes DOM não foram apresentados como auditoria visual. O Aseprite e o Godot foram usados sem janela para conferir arquivos, e não como aprovação artística de anatomia ou movimento.

As skills instaladas não geram poses perfeitas automaticamente. Não há rig, identificação automática de membros, sincronização em nuvem ou importador de projeto Aseprite no navegador. O Pixelgen exporta .aseprite; para reabrir todas as informações na bancada, use .pixelgen.json. A biblioteca depende dos dados deste navegador e exige backups exportados para conservação fora dele.
