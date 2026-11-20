# Piloto local do Mormaço — integração cel + pixel

Cena: `godot/scenes/overworld/mormaco_cel_pilot.tscn`. Atalho: `TESTAR-MORMACO-CEL.cmd`. Projeto ativo: `C:/Users/user/produto/pipa-club/godot`.

## Implementado

- Kael de produção com idle, walk, corrida e oito orientações, sem ampliar o sprite.
- Caminhada por teclado e navegação por clique com AStarGrid2D, bloqueio contínuo das margens, água, patamares, cercas e objetos.
- 28 árvores separadas, mais cercas e rochas grandes ordenadas pelo apoio. Água e cachoeira preservam os recortes do cenário.
- Animações de água, queda, copas, quadros existentes do Mormaço, vapor e ondulações.
- Visão geral com F2; câmera de jogo com zoom 1.0; saída com Esc.

## Verificado

`godot/tools/mormaco_cel_pilot_checks.gd`, executado em Godot 4.7.2 headless e com janela OpenGL na RTX 5070. O relatório automático é `checks.json`. Foram percorridos três destinos e o retorno à entrada, sem sair do chão permitido; conferidos bloqueios de água, cerca e limite externo. Capturas de trás/frente da árvore comprovam a ordenação no enquadramento selecionado. A troca de quadro do Mormaço é verificada pelo consumidor. Os shaders foram compilados pelo renderer nativo nas capturas.

Capturas: `01-margem-kael.png`, `02-mormaco-animado.png`, `03-atras-da-arvore.png`, `04-frente-da-arvore.png`, `05-geral.png`, `06-margem-detalhe.png`.

## Limites desta entrega

Somente a margem inferior foi convertida em espaço jogável. Patamares, escada oeste e mirante não possuem travessia neste piloto. Não substitui o mapa C da campanha, não inicia batalha nem altera os eventos narrativos. Nenhum save de campanha é lido ou gravado. A renderização prévia não é uma passada manual de pixel art em Aseprite. Não foi medido desempenho em celulares nem em hardware inferior; não houve sessão humana de teste nesta entrega.

O kit é pré-renderizado em camadas 2D. Os materiais cel específicos do Blender não foram exportados como PBR/GLB; isso preserva a aparência no renderer Compatibility do projeto. A conversão completa da região exigirá integrar alturas, conexões e gatilhos ao modelo de mapa existente.
