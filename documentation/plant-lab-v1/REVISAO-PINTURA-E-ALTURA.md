# Pintura de rampas e faces com vários andares

Correção de 06/11/2026, após a revisão visual do usuário.

## Causas e solução

1. O recorte orgânico da grama adjacente à rampa expunha a textura de terra para fora da largura física da passagem. O autotile agora mantém a grama íntegra nas laterais da rampa. As transições de trilhas comuns continuam orgânicas.
2. Pincéis 2×2 até 4×4 podiam pintar fora de rampas estreitas. Quando o ponto inicial é uma rampa, pintura, prévia do pincel e preenchimento ficam restritos às peças da rampa na mesma fileira/cota. Pintar diretamente fora dela continua permitido.
3. A textura de terra de paredes repetia duas faixas horizontais a cada 16 px. Em barrancos altos isso parecia uma junta entre andares. As faixas foram substituídas por manchas e veios curtos descontínuos. O lábio de grama continua somente no topo da face; patamares reais continuam existindo.

## Verificação

- 32 testes Node aprovados, incluindo pincéis 1–4, preenchimento, contenção da terra, trilhas comuns, parede de 48 px com um único lábio e movimento.
- `paint-height-ui-check.mjs`: clique real no editor, pincel 4×4 em rampa de 1 célula; somente essa célula mudou. Nenhum erro de página.
- Capturas ampliadas inspecionadas sem objetos: `captures/paint-ramp-detail-after.png` e `captures/height-wall-detail-after.png`, com base completa do barranco.
- Antes/depois do mesmo caso: `captures/paint-height-before.png` e `captures/paint-height-after.png`.
- Godot: importação, comparação pixel a pixel entre raster exportado e dinâmico, e testes de terreno passaram. Kit de texturas regenerado.

A conexão de controle com a aba do usuário estava indisponível nesta rodada; a validação de interface usou uma sessão isolada do mesmo editor local. Não alterou a composição salva do usuário. Recarregar a aba carrega a correção.
