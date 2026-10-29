# Professor Assis — primeiro teste de caminhada

Direção: esquerda. Quatro poses de 48×64; pivô local (24,62); paleta compartilhada com 31 cores opacas usadas; transparência binária. Ciclo `walk-left`, 140/110/140/110 ms (500 ms). Estudo para aprovação de movimento; não integrado ao jogo.

Produção: imagem gerada pelo image_gen integrado, usando `../rpg-overworld-study-v1/kael-professor-4-direcoes.png` como referência de identidade (professor na linha inferior). A fonte está preservada em `generated-walk-source.png`; o texto enviado está em `prompt.txt`. Conversão pelo core do Pixelgen, grade 4×1, 48×64, 32 cores opacas máximas e margem 2. A imagem gerada é rascunho, não pixels finais.

Limpeza nativa reproduzível: `node tools/pixelgen/examples/build-professor-walk.mjs` lê `draft.pixelgen.json`, estabiliza a cabeça reaproveitando os mesmos pixels nos quatro quadros, diferencia a profundidade das pernas no contato oposto e exporta projeto, Aseprite e atlas. Os contornos do corpo e o movimento do jaleco vêm das poses geradas. O ciclo é um primeiro teste; a coordenação dos braços e o desenho dos passos ainda podem ser refinados após revisão em movimento.

Arquivos finais: `professor-walk-sheet.png`, `professor-walk.pixelgen.json`, `professor-walk.aseprite`, `professor-walk-atlas.json` e `professor-walk.gif` (prévia ampliada 6×, nearest-neighbor). O atlas usa coordenadas e pivôs em pixels; não é um recurso Godot importado automaticamente. A cabeça não foi separada em camada anatômica no arquivo Aseprite: ele contém os quadros completos em uma camada editável.

Verificado: quatro quadros distintos sem recorte nas bordas; paleta/alpha; serialização; leitura independente das cels, tag e durações do Aseprite; GIF decodificado confere pixel a pixel com o projeto. A abertura no Aseprite e a revisão no jogo não foram executadas.
