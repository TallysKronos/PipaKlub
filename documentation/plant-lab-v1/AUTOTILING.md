# Autotiling orgânico do Studio
Data: 2026-11-05.

## Entrega
Grade lógica32×32 preservada. O modo orgânico resolve os8 vizinhos em47 máscaras canônicas; diagonais só contam quando os dois lados existem. Grama/terra e pedra/terra têm3 variantes por máscara, com lookup e imagens em cache. Terra permanece a base das transições, inclusive entre pedra e grama.

As máscaras contêm centros, bordas, cantos convexos e côncavos, corredores e ilhas. A textura varia por coordenada estável. O atlas de parede mantém fase no espaço mundial, independentemente da célula.

Nos relevos, cada amostra do topo tem altura física. O recorte gera a face até o apoio seguinte, sem paredes entre cotas iguais; a mesma superfície atende seleção, altura de Kael, colisão e oclusão. Topo, face e sombra são imagens separadas com ordem compatível. Rampas têm passagem contínua e não recebem parede na boca.

## Usar
Em Propriedades > Terreno e relevo:
- Encaixes orgânicos liga/desliga o comportamento; desfazer restaura o estado.
- Ver47 encaixes abre a inspeção de materiais/variantes e permite baixar o PNG.
- Amostra cria uma composição de demonstração, preservando objetos e permitindo desfazer.
Pintar piso/relevo atualiza os encaixes ao redor. Não exige colocar bordas manualmente.

Os projetos antigos mantêm células, posições e cotas; o novo campo autotiling fica ativo por padrão e pode ser desligado para comparação.

## Godot
O ZIP inclui grass.png/stone.png (256×576), dirt.png, earth.png, rock.png, as três camadas montadas e os scripts que regeneram o terreno após edições nativas.
Inclui também autotile/terrain-set.tres: dois conjuntos de terrenos para TileMapLayer (grama/terra e pedra/terra),47 peças ×3 variantes, além das bases de terra. O volume dos barrancos é responsabilidade de terrain.gd/autotile.gd; não é uma altura embutida no TileSet de piso.
autotile/build_tileset.gd permite recompilar o recurso. O kit original está em art/environment/topdown-autotile-v1/.

## Conferência
-20 testes Node:47 máscaras, normalização dos256 casos,1024 vizinhanças com encaixe horizontal/vertical, apoio arredondado, extrusão, picking, barreiras, rampas, importação e exportação.
-14 cenários do Studio e13 regressões do editor, incluindo quatro resoluções.
-Teste de autotiling no navegador: ligar/desligar/desfazer, atlas, PNG baixado e juntas2× sem objetos.
-Teste nativo TileMapLayer: pintura de uma forma irregular e uma ilha em ambos os conjuntos de terrenos.
-Teste nativo de ida/volta de rampas e seleção.
-Comparação entre imagens geradas no Studio e regeneradas no Godot: mesmos pixels visíveis e alfa. Cores RGB em pixels de alfa zero são ignoradas porque o importador Godot expande cor nas bordas transparentes.
-Nenhum pixel das imagens de referência foi copiado ou redistribuído.

## Limites
Materiais originais procedurais de primeira versão, com acabamento pixel nativo. Não inclui água, paredes construídas, streaming ou colisões de objetos que excedam as regras existentes. O escopo continua sendo o editor local e o projeto de prévia; não altera a campanha.

