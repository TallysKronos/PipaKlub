# Prévias e controles contextuais

Primeira entrega das prioridades ST-03 e ST-01 do mapeamento.

## Controles

- Piso e paredes exibem o tamanho do pincel; preencher usa o material escolhido.
- Relevo exibe tamanho, cota e ação de nivelar/subir/baixar.
- Cachoeiras exibem largura de 32, 64 ou 96 px, sincronizada com a biblioteca.
- Cota e ação de altura ficam ocultas durante pintura de pisos, paredes e cachoeiras.
- Propriedades de objetos não ocupam o painel durante essas ferramentas de superfície.
- Trocar entre bibliotecas de paredes/cachoeiras e terreno limpa buscas incompatíveis; miniaturas e seletores preservam os materiais selecionados.

## Prévia

Passe o mouse sobre o mapa antes de clicar. Piso, preenchimento e parede mostram o material aplicado na geometria visível, com um contorno fino e uma mensagem de estado. A indicação inclui as transições que mudarão em tiles vizinhos.

O renderer da prévia reutiliza os buffers de sustentação e os mesmos samplers de superfície/face do renderer da pintura. Não recalcula toda a geometria a cada movimento. O cache muda quando o ponto, o material, o pincel ou o mapa mudam.

A prévia não altera o documento, o salvamento ou o histórico. Nas paredes, o alvo é a lateral visível. Nas cachoeiras, a indicação mostra encaixe válido ou explica por que falta uma face com água superior/inferior. O botão de olho na barra superior liga/desliga a prévia.

### Segunda entrega: altura e rampas

H agora simula o volume ao subir, baixar ou nivelar. U mostra a rampa antes de aplicar; Shift mostra sua remoção. O resultado inclui o topo, as faces expostas, a área que reaparece ao baixar o terreno e as sombras de contato. É uma prévia do terreno; objetos existentes permanecem como referência até a aplicação.

O cálculo roda em um Worker. Enquanto calcula, a interface informa o estado; movimentos mais recentes substituem solicitações pendentes e resultados antigos não substituem a prévia atual. A aplicação e a prévia usam `geometryEdit`, preservando o mesmo conjunto de alterações.

Rampas inválidas informam se falta espaço, se os patamares não são planos ou se a cota ao norte/sul está incorreta. Alterações de altura avisam quando removerão rampas que perderiam apoio. Um gesto de subir/baixar não reaplica a ação em células já visitadas.

A cota de destino aparece somente ao nivelar, pois subir/baixar usam variação relativa. A ferramenta Rampa mostra a orientação atual e a instrução de Shift. Os pontos ST-02 e ST-04 em diante permanecem propostas.

## Verificação

- 60 testes passaram, incluindo comparação dos pixels da prévia com a pintura efetiva em pisos, rampas, curvas e transições.
- Teste de navegador verifica ausência de mutação no hover, aplicar/desfazer, alvo inválido, largura da cachoeira e botão de prévia.
- Capturas em 1920×1080, 1440×900, 1280×720 e 844×390.
- Comparação do raster exportado com Godot passou.

Atualização da segunda entrega: 64 testes passaram. `geometry-preview-ui-check.mjs` verifica hover sem alteração, aplicação equivalente à prévia, desfazer/refazer, criação/remoção de rampa, razões de invalidez e descarte de resultados antigos. Capturas em `captures/preview-height-volume.png`, `captures/preview-ramp-volume.png`, `captures/preview-ramp-remove.png` e `captures/preview-ramp-invalid.png`.

Capturas: `captures/preview-floor.png`, `captures/preview-wall.png`, `captures/preview-waterfall-valid.png`, `captures/preview-waterfall-invalid.png` e `captures/context-*.png`.
