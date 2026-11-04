# Vila do Primeiro Vento · bairro inicial v2

Estado: **cidade aprovada visualmente e conectada ao fluxo local da campanha**, ainda sem testes funcionais de transição/salvamento. A cena `bairro-jogavel.tscn` continua sendo uma prévia independente; a campanha principal carrega o novo adaptador `neighborhood_view.gd` para o checkpoint `quintal`. O ateliê usa o interior e o fluxo de treino/Oficina existentes. Casa e lojinha permanecem pontos exteriores com diálogo, sem interior novo ou compras.

## Organização e intenção

Três ruas em H, com 48 px de diferença entre a rua alta e a residencial:

- **Rua do Primeiro Vento:** casa azul de Kael com varanda e pipa presa ao guarda-corpo; quintal, portão aberto, correio, Nina, Fusca e ponto de ônibus.
- **Ladeira das Rabiolas:** conexão entre cotas, com calçadas contínuas e travessia. Uma escadaria de oito degraus dá uma alternativa para pedestres, apoiada no mesmo terreno e ligada à calçada superior.
- **Rua dos Inventos:** professor em laboratório de vínculos com esquadrias profundas, marquise de vidro e jardim; casa vizinha com recuo; lojinha de pipas com toldo listrado, materiais e pipas nas vitrines.

Cinco construções com lotes separados e intervalos livres; nove árvores em grupos esparsos; três veículos estacionados; quatro personagens com conversa; bancos e pequena área de encontro. A composição mantém a rua e as entradas legíveis, em vez de cercar o jogador com uma bordadura de árvores ou casas geminadas.

## Abrir e jogar

Cena: `godot/scenes/overworld/neighborhood/bairro-jogavel.tscn`. No editor, abrir e executar a cena com F6. Pelo PowerShell:

```powershell
./tools/overworld/open-neighborhood-play.ps1
```

O launcher aceita `GODOT_BIN` ou Godot no PATH e usa o runtime local já instalado como alternativa. Cria perfil isolado em `tmp/neighborhood-play-profile`; não lê nem grava slots de campanha. Não usa rede, Supabase ou autenticação.

WASD/setas/analógico: andar; E/Enter/A: conversar ou examinar; M/View: vista geral; Escape/Start: pausa. Uma conversa interrompe a caminhada; E avança/fecha, Escape fecha. Pausa permite continuar, recomeçar a prévia ou sair. As visitas ao professor e à lojinha são registradas apenas em memória nesta sessão.

## Arte e fontes

Arquitetura revisada a partir do catálogo moderno: cinco pinturas com volumes articulados, peitoris e molduras espessas, entradas recuadas, marquises e vegetação integrada. A casa azul do Kael foi gerada especificamente com varanda apoiada, pergolado e pequena pipa no guarda-corpo. Professor, loja e duas casas vizinhas reaproveitam as ilustrações detalhadas do catálogo urbano. Originais e proveniência em `art/overworld/kits/bairro-inicial-v2/fontes/arquitetura-v3/`; preparo reproduzível em `tools/overworld/prepare_neighborhood_architecture.py`.

Cada pintura usa uma única transformação afim, calculada pelas três quinas da fundação. A divisão em duas fachadas serve à profundidade; ambas compartilham a mesma transformação, sem dobra ou escalas verticais independentes. As bases seguem a projeção 2:1 e o desnível real do lote; as verticais permanecem verticais. Colisão usa a fundação ajustada. A ordem de desenho das fachadas usa a base, evitando cobrir NPCs à porta. O atlas de profundidade continua ocultando Kael e Rabbito atrás dos edifícios. São pinturas em planos com aproximação de profundidade, não geometria individual de cada floreira, janela ou varanda; interiores não existem nesta prévia. Terreno, calçadas, barrancos, escadas e rampas continuam geometria nativa.

