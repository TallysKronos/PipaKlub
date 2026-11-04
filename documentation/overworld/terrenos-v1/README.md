# Revisão — pisos e paredes modulares

24 pisos × 55 recortes/variantes + 12 paredes × 16 peças = 1.512 peças derivadas de 36 materiais gerados.

## Pranchas

- `CATALOGO-24-PISOS.png`: pisos em montagens com cantos e vazados.
- `CATALOGO-12-PAREDES.png`: cantos internos, externos e terminações.
- `GUIA-47-ENCAIXES.png`: os 47 estados de terreno, identificados por máscara.
- `FONTES-36-MATERIAIS.png`: fontes finais; não confundir com os tiles na escala de jogo.
- `AUDITORIA-NATIVA.png` e `nativo/`: todas as 36 páginas Godot 1280×720.
- `*-repeticao-8x8.png`: repetição UV e variação dos centros.
- `*-encaixes.png`: composição isométrica por máscaras.

## Evidências e limites

`geometria-encaixes.json`: 47 estados canônicos e 169 pares válidos de vizinhança, sem divergência nas portas de borda. `preparacao.json`: os centros têm 1.024 pixels opacos por losango 64×32 e lados opostos da textura base coincidem. Isso não equivale a aprovação estética ou a validação de um mapa inteiro.

`godot-native.log`: 24 TileSets exportados e 36 páginas renderizadas. A galeria usa `set_cells_terrain_connect` do Godot para formar recortes reais em L e vazados; não é só uma montagem de PNGs previamente escolhidos. Paredes foram revistas nas duas faces, em trechos longos, cantos internos/externos e terminações.

Fontes com aparência incorreta foram refeitas antes da multiplicação em tiles. Juntas estruturadas mantêm sua fase entre alternativas; centros e bordas do material não recebem contorno decorativo de tile. As paredes mantêm fases consecutivas e tampas separadas dos segmentos intermediários.

Sem suíte de testes, conforme preferência do usuário. A entrega está preparada e revista na galeria, sem distribuição nos mapas, alterações de colisão ou publicação. Ver instruções e fontes de pesquisa em `art/overworld/kits/terrenos-v1/README.md`.
