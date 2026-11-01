# Kael · salto de barranco · estudo integrado

Dois vídeos MiniMax H3 **locais**, sem API paga, usando as referências SE e NE da caminhada aprovada como estudo pelo usuário. Os grafos completos estão em `workflows/`. Jobs: SE `160bc00d-9ea4-4a5d-a143-1e892349c64b`, NE `50a572d3-d5e2-441f-b56b-23cb0da71a3e`.

`pacote/` contém PNG transparente, projeto Pixelgen editável, Aseprite indexado, atlas, GIF e relatório técnico. São 16 quadros selecionados por vista, 32 no total. Algumas poses têm sustentação; não são 32 desenhos únicos. Tempos e referências de origem estão no manifesto. SW e NW usam espelhamento no consumidor, preservando a convenção do avatar anterior.

A célula do salto é **96×112**, pivô **48,110**, ampliada para braços abertos. A escala do corpo é a mesma da caminhada 64×96; a paleta de 32 cores também. Nenhum quadro foi ampliado individualmente. O ponto inferior de apoio é normalizado por translação para retirar o deslocamento vertical do vídeo; o controlador do mapa aplica o arco real. O chroma remove magenta e o verde introduzido pelo primeiro vídeo.

Preparação 120 ms, voo 540 ms, aterrissagem 160 ms; total 820 ms, **sem loop**. O GIF repete apenas para facilitar revisão. O empacotador é `tools/pixelgen/examples/pack-kael-video-jump.py`; o verificador é `verify-kael-video-jump.mjs`.

## Integração Godot

O avatar compartilhado da campanha usa a família de caminhada por vídeo em oito direções. Nas **Veredas**, também usa o salto novo. Há dois pontos permitidos: frente do mirante (48 px de altura) e frente do pátio elevado (80 px). As marcas duplas no chão e o aviso indicam a ação **Interagir: E/Enter no teclado ou botão de interação do controle**. Só desce; o retorno continua pelas rampas/escadas.

As conexões explícitas vêm de `veredas_modular_landscape.gd`. O controlador `ledge_jump.gd` exige apoio e caminho de aproximação livres, valida o pouso, impede reentrada, interpola a altura sem atravessar visualmente a parede e mantém a coordenada persistente no início até aterrissar. Pausa congela a ação. Encontros e movimento normal aguardam a conclusão. O parceiro voa por uma curva lateral e pousa separado do jogador. Só a aterrissagem emite o pedido de autosave.

Evidências em `documentation/overworld/kael-ledge-jump-v1/`: capturas 1280×720, GIF/MP4 do jogo e teste do fluxo com perfil fictício, sem escrita de campanha. `godot/tests/ledge_jump_checks.gd` cobre apoio, altura real, arco, endpoints, destino inválido, retorno e repetição. `godot/tools/ledge_jump_review.gd` exercita o consumidor real.

## Revisão visual

### Limpeza de contorno e estabilidade da roupa

Depois da primeira revisão do usuário, os 32 quadros receberam acabamento no Aseprite: retirada de ilhas desconectadas de até dois pixels, contorno externo com o índice 31 da paleta e máscara por quadro para a calça, com base 6 e sombra 19. Assim o tom da roupa não depende da variação de azul produzida pelo vídeo. A paleta original, as poses, as durações e o tamanho do corpo foram preservados. O contorno não cresce para fora da silhueta.

O estado anterior está em `cleanup/before.pixelgen.json`; regiões e regras em `cleanup/policy.json`; contagens em `cleanup/report.json`. A proposta reproduzível fica em `tools/pixelgen/examples/clean-kael-jump.py`, e o empacotador reaplica a mesma regra às extrações futuras deste lote. O verificador não sobrescreve mais o documento Aseprite retocado.

Os quadros exportados pelo Aseprite foram comparados, pixel por pixel, ao PNG e ao Pixelgen. O relatório confirma paleta/duração preservadas e ausência dos tons azuis rejeitados nas regiões marcadas da calça. A comparação independente escolheu a versão limpa (8/10), sem perda material de silhueta, mãos, faixas claras ou pernas. Ver `pacote/comparacao-limpeza.gif` para a comparação em movimento; contagens e prancha estática não certificam ausência de toda cintilação.

A crítica independente considerou o resultado utilizável como estudo integrado, sem falha anatômica impeditiva. Ainda há uma pequena variação de orientação entre repouso e voo e sustentação da pose no ar. Isso permanece registrado para retoque artístico; teste técnico não equivale a aprovação visual final. Não há nado, corrida ou outros movimentos novos neste lote.
