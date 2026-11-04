# Clareira e Veredas — atualização da campanha

Origem: `origin/codex/mapa-veredas-do-encanamento`, commit `649471de`. Foram aplicados os seis commits posteriores ao Jardim (`1fbc0147`, `0c402c55`, `5549f21f`, `f44ad24d`, `e6c62cac`, `649471de`) sobre a integração local de Kronasta. Os arquivos do Bosque e a missão da Nina foram preservados. Não houve merge ou push em main.

## Conteúdo atualizado

Clareira e Veredas agora usam as plantas novas: platôs e caminhos elevados na Clareira; canal recortado, ponte de três células, escada e pátio elevado nas Veredas. Foram trazidos os geradores, fontes Tiled, compilados, estruturas, testes, planos e evidências do construtor. A trilha de passos do seguidor funciona também na campanha, pois o controlador oficial herda o renderer da prévia.

A renderização nativa substitui os materiais da planta anterior; o carregamento dos contornos antigos foi desativado somente nas áreas com `forest.nativeProps`, evitando aplicar máscaras de outro layout. O caso de água com cachoeira do Bosque permanece suportado.

## Encaixes na campanha

- Materiais das três partes usam recibos atômicos, sem duplicar coleta ao recarregar. Baús conservam as cinco identidades e as recompensas existentes, incluindo baús já abertos em saves antigos.
- Rabiola de Nina só aparece depois da vitória e da aceitação da missão. O baú dos canos continua protegido antes de vencer o guardião.
- O atalho do pátio para o Jardim é liberado após recolher a rabiola, preservando o gating da campanha anterior. O evento é acrescentado pelo adaptador, em piso apoiado a leste do guardião; não altera a fonte Tiled do construtor.
- Os treinadores Cauê e Celina foram reposicionados para a aproximação anterior ao rio/pátio. A campanha verifica que permanecem fora de um raio de dez células do guardião, preservando o espaço de apresentação do boss.
- As chegadas A↔B↔C usam as coordenadas autorais e suporte do terreno atual. A integração da Nina no Jardim continua no adaptador.
- Saves nativos dos layouts anteriores de até 64×48 continuam carregáveis. Antes de exibir o mundo, a posição é normalizada para o chão transitável mais próximo e gravada no mesmo slot, sem alterar moedas, itens ou recibos. A tolerância aos limites antigos é apenas para leitura: movimento, recompensas e novas gravações continuam usando a geometria atual. Retornos de batalhas antigas também passam por essa normalização.

## Validação

Todos os saves usados nas verificações são temporários, isolados dos saves do jogador.

| Verificação | Resultado |
| --- | --- |
| Campanha completa, captura nativa | 148 verificações, zero falhas |
| Node, Jardim/Clareira/Veredas e auditoria do Bosque | 17 testes passaram |
| Clareira, controlador real da prévia | 42 alvos, 84 viagens, 20.940 frames, zero falhas |
| Veredas, controlador real da prévia | 72 alvos, 144 viagens, 61.500 frames, zero falhas |
| Overworld completo | 88.039 verificações, zero falhas |
| Ritmo de encontros | 433 verificações, zero falhas |
| Regressão da campanha do Bosque | 114 verificações headless, zero falhas |

O teste de campanha em `godot/tests/park_campaign_integration.gd` exercita o percurso completo, os oito materiais de B/C, baús antes/depois do boss, combate real por inputs, rabiola, atalho, retorno à Nina, recarga em disco, derrota e fuga. Inclui uma posição real do layout antigo (61,5;25,5) fora das novas Veredas, confirmando que continua carregável e mantém recompensas. A contagem final e capturas nativas 1280×720 ficam em `documentation/overworld/park-campaign-v1/`.

## Limites

As novas cutscenes de Tyler/Rai, Grampo e porta das Ruínas citadas nos relatórios do construtor ainda são pedidos futuros: esta atualização preserva o roteiro e o combate existentes. Não cria uma cena de Ruínas sem contrato, nem novas falas/revelações. Nenhuma nova arte de personagem foi gerada.

Não houve playtest humano com controle físico, build distribuível ou avaliação em outras GPUs. Permanecem os diagnósticos headless de shader de outro bioma e, nesta máquina, o aviso de cache gráfico em `user://`, já documentados antes. Isso é separado dos resultados das asserções.

Para testar, abrir `godot/project.godot` nesta worktree e pressionar F5. A sequência normal do parque agora percorre as três plantas novas; o Bosque opcional permanece em M → Região de Kronasta.
