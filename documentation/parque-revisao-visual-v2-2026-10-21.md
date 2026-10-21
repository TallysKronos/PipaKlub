## Revisão visual do parque — 21/10/2026

A primeira composição foi substituída pelo Jardim das Pipas e pela Clareira do Papel. A referência geral, os dois atlases e os prompts estão em `assets/world/park-kit-v2/README.md`. As árvores são peças completas, com uma única âncora e colisão na base; o terreno usa materiais exclusivos do parque, de menor contraste. Encontros ficam apenas nos habitats de capim alto, deixando o gramado baixo livre.

Builds de servidor e Pages concluídos. Suíte completa: 322 testes aprovados. O teste do parque verifica acesso a cada interação/saída e habitat, remoção das árvores montadas com copa/tronco separados e entrega real do atlas RGBA pela rota autorizada de assets. Na auditoria do navegador, o carregamento inicialmente apontou um atlas ainda não registrado; a rota foi corrigida antes da entrega. Também foi corrigido um habitat que sobrepunha a cerca do descanso.

O `.tmj` continua editando a geometria e o `.art.json` a composição, no pipeline existente. Não foi implementado importador nativo de camadas GID nesta revisão. Nenhuma migração nova, push ou deploy faz parte desta alteração visual.