Pisos v4 coordenados com as construções: calçada de placas claras de calcário, gramado verde com pinceladas angulares e asfalto azul-acinzentado discreto. O muro de contenção reaproveita o desenho do calcário em valor mais escuro, substituindo a rocha escura do cais. Passeio e grama foram gerados com **image_gen integrado**; originais e prompts em `art/overworld/kits/bairro-inicial-v2/fontes/pisos-v4/`. O asfalto preserva o desenho anterior com contraste reduzido e paleta ajustada.

Preparo reproduzível: `tools/overworld/prepare_neighborhood_floors.py`. Amostras de 512 px, 12 cores no passeio e 8 no gramado, sem dithering; cada material recebe extensão refletida 2×2 de 1024 px para compartilhar o perfil das arestas. A prancha `PISOS-V4-REPETICAO.png` registra repetição 3×3; a reflexão ainda pode gerar recorrências perceptíveis em áreas muito extensas. UVs mantêm a mesma escala e fase nos pisos conectados (16 células no passeio/asfalto, 20 no gramado). A geometria e as colisões não mudaram; rebaixos, rampas e escada foram revistos em capturas nativas ampliadas.

Veículos e ponto de ônibus vêm de `mobilidade`. Props de jardim/bancos/postes vêm do kit comum. Kael e Rabbito usam os mesmos sprites e animações do cais. Professor e Nina reaproveitam os assets existentes; os visuais de Lia e Zeca usam recortes individuais das folhas `morro/bia.png` e `morro/zeca.png`. O visual reutilizado para Lia é provisório antes de uma integração narrativa definitiva. Não foram criados retratos ou ciclos novos de NPCs. Veículos estão estacionados, sem simulação de trânsito.

## Estrutura e inspeção

O mesmo conjunto de células fornece as alturas e a geometria ao controlador. A rampa principal tem altura contínua; a escadaria tem oito pisos de 6 px, com apoio quantizado para os pés e consulta contínua para transições. O terreno entre a escadaria e a ladeira compartilha a inclinação, evitando um vão vertical isolado. Faces expostas derivam das diferenças entre os dois lados da aresta. Rampas de meio-fio terminam na cota do asfalto, com laterais em cunha e sem face atravessando a boca.

Prédios, cercas, carros, árvores, postes, bancos e NPCs limitam a aproximação. O controlador, acompanhamento de Rabbito, máscara de profundidade e inputs são compartilhados com o cais; a cena principal da campanha continua independente. Um parâmetro permite ao controlador carregar o novo mundo. O resolvedor preserva materiais de malha e impede que o terreno apague os degraus e floreiras desenhados que avançam além da fundação.

Capturas nativas 1280×720: vista geral; Kael; professor; loja; praça; ladeira; escadaria; bocas dos meios-fios; terreno sem casas/props. O percurso nativo em `jogavel/percurso.json` registra os destinos alcançados e as quatro conversas, incluindo ida, volta e subida pelo atalho. As inspeções são capturas e percurso local no controlador real; não foram executadas suítes do projeto, compras, saves, viagens entre mapas ou controle físico.

Limites atuais: mapa exterior de revisão; portas exibem comentário, não carregam interiores; conversas não concedem itens; NPCs permanecem em suas posições; não há trânsito, ciclo dia/noite ou ambiente sonoro novo. As saídas das ruas ainda não fazem transição para a campanha. O pacote contém um projeto de prévia independente, não um build Steam.


### Encaixe da casa do Kael

A calibração usa duas arestas medidas de parede/chão no original: (110,959)–(647,1208) e (778,1224)–(1177,1010). Sua interseção prolongada define a quina virtual da fundação. A floreira da janela e o patamar da porta são avanços, não referências do retângulo principal. Isso mantém a fachada paralela à rua, em vez de girá-la para acomodar um ornamento. A captura `casa-kael-alinhamento-1280x720.png` mostra a direção da base em ciano e da calçada em amarelo. O recuo permanece dentro do quintal, com acesso ao portão.


