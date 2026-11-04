# Biblioteca de arquitetura moderna — revisão v1

24 assets: seis casas, seis estabelecimentos, seis prédios empresariais e seis laboratórios.

- [Catálogo completo](CATALOGO-24-CONSTRUCOES.png).
- Escala nativa com Kael: [casas](ESCALA-casas.png), [comércios](ESCALA-comercios.png), [empresas](ESCALA-empresariais.png), [laboratórios](ESCALA-laboratorios.png).
- [Prancha da renderização no Godot](AUDITORIA-NATIVA.png); oito imagens 1280×720 em `nativo/`.
- Dimensões/alpha/normalização em `preparacao-raster.json`; logs de importação e renderização nesta pasta.
- Fontes, PNGs, manifesto e projeto Iso Studio: `art/overworld/kits/urbano/`.
- Instruções e inventário completos: `art/overworld/kits/urbano/README.md`.

Revisão: família visual consistente e silhuetas distintas, fontes transparentes, recortes inteiros nos oito enquadramentos nativos. O catálogo usa escalas diferentes para caber; consultar as quatro pranchas ESCALA para comparar com Kael. Nenhuma pintura foi usada como fundo de mapa.

Esta entrega é uma biblioteca preparada. A adaptação a cada lote, colisão de anexos, altura de porta e oclusão precisam da revisão no mapa de destino. Não há integração da campanha, interiores, teste de percurso ou publicação. Nenhuma suíte de testes executada.
