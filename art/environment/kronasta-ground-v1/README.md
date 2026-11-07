# Kronasta — kit de pisos 1

**27 materiais autorais**, gerados com o image_gen integrado e preparados para o editor e a exportação Godot. A árvore aprovada foi usada como referência de acabamento e paleta, sem colocar árvores nas texturas.

- **9 gramas:** viva, musgo, baixa, seca, bosque sombrio, prado florido, brejo, serra e folhas.
- **9 terras:** rubra, escura, trilha batida, areia dourada, clara e úmida, cascalho, lodo e raízes.
- **9 pedras/biomas:** calçamento, pedra musgosa, ruínas, tijolos, ardósia, basalto, cinzas, neve e gelo.

## Arte e arquivos

- [Catálogo com repetições](catalog-preview.png).
- `textures/`: três variações de 32×32 por material, reunidas em PNGs 32×96.
- `atlases/`: 47 máscaras × 3 variações por piso, PNGs 256×576.
- `terrain-set.tres`: 31 conjuntos de terrenos pintáveis (os quatro anteriores e os 27 novos). No Godot, as texturas devem estar em `res://autotile/`; o projeto exportado pelo Studio já inclui todos os arquivos nas posições corretas.
- `kit.json`: catálogo, prioridades, cores de contorno e receita.
- Pranchas originais preservadas em `sources/`: [gramas](sources/grass.png), [terras](sources/earth.png), [pedras/biomas](sources/stone.png).
- Prompts completos: [gramas](sources/grass-prompt.txt), [terras](sources/earth-prompt.txt), [pedras/biomas](sources/stone-prompt.txt).

As texturas são recortes da arte gerada, reduzidos por vizinho mais próximo, com paletas de 24 cores por material. Faixas periféricas compartilhadas e bordas opostas compatíveis permitem alternar as três variações sem fendas. Não foram substituídas por desenhos procedurais. Geradores: `build-ground-kit.py` e `build-ground-atlases.mjs`.

## Uso

Recarregue o Studio. Escolha **Terreno** na biblioteca ou **Piso do kit** nas propriedades. Pintura, preenchimento, conta-gotas, desfazer, JSON e exportação usam os mesmos identificadores. **Mostruário de pisos** abre uma amostra 30×16 com todos os materiais; Desfazer recupera o mapa anterior.

Os limites usam prioridades e vizinhos para misturar o material com o chão realmente adjacente, sem uma faixa artificial de grama entre pisos do kit. Os atlas isolados exibem grama como fundo padrão; a composição com outros pisos é resolvida pelo renderer. A geometria, as rampas e os barrancos continuam derivados da mesma sustentação.

Neve, gelo e lodo são materiais visuais nesta etapa, sem efeitos novos de movimento ou status.

## Validação

- 47 testes Node passaram: três variações com bordas compartilhadas, 47 recortes opacos por material, transições diretas entre pisos, JSON e regressões de água/relevo/vegetação.
- Interface: os 27 pisos pintados pelo mouse, 32 miniaturas de piso, seletor sincronizado, desfazer/refazer e atlas no diálogo. Capturas e relatório em `documentation/plant-lab-v1/captures/ground-*`.
- Godot 4.7.2: geração e pintura dos 31 terrain sets, execução da cena e comparação pixel a pixel entre raster dinâmico e exportado, inclusive sobre rampas e barrancos com os novos materiais.

A amostra foi testada em sessão isolada; a composição salva do usuário não foi substituída. Sem merge ou push nesta etapa.
