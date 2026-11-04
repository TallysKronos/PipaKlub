# Revisão — frutíferas articuladas v1

Entrega: 12 rigs Soulgen editáveis, 36 PNGs de componentes, 12 cenas Godot articuladas, fallback de repouso, biblioteca Iso Studio e galeria local de pancada/queda. Aprovação artística final pendente do usuário.

- `PREVIA-ANIMADA.gif`: 48 quadros do estudo de queda, renderizados pelo sampler real do Soulgen, com tronco fixo e copa móvel.
- `CATALOGO-12-FRUTIFERAS.png`: montagens de repouso, com miniaturas ajustadas individualmente.
- `ESCALA-NATIVA.png`: árvores e Kael na escala 1:1, Kael com 84 px.
- `AUDITORIA-NATIVA.png` e `nativo/`: 13 capturas Godot 1280×720; repouso, extremo do impacto e queda para todas as espécies, mais uma interação real com desprendimento e pouso.
- `rig-preparation.json`: fontes, pivôs, parentesco e revisão do contrato de junta.
- `godot-import.log`, `godot-native.log`: importação/renderização da galeria.

Foram corrigidos frutos pintados no tronco da jabuticabeira, frutos fora da casca, ruído isolado de geração e distância entre tronco e copa do coqueiro. A montagem final foi revista com raiz visível, sem personagem encobrindo a junta. Copa sobrepõe os galhos completos para preservar encaixe durante a rotação.

Nenhuma suíte de testes foi executada, conforme a preferência do usuário. Houve checagem do formato no exportador, amostragem das juntas para preparar o rig e inspeção visual das capturas. Isso não valida navegação, coleta, inventário, regeneração ou posicionamento em mapas de campanha; essas integrações não foram feitas.

Como editar e abrir a prévia: `art/overworld/kits/frutiferas/README.md`.

## Jabuticabeira — revisão 2
Feedback do usuário: espécie estava estranha. Refiz a arte do tronco (casca clara e bifurcação suave), copa (folhas menores) e fruto (redondo, sem haste longa). Substituí a fila de três frutos por 16 jabuticabas pequenas em grupos irregulares sobre a casca. Todas permanecem peças destacáveis; a quantidade é uma composição visual desta prévia, não uma regra de economia da campanha. Versão anterior preservada em fontes/revisoes/jabuticabeira-v1. Prompts e fontes da revisão em fontes/revisao-jabuticabeira-v2.json.

Prévia focada: JABUTICABEIRA-V2.gif. Comparativo: JABUTICABEIRA-ANTES-DEPOIS.png. Projeto portátil e pacote ZIP atualizados. Reimportação Godot e capturas de repouso/impacto/queda atualizadas, sem suíte de testes.

## Coqueiro — revisão 2
Corrigido deslocamento da copa em relação ao tronco curvo. O pivô agora usa uma seção opaca real do pescoço do tronco e o encontro das hastes das folhas, em vez dos centros dos PNGs. Mantida escala uniforme por componente; copa proporcionalmente maior e tronco um pouco menos robusto. Cocos reposicionados como cacho sob a junção. A restrição anatômica usa esse mesmo par de pontos e permanece válida durante o balanço. Não houve redesenho raster nesta revisão, somente montagem e pivôs. Versão anterior preservada em fontes/revisoes/coqueiro-v1.

Prévia: COQUEIRO-V2.gif. Comparativo: COQUEIRO-ANTES-DEPOIS.png. Rig normal/portátil, cenas Godot, catálogo, captura nativa e pacote ZIP atualizados. Sem suíte de testes; revisão visual de repouso, extremo e queda na galeria Godot.
