# Soulmonsters Studio

Editor local top-down com ferramentas, relevo orgânico, vegetação, água, eventos, projetos e exportação Godot. Tiles de 32 px; mapas entre 8×8 e 64×64. Aplicativo web local, sem instalador desktop.

Execute `node tools/plant-lab/server.mjs` na raiz e abra http://127.0.0.1:5256/.

- [Manual de uso](../../documentation/plant-lab-v1/MANUAL-DO-STUDIO.md): projetos/versões, pisos e paredes, formas, rampas/escadas, rios, carimbos, variantes, assets e eventos.
- [Entrega das 20 melhorias](../../documentation/plant-lab-v1/IMPLEMENTACAO-20-MELHORIAS.md): implementação, evidências e limites definidos.
- [Integração Godot](../../documentation/plant-lab-v1/INTEGRACAO-GODOT.md): exportação, revisão de diferenças, preservação de mudanças manuais e montagem em namespace.

A biblioteca inclui 32 pisos, 14 paredes, vegetação e árvores conectadas, três larguras de cachoeiras e assets próprios importáveis. Terreno e material de parede são ferramentas separadas. Foco por andar e camadas protegem a edição; a geometria física também determina curvas, oclusão e rampas.

Projetos, versões, carimbos e biblioteca importada ficam em IndexedDB. Preferências de interface ficam separadas no localStorage. O JSON é a cópia portátil. Testes de navegador usam contextos isolados, sem modificar o projeto aberto pelo usuário.

## Verificar

```powershell
$testFiles = rg --files tools/plant-lab -g '*.test.mjs'
node --test $testFiles
node tools/plant-lab/projects-audit-ui-check.mjs
node tools/plant-lab/preview-ui-check.mjs
node tools/plant-lab/geometry-preview-ui-check.mjs
node tools/plant-lab/level-focus-ui-check.mjs
node tools/plant-lab/regions-ui-check.mjs
node tools/plant-lab/advanced-ui-check.mjs
node tools/plant-lab/final-workflows-ui-check.mjs
node tools/plant-lab/performance-benchmark.mjs
```

Os scripts de UI usam Chromium via Playwright do ambiente local. Capturas e relatórios ficam em `documentation/plant-lab-v1/captures/`. O benchmark mede CPU do raster Node; não representa FPS de navegador.

`node tools/plant-lab/prepare-godot.mjs` regenera a bancada nativa separada em `godot-preview/`. Aceita `--ramps`, `--waterfalls`, `--surface-corners` e `--layout arquivo.json`. A integração na campanha é uma ação distinta da exportação; nenhum merge foi feito por esta entrega.

## Vista isométrica e campanha

Abra **Vista isométrica 2:1** no palco. **Projeto atual** usa a mesma planta da vista top-down. Escolha o pincel antes de abrir a vista e clique para aplicar Piso, Preencher, Relevo ou Rampa. Com o canvas em foco, use as setas para testar Kael sem gravar o deslocamento. A roda aproxima e o botão central move a câmera.

O seletor também lista os mapas nativos `overworld-godot-1` do jogo. A vista de campanha é geométrica e de consulta: clique para inspecionar a célula e baixe o JSON nativo com todos os dados. Os projetos do Studio continuam usando o fluxo de exportação Godot existente.
