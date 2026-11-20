# Revisão 2 — terreno contínuo e bosque reconstruído
Data: 2026-11-05.

## Diagnóstico do defeito mostrado
Não era somente uma composição antiga. A implementação anterior usava o mesmo recorte para aparência da grama e presença física do solo. Isso retirava faixas pequenas de suporte por célula. Rampas retangulares e patamares recortados podiam discordar na chegada/lateral. Além disso, as faces arredondadas podiam herdar terra da célula inferior, mesmo pertencendo a uma formação de rocha. Os testes anteriores de combinação das47 peças não bastavam para validar essas situações.

O mapa antigo também continha intervalos de grama entre segmentos de caminho. Refazer uma textura não desenha uma conexão de trilha que não está nos dados.

## Pesquisa e decisão aplicada
- [BorisTheBrave — Marching Squares / dual grid](https://www.boristhebrave.com/docs/sylves/1/articles/tutorials/marching_squares.html): armazenamento compartilhado e seleção pelas amostras nos cantos; vizinhos afetados devem ser reconstruídos. Aplicação própria neste editor: campo dual de ocupação para a geometria, em vez de cada célula encolher sua borda isoladamente.
- [Godot — Using TileSets](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html#creating-terrain-sets-autotiling): terrenos configuram combinações de lados/cantos em atlas. Mantivemos o conjunto47 para os materiais do piso e o TileSet exportável.
- [SLYNYRD — Top Down Tiles Part 2](https://www.slynyrd.com/blog/2023/3/26/pixelblog-43-top-down-tiles-part-2): textura base precisa repetir bem; variantes de borda/canto e camadas devem ser conferidas juntas. Terraços exigem encaixes próprios das laterais. A arte desta revisão é original: não foram copiados pixels do artigo.

A escolha de combinar campo dual para suporte com atlas por vizinhança para revestimento é uma decisão de implementação para esta bancada, não uma recomendação universal dos autores citados.

## O que mudou
- Geometria separada do recorte da grama. A altura é amostrada em um campo compartilhado por todas as células vizinhas.
- Pés, cliques, oclusão, topo e extrusão usam essa altura; o revestimento não abre buracos físicos.
- Patamar de chegada e saída de rampa conserva apoio inteiro. Pintar uma nova rampa conecta a terra nos acessos sem apagar pedra previamente pintada.
- Faces curvas herdam o material do volume que as sustenta. Selecionar a face para editar altura/material aponta esse volume, não o chão inferior.
- Rocha com facetas irregulares mais largas, texturas de parede64×64 e fase mundial contínua. Rampas recebem leitura de inclinação sem degrau na boca.
- Bosque reconstruído com dois acessos duplos, terraços e trilha contínua. A vegetação do exemplo novo evita ocupar o centro do percurso.
- O projeto nativo de prévia passa a abrir essa composição reconstruída em res://layout.json.

## Controles
- **Reconstruir amostra**: refaz pisos/relevo, conservando as peças atuais. Ctrl Z desfaz.
- **Mapa > Novo bosque de teste**: carrega também a composição de vegetação revisada. Ctrl Z recupera a composição anterior.
- **Mapa > Reparar acessos das rampas**: conecta materiais de trilha em mapas anteriores, sem alterar alturas nem substituir pedra.

O editor não substitui automaticamente o projeto salvo no navegador. A revisão de código passa a atuar sobre a geometria existente; reconstrução/troca de composição dependem desses comandos explícitos.

## Conferência executada
-27 testes de modelo: atlas,47 máscaras/256 casos,1024 vizinhanças, ausência de faixas internas entre terrenos ligados, fechamentos de patamares, material das curvas, reparo dos acessos, picking, barreiras, exportação e persistência.
-Busca em malha de8px: todos os centros elevados do exemplo são acessíveis.
-Controle por teclado do Studio: Kael sobe e desce os dois percursos até a cota2.
-Capturas das junções em2×, sem vegetação sobre os encontros, além do legado corrigido e do bosque reconstruído.
-Regressões das ferramentas/camadas do Studio.
-Godot: importação e comparação das imagens regeneradas com as exportadas, considerando pixels visíveis e alfa; não é uma aprovação artística automática.

## Artefatos
- captures/rebuild-v2-bosque.png
- captures/rebuild-v2-legado-corrigido.png
- captures/rebuild-v2-juntas-terra.png
- captures/rebuild-v2-juntas-rocha.png
- captures/rebuild-v2-verificacao.json
- art/environment/topdown-autotile-v1/bosque-reconstruido.json
- tools/plant-lab/terrain-field.mjs e terrain-field.test.mjs

## Limites
A base continua editável em grade32×32 e usa materiais procedurais originais. Não foram implementados água, pontes, streaming ou rampas em todas as direções. As rampas deste editor sobem ao norte. A revisão pertence ao Studio e à prévia Godot; não modifica a campanha.

