# Biblioteca de mobilidade — revisão v1
32 peças para composição com a arquitetura moderna de Soulmonsters.

- `CATALOGO-32-ASSETS.png`: visão geral com miniaturas ampliadas/reduzidas por peça.
- `ESCALA-*.png`: quatro pranchas na escala de pixel preparada, com Kael a 84 px.
- `nativo/`: páginas 1280×720 renderizadas pelo Godot usando o Prop real.
- `preparacao-raster.json`: dimensões de origem, recorte alpha e medidas finais.
- `godot-import.log` e `godot-native.log`: evidência de importação/renderização.

A revisão cobre apresentação estática, transparência, silhueta e leitura da biblioteca. Não comprova condução, colisão ou navegação nos mapas. Os PNGs e cenas estão preparados; aplicação na campanha e revisão de cada base/pivô no terreno continuam necessárias.

Não foram executadas suítes de testes, conforme preferência do usuário. Importação e capturas são verificações visuais da preparação dos assets. Aprovação artística final pendente.


## Resultado da revisão
- 32 fontes e 32 PNGs RGBA preparados, 32 cenas reutilizáveis.
- Inspeção da prancha completa, comparativos 1:1 e 11 páginas nativas cobrindo todas as peças.
- Nenhum erro de recurso/script registrado nos logs de importação e captura.
- Ajustada a separação entre Kael e caminhão na galeria para evitar sobreposição na comparação.
- Escala final, textura, pivô e base constam por asset em kit.json; ajuste de colisão no mapa ainda pendente.
- Geometria de chão exibida nas capturas é somente uma referência da base proposta, não piso incorporado ao PNG.
