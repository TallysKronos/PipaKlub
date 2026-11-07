# Pincel de floresta de Kronasta

Recarregue o editor. **K / Floresta** ou o asset **Árvores de Kronasta** ativa o pincel; tamanhos 1–4 respeitam a grade de 32 px. Shift ou botão direito apaga a área. **Bosque de teste** abre uma amostra reversível por Desfazer.

A arte atual é gerada e depois fatiada, conforme a correção do usuário. Fonte, sprite, copa, tronco, atlas, prompt e receita estão em `art/environment/topdown-forest-v2/`. A arte procedural anterior foi substituída no consumidor.

Conexões usam 47 máscaras de vizinhança, separadas pela cota real do apoio. Árvores não são plantadas em água ou rampas. Colisão dos troncos usa o sistema de objetos; copas e Kael são ordenados pela base, com oclusão dos barrancos preservada. A floresta fica na camada de vegetação, com trava e visibilidade existentes.

Validação: 40 testes Node, incluindo os 256 padrões de vizinhança, deduplicação, clareiras, importação/exportação e regressões de terreno. Teste de interface com pintura 2×2, apagar por Shift, desfazer/refazer, Kael bloqueado no tronco por teclado e capturas atrás/na frente da copa. Evidências em `captures/trees-*`.

Godot 4.7.2 importou e executou a cena. `check_trees.gd` compara máscaras e regiões com o Studio. No projeto exportado, K pinta árvores e Shift apaga; sprites e atlas seguem no ZIP. Não é um TileSet de chão: as árvores usam recortes de atlas e ordenação por base para manter a profundidade.

As capturas do editor foram feitas em sessão isolada. A composição salva do usuário não foi substituída. Nenhum merge ou push foi feito nesta etapa.