### Escala dos elementos urbanos

O espaço externo usa preto azulado `#0B1525`. Referência de escala: NPC com 51 px; altura opaca total dos recortes do Fusca 100 px, jipe 118 px, Kombi 128 px, abrigo de ônibus 130 px e bancos 38 px. Altura do recorte inclui chão projetado, não equivale à altura física do veículo. A Kombi foi afastada da travessia e o banco separado do abrigo ampliado. Os bloqueadores foram ampliados junto dos objetos. As quatro capturas `escala-*-1280x720.png` comparam Kael e cada objeto no mesmo nível. Esta revisão fez capturas estáticas; o percurso de 32 destinos registrado anteriormente não foi repetido após ampliar os bloqueadores, conforme a preferência de não rodar testes.


### Bloco de terra flutuante

O perímetro externo recebe faces verticais até a base comum `z=-40`, fechadas também por uma face inferior. As bordas derivam das mesmas células e alturas do piso; ruas e passeios também recebem sustentação, sem paredes entre células internas. O trecho alto tem lateral maior até a mesma base, preservando o relevo. Material de terra reaproveitado de `terrenos-v1/superficies/terra-barranco.png`, com paleta terrosa mais discreta, oito cores e UVs contínuos no contorno. Preparo em `prepare_neighborhood_floors.py`. Não cria superfícies caminháveis ou altera colisões. Capturas ampliadas: `base-canto-frontal`, `base-ponto-onibus` e `base-rua-alta`, todas 1280×720, sem HUD cobrindo as juntas.


### Revisão da chegada da escada

Patamar inferior pavimentado em `u=8..11, v=11..13`, ligado à calçada existente em `u=11`, na cota 8 px. A escadaria deixa de terminar na grama. Os oito pisos mantêm a subida 8→56 px e compartilham os UVs /16 do passeio. Dois corrimãos contínuos substituem as peças por célula: postes apoiados nos degraus e patamares, com pequenas extensões horizontais nas extremidades e bloqueadores próprios. Conferência visual nativa ampliada do conjunto e das chegadas superior/inferior; caminhada e testes não foram executados nesta revisão.


### Primeira integração à campanha

A rota `world/quintal` em `front_end.gd` agora carrega a cidade num SubViewport com o HUD de exploração atualizado. `neighborhood_view.gd` adapta o controlador à pausa, equipe, bolsa, mapa, autosave periódico e ao parceiro equipado. Falar com Assis/usar a entrada leva ao interior existente do professor. As saídas sinalizadas à direita levam ao parque e ao Morro depois do tutorial concluído; sua conclusão continua sendo validada pelo fluxo existente.

`neighborhood_checkpoint.gd` identifica o novo espaço como `bairro-inicial-v2`, separando células nativas de posições do antigo mapa. Checkpoints antigos são interpretados para entrada pela casa/professor/parque/Morro; novos registros conservam a posição em `player.cityPosition` para retorno de outros mapas. A validação aceita saves antigos sem esses campos e verifica os campos novos. A gravação segue o Store existente, sem trocar a pasta ou excluir slots. Não foi executado teste de round-trip de save.

A captura `campanha-1280x720.png` veio da rota real com estado fictício apenas em memória, sem criar slots, movimentar ou disparar interações. Abertura/parse e referências foram conferidos. Ainda falta o teste manual de sair/reentrar no professor, viajar às duas regiões e carregar novamente uma jornada. Os novos interiores da casa e da lojinha pertencem à próxima etapa.


Para experimentar a campanha com a cidade nova: `./tools/overworld/open-campaign-city.ps1`. Abre o menu principal e usa perfil local separado em `tmp/campaign-city-profile`; jornadas criadas ali ficam nesse perfil. Para usar os slots normais, abra a cena principal `godot/scenes/campaign.tscn` no Godot. O launcher da prévia do bairro continua sem saves e sem o fluxo da campanha.
