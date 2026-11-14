# Revisão de arte 2D mangá — Kronasta

Revisão completa de Morro do Sol, Cavernas de Cristal e Planícies: 23 texturas e 17 peças. Os cinco primeiros fontes do Morro ficam na raiz desta pasta, com prompts próprios. Os demais fontes e seus prompts ficam na subpasta de cada kit. A ferramenta integrada de geração de imagem forneceu a arte original; as referências de acabamento vieram do Bairro Inicial, de Centro Studio e dos estudos aprovados. Nenhum fonte de outro jogo foi copiado.

- Morro: cor chapada, linhas seletivas de tinta, cimento e terra com menos ruído, telhas e objetos urbanos com silhuetas distintas. O ponto elétrico preserva o ID e é representado por poste, caixa fechada e conduítes.
- Cavernas: ardósia violeta, água fria, paredes facetadas e cristais desenhados em planos, com brilho reservado sobretudo às peças.
- Planícies: verdes sálvia, flores espaçadas, estratos de terra dourada e objetos de campo com contorno de tinta.

As texturas usam costura de mínima diferença no trecho sobreposto, quantização sem dithering e igualdade pixel a pixel das bordas opostas. Os sprites mantêm a base isométrica 2:1; a escada reprojeta a pintura do estudo sobre oito espelhos de 8 px e a ponte tem tabuleiro alinhado ao losango de 1×1. A validação de halo é uma checagem objetiva de pixels claros nas bordas, acompanhada de inspeção das pranchas.

Reproduzir na raiz do repositório, com Python e Pillow:

```sh
python tools/normalizar-piloto-manga.py
python tools/normalizar-kits-manga.py morro-v2
python tools/normalizar-kits-manga.py cavernas-cristal-v1
python tools/normalizar-kits-manga.py planicies-v1
python tools/validar-kit-tiles.py morro-v2 --prancha
python tools/validar-kit-tiles.py cavernas-cristal-v1 --prancha
python tools/validar-kit-tiles.py planicies-v1 --prancha
```

As três pranchas e o log ficam na pasta de QA acima. Ainda vale revisar no jogo as fiadas de tijolo e telha em zoom fracionário, os veios de cristal sob a luz do bioma e a leitura da água em relação ao piso. A revisão foi estática, sem alterar mapas, código de jogo ou kits externos.
