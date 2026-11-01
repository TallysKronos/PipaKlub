# Piloto de continuidade do piso — Clareira

Teste local de 29/10/2026, seguindo o [estudo de Dofus](../dofus-tiles-study/README.md). Aprovação visual ainda pendente.

## Escopo

Retângulo lógico de 15×12 células, começando em (23,33), na área da praça com banco e ligação às pontes. Apenas superfícies de nível zero, sem rampas, participam do piloto. O contorno, as cores e a praça mudam nesse trecho; os arredores conservam o desenho anterior. A extremidade do experimento se mistura gradualmente ao original para não criar uma emenda retangular de teste.

O protótipo é uma vista opt-in em `godot/tools/`. O renderer usado pela campanha, os mapas fonte, as células compiladas, as alturas, as colisões, os eventos e os saves não foram alterados.

## O que foi experimentado

- Fronteiras extraídas de regiões conectadas de terra/piso, com tratamento de anéis e concavidades.
- Simplificação limitada a 0,65 célula, seguida de duas passagens suaves no contorno completo. A forma não é construída a partir de um arco em cada canto do tile.
- Praça com a pegada construída exata; a terra funciona como fundo contínuo nos seus acessos.
- Pinturas existentes reutilizadas com menor contraste sobre uma base clara: sem gerar uma família nova de assets antes de aprovar a direção.
- Máscara lógica a 32 amostras por célula, filtrada linearmente. Os mesmos dados de máscara são amostrados por todas as células do trecho, incluindo o encontro com o mato.

Há duas variáveis nesta primeira amostra: contorno e contraste. A captura de cores chapadas permite examinar a forma sem a textura. Se o contorno for aprovado e a pintura ainda precisar de trabalho, podemos refinar uma coisa de cada vez.

## Evidência

Seis capturas reais OpenGL no Godot 4.7.2, 1280×720, mesma câmera nas comparações. As capturas foram abertas e inspecionadas. Não são imagens de conceito geradas.

- [Antes](01-antes.png)
- [Antes sem objetos](02-antes-sem-objetos.png)
- [Depois](03-depois.png)
- [Depois sem objetos](04-depois-sem-objetos.png)
- [Cores chapadas](05-cores-chapadas.png)
- [Juntas ampliadas](06-juntas-ampliadas.png)
- [Comparação com controle deslizante](index.html)

O capturador comparou a serialização completa dos dados de mapa antes e depois: `mapDataUnchanged: true`. O relatório está em `report.json`. Esse teste confirma a não alteração da fonte lógica; não é uma nova validação de toda a jogabilidade da campanha.

## Prévia interativa

Na raiz do checkout, usando o Godot instalado:

```powershell
& 'C:/Users/user/produto/pipa-club/tmp/godot-4.7.2/runtime/Godot_v4.7.2-stable_win64_console.exe' --path godot --script res://tools/terrain_pilot_capture.gd -- --live
```

Depois das capturas, a janela permanece aberta no trecho de teste. WASD/setas ou clique usam o controlador da prévia; F6 alterna antes/depois preservando a posição do personagem. Não inicia campanha nem grava progresso.

## Limites antes de ampliar

O contorno natural ainda precisa da avaliação estética do usuário: o objetivo é tirar a frequência de gominhos sem deixar a borda lisa demais. Não foram produzidos novos tufos, ladrilhos ou barrancos. Rampas, altura e água continuam na implementação existente. O piloto usa um nível e uma área pequenos; expansão para vários níveis, junções complexas e mapas inteiros exige revisar esses casos antes de integrar à campanha.
