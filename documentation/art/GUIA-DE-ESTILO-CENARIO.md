# Guia de estilo de cenário · o mapa conversa com os personagens

14/11/2026. Vale para todo mapa, prédio e prop do overworld, junto com
`documentation/art/PIPELINE-CONCEPT-PARA-JOGO.md`.

## A regra

**O concept define o conteúdo e o clima. Os personagens definem como se desenha.**

Os concepts do designer (`art/overworld/conceitos/`) são ilustrações pintadas, em perspectiva,
cheias de detalhe pequeno. Servem para dizer *o que* existe no lugar (prédios, caminhos, props,
cores dominantes, clima). Nunca se copia o *jeito de desenhar* deles: o jeito de desenhar vem do
Kael, dos NPCs e dos Soulmonsters, que são pixel art.

## O problema medido

| Peça | Como é feita | Cores |
| --- | --- | --- |
| Kael (`godot/assets/kael-video/iso-v2/idle.png`) | pixel art, desenhada no tamanho em que aparece | 26 |
| Prédios da Vila (`godot/assets/overworld/kits/bairro-inicial-v2/buildings/`) | pintura de 784 px reduzida para ~290 px na tela | ~139 mil |

São dois estilos lado a lado. Seguir os concepts do jeito que eles são aumentaria a distância.

## As regras de desenho

1. **Projeção:** isométrica 2:1 (célula de 64 × 32 px), a mesma dos mapas. A perspectiva do concept é
   reprojetada, nunca decalcada.
2. **Densidade de pixel igual à dos personagens:** 1 pixel da arte = 1 pixel do jogo com zoom 1 (o
   Kael tem 70 px na folha e 67 px na tela). Nada de pintura grande reduzida.
3. **Régua de escala:** degrau e meio-fio = 8 px; um nível do terreno = 48 px; porta ≈ 1,3 × a altura
   do Kael; um andar ≈ 1,9 × a altura do Kael.
4. **Paleta mestra:** `art/overworld/estilo/paleta-mestra.hex` (também `.gpl` para o Aseprite e
   `.png`): 48 cores tiradas do Kael, dos 15 NPCs e de 60 Soulmonsters v2. Toda cor de cenário sai
   dela ou da sua **extensão de cenário** (ver "Tarefa da paleta" abaixo).
5. **Contorno:** só na silhueta externa de prédios e props, 1 px, na mesma família escura do
   contorno do Kael (`#10101c`, `#171b2b`, `#15283f`). Linhas internas na cor escura do próprio
   material. Chão e terreno sem contorno.
6. **Sombra:** cel, 2 a 3 tons por material, luz vindo do alto e da esquerda da tela (a mesma dos
   personagens). Sem degradê, sem aerógrafo, sem textura pintada.
7. **Detalhe mínimo:** nenhum detalhe menor que 2 px (o tamanho do olho do Kael). Muitos objetos
   pequenos do concept viram poucos objetos maiores.
8. **Hierarquia:** o cenário fica 10 a 20% menos saturado e com menos contraste que os personagens.
   Em escala de cinza, o Kael e o companheiro ainda se destacam do chão e das paredes.

## Teste de convivência (obrigatório em toda entrega)

Toda peça de cenário entregue vem com uma imagem em que o Kael, o Rabbito e um NPC estão sobre ela,
no tamanho do jogo e ampliada 2×, e a mesma imagem em escala de cinza. Se a peça "parece de outro
jogo" ao lado deles, volta.

Exemplo: `art/overworld/estilo/teste-convivencia-loja.png` (a loja da Vila como é hoje e convertida).

## Ferramenta

`tools/sprites/converter-cenario.mjs` converte uma pintura para pixel art na densidade dos
personagens, presa à paleta mestra:

```
cd tools/sprites && npm install
node converter-cenario.mjs <pintura.png> <saida.png> <altura-em-px-na-tela>
```

O teste com a loja mostra o limite: a densidade de pixel fica certa, mas a cor sai torta (plantas
amarelas, toldo verde virando cinza, pontinhos no telhado), porque a paleta só dos personagens não
tem as cores de cenário. A conversão é o **primeiro passo**; o acabamento à mão no Aseprite (limpar
grupos de pixels, refazer contorno e sombra) é obrigatório.

## Tarefa da paleta (antes de produzir mapas em série)

Criar a **extensão de cenário** da paleta mestra, no mesmo espírito das cores dos personagens
(mesma variação de matiz entre luz e sombra, mesma saturação máxima): rampas de 4 a 5 tons para
vegetação, terra, pedra e concreto, água, telhado, madeira pintada e vidro. Salvar em
`art/overworld/estilo/paleta-cenario.hex` (+ `.gpl` e `.png`) e testar refazendo a loja da Vila.

## Ordem de produção para uma região nova

1. Ler o `BRIEF.md` e o concept da região em `art/overworld/conceitos/`.
2. Fazer a ficha de tradução e o blockout (pipeline, etapas 0 e 1).
3. **Peça-teste da região:** um prédio e dois props do concept refeitos nestas regras, com o teste
   de convivência. O dono aprova antes do resto.
4. Só então o kit inteiro e o mapa.
