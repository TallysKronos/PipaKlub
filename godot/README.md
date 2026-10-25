# Soulmonsters — primeira versão Godot

## Cena inicial atual: Veredas ilustradas

A abertura usa `scenes/illustrated_veredas.tscn`, com arte panorâmica e atores separados. A revisão de movimento usa polígonos de chão e obstáculos, contato nos pés, rotas com folga e seguidor por pegadas. Entrada, duas pontes, mirante, encosta, rampas e pátio podem ser explorados; combate e missão do boss ainda não foram integrados nessa cena. M alterna visão geral e F3 destaca pisos e obstáculos.

`Iniciar.ps1 -Test` verifica dez marcos nos dois sentidos e percorre as rotas com o controlador real em quadros de 1/60 s. Veja [assets/illustrated/README.md](assets/illustrated/README.md). Não há save nessa cena: F5/save e a planta integral descritos abaixo pertencem ao protótipo anterior `scenes/main.tscn`. O pátio de escala continua em `scenes/scale_yard.tscn`. As seções seguintes registram as etapas anteriores.

Protótipo nativo independente em Godot 4.7.2, renderer Compatibility, Windows como primeiro destino. Não substitui o cliente Canvas e não conecta banco, contas ou economia de produção. Nenhum asset de Digimon foi incorporado.

## Executar

Abra `project.godot` no Godot 4.7 e pressione F6/F5. No Windows também pode executar `./godot/Iniciar.ps1` da raiz do repositório; `-Editor` abre o editor e `-Test` executa as verificações sem janela. Em outro computador, instale Godot da distribuição oficial e defina GODOT_PATH ou passe `-GodotPath` ao launcher. Não há download automático de executáveis no launcher.

A instalação desta tarefa está em C:/Users/User1/Documents/Codex/tools/godot, fora do Git. Não há executável standalone exportado nesta entrega: o projeto roda com o binário Godot. Export templates e build distribuível Windows serão a próxima etapa.

## Controles

WASD, setas ou analógico esquerdo movem Kael na orientação da tela. Clique no chão para seguir uma rota. E/Enter ou A do controle interagem. F5 salva; Esc abre uma pausa. Os botões Entrada, Canal, Nina e Encosta são atalhos temporários de revisão. Eles não existem no jogo original.

## Incluído

- Cena nativa Node2D, câmera com suavização, interface Control e ordenação dos personagens por profundidade.
- Kael animado a partir do avatar original, com cabelo e mochila presos às âncoras dos quadros. Rabbito usa o atlas original; Nina usa a pose estática existente.
- Planta integral das Veredas importada em JSON, terreno ilustrado, relevo, rampas, duas pontes, árvores e cinco baús.
- Navegação AStar em coordenadas de mundo e altura. Água sem ponte e troncos bloqueiam movimento; rampas conectam patamares.
- Conversa inicial com Nina e estado de baús em um save próprio `user://veredas-prototype-v1.json`, sem concessão de itens na conta original.
- Validação de versão, posição transitável e IDs de baús ao carregar o save.

## Limites da primeira etapa

Ainda não há combate, inimigos selvagens, boss desenhado, abertura, oficina, coleção, áudio, login ou integração Steam. O conteúdo do baú é uma mensagem de protótipo, não um inventário migrado. O diálogo é texto e botão; o retrato foi separado para futura composição. Gamepad e interação estão implementados, mas não houve teste com um controle físico.

A arte do terreno ainda usa desenho nativo de polígonos a partir das superfícies, não um TileMapLayer pintável no editor. Esta etapa verifica portabilidade e funcionamento; não comprova ainda ganho de autoria de mapas. O próximo passo é converter a família de materiais em TileSet/TileMapLayer e extrair ator, interação e diálogo em cenas reutilizáveis. O tile/colisão e a navegação precisam continuar usando as mesmas medidas.

## Arquitetura e fontes

`scenes/main.tscn` compõe a raiz; `scripts/main.gd` controla este primeiro fluxo, `region.gd` concentra geometria/navegação e `avatar.gd` monta o avatar por âncoras. Dados e artes originais estão em assets. Para sincronizar novamente da versão atual, execute `node scripts/godot-sync.mjs` na raiz do repositório. Os arquivos de importação do Godot podem ser regenerados; `.godot` e `exports` são ignorados.

Save de teste fica na pasta user:// do projeto Godot, separado do navegador. A API e as migrações do jogo original não foram modificadas. Para distribuição futura, incluir o aviso de licença do Godot e inventariar licenças de plugins quando houver.

