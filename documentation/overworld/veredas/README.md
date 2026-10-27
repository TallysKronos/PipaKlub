# PIP-86 — primeira montagem nativa das Veredas

## Alvo visual

`art/overworld/conceitos/veredas/veredas-estudo-v1.png` recebeu o comentário do proprietário: “Essa planta ficou incrível, seria maravilhoso se conseguisse fazer completamente fidedigno”. Esse estudo orienta cores, materiais e formas. Os símbolos brancos das rampas e cubos do rascunho não são assets do jogo.

A geometria autoritativa continua nos dois `.tmj`. O estudo gerado não comprova alinhamento de pixels e não é usado como uma imagem de fundo que substitui o terreno.

## Entrega desta etapa

- Kit em `art/overworld/kits/veredas/`, cópia de runtime em `godot/assets/overworld/kits/veredas/` e projeto do Iso Studio `veredas.isostudio.json`.
- 28 amostras de piso 64×32, atlas de sete superfícies e 208 máscaras de transição. O preenchimento nativo é um losango contínuo sem contorno de tile.
- Fontes geradas próprias de grama, terra, água, arenito, pátio, madeira, buriti, capim de margem e canos. Prompts e ferramenta estão nos três registros `fontes/geracao*.json`. As fontes originais são preservadas.
- Barrancos revestidos por UVs contínuas; rampa de terra projetada sobre `height_at`, com cunha lateral exposta. As quatro direções são suportadas pelo consumidor; as plantas atuais usam somente `v-`.
- Ponte com tabuleiro, juntas de tábuas, vigas externas e apoios nas extremidades. Seu eixo vem do comprimento das duas cadeias conectadas, incluindo pontes largas.
- Buritis e árvores menores aproveitam as mesmas posições e bloqueadores originais. Tufos baixos são sprites verticais separados, colocados esparsamente pelas adjacências reais de água/bosque. Não há copa pintada no chão ou preenchimento automático de árvores.
- Dois conjuntos de canos decoram células de bosque já bloqueadas na borda do pátio. Não são novos bloqueadores.
- Cinco baús, Nina, Lacertubo, interações e recompensas mantêm suas posições. Na correção das rampas, os dois `.tmj` receberam a propriedade `rampa_comprimento=4` e os mapas compilados foram atualizados. A implementação permanece na cena de revisão; não substitui silenciosamente a campanha.

## Evidências

`antes/` contém cinco enquadramentos originais. `depois/` contém onze capturas gráficas 1280×720: os seis enquadramentos da primeira montagem e cinco detalhes das rampas principais, incluindo topo, meio e base do acesso ao pátio. As cinco câmeras originais mantêm posição e zoom para comparação. `rampas/antes/` preserva a montagem com rampas curtas para comparação com a correção.

## Correção das rampas

A subida de 64 px estava comprimida em uma célula 64×32; sua projeção tinha leitura de parede. Agora cada acesso distribui a subida pelas quatro células de trilha existentes abaixo da chegada. Não houve alargamento de caminho ou deslocamento de peça/evento.

O parser do Mapa Studio deriva `rampFrom`/`rampTo` para cada segmento. O compilador e o modelo Godot usam o mesmo perfil para altura e conexões: não se pode sair pelo lado de uma rampa para um piso de altura incompatível. As faces adjacentes terminam na altura de cada extremidade da rampa, em vez de atravessá-la com um retângulo. Os vértices de render usam coordenadas fechadas exatas para não deixar frestas entre segmentos.

Foram inspecionadas capturas nativas dos quatro acessos (piloto e três principais), com o personagem no topo, meio e base do acesso ao pátio. A última execução gráfica terminou sem erros, em `rampas/native-render.log`. Nenhuma suíte de testes foi executada. As imagens demonstram encaixe visual e apoio em posições fixas; não são uma simulação completa de movimentação.

`godot/tools/veredas_capture.gd` captura somente a cena local independente: não simula controles, não carrega conta e não grava campanha. Importação e última execução gráfica terminaram sem erros no log arquivado. Não foram executadas suítes de testes, conforme a preferência do proprietário. As capturas não comprovam travessia, interação ou combate de ponta a ponta.

## Abrir para revisar

Da raiz, com o executável Godot disponível:

```powershell
godot --path godot res://scenes/overworld_preview.tscn -- --area=veredas-piloto --art-preview
```

O seletor da cena permite mudar para Veredas do Encanamento. Também é possível executar com `--area=veredas-do-encanamento`. O executável 4.7.2 usado nesta máquina fica em `../pipa-club/tmp/godot-4.7.2/runtime/`.

## Ainda não é aceite final

A prova de ponte/rampa está montada e a primeira aplicação no mapa maior permite comparar o resultado com o conceito. Ainda faltam acabamento mais orgânico das margens e dos barrancos, revisão da repetição/escala de árvores e canos, e conferência interativa dos acessos e oclusões. A água ainda não tem animação própria. Os cantos e rampas são geometria nativa, não uma família completa de sprites independentes de catálogo. Aprovado o resultado visual, a incorporação à campanha e a conferência final devem ser registradas separadamente. Não foi feito push nem deploy nesta etapa.
