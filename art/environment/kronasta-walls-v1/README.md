# Revestimentos verticais de Kronasta

12 materiais próprios para paredes e barrancos, além das faces originais de terra e rocha. O piso é escolhido separadamente: uma superfície horizontal não reutiliza automaticamente sua textura na parede.

## Materiais

Terra com raízes, argila rubra, arenito, rocha cinza, ardósia vertical, basalto colunar, alvenaria de pedra, tijolos envelhecidos, concreto envelhecido, ruínas musgosas, gelo e paliçada de madeira.

## Uso no Studio

- Atualize a página e escolha **Parede / barranco** no inspetor.
- Use **J — Revestir face** para pintar somente o revestimento. Pisos, alturas e rampas são preservados.
- **Mostruário de faces** abre uma amostra com os 12 materiais em volumes de quatro níveis. Ctrl Z restaura o mapa anterior.
- No projeto Godot exportado, J ativa o revestimento e T percorre os materiais.

## Origem e reprodução

- [Arte gerada](sources/walls.png) e [prompt](sources/prompt.txt).
- [Catálogo visual](catalog-preview.png) e [definições](kit.json).
- `tools/plant-lab/build-wall-kit.py` recorta a prancha, reduz com vizinho mais próximo, limita a paleta e compatibiliza as extremidades das texturas de 64 × 64 pixels.
- O sampler mantém a orientação vertical da arte usando a altura negativa do mundo. Raízes e tábuas aparecem na orientação correta.
- O contorno e a sombra superior são aplicados uma vez por face exposta, sem repetir uma faixa a cada andar. A geometria existente mantém os encaixes, cantos, colisão e bocas das rampas.

## Validação

51 testes automatizados passaram. A verificação pelo navegador pintou os 12 materiais, conferiu a preservação dos pisos, alturas e rampas e exercitou desfazer/refazer. As capturas estão em `documentation/plant-lab-v1/captures/wall-*.png`.

A comparação do raster nativo do Godot com as camadas exportadas passou, incluindo a asserção original de altura. O cenário de regressão desloca a galeria uma linha para conservar o ponto de referência no chão.
