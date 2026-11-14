# Laboratório v2 · Etapa 3 · Kit da fachada

O pedido “next” após a apresentação do quadro-chave foi tratado como avanço para o corte da fachada. O interior continua pendente de ampliação.

## Entrega

- **24 recortes PNG** em `pecas/`, sem escala, recoloração ou nova geração.
- `kit.aseprite`: uma camada por recorte, no canvas original 768 × 576.
- `atlas.png`: 1024 × 2048, 2 px transparentes de margem; usar nearest, sem mipmaps.
- `manifesto.json`: arquivo, região no atlas, posição original, pivô em pixels, pegada e apoio em células, cota e ordem de desenho.
- [Quadro aprovado remontado no Godot](remontagem-godot.png): 24 Sprite2D com AtlasTexture e pivôs.
- [Prancha dos recortes](prancha-pecas.png) e [mapa de propriedade dos pixels](mapa-de-recortes.png).
- `remontagem.png` e `remontagem-aseprite.png`: composições para comparação automatizada.
- `verificacao.json`: resultados medidos.

## Natureza do kit

Este é um **kit de montagem fixa por superfícies visíveis**, cortado da arte aprovada. Não é uma biblioteca de prédios intercambiáveis: não existem fundos reconstruídos atrás da torre, instrumentos ou vegetação. Alguns recortes incluem encontros com peças vizinhas e fragmentos de acabamento necessários à reprodução exata. Mover ou retirar componentes pode abrir lacunas; desenhar as superfícies ocultas é uma tarefa adicional, caso esse uso seja necessário.

O quadro-chave original e seu arquivo Aseprite permanecem preservados. O corte não muda os pixels aprovados.

## Remontagem 1:1

Para cada entrada de `parts`:

1. Extrair `atlas_rect` do atlas ou abrir `file`.
2. Usar Sprite2D com `centered=false`, `offset=-pivot_px`, `position=position_px`.
3. Manter `draw_order` na composição fixa. Usar filtro nearest e escala 1.
4. O deslocamento `position_px-pivot_px` deve coincidir com o canto superior esquerdo de `source_rect`.

A conferência compara PNGs individuais, regiões do atlas, pivôs e resultado remontado com o quadro-chave. Também verifica 2 px vazios em volta das regiões do atlas.

## Apoio na Vila · preparação para a etapa 4

A planta usa células 64 × 32, lote u=0,5..14 / v=−10..−1, entrada (7,25; −1) e terreno +48 px. `ground_anchor_cells`, `support_height_px` e `footprint_cells` registram as referências da planta. As pegadas são indicação de apoio, **não colisões prontas**.

Referência do canvas: pixel (24,316) corresponde à célula (0,5; −1), na cota local zero. Para trasladar o kit inteiro à projeção do bairro:

```text
origem_do_kit = projetar(0,5; −1; altura=48) − (24;316)
posição_global_da_peça = origem_do_kit + position_px
```

Isso equivale à projeção da célula de apoio de cada peça com sua cota. O pivô pode ficar fora do retângulo de uma cobertura alta; isso é intencional.

Na montagem do bairro, conferir o contorno real do piso pintado contra o lote, a faixa frontal de uma célula, a calçada e o vizinho. A ilustração tem recuos e bordas pintadas; não derive colisão da área opaca inteira e não use a deformação afim do renderer antigo para fazê-la caber.

## Responsabilidades da integração

Conforme o pipeline, a montagem no mapa e a captura final ficam com o integrador/Claude. Para essa etapa:

- Copiar o kit aprovado para os assets de runtime e usar o manifesto como fonte única.
- Atualizar o consumidor que hoje aponta para `campaign/professor-pixel-v2/fachada.png`; preservar a versão anterior até a conferência.
- Posicionar o conjunto no lote ampliado; manter a entrada (7,25; −1) e Sr. Assis (6,8; −0,65).
- Calibrar colisões e profundidade para Kael/companheiro passarem à frente e atrás das peças adequadas.
- Capturar no bairro e acrescentar essa captura ao comparativo, verificando contra o quadro-chave.
- Validar acesso, retorno do interior e saves na etapa de gameplay.

Nenhum mapa, colisão, entrada ou save foi alterado neste commit. O interior ainda não foi redesenhado.

## Reprodução

Da raiz do checkout:

```powershell
godot --headless --path godot --script tools/laboratorio_v2_kit.gd
godot --path godot --script tools/laboratorio_v2_kit_preview.gd --rendering-method gl_compatibility
```

O primeiro comando recorta e empacota; o segundo usa o atlas e os pivôs em Sprite2D reais, gera as pranchas e confere os dados. O Aseprite editável foi montado em modo headless a partir dos recortes. A regeneração automática de PNG/atlas não altera o arquivo editável; após mudar os cortes, atualizar suas camadas com as mesmas posições do manifesto.

Os testes são de integridade de assets e de remontagem estática. Não comprovam navegação ou oclusão no bairro.

## Resultado da conferência

24 camadas no Aseprite; 24 Sprite2D no teste Godot. PNGs individuais, atlas e exportação do Aseprite recompõem os 232.810 pixels opacos da fonte, com zero diferenças. A segunda execução manteve o mesmo SHA-256 do atlas (registrado em verificacao.json). Fonte aprovada preservada com SHA-256 53e9aac4b1f742e63aea1958b9d3257f3fc2ddd8302fce72d0a60ffc83e68f6c. Avisos de acesso ao cache/log do Godot no ambiente restrito não afetaram as capturas; os comandos concluíram com código 0.
