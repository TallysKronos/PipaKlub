# Kit interno do laboratório do Sr. Assis

O kit recorta o [quadro-chave aprovado](../quadro-chave.png) em 22 peças, na escala original de 720 × 512 px. Há peças distintas para as paredes, as duas abóbadas, a torre, a entrada, a recepção, o aparelho de losango sobre a bancada, a maleta com sensor e o estoque público.

- [Prancha das 22 peças](prancha-pecas.png) e [mapa dos recortes](mapa-de-recortes.png).
- [Kit do Aseprite](kit.aseprite), com uma camada por peça.
- [Atlas PNG](atlas.png) com margem transparente de 2 px e [manifesto](manifesto.json) com retângulos de origem e do atlas, pivôs e ordem de desenho. Os PNGs separados ficam em `pecas/`.
- [Remontagem no Godot](remontagem-godot.png) e [verificação](verificacao.json).

## Montagem

Use filtro nearest, escala 1× e os pivôs do manifesto. O canto de cada recorte no canvas é `position_px - pivot_px`. As coordenadas de apoio e as pegadas em células vêm da [planta ampliada](../planta.png), com 13 × 7,6 células. A grade usa 64 × 32 px e a entrada está no eixo u = 6,30. Os pivôs em pixels remontam a imagem e as pegadas servem de referência para calibrar colisões na cena.

O kit cobre a montagem fixa do quadro-chave. Os recortes carregam os pixels visíveis e podem incluir trechos contíguos de piso ou parede. Piso e paredes precisam de pintura adicional para uma disposição diferente de móveis. Para a ordem em profundidade na cena, agrupe aparelho e monitores com a bancada de pesquisa e agrupe maleta e sensor com a mesa. O acesso público ao estoque, a porta, a oclusão com Kael e as colisões serão conferidos na integração em `professor-home`.

## Reprodução e conferência

```powershell
godot --headless --path godot --script tools/laboratorio_v2_kit_interior.gd
godot --path godot --script tools/laboratorio_v2_kit_preview.gd --rendering-method gl_compatibility -- --interior
```

O primeiro comando gera os cortes e o atlas. O segundo compara cada região do atlas com seu PNG e recria o quadro pelos pivôs. Em seguida compara a captura de 22 Sprite2D com o quadro original no mesmo fundo e em zoom 1. O PNG exportado do Aseprite também passa pela comparação com o quadro original. As verificações cobrem os 210.684 pixels opacos e a margem transparente do atlas. A conferência da fachada regenerou seu atlas com o mesmo SHA-256 e remontou suas 24 peças no Godot.

A cena jogável e as capturas estão na [entrega de integração](../integracao/README.md).
