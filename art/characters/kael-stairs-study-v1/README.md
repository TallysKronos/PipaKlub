# Kael — estudo de subida de escada

Escopo reduzido após a rejeição visual da biblioteca anterior: **uma direção, quatro poses**. Vista de costas, subindo para o fundo da tela.

A primeira tentativa diagonal repetia a mesma passada; o estudo escolhido usa a vista traseira para deixar explícitos joelho levantado, sola do pé e troca da perna de apoio. Não substitui os sprites da campanha.

- `kael-stairs-source.png`: arte gerada pelo imagegen integrado, com fundo transparente, quatro poses em linha. Prompt final em `prompt.txt`. Referência de identidade: `../kael-walk-pixel-v1/generated-walk-source.png`.
- `kael-stairs.pixelgen.json`: candidato convertido no Pixelgen, 64×80 por quadro, 32 cores opacas + transparente, uma camada. **Conversão não equivale a retoque manual de todos os pixels.**
- `kael-stairs.aseprite`: exportação editável desse mesmo candidato, quatro quadros e tag `stairs-up-N`.
- `kael-stairs-sheet.png`: folha nativa 256×80.
- `kael-stairs.gif`: prévia 6×, 180/140/180/140 ms, ciclo de 640 ms.
- `kael-stairs-preview-6x.png`: quatro poses ampliadas sem suavização.
- `kael-stairs-atlas.json`: coordenadas, durações e pivô.

No Pixelgen: **Kael · subir escada · 4 quadros**. A auditoria técnica encontrou alpha binário, quatro quadros preenchidos e nenhuma borda cortada. A leitura das poses foi inspecionada na prancha; a aprovação do movimento e o contato dos pés precisam ser conferidos sobre a escada real. Não afirmar integração ao Godot ou arte final.

Não deriva do rig procedural de 256 quadros. A arte foi gerada como sequência e só depois convertida, preservando a fonte para comparação e revisão. Há pequenas variações do cabelo/casaco entre as poses; não são eliminadas por uma checagem de cores.
