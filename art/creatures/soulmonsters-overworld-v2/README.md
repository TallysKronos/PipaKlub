# Overworld v2 — 194 formas

As 194 folhas do catálogo anterior foram convertidas/reconstruídas no formato de 224×112 px, com duas células de 112×112. A primeira mostra frente SW; a segunda, costas NW. O apoio é (56,100). Os PNGs estão integrados ao caminho normal de companheiro equipado no Godot.

- [Galeria comparativa das 194 formas](index.html)
- [Manifesto com origem, estágio e hash](manifest.json)
- [Validação das 194 folhas](validacao.json)
- [Revisão visual e limitações](REVISAO.md)
- [Abrir a comparação no Godot](comparar.ps1)

A cena de comparação usa o mapa real e um save temporário. Page Up/Page Down percorrem os 194 modelos. As teclas 1, 2 e 3 escolhem a arte anterior, a nova ou ambas. F4 alterna frente/costas. F2 alterna zoom 1/1,15. F3 alterna CRT. F5 alterna a arte anterior entre escala 1/1,25.

A galeria web mostra a escala nativa e oferece ampliação para inspeção. As nove pranchas também estão disponíveis como prancha-01.png a prancha-09.png.

## Altura e leitura

| Porte do estudo | Altura visível |
| --- | --- |
| Bebê | 41 px |
| Criança | 55 px |
| Jovem | 70 px |
| Adulto | 84 px |

A altura é a mesma entre as duas vistas e o último pixel opaco está em y99. Cada criatura usa até 20 cores, com alpha binário e filtro Nearest. A folha nova dispensa a ampliação adicional de 25% aplicada ao sprite antigo na comparação.

Quando o cânone não define estágio, a classificação de porte é uma decisão visual deste estudo, registrada no elenco. Ela não altera regras de evolução, obtenção ou campanha.

## Produção

191 formas partiram dos originais de geração, usando Xprite 0.1.2 em Convert com TwoStage, como no teste aprovado do Azulfazo. A conversão recebe as dimensões nativas finais, calculadas para preservar a altura. A paleta é compartilhada pelas duas vistas. A seleção da fonte e as correções de orientação preservam as folhas e os concepts existentes.

Lince de Cerco bebê, Najarcal bebê e Rasacopa tiveram reconstrução na grade nativa. Glacerol recebeu limpeza de fundo e halo no Aseprite. Riscavela recebeu remoção localizada de dois resíduos. O Azulfazo mantém o acabamento aprovado do piloto. As outras folhas passaram por conversão técnica, inspeção visual e exportação editável. A existência de um arquivo Aseprite não significa que cada pixel das 191 conversões tenha sido redesenhado manualmente.

Os originais e folhas anteriores continuam disponíveis. Os PNGs de runtime ficam em godot/assets/campaign/overworld-v2. Os arquivos deste diretório são as fontes de arte e revisão. O motor utiliza o catálogo novo por ID e mantém os aliases dos saves anteriores.

## Verificação

A validação registra 194 folhas, 388 vistas, paleta, transparência, tamanho, apoio e correspondência do PNG com o runtime. A auditoria do Aseprite confirmou os 194 arquivos editáveis e seus quadros, sem divergências de pixel.

A suíte de companheiros do Godot passou em 518 verificações. Conferimos também o renderer gráfico com oito amostras, incluindo crianças, cavaleiros, os bebês reconstruídos e o Glacerol. As capturas ficam neste diretório com nomes in-game-<id>-sw.png e in-game-<id>-nw.png, além das variações de escala e CRT.

O mapa desta branch ainda emite os avisos anteriores sobre os NPCs Cauê e Celina. A ausência de falhas na suíte de companheiros não encerra esses problemas anteriores do mapa.

## Reconstruir o lote

Os auxiliares estão em scripts/overworld-xprite-v2. O elenco permanente é roster.json. A preparação usa Pillow para ler os PNGs, recortar RGBA e medir as poses. A conversão usa a biblioteca Xprite instalada isoladamente em tmp/xprite-azulfazo.

Execute a partir da raiz do checkout, com Python/Pillow, Node e Aseprite disponíveis.

1. Instale a dependência de teste com npm install --prefix tmp/xprite-azulfazo --ignore-scripts --no-audit --no-fund --package-lock=false @xprite/pixelate@0.1.2.
2. Execute prepare.py e convert.mjs.
3. Execute preview.py para montar as pranchas de inspeção e a lista de exportação.
4. Rode export.lua pelo Aseprite batch, com parâmetros root=<pasta desta coleção> e scratch=<repo>/tmp/overworld-xprite-v2. Ele preserva as fontes que receberam acabamento manual individual.
5. Execute publish.py e validate.py. Rode audit.lua pelo Aseprite para conferir a correspondência entre PNG e editável.
6. Importe os assets e execute a cena de comparação e a suíte de companheiros no Godot.

As correções individuais estão conservadas nos arquivos Aseprite entregues. Uma conversão nova deve ser comparada com esses arquivos antes de substituir um acabamento aprovado.

O próximo refinamento pode partir da galeria ou da comparação no jogo. Priorize uma folha concreta por vez e registre o ID e a vista observada, para manter a revisão verificável.
