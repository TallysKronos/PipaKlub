# Jardim de Kronasta — projeto separado para Godot 4

Extraia o ZIP inteiro, abra `project.godot` no Godot e execute `main.tscn` (F6) ou o projeto (F5 no editor). Os PNGs e o layout estão incluídos; não depende da campanha.

Na janela da bancada: 1–6 seleciona planta; clique planta. V seleciona e arrasta. E apaga. P seleciona/cicla piso; clique/arraste pinta. G mostra grade. Del exclui. F espelha a seleção. R restaura o JSON original da exportação.

Tab alterna teste/edição. No teste, WASD/setas move Kael e Shift corre. Roda muda zoom inteiro. A folhagem ordena pela raiz. Barrancos bloqueiam; rampas dão acesso. A folhagem sem marcação de colisão não bloqueia e Kael usa poses estáticas.

F5 dentro da janela de jogo grava uma cópia em `user://jardim-kronasta.json`, na pasta de usuário separada `SoulmonstersPlantLab`. Esse arquivo é reaberto na próxima execução. O layout original em `res://layout.json` permanece intacto. A bancada do navegador possui desfazer e exporta outro ZIP com qualquer mudança.

O piso é uma base procedural provisória, não um tileset final. A montagem e a escala usam pixels nativos, plantas ancoradas em(32,52) e Kael em(40,65). Filtragem nearest. Este projeto é uma prévia de arte e edição, sem alteração de cenas, saves ou regras da campanha.

Relevo: H seleciona/cicla cota de 1 a 12; L pinta chão 0; T alterna face terra/rocha; U cria rampa subindo ao norte (Shift+clique remove). A rampa exige patamar 1 nível acima ao norte e mesmo nível ao sul. G exibe a grade projetada. Cotas e rampas seguem no layout salvo/exportado.

O revela objetos atrás do terreno; [ e ] escolhem a cota de apoio (0–12) para plantar no chão encoberto. Testar restaura a oclusão normal automaticamente. A revelação só afeta o editor.

O Soulmonsters Studio exporta `layer` (Vegetação/Objetos) e `collidable` por peça. Peças marcadas bloqueiam a aproximação de Kael em um raio de12px, respeitando a altura de apoio. A prévia nativa preserva esses campos ao salvar. Visibilidade e bloqueio de camadas são preferências do editor web.

Autotiling: o mesmo contorno recorta topo, gera faces e sombras e define a altura física. O renderer regenera o terreno se o piso/relevo mudar. `autotile/terrain-set.tres` fornece terrenos automáticos para TileMapLayer (conjunto0 grama/terra, conjunto1 pedra/terra). Esse recurso é de piso; o volume dos barrancos é gerado pelos scripts do projeto. `autotile/build_tileset.gd` recompila o TileSet.

Revisão2: geometria em campo dual independente da textura, patamares de rampa inteiros e material da face herdado do suporte. Texturas de parede64×64. O exemplo reconstruído está em layout.json; R recupera o projeto exportado se uma cópia antiga da bancada tiver sido salva em user://.
