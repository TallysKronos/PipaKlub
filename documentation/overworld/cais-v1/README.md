# Cais dos Elos — ensaio estrutural isométrico

Reconstrução estrutural da referência de cais recebida em 28/10/2026, com materiais de madeira, rocha e palha gerados para a linguagem 2D mangá de Soulmonsters. A cena usa polígonos e malhas 2D projetados de coordenadas de planta e altura; não é uma pintura única do mapa.

## Conteúdo

- 23 superfícies identificadas, incluindo quatro lances de escada.
- Oito cotas principais de apoio: praia +8, cais +12, deck inferior +64, deck superior/base da torre +128, andar da torre +192, terraço intermediário +224, andar superior da torre +256, terraço alto +288 px.
- Cobertura da torre com beiral +320 e topo +352 px.
- Escadas: 8 espelhos ×8 px entre 128 e64; 8×8 entre 192 e128; 8×7 entre64 e8; 13×4 entre64 e12. Cada lance termina exatamente na cota seguinte.
- Três escadas de mão, terraços na rocha, pilares, decks de 5 px de espessura, ponte plana e ponte com flecha de 12 px e chegadas +128.
- Cais baixo em zigue-zague, ilha de areia, coqueiros articulados reutilizados, guarda-sol e canoa.
- Passagem inferior +64 e deck +128 na mesma posição em planta, com IDs independentes. O arquivo `layout.json` registra a planta e as conexões.

## Precisão e revisão

As cotas são decisões desta reconstrução; a imagem de referência não contém medidas ou planta de navegação. Foram mantidos os grupos estruturais e a organização geral. A rede central foi interpretada em módulos próprios, os adereços foram adaptados e a vegetação ficou mais aberta. Não é uma réplica pixel a pixel do mapa original.

O ensaio usa uma sonda de apoio, sem ler campanha. Sua consulta considera superfície e posição, em vez de escolher automaticamente o piso mais alto. WASD movimenta a sonda em coordenadas da planta. E troca entre os dois extremos de uma escada de mão próxima; essa troca é instantânea de inspeção e não uma animação de escalada.

`percurso-da-sonda.json` registra a revisão nativa por pequenos deslocamentos: 16 pontos do cais à torre, 12 na volta, quatro na praia e quatro na passagem inferior. Essa revisão encontrou e corrigiu uma conexão ausente entre a saída da escada da torre e a ponte. Os 36 destinos foram alcançados depois da correção. A visualização das escadas usa a altura discretizada dos degraus; a compatibilidade das conexões usa o perfil contínuo.

Capturas nativas: vista geral 1280×960, vista 1280×720, geometria sem decoração, escada central, escada da praia, torre e duas camadas da passagem. A vista adicional sem deck superior é um corte de inspeção: revela a mesma sonda no piso inferior, sem deslocá-la na planta.

Correções feitas durante a revisão:

- Remoção de faces internas de madeira em ligações de mesma altura, considerando contatos parciais.
- UVs contínuos nas faces de rocha; textura dos pilares orientada na vertical.
- Coqueiros retirados da chegada da escada e apoiados no deck quando ocupam um deck.
- Normalização de madeira/palha ajustada para não converter gradientes do fonte em granulação forte.
- Ponte com perfil curvo compartilhado entre pintura, suportes laterais e consulta de altura.
- Fundo de água ampliado para não terminar dentro das capturas de detalhe.

## Fontes e arquivos

Novos fontes e prompts: `art/overworld/kits/cais-v1/fontes/`. Madeira e palha são normalizadas em oito cores sem dithering, rocha em quatro. Areia e grama vêm das bibliotecas aprovadas. O coqueiro do cais tem novas peças mangá em `palma/`, derivadas do contrato de rig de `frutiferas/rigs/coqueiro`; a biblioteca original não foi alterada. A referência do usuário está na documentação de comparação e não é usada como textura da cena.

Cena: `godot/scenes/overworld/pier/cais-dos-elos.tscn`.

```text
godot --path godot --script res://tools/pier_preview.gd -- --live
```

Importar o projeto antes da primeira execução. Sem `--live`, a prévia produz as capturas e os registros e encerra. A cena permanece isolada: não instala essa representação de superfícies no modelo de campanha, não usa o personagem/seguidor e não valida pathfinding, colisão física, save, transição entre mapas ou oclusão arbitrária de todos os layouts possíveis. Não foram adicionadas nem executadas suítes de testes do projeto.

## Correção de interpenetrações após revisão do usuário

A ordenação por profundidade média e o `z_index` global dos tapetes permitiam que faces grandes de grama/rocha encobrissem madeira e escadas, e que tapetes fossem vistos através dos pisos superiores. A tentativa de ordenar apenas por relações entre polígonos ainda produziu ciclos. Ela foi substituída por `pier_visibility.gd`: cada plano tem profundidade afim na projeção; as regiões cobertas por faces opacas à frente são recortadas em fragmentos convexos com UVs interpolados. A subtração mantém buracos abertos por meio de peças convexas, sem preencher anéis internos. Essa montagem não usa fallback de profundidade média para resolver a visibilidade das faces opacas.

As partes com alpha dos coqueiros são recortadas contra os sólidos e desenhadas preservando sua transparência; seus retângulos não ocultam madeira por conta própria. Os coqueiros próximos dos andares da torre foram removidos, mantendo um no posto lateral. O tapete da base foi movido para `[8.8,-1.3,9.7,-.3]`, fora da escada e da projeção em planta dos andares superiores. Os tapetes usam a cota de seu deck, sem camada global que os faça passar por cima de outros pisos.

