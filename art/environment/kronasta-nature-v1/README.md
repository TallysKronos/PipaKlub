# Kronasta — kit de variedades 1

**30 artes novas**, produzidas com o image_gen integrado usando a árvore aprovada como referência de estilo. As três pranchas originais estão preservadas em `sources/`; os PNGs do jogo foram recortados dessas artes, sem redesenho procedural.

- 6 árvores: ipê amarelo, ipê rosa, araucária, tropical de folhas largas, ancestral e casca clara.
- 12 plantas: duas samambaias, arbusto angular, arbusto de frutos, flores azuis/violetas/amarelas, margaridas, bromélia rubra, capim lavanda, folhas do brejo e musgo florido.
- 12 peças: quatro formações de pedra, tronco oco, toco em broto, galho, folhas secas, três grupos de cogumelos e raízes.

## Arquivos

- [Prancha de recortes na escala do jogo](catalog-preview.png).
- `sprites/`: 30 sprites individuais com transparência binária; árvores 64×96, demais peças 64×64. Os desenhos têm tamanhos próprios, não foram ampliados todos para preencher a mesma caixa.
- `atlases/`: seis atlas de árvore de 512×576, 47 encaixes cada.
- `parts/`: copa e tronco separados de cada árvore.
- `kit.json`: nomes, tamanhos, pivôs, famílias e colisão padrão.
- Prompts completos: [árvores](sources/trees-prompt.txt), [plantas](sources/plants-prompt.txt), [cenário](sources/props-prompt.txt).
- Artes originais: [árvores](sources/trees.png), [plantas](sources/plants.png), [cenário](sources/props.png).

O recorte usa vizinho mais próximo, paleta de 40 cores por peça, sem dithering, e preserva as sombras da arte gerada. Fragmentos pequenos de células vizinhas foram removidos das árvores. Regeneração com `tools/plant-lab/build-nature-kit.py`; catálogo autoral em `tools/plant-lab/nature-kit.mjs`.

## Editor e Godot

Recarregue o Studio e abra **Jardim de variedades**. Desfazer recupera a composição anterior. Categorias **Árvores**, **Plantas** e **Cenário**, com busca por nome/família.

As seis árvores usam o pincel de floresta. Espécies diferentes não copiam fragmentos umas das outras, nem conectam copas de cotas distintas. Pedras grandes e troncos definidos no catálogo começam com colisão; ela pode ser alterada nas propriedades.

A exportação Godot inclui catálogo, sprites e atlas. No projeto nativo, **N** percorre as peças do catálogo; **K** ativa floresta (Shift apaga). O renderer seleciona o atlas correspondente à espécie.

## Verificação

43 testes Node aprovados. Interface testada com os seis pincéis, pintura de tronco com colisão, busca, categorias e desfazer. Godot importou e executou a cena; `check_nature.gd` confirmou os 30 sprites e comparou as máscaras/regiões dos seis atlas com o Studio. Capturas em `documentation/plant-lab-v1/captures/nature-*`.

A sessão do usuário e a campanha não foram substituídas. Sem merge ou push nesta etapa.
