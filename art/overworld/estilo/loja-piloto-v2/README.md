# Paleta de cenário e loja-piloto da Vila

A extensão reúne 40 cores em oito rampas. Use a [lista HEX](../paleta-cenario.hex), a [GPL para Aseprite e GIMP](../paleta-cenario.gpl) ou a [cartela PNG](../paleta-cenario.png). A ordem vai da sombra para a luz e coincide nos três arquivos. A paleta mestra dos personagens continua sendo a base de contornos e acentos.

| Material | Sombra → luz |
| --- | --- |
| Vegetação | `#29463F` · `#3D6850` · `#527D56` · `#789661` · `#A5B77A` |
| Terra | `#533C3D` · `#755044` · `#A07457` · `#C59A70` · `#DFBB92` |
| Pedra | `#3C4357` · `#596177` · `#788497` · `#9DA9B5` · `#C8CDD1` |
| Concreto | `#595163` · `#84727C` · `#AB918B` · `#D6B79F` · `#F0DCC0` |
| Água | `#18394E` · `#22566D` · `#34798A` · `#589CA6` · `#95C8C5` |
| Telhado | `#303B58` · `#485476` · `#627493` · `#8A99B0` · `#B8C4D0` |
| Madeira pintada | `#673947` · `#8E4B50` · `#BB6457` · `#D58168` · `#ECA789` |
| Vidro | `#173246` · `#27536C` · `#407E91` · `#75ABB7` · `#B4D0D1` |

Verdes frios nas sombras e mais amarelos nas luzes dão volume à vegetação. Terra e concreto usam sombras rosadas ou violáceas. Água, telhado e vidro têm rampas separadas para segurar o contraste entre superfície, reflexo e estrutura. A madeira pintada usa corais intermediários, reservando-se os tons mais vivos da mestra para detalhes pequenos.

## Linha & Papel

A [loja em seis camadas editáveis](loja.aseprite) foi desenhada pixel a pixel na projeção do mapa. A fachada atual serviu de referência de construção, com telhado plano, respiro, toldo frontal listrado, toldo verde lateral, placa de pipa, lanterna, vasos e mercadoria. O redesenho usa uma vitrine lateral com três pipas legíveis e uma entrada definida por duas folhas e puxadores claros. A revisão independente confirmou a leitura da entrada depois do ajuste.

- [Loja transparente](loja.png), canvas de 340 × 328 px e 37 cores da paleta mestra e da extensão.
- [Comparativo da pintura atual e da loja-piloto](comparativo.png), com os mesmos pontos de apoio.
- [Convivência 1× e 2× em cor e em cinza](../teste-convivencia-loja-v2.png), ao lado do [estudo anterior](../teste-convivencia-loja.png).
- [Verificação do PNG](verificacao.json), com os apoios medidos em 2:1, zero cores fora da paleta e zero pixels semitransparentes ou opacos isolados.

Os apoios (20, 237), (170, 312) e (318, 238) delimitam 298 px de largura isométrica, correspondentes ao lote de referência de 9,3 células somadas nos dois eixos. Os novos contornos e a sombra foram desenhados no tamanho final. A convivência é uma prancha de aprovação visual. O PNG do jogo continua sendo a referência até a aprovação do piloto.

Para regenerar a cartela e as pranchas a partir da raiz do checkout:

```powershell
godot --headless --path godot --script tools/paleta_cenario_cartela.gd
godot --path godot --script tools/paleta_cenario_loja_preview.gd --rendering-method gl_compatibility
```

A [proposta para o interior da Linha & Papel](interior/README.md) usa os materiais desta fachada e a disposição da loja atual.
