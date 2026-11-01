# Kael — primeiro teste de caminhada

Direção esquerda; quatro poses de 48×64, pivô local (24,62), transparência binária e paleta compartilhada de até 32 cores opacas. Sequência `walk-left`: 140/110/140/110 ms, ciclo de 500 ms. Estudo para revisão, disponível no Pixelgen sem substituir o Kael no jogo.

Identidade: cabelo azul-escuro alto, fones cianos no pescoço, jaqueta azul com faixas claras e tiras presas ao quadril, camiseta preta, calça cinza-azulada e calçado escuro com sola clara. Referência: `../rpg-overworld-study-v1/kael-professor-4-direcoes.png`, linha superior. A imagem foi gerada pelo image_gen integrado; fonte em `generated-walk-source.png`, prompt completo em `prompt.txt`.

Conversão: core do Pixelgen, 4×1, 48×64, margem 2, amostragem por cor dominante e até 32 cores opacas. O rascunho indexado está em `draft.pixelgen.json`. A limpeza nativa reaproveita os mesmos pixels de cabeça nos primeiros 30 pixels de altura de cada quadro para eliminar redesenho do rosto e cabelo. As poses de braços, pernas e tiras da jaqueta vêm da imagem gerada. A coordenação dos membros ainda está sujeita à revisão visual do ciclo.

Reproduzir os arquivos finais a partir do rascunho:

```sh
node tools/pixelgen/examples/build-kael-walk.mjs
python tools/pixelgen/examples/export-preview.py art/characters/kael-walk-pixel-v1/kael-walk.pixelgen.json
```

O exportador de prévias requer Pillow. PNG nativo, projeto indexado, Aseprite com tag/durações, atlas JSON e GIF ampliado 6× estão nesta pasta. A prévia ampliada usa nearest-neighbor. O atlas informa recortes e pivôs em pixels; não é um recurso Godot automaticamente importado.

Verificação: dimensões, alpha e paleta, quatro quadros distintos, cabeça estável, leitura independente das cels/tag/durações no Aseprite e comparação de cada quadro do GIF com os pixels do projeto. A inspeção interativa do Pixelgen segue indisponível por configuração do Work; abertura no aplicativo Aseprite e revisão no jogo não executadas.

Studio 2: Corpo e Cabeça agora são camadas editáveis separadas no projeto e no Aseprite, com aparência e tempos preservados.
