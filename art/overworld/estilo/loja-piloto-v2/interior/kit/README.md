# Kit do interior da Linha & Papel

Kit de montagem fixa do quadro aprovado, com 19 recortes em resolução nativa e 19 camadas editáveis no Aseprite.

## Arquivos

- `pecas/` contém os PNGs individuais com transparência.
- `atlas.png` reúne os recortes em 1024 × 2048, com margem transparente de 2 px por região.
- `manifesto.json` registra regiões, pivôs, posições, ordem e apoios de referência.
- `interior-montado.aseprite` permite editar cada recorte na posição original.
- `remontagem-godot.png` compara o quadro e a montagem por Sprite2D/AtlasTexture em 1×.
- `remontagem-aseprite.png` registra a exportação das camadas.
- `prancha-pecas.png` e `mapa-de-recortes.png` mostram a divisão.
- `verificacao.json` registra a comparação dos pixels visíveis e as verificações do atlas.

## Montagem

Para cada registro do manifesto, criar um Sprite2D com `centered = false`, filtro nearest, região `atlas_rect`, posição `position_px`, offset negativo de `pivot_px` e `z_index = draw_order`. O posicionamento reproduz a arte em 976 × 680.

Os recortes incluem somente superfícies visíveis. Alterar a posição dos móveis pode expor regiões de piso, parede ou tapete que precisam ser pintadas. Mesas e bancos estão agrupados por conjunto.

Os apoios foram estimados no quadro. A projeção de referência consta no manifesto e corresponde às medidas visuais da arte. Na integração, calibrar a cena `kite-shop` usando a porta, o chão e os pés dos personagens. Conferir o corredor desde a entrada até o caixa, passagem pelas mesas, saída e interações. Definir colisões e ordenar o personagem pelo apoio dos móveis. Para ocultá-lo entre banco e mesa, será preciso dividir as faces que cruzam sua trajetória.

## Reprodução

Executar na raiz do repositório com o Godot configurado no PATH.

```powershell
godot --headless --path godot --script tools/loja_v2_kit_interior.gd
godot --path godot --script tools/laboratorio_v2_kit_preview.gd --rendering-method gl_compatibility -- --loja-interior
```

Após reexportar as camadas do Aseprite, executar novamente a prévia para conferir sua igualdade com o quadro. A comparação normaliza o RGB invisível dos pixels com alfa zero, preservando os 370.506 pixels opacos da fonte.
