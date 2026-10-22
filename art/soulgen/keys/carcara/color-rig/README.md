# Carcará · rig colorido com expressões

Revisão solicitada pelo usuário em 2026-10-21: preservar o modelo gerado colorido, corrigir glitches e acrescentar expressão de golpe, dano e vitória. Esta solicitação substitui a restrição de 15 cores na versão apresentada. Os PNGs e atlas pixel art da entrega anterior continuam preservados como histórico.

## Correções

- A animação amostra diretamente os recortes RGBA da fonte gerada em `../source/layers-generated.png`, sem recolorir, reduzir para 64 px ou rotacionar em pixels inteiros a cada quadro.
- Todas as partes recebem a transformação comum do corpo antes da rotação local em ombros/laço. Asas e rabiola usam pivôs fixos.
- Ciclos contínuos fecham sem salto de pose; ações únicas têm preparação, ação e recuperação. A galeria repete ações com intervalo, mas a visualização principal respeita o fim da ação.
- Não há flashes, patches retangulares desencontrados ou mudança da silhueta ao trocar a expressão. As novas texturas do corpo têm alpha idêntico e pixels fora das janelas faciais idênticos ao corpo original.
- O rosto fica firme na preparação/golpe (0,22–1,65 s), aperta os olhos no dano (0,03–0,72 s) e sorri com os olhos na vitória (0,25–2,08 s). Retorna à expressão neutra ao recuperar. Repouso e voo mantêm a face neutra.

## Arquivos e reprodução

`rig.mjs` contém as partes/recortes e animações Canvas 2D. `body-reference.png` é o recorte do corpo original. `expressions-generated.png` foi editado com `image_gen` a partir desse recorte; o prompt está em `face-prompt.json`. `prepare-faces.py` registra apenas as regiões faciais da imagem gerada sobre o corpo original e preserva alpha/pixels externos. Não desenha olhos proceduralmente.

`body-fierce.png`, `body-hurt.png`, `body-happy.png`: corpo na mesma posição/tamanho, com expressões. `faces-comparison.png`: neutro, golpe, dano e vitória. `face-validation.json`: hashes e checagens de igualdade fora da face. `review-victory.png` e `review-hurt.png`: inspeção no navegador.

```text
python art/soulgen/keys/carcara/color-rig/prepare-faces.py
node art/soulgen/keys/carcara/color-rig/build-preview.mjs
node --test art/soulgen/keys/carcara/color-rig/rig.test.mjs
node art/soulgen/keys/carcara/serve.mjs
```

`preview.html` é independente: inclui fontes de imagem e código de animação. O build também atualiza a prévia principal da pasta Carcará, servida em `http://127.0.0.1:5235/preview.html`. Há pausa, velocidade e controle de tempo para examinar os extremos. O PNG fonte original é embutido sem modificação.

## Verificado e limites

Quatro testes passaram: continuidade dos ciclos, recuperação/valores finitos, seleção temporal das expressões e uso da mesma geometria de corpo sem sobreposição extra de rosto. A preparação facial verifica alpha idêntico e igualdade de todos os pixels fora das janelas de olhos/sobrancelhas. Expressões de dano/vitória e ataque inspecionadas na prévia local.

É uma animação de recortes nesta vista, não rotação 3D nem animação de penas individuais. Ainda não foi integrada ao jogo ou exportada como substituta do atlas pixel art. A prévia usa a paleta colorida; não foi submetida ao linter de 15 cores, que pertence ao contrato anterior.