As escadas de mão das rochas têm afastamento físico de 0,40/0,30 célula das faces, com apoios na parede e extensão correspondente das bordas dos patamares. Seus corrimãos e degraus ficam à frente da rocha. Os pilares automáticos agora terminam na superfície mais alta abaixo do deck, incluindo madeira inferior, em vez de atravessar um deck para alcançar a rocha. Os andares da torre usam seus pilares estruturais compartilhados, sem duplicação de postes por andar.

As vistas de corte são reconstruídas sem o deck selecionado antes de calcular a visibilidade. Apenas esconder o deck já recortado não revelaria as partes inferiores removidas. A sonda de movimento continua sendo uma ferramenta de inspeção com desenho simplificado; isto não substitui a integração e revisão do personagem real no renderer da campanha. O recorte estático tem custo de preparação adicional, ainda sem perfilamento de produção para mapas maiores.

Revisadas novamente as vistas gerais, torre, geometria sem decoração e `escadas-rocha-1280x720.png`. Os 36 destinos da sonda continuam alcançáveis. `auditoria.json` registra a contagem de faces/fragmentos e as correções desta revisão.

## Coqueiro mangá · revisão de identidade

Copa, tronco e coco foram gerados separadamente com o image_gen integrado. Originais, prompts e cortes estão em `art/overworld/kits/cais-v1/fontes/coqueiro-manga/`; `tools/overworld/prepare_pier_palm.py` reproduz a normalização e os encaixes. Folhas largas com recortes grandes, verdes sálvia/teal, sombras chapadas e anéis espaçados substituem o neon e os folíolos miúdos. A normalização remove o halo de alpha do fonte e reduz as peças com antialiasing para sua escala de uso, preservando os originais.

Tronco com raiz fixa, copa e três frutos mantêm peças e pivôs independentes. `coqueiro-manga-montagem.png` mostra os mesmos retângulos usados no runtime. Conferidos o encaixe estático da copa, apoio das raízes e vistas nativas geral/torre. O cais usa a pose de repouso: não foi validada uma animação de vento ou colheita com a nova silhueta, nem substituído o coqueiro dos outros mapas.

Revisão de apoio após observação do usuário: o coqueiro do patamar inferior foi recuado de `(2.2,3.4)` para `(2.1,4.2)`, mantendo cota 112. O coqueiro do patamar intermediário passou de `(0,3.3)` para `(0,3.6)`, mantendo cota 208. O centro apoiado sozinho não basta: a abertura das raízes precisa caber atrás da borda. Captura nativa ampliada: `coqueiros-apoio-1280x720.png`.

## Primeira travessia jogável com Kael

Cena separada: `godot/scenes/overworld/pier/cais-jogavel.tscn`. Abrir pelo Godot (F6) ou executar `powershell -File tools/overworld/open-pier-play.ps1`. O launcher usa perfil local isolado em `tmp/pier-play-profile`. Não muda a cena principal do jogo, não lê nem grava saves de campanha e não acessa serviços online.

- WASD/setas ou analógico: caminhar na direção da tela.
- E/Enter ou A/×: usar uma escada de mão próxima; subida e descida usam os frames existentes de Kael.
- M/View: vista geral do cais; pressionar novamente para voltar à caminhada.
- Escape/Start: pausar, continuar, recomeçar ou fechar a prévia.

Kael reutiliza `avatar.gd` e suas camadas ancoradas; o Rabbito animado acompanha o histórico do caminho e das alturas, sem cortar os vãos por uma linha reta. A colisão usa a pegada de apoio no grafo de superfícies: bordas expostas bloqueiam o disco dos pés, conexões admitem travessia na cota compatível e escadas de mão são interações explícitas. Não se trata de colisão via CharacterBody2D em um único plano: esse modelo não distinguiria dois decks sobrepostos com a mesma planta. Pilares da torre, coqueiros da praia e guarda-sol também bloqueiam aproximação.

A profundidade dinâmica usa dois mapas RF calculados uma vez a partir dos polígonos/planos do mesmo cenário (com e sem telhado). O shader de Kael, sombra e acompanhante compara a profundidade por pixel. Pilares, decks e faces ocultam o corpo de acordo com sua posição; sob o deck, uma silhueta discreta ajuda a orientar. No último andar, o telhado passa a translúcido e deixa de esconder o personagem. A máscara inclui o alpha das árvores; não considera o retângulo inteiro da copa como sólido. As peças do cais continuam estáticas; vento nas copas e áudio ambiente ainda não foram adicionados nesta etapa. A água mantém o shader animado existente.

A pequena jornada “Um fio até o horizonte” começa no desembarque, orienta a subida ao mirante e termina ao interagir no tapete do último andar. Conclusão apenas em memória, sem recompensa de campanha. Câmera segue o personagem, com suavização e limites; menu e HUD reutilizam o kit visual existente.

Auditoria nativa em `jogavel/`: 11 capturas 1280×720, caminho sob/sobre o deck no mesmo XY, ponte, escada de mão, mirante, patamar das rochas, praia, retorno e pausa. `percurso.json` registra 68 destinos alcançados no controlador real, incluindo ida e volta pelas três escadas de mão e quatro lances de degraus. Esta é inspeção local do percurso/capturas, não uma suíte do projeto nem teste com controle físico. Os mapas de profundidade têm 972×912; uma execução local mediu 441 ms para o mapa principal, além da preparação geométrica e do segundo mapa. Isso não é uma medição de FPS ou de desempenho em consoles.
