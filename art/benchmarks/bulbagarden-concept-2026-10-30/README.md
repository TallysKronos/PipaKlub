# Pesquisa Bulbagarden · 30/10/2026

Abrir `index.html` para o estudo e a galeria offline. Fonte de texto: `ESTUDO.md`. Observações por imagem: `FICHAS.md` e `case-notes.json`.

Cobertura: quatro páginas da categoria principal (602 arquivos), todas as paginações das 15 subcategorias diretas e união deduplicada de 725 arquivos. Há 48 pranchas inspecionadas visualmente, com oito originais ampliados. O índice completo não equivale a análise individual de todas as imagens.

`references/` contém os 48 originais de pesquisa, sem alteração. `reference-sources.json` registra URLs de arquivo e mídia, dimensões, tamanho e SHA-256. As artes são referências de terceiros, fora do runtime; não são personagens/assets licenciados para reutilização em Soulmonsters. A afirmação de fair use nas páginas de origem é metadado do arquivo, não uma licença concedida ao projeto. Nenhuma autoria individual foi presumida; anotações japonesas não foram traduzidas.

`collect_index.py` registra a listagem principal e subcategorias; `complete_catalogue.py` completa a paginação e a união; `inspect_references.py` seleciona referências e reaproveita arquivos disponíveis; `build_diagnostic_sheets.py` monta prévias de inspeção sem redesenhar fontes; `build_report.py` preserva originais e gera a galeria e as fichas. Os auxiliares de imagem dependem de Pillow. Scripts de consulta fazem apenas leitura do site.

A síntese está ligada ao documento de direção e à referência local de produção de assets. Não houve criação de um novo Zuric, alteração do jogo ou publicação nesta pesquisa. As três famílias de exploração descritas no estudo são propostas para a etapa seguinte.
