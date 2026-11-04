# Pântano — primeira prévia jogável, 30/10/2026

Complemento pedido durante a revisão: tufos de grama substituídos por folha larga em cel shading e menor frequência; ponte estilizada em arte nativa2D com espessura, contorno, tábuas, pregos, postes e cordas laterais. Mantida a pegada/cota da ponte e as cabeceiras. Árvores na água também respeitam a desobstrução das rampas, corrigindo uma copa que ainda cobria o acesso nordeste. Recapturadas arte e arte-terreno das três partes; geometria não mudou. Comparação da revisão em `captures/a/comparacao-estilo.png`. Verificação nativa de passagem, cabeceira e pé de rampa. Aprovação artística e export continuam pendentes.

Validação desta revisão:16 testes Node de mapa/modelo/conferência/industrial passaram; teste de água do pântano confirmou142/121/131 amostras transitáveis no tabuleiro e zero falhas. Logs `testes/node-cartoon.log` e `testes/water-cartoon.log`. Capturas finais sem SCRIPT ERROR/SHADER ERROR; aviso de cache/log de usuário no sandbox continua. As imagens geométricas preservam a ponte simples de conferência. A ponte ilustrada é mais espessa, mas não altera o plano de apoio nem o grafo físico; a bateria completa de movimento anterior não foi repetida nesta troca de arte.

Revisão artística posterior: árvore v1 rejeitada pelo dono por realismo. Consumidor das três partes atualizado para `arvore-cipos-v2.png`, direção 2D mangá/cartoon inspirada na linguagem de Dofus, com formas grandes, contorno grosso e sombras simples. Mesma pegada/âncora; desobstrução de rampas ampliada para a copa larga. Recapturadas as155 vistas artísticas (A51/B52/C52), total de465 evidências preservado. Geometria, água, itens e movimento inalterados; não repetida bateria física de226 viagens por esta troca de arte. Node de pântano/modelo:7 testes passaram. Capturas do Godot validam montagem; export, controle físico e aprovação do dono continuam pendentes. Fontes e prompt v2 no README do kit.

## 1. Arquivos criados e alterados
Pesquisa: `../pesquisa-direcao.md`; brief ASCII: `art/overworld/briefs/pantano.md`. Gerador `tools/mapa-studio/desenhar-pantano.mjs`, plantas Tiled e compilados `kronasta-pantano-a/b/c`, índice da prévia. Kit `pantano-v1`: árvore ilustrada com raízes/cipós, fonte e prompt preservados. Construtor `swamp_structures.gd`; alterações condicionais em `kronasta_forest.gd`, `forest_structures.gd` e shader de chão; água em `swamp_water.gdshader`. Outros biomas mantêm comportamento anterior quando `forest.swamp=false`.

## 2. Resultado automático
As três partes:
```
CONFERÊNCIA ZERO QUEBRA: SEM ERRO · 0 erros · 0 avisos
Platô 40.8% · 3 itens (1 escondidos) · 16 células de rampa · 0 inalcançáveis · 0 degraus soltos
```
Ligações A↔B↔C por terra0, saída v−(24,0) e retorno v+(24,39); chegadas declaradas. C→A é retorno independente. Quatro acessos largos v− por parte. Mato é opcional. A moldura inicialmente caminhável junto às rampas sul foi corrigida recuando aterros e acessos; sem avisos restantes. Canal curvo atravessa a moldura e continua fora do mapa. Superfície d'água−12px, piso0, cabeceiras apoiadas em terra; recorte, face e água usam o mesmo contorno. Não há cachoeira ou poço nesta versão.

## 3. Capturas e revisão
`../captures/a/{geometria,arte,arte-terreno}/`:51 vistas por versão; B e C:52 por versão. Total465 PNG1280×720; manifesto/hashes em `capturas.json`. Gerais, entrada/saídas, centro, aterros, raízes, todas as bocas de rampas, cantos de relevo, cabeceiras e 12 amostras ampliadas das margens por área. Sem personagem nas juntas. Água contínua não tem ponta interna nem margem construída; nenhuma mureta foi criada.

