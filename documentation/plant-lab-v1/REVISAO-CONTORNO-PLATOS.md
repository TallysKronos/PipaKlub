# Contorno dos platôs

## Problema

As faces frontais tinham acabamento, mas os limites posteriores e laterais entre pisos com grama igual ficavam sem leitura de desnível.

## Implementação

O renderer consulta o campo de alturas já calculado para sustentação. Nos pixels do lado alto de uma descontinuidade (>0,22), pinta um contorno escuro de 1 px e uma faixa interna clara de 1 px. A cor acompanha o material efetivamente visível (grama, terra ou pedra), independentemente da altura nominal da célula. Os dois lados de pisos na mesma altura não recebem uma junta.

As rampas mantêm seu acabamento próprio. O gradiente suave e as bocas não recebem contorno transversal. Não altera colisão, apoio, picking, objetos ou composição. O mesmo cálculo está no renderer dinâmico do Godot; a exportação inclui a camada já renderizada.

## Validação

- 34 testes Node aprovados: limites norte/sul/leste/oeste, faixa interna, pisos contínuos, bocas livres, regressões de pintura, movimento e paredes altas.
- Capturas `captures/relief-rim-before.png` e `relief-rim-after.png` do mesmo mapa sem objetos.
- `relief-rim-ui-check.mjs`: captura do editor e detalhe 2× sem vegetação, sem erros de página. Resultado inspecionado em `captures/relief-rim-detail.png`.
- Godot 4.7.2 importou o projeto e passou na comparação entre raster dinâmico e camadas PNG exportadas.

Teste visual feito em sessão isolada; recarregar a aba do usuário carrega o novo acabamento sem reconstruir o mapa. Sem publicação Git nesta revisão.