## Verificado

Godot oficial 4.7.2 importou o projeto. Execução headless com `--smoke` verifica carregamento da cena, navegação da entrada ao pátio, altura do pátio, bloqueio do canal fora da ponte, cinco baús e quadros do parceiro. O verificador de referências retornou zero erros/avisos. Captura do viewport pelo renderer gráfico foi inspecionada; isso não equivale a playtest manual completo.

## Próximos passos

1. Ajustar TileSet e edição visual do trecho de referência, com bordas e alturas.
2. Separar cenas reutilizáveis de Kael, parceiro, baú e NPC.
3. Validar teclado, controle, interação e save em um percurso manual completo.
4. Migrar uma batalha e seu retorno ao mapa.
5. Definir saves offline, integração de conta e exportação Windows para avaliação Steam.


## Revisão de escala e primeira camada TileMap

A cena inicial passou a ser `scenes/scale_yard.tscn`, um pátio compacto para avaliar proporções antes de ampliar a região. A cena `scenes/main.tscn` preserva as Veredas completas. A câmera usa zoom 1.4 (antes 0.95), aproximadamente 47% mais próximo. Árvores foram reduzidas em cerca de 13% em relação ao personagem. O save do pátio é separado: `user://scale-yard-v1.json`.

O pátio tem ponte, rampa de 80 unidades, Nina, um baú e árvores. Os atalhos da HUD ajudam a comparar clareira, Nina, rampa e baú. Nesta revisão não foram geradas novas artes: as ilustrações existentes foram normalizadas para os primeiros tiles isométricos.

`tiles/veredas-materials.tres` é o TileSet externo, com células de 128×64, quatro materiais e quatro orientações espelhadas para cada material. `tiles/reference-ground.tscn` contém o TileMapLayer persistido: abra essa cena para pintar a camada no editor. A escala 0.82 faz cada passo corresponder a 64 unidades do mundo original (52.48×26.24 na tela). `tools/build_tiles.gd` regenera o atlas e a cena base; execute apenas para reconstruir a base, pois ele substitui a pintura dessa camada. Se o atlas mudar de dimensão, reimporte no editor antes de reconstruir a cena.

Apenas a camada base de grama foi convertida em TileMapLayer. Caminhos, água, rampas e barrancos ainda usam a geometria do protótipo. Os próximos assets são transições, bordas e cantos; não considerar este atlas um kit final de autotiling. Alterar só a pintura da camada base não muda navegação: até a migração completa, os limites transitáveis continuam no JSON da cena.

Verificado: importação Godot, teste do trajeto completo do pátio, bloqueio de água fora da ponte, altura, interação por proximidade, save isolado e correspondência entre a grade de tiles e a projeção. Captura gráfica inspecionada; sem playtest com controle físico nesta etapa.


## Transições do caminho — primeira família

O pátio agora usa duas camadas TileMapLayer de caminhos: PathsLow e PathsHigh, na cena `tiles/reference-paths.tscn`. O TileSet `tiles/path-transitions.tres` tem 16 máscaras de borda, com quatro orientações de textura (64 tiles). As máscaras consideram vizinhos nas quatro direções do mundo: negativo/positivo X e negativo/positivo Y. Células internas não recebem borda; cantos combinam duas ou mais bordas. A passagem para grama usa mistura com largura controlada e variação suave. Os materiais são os já existentes, sem nova geração de arte.

Para regenerar: execute `Godot --headless --path godot --script res://tools/build_transitions.gd`, reimporte o projeto no editor e depois execute o mesmo comando com `-- --paint`. A primeira etapa grava o PNG; a segunda gera o TileSet e pinta as camadas iniciais a partir do JSON. Isso substitui a pintura dessas camadas: preserve edições manuais antes de regenerar. Não são terrains Connect configurados no editor; a seleção por vizinhança acontece na ferramenta de preparação. Os tiles continuam disponíveis para pintura manual.

A ponte mantém deck livre de terra e recebe cabeceiras, sombra e espessura. A água ganhou pedras de margem interrompidas nas travessias. Rampas ganharam cunhas laterais de sustentação. Água, barrancos e rampas ainda usam geometria do protótipo: não afirmar que todo o mapa já foi convertido em tiles.

Verificação adicional: 64 tiles presentes, célula interna sem borda, canto externo com duas transições e nenhuma célula de terra sobre a ponte. Captura gráfica do pátio revisada. Para avaliar novas alturas e o encaixe superior da rampa, use o botão de revisão Baú; a captura inicial não enquadra o patamar inteiro.
