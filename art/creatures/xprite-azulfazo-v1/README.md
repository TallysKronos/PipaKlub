# Azulfazo — comparação Xprite no jogo

Abra [Comparar no Godot](comparar.ps1) pelo PowerShell ou a cena [overworld_pixel_compare.tscn](../../../godot/scenes/overworld_pixel_compare.tscn) no editor. A cena usa o mapa real das Veredas e um save temporário.

A folha Xprite está integrada ao caminho normal do companheiro Azulfazo no checkout de estudos. Outros modelos continuam no catálogo de 80×80. O experimento tem duas células de 112×112, apoio (56,100), altura visível de 70 px nas duas vistas, 16 cores e filtro Nearest. O jogo recebe o PNG pronto, sem executar a biblioteca Xprite.

## Controles da comparação

| Controle | Ação |
| --- | --- |
| 1 | Mostra a versão antiga como companheiro |
| 2 | Mostra Xprite com acabamento |
| 3 | Mostra ambos ao lado de Kael |
| F4 | Alterna frente SW e costas NW |
| F2 | Alterna zoom da câmera entre 1 e 1,15 |
| F3 | Liga/desliga o filtro CRT da cena |
| F5 | Alterna a versão antiga entre escala 1 e 1,25 |
| Controles de exploração | Caminha no mapa com o companheiro |

A imagem inicial mostra o antigo em 1,25× e o novo em 1×. O antigo tem 54 px visíveis no PNG, ou 67,5 px nessa ampliação. A versão nova tem 70 px visíveis. Essa configuração aproxima as alturas para comparar a leitura das formas. A captura ambos-1x mostra também a diferença em escala unitária.

O rodapé mostra a referência exata do Kael de 70 px solicitada pelo autor. O personagem controlável no mapa continua sendo o avatar deste checkout, que usa uma versão anterior. Essa diferença entre checkouts deve ser considerada ao avaliar proporção.

## Resultados preservados

- [Frente no mapa](in-game-sw.png)
- [Costas no mapa](in-game-nw.png)
- [Ambos em escala 1](in-game-sw-ambos-1x.png)
- [Zoom 1,15 com CRT](in-game-sw-crt-zoom.png)
- [Folha antiga](atual.png), [Xprite sem retoques](xprite-sem-retoque.png) e [Xprite com acabamento](xprite-final.png)
- [Original de geração](geracao-original.png)
- [Detecção automática](auto-grid.png), [alternativa PixelOE](candidato-pixeloe.png) e [alternativa Structure](candidato-structure.png)
- [Medições e parâmetros](medidas.json)
- [Fonte editável](../soulmonsters-overworld-v2/azulfazo-xprite/azulfazo-xprite.aseprite)

## O que o teste mostrou

A execução de Auto sobre o original retornou uma grade de 482×167 e confiança 0,04697. O resultado excedia o tamanho planejado. O fluxo selecionado usa explicitamente Convert, com TwoStage e blocos nas dimensões finais calculadas para cada pose. Trata-se de conversão controlada pelo tamanho de jogo. O resultado automático está preservado para comparação.

O recorte das poses usa a cobertura alpha a partir de 128. Cada vista é convertida para 70 px visíveis, com largura proporcional, e montada na célula 112. Uma paleta compartilhada de 20 cores é calculada depois de reunir as vistas. O acabamento Aseprite agrupou os azuis e dourados, ajustou sel-out e reforçou olhos e brilho, chegando a 16 cores.

A fonte Aseprite contém a base e a camada de ajustes. O relatório registra 24,23% dos pixels visíveis modificados, concentrados em união de tons. As formas foram conservadas. A revisão independente considerou a leitura de rosto, peito, asas e rabiola melhor que a da versão antiga.

Ainda existem pixels de cor sem vizinho ortogonal, principalmente em diagonais e espirais. O teste não fecha o requisito anterior de zero pixels de cor isolados. A próxima intervenção sugerida é simplificar os interiores claros das asas e alguns recortes escuros das coxas, conferindo o resultado em 1× ao lado de Kael. A expansão para as 194 folhas depende da aprovação do fluxo e do piloto.

O mapa usado nesta branch também emite avisos antigos de identidade dos NPCs Cauê e Celina. Eles são anteriores a esse experimento e aparecem nos testes anteriores do mesmo checkout.

A suíte overworld_companion_checks concluiu 486 verificações com zero falhas. Além do catálogo existente, ela verifica o PNG de 224×112, apoio (56,100), altura de 70 px, seleção das quatro diagonais e uso do Azulfazo equipado no parque, Morro, casa e cidade. As capturas de comparação foram produzidas no renderer gráfico do Godot.

## Repetição do processamento

A biblioteca usada foi @xprite/pixelate 0.1.2, instalada somente em tmp/xprite-azulfazo com --ignore-scripts. Os scripts do experimento estão em reproducao/. Para repetir a etapa automática, copie-os para a mesma pasta temporária, instale a versão fixada e execute prepare.py, run.mjs e convert.mjs nessa ordem. prepare.py usa Pillow para entrada RGBA. Os arquivos RGBA resultantes têm dimensões declaradas nos JSONs ou 224×112 para as três conversões.

No Windows/Node 24, preloadWasm apresentou um caminho duplicado C:/C:/. A cópia temporária de dist/grid-ac-rl-consensus.js recebeu import de fileURLToPath de node:url e substituição de decodeURIComponent(url.pathname) por fileURLToPath(url). Essa adaptação é específica do ensaio em Node. A biblioteca fica fora do runtime Godot.

O projeto Xprite usa MIT e inclui atribuições de componentes em https://github.com/rhinoc/xprite-pixelate/blob/main/NOTICE.md. O experimento distribui as imagens e nossos scripts, sem incorporar a biblioteca ao jogo.
