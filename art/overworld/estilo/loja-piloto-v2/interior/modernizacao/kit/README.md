# Kit moderno da Linha & Papel

Vinte recortes do quadro moderno aprovado, com atlas 2048 × 2048 e camada editável por peça no Aseprite. O canvas remontado tem 1120 × 820 px, em escala 1×.

## Conteúdo

- Piso e duas paredes.
- Duas janelas e três quadros de pipa.
- Duas prateleiras metálicas, expositor de pipas, gôndola e balcão.
- Terminal digital, duas mesas com pés e bancos posteriores, dois bancos dianteiros.
- Porta de vidro e capacho.

## Arquivos e montagem

Os PNGs individuais ficam em pecas/. O manifesto.json fornece regiões do atlas, source_rect, pivot_px, position_px, draw_order e pegadas da planta de referência. Configurar Sprite2D com centered=false, offset=-pivot_px e position=position_px. Aplicar filtro nearest e preservar a escala 1×. O atlas usa bordas transparentes de 2 px e regiões com filter_clip.

O interior-montado.aseprite contém os vinte recortes editáveis. O mapa-de-recortes.png identifica a divisão, e prancha-pecas.png mostra as peças.

As verificações conferem igualdade de todos os pixels visíveis com o quadro aprovado, tanto na montagem do atlas no Godot quanto na exportação do Aseprite. Conferem também as regiões e a margem transparente do atlas.

## Limites e próxima etapa

O kit recorta superfícies visíveis. Paredes, piso, móveis e sombras mantêm o posicionamento do quadro. Reposicionar móveis exige pintar as superfícies ocultas. Mesas incluem seus bancos posteriores. Os bancos dianteiros têm camadas próprias.

As pegadas usam [u inicial,v inicial,u final,v final] e vêm da planta aprovada. Os apoios visuais foram estimados na pintura para remontagem, e precisam ser calibrados no mapa. Na integração da cena kite-shop, conferir acesso pela porta, escala, corredor, interações e colisões. Para intercalar personagens entre partes do móvel, completar as faces ocultas e definir a ordenação pelo chão.

Esta entrega encerra a etapa 3. As evidências de remontagem estão em remontagem-godot.png, remontagem-aseprite.png e verificacao.json.

## Reprodução

Executar na raiz do checkout com o Godot no PATH.

```powershell
godot --headless --path godot --script tools/loja_interior_moderna_kit.gd
godot --path godot --script tools/laboratorio_v2_kit_preview.gd --rendering-method gl_compatibility -- --loja-moderna
```

Depois de reexportar as camadas no Aseprite, executar novamente a prévia para conferir a igualdade com o quadro-chave.
