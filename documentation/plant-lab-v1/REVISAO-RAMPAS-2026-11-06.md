# Rampas: leitura e encaixes

## Diagnóstico

Mapa real exportado da sessão e preservado em `cases/ramp-user-2026-11-06.json` (43 objetos). A sombra anterior de apenas 7,5% escondia a inclinação no mesmo material da trilha. Sem acabamento próprio nas extremidades externas, o encontro com o barranco parecia uma sobreposição. A inspeção do raster confirmou superfície contínua: nenhuma face atravessava as 11 peças de rampa desse mapa. Não houve necessidade de deslocar os objetos ou substituir a composição.

## Correção

- Sombra graduada de inclinação com transição nas duas bocas.
- Ombros estreitos de terra, luz e sombra lateral; pequenas marcas de erosão, sem degraus falsos.
- Coordenada contínua por grupo de rampas da mesma cota: duas peças adjacentes não ganham uma borda no meio.
- Mesmo cálculo no renderer do Studio e na geração dinâmica do Godot. A geometria e as cotas de apoio continuam sendo a fonte de navegação, seleção e oclusão.

## Evidências

Capturas `captures/ramp-before.png` e `ramp-after.png`: mesmo raster do mapa real, sem vegetação.
`ramp-user-after-studio.png`: editor com a composição preservada.
`ramp-user-joints-{terra,rocha,grama}.png`: bocas e laterais ampliadas em 2×. A captura de grama conserva Kael na posição original; a superfície completa também foi verificada sem personagem por amostragem do raster.

29 testes Node passaram, incluindo todas as posições de pixels das 11 peças de rampa do mapa real, travessia pelos centros e proximidades das bordas, e ausência de borda entre peças da mesma rampa.

`ramp-refinement-ui-check.mjs`: quatro percursos reais por teclado com Shift+W/S nos acessos de terra e rocha, ida e volta, cota 0 → 2 → 0, sem erros de página. Resultado em `captures/ramp-refinement-check.json`. Os acessos estreitos de grama foram conferidos pelo teste de movimento e raster; não por teclado.

Godot 4.7.2: importação, `check_autotile.gd` e `check_terrain.gd` passaram. O raster dinâmico corresponde às camadas PNG exportadas, incluindo as rampas. Não houve alteração na campanha nem publicação Git nesta revisão.
