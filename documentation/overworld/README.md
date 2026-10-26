# Overworld — PIP-83, PIP-87 e PIP-88

## Entrega em revisão

O kit comum e o kit Morro estão preparados para avaliação visual. As cinco imagens em `art/overworld/conceitos` são estudos montados no próprio Godot a partir das plantas; os arquivos `-referencia` usam a mesma geometria e câmera em rascunho. Não são imagens conceituais livres que alteram os caminhos. A repetição de casas e a simplicidade dos pisos ainda precisam de uma passagem de composição antes de considerar a arte final aprovada.

A cena `res://scenes/overworld_preview.tscn` permite percorrer dez plantas (nove áreas e o piloto), alternar rascunho/arte e verificar eventos e baús. É uma ferramenta de revisão: encontros apenas sinalizam o mato; baús não entregam itens; nenhuma gravação da campanha é alterada. A campanha principal continua usando suas áreas existentes.

Abra `godot/Previa-Overworld.ps1`. Caminhe com WASD/setas ou controle; clique para traçar uma rota; use E ou o botão de interação do controle perto de um evento. A roda ajusta o zoom. O seletor troca de planta.

## Fontes e regeneração

- Plantas e modelo compartilhado: referência `claude/mapas-areas`, commit `469cb4e4c498faf6afcca9ee3f6782d72538f4a7`; importação pontual, sem merge da branch.
- `tools/overworld/build_art.py`: prepara PNGs, geometrias SVG, sombras separadas, projetos Iso Studio, réguas de escala e cópias para Godot. Fontes de imagem e prompts estão em cada pasta `fontes` dos kits.
- `tools/overworld/vestir-morro.mjs`: acrescenta casas somente a lotes já bloqueados e muretas decorativas. Verifica que nenhuma célula ou conexão caminhável mudou.
- `tools/import-overworld.mjs`: compila as plantas, gera cenas reutilizáveis das peças e dados de referência para comparação independente no Godot. Executar depois do construtor de arte.
- `tools/overworld/check-kits.mjs`: confere arquivos, variantes, identificadores e footprints dos projetos Iso Studio.

Use a mesma escala 64×32, altura de nível 64 e unidades verticais de 32 do Iso Studio. O volume visual de uma copa pode superar sua colisão: `visualFootprint` delimita o desenho; `footprint` define a navegação. A escala da imagem é uniforme. `anchor` posiciona o desenho no Godot; `isoAnchor` segue a origem do editor. Sombras de contato são arquivos próprios.

Os SVGs de arquitetura em `fontes/geometria` são guias; a arte selecionada das casas vem de `casas-morro-v2.png`. A normalização remove somente resíduos de transparência de alfa até 8/255; as fontes originais permanecem preservadas. O recorte usa o componente principal para evitar pedaços vizinhos das pranchas.

## Validação e limites

Resultados reproduzíveis em `reports`: 216 verificações de kit; 34.381 comparações e verificações de navegação das novas plantas; 1.510 verificações do parque e 9.386 do Morro antigo, todas sem falhas. O percurso da campanha existente passou em 209 verificações com armazenamento isolado. Esse percurso não certifica uma integração da campanha com as novas plantas.

O teste novo compara todas as células, conexões e alturas de rampas com o modelo JavaScript; também percorre rotas pelo controlador real. A auditoria Iso Studio cobre footprints e identificadores, não afirma validar contornos de copas com a regra de caixa sólida do auditor raster legado. As capturas verificam cortes de controles em sete resoluções; inspeção artística continua necessária.

## Pendências para concluir as issues

PIP-83: aprovação visual do kit comum. PIP-87: refino de composição, aprovação do kit Morro e dos cinco conceitos. PIP-88: a prévia e a paridade de geometria estão implementadas, mas a troca das áreas da campanha ainda depende da aprovação exigida na issue, dos demais kits de bioma e da adaptação dos pontos de entrada/checkpoints para as novas coordenadas. O piloto ainda usa chão de rascunho com peças comuns; não é apresentado como kit final de Veredas.

Nenhuma publicação, merge ou atualização do Linear foi feita nesta entrega.
