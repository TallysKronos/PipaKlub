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

Clique em **Abrir mapa da campanha** no palco ou no menu **Arquivo**. O mapa escolhido ocupa o palco principal. **Voltar ao projeto** retorna à planta anterior. A opção **Projeto atual** mostra a planta do editor top-down em isometria, com os pincéis de Piso, Preencher, Relevo e Rampa. Com o canvas em foco, use as setas para testar Kael nesse projeto. A roda aproxima e o botão central move a câmera.

Use **Buscar mapa** para filtrar por nome ou bairro. Ao abrir um mapa, escolha um dos pincéis disponíveis e clique ou arraste sobre o piso. **Mover vista** desloca a câmera. **Desfazer** (Ctrl+Z) reverte a última ação ou o último traço. **Salvar no jogo** (Ctrl+S) grava as alterações no JSON local do Godot. **Baixar cópia** baixa o JSON sem gravar no projeto. Alterações ainda abertas geram um aviso ao recarregar a página.

O Studio protege rampas, água, eventos e peças com colisão. Estruturas geradas pelos scripts do Godot ficam fora da edição visual. Se outro processo alterar o arquivo, salve sua cópia via exportação e reabra o mapa antes de tentar novamente. A gravação atua sobre o JSON usado pelo Godot. Ao regenerar um mapa a partir do seu gerador de origem, reaplique ou incorpore as edições na fonte.

Para usar a biblioteca completa, selecione o mapa e clique em **Editar no Studio**. A primeira abertura cria um projeto top-down salvo neste navegador. As próximas aberturas retomam a mesma cópia, que também aparece em **Arquivo → Projetos e versões**. Pinte com as ferramentas normais, arraste assets da biblioteca e clique em **Jogar** para testar movimento e colisão. A conversão aproxima o relevo e os materiais do Godot; peças geradas por scripts e regras de história não passam para o teste do Studio. Essa cópia usa o salvamento de projetos do Studio, separado de **Salvar no jogo** da vista isométrica.

Por padrão, o Studio lê `godot/assets/overworld/maps` no mesmo checkout. Quando o jogo está em outro checkout, defina `PLANT_LAB_MAPS_DIR` como o caminho dessa pasta antes de iniciar o servidor. O catálogo e o salvamento passam a usar a mesma pasta.