Blocagem capturada antes da geração do asset. Revisão de pranchas geométricas/artísticas das três partes, mais detalhes nativos de cabeceira, implantação e acessos. Algumas copas encobriam rampas: exclusão por projeção dos acessos adicionada e arte recapturada. Revestimento e face de terra reaproveitados, vegetação nova presa ao tronco. Capturas geométricas não incluem árvores, arte-terreno retira cenário para expor juntas. Não houve mapa anterior a substituir, portanto não há comparação antes/depois de uma região existente.

## 4. Percurso e testes
Percurso real da prévia com física e seguidor, sem teleporte para os destinos internos, reaproveitando o teste de nome histórico `industrial_map_checks.gd` com `INDUSTRIAL_AREA` apontando para o pântano:
- A:37 destinos,74 viagens,18.900 quadros,zero falhas.
- B:38 destinos,76 viagens,18.940 quadros,zero falhas.
- C:38 destinos,76 viagens,18.940 quadros,zero falhas.
Total226 viagens; itens/interação, subidas/descidas, pés, seguidor e saídas/chegadas. A correção final de copas e o refinamento das folhas na água alteram somente arte, não o grafo testado.

Node16 testes aprovados. `overworld_checks.gd`:146.169 checagens/zero falhas. `morro_map_checks.gd`:9.386/zero. Regressão Bosque:79 amostras de margem protegidas,108 amostras de ponte transitáveis/zero falhas. Teste novo `pantano_water_checks.gd`:142/121/131 amostras de tabuleiro transitáveis A/B/C, todas as arestas do grafo fora de água, zero falhas. As células bloqueadas junto ao contorno são conservadoras; não houve amostra de margem dentro de célula caminhável no pântano. Não confundir esse zero com margem inexistente.

Testes gerais ainda emitem diagnósticos legados de shader e recursos na saída; asserções e saídas dos testes passaram. Erro inicial de tufos de encontro por variante ausente no kit floresta foi corrigido condicionando o consumidor do pântano; capturas finais sem SCRIPT ERROR/SHADER ERROR. Logs gráficos no sandbox podem indicar impossibilidade de criar cache/log de usuário; não declarar execução completamente silenciosa.

## 5. Itens, pistas e revelações
Três materiais por parte: papel no aterro, varetas escondidas entre raízes e cola no topo norte. Total9,3 escondidos. Não há item novo ou pista canônica. Interação de margem tranquila apenas descritiva, sem cura. Autorização explícita do dono para prévia independente, sem chefe nem revelações. Conta, save, batalha e recompensas não foram alterados.

## 6. Pedidos ao integrador
Decidir quando e onde ligar a campanha e implementar persistência/coleta pelos sistemas oficiais. Nomes são descritivos de trabalho, não acréscimo silencioso à bíblia. Kit usa o carregador PNG com cache existente; preparar inclusão/importação no export e validar no pacote. Arte nova não substitui colisões por um fundo único.

## 7. Dúvidas para o dono
Sem bloqueio para avaliar esta prévia. Aprovação artística ainda pendente. Recomendação para próxima iteração: avaliar a água e a densidade primeiro; depois diferenciar mais a topologia de B/C. Nesta primeira versão as três compartilham a estrutura de aterros/travessia, com curvas distintas do canal. Não afirmar três layouts narrativos totalmente diferentes ou marco único já concluído em C. A árvore gerada é a família visual do kit, não personagem canônico.

## 8. O que não foi verificado
Sessão humana longa, controle físico, Steam Deck, FPS/memória prolongados, export empacotado, campanha, recompensas e áudio. Não foi criada sala isolada adicional para o kit: o trecho real de A serviu de conferência; terreno/margens/ponte já eram componentes medidos existentes, árvore nova foi revisada no cenário. Nem todos os465PNG foram abertos individualmente em tamanho nativo; pranchas complementam os detalhes selecionados. Folhagem sem rig/animação; água tem apenas ondulação visual discreta. Alpha da árvore foi amostrado e depende do shader de recorte para rejeitar névoa externa. Sem certificação botânica ou aprovação artística do dono. Nenhum push ou merge automático.
