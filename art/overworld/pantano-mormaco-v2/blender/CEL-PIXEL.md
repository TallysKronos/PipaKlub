# Mormaço — cel shading + pixels

Variante visual derivada de `mormaco-referencia.blend`, preservado sem alterações por este processo.

- `mormaco-cel-pixel.blend`: cena editável com materiais cel e contornos.
- `mormaco-cel-pixel-nativo.png`: render em 836 × 471.
- `mormaco-cel-pixel.png`: apresentação em 1672 × 942, com repetição exata 2 × 2 de cada pixel.
- `estilizar_cel_pixel.py`: reprodução do tratamento a partir da cena original.
- `validacao-cel-pixel.json`: resolução, escala inteira e contagens do processamento.

Os materiais de superfície usam Diffuse → Shader to RGB → ColorRamp CONSTANT → Emission. Cada material tem três faixas: sombra fria, meio-tom e luz quente. As texturas procedurais de roughness/cor da versão anterior deixam de comandar a aparência. Sprites e fundo mantêm seus próprios materiais de imagem.

As silhuetas de volumes selecionados recebem cascas invertidas finas em azul petróleo. Folhas individuais não recebem cascas, evitando um contorno escuro em cada detalhe. O filtro de render é mínimo; a ampliação usa NumPy repeat, sem interpolação ou nitidez artificial.

Este é um render 3D em grade discreta, não uma passada manual de pixel art em Aseprite. A resolução escolhida apresenta o mapa inteiro; a densidade final em relação ao Kael depende da câmera de gameplay na futura integração. A variante ainda não está aplicada no Godot.

Execute `estilizar_cel_pixel.py` com Blender 5.1 em background, a partir da raiz do projeto, depois de gerar a cena original.
