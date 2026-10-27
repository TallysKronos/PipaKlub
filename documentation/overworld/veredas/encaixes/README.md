# Correção dos encaixes destacados pelo proprietário

As imagens enviadas apontavam uma saliência quadrada no encontro superior da rampa e uma lateral que parecia atravessada por uma coluna com triângulos de gramado entre as faces.

## Causas e correções

- Quatro pequenas saliências de bosque elevado junto às bocas foram rebaixadas. O ombro bloqueado do pátio foi unido numa faixa de sustentação, em vez de uma sequência de colunas. Somente células de bosque já bloqueadas mudaram de altura; caminhos, peças, NPCs e recompensas mantêm posições.
- Laterais estavam na camada do piso, atrás de todas as paredes. Agora participam da ordenação de profundidade do terreno, com geometria preservada ao deslocar a chave de ordenação.
- Faces posteriores faltavam nas bordas côncavas. Os mapas com rampas longas passam a fechar o volume nesses lados. A posição dos topos e das paredes determina a oclusão; as faces posteriores não recebem um contorno brilhante atravessando o gramado.
- O revestimento da lateral era esticado em cada trecho. Agora usa coordenadas de mundo e altura, com a mesma fase, escala e luz dos barrancos adjacentes.

## Evidências e limites

`antes/` preserva os detalhes entregues na revisão anterior. `depois/` contém os enquadramentos atualizados, incluindo capturas sem personagens encobrindo as juntas. A revisão foi feita no renderer gráfico do Godot 4.7.2 em 1280×720. `native-render.log` registra a execução sem erros. Não houve suíte de testes nem percurso interativo completo.

O procedimento de revisão ampliada foi registrado no `AGENTS.md` e em `documentation/continuidade-terreno-isometrico.md` para os próximos layouts. Não houve push ou publicação.
