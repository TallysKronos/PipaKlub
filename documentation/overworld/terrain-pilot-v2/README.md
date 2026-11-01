# Piloto de pisos — segunda revisão

Refinamento de 29/10/2026 após a avaliação positiva do primeiro piloto. Continua isolado da campanha.

## Mudanças

- Área ampliada para 18×23 células, começando em (20,22), incluindo a praça, a rampa próxima e as duas extremidades das pontes.
- Pequenas irregularidades esparsas no contorno contínuo da terra, com amplitude máxima de 0,035 célula. A borda não recebe uma ondulação regular por tile.
- Superfícies de nível zero e um, incluindo a inclinação da rampa, usam a altura real dos cantos. A textura acompanha as coordenadas lógicas do terreno, mantendo sua continuidade na mudança de altura.
- Acesso da rampa e terra adjacente às pontes preservados na máscara para evitar recortes de grama atravessando a passagem.
- Praça mantém borda construída; pinturas existentes permanecem com contraste reduzido.

## Verificação

Treze capturas nativas de 1280×720 estão em [index.html](index.html), com comparações na mesma câmera. Foram inspecionados o piso, a rampa em cores chapadas e os encontros com as pontes sem objetos cobrindo as juntas.

O [relatório](report.json) confirma que os dados completos do mapa não mudaram e que F6 preserva a posição do personagem. Isso não substitui um teste completo da campanha.

O renderer da campanha, os mapas fonte, as colisões, os eventos e os saves não foram alterados. Água, pontes e faces dos barrancos continuam com a implementação existente. Os arredores fora do retângulo experimental conservam suas bordas antigas; há mistura gradual na extremidade do teste.

## Prévia no Godot

Na raiz do checkout:

```powershell
& 'C:/Users/user/produto/pipa-club/tmp/godot-4.7.2/runtime/Godot_v4.7.2-stable_win64_console.exe' --path godot --script res://tools/terrain_pilot_capture.gd -- --live
```

Depois das capturas, F6 alterna antes/depois. A prévia não grava campanha. O [primeiro piloto](../terrain-pilot-v1/index.html) permanece disponível para comparação. A integração em mapas completos fica para depois da avaliação desta expansão.
