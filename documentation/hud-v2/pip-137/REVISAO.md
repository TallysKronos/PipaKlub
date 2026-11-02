# PIP-137 · Transições e sons

Implementação local da direção B, Mural de Kronasta. Sem push, merge ou alteração no Linear.

Código auditado: commit `736b3751`; resumo executável em `suites.json`.

## Decisão

A passagem entre cenas usa uma cortina de tinta com pipa em marca d’água e borda de papel recortado. Nas cargas pesadas, uma etiqueta no canto inferior direito mostra pipa e “Carregando…”. O indicador acompanha o estado real; não inventa percentual. Reutiliza o papel ilustrado e as fontes do Mural, sem criar nova imagem raster nem copiar referências externas.

O fechamento dura 140 ms e a saída pela esquerda 320 ms. Revelações curtas duram 280 ms. Com movimento reduzido, a pipa fica estática e a cortina usa fade de 80/100 ms, sem deslocamento. Não há tempo mínimo artificial de carregamento: a cidade e o parque continuam aguardando sua inicialização e o primeiro frame antes da saída.

O bloqueio de input permanece durante a carga; ao remover a cortina, o foco anterior volta caso seu controle ainda exista. A camada de revelação curta se remove ao terminar. Retornos, pausas e batalha mantêm os seus fluxos e dados existentes.

## Sons

Reutilização do catálogo autoral `godot/assets/audio/sfx-v1/catalog.json`; nenhum WAV foi alterado. A galeria permite ouvir amostras isoladas.

| Ação | Evento / tratamento |
| --- | --- |
| Navegar, confirmar, voltar | `ui.focus`, `ui.confirm`, `ui.cancel`, mantidos |
| Troca de cena | `world.transition`, agora disparado pela apresentação, no bus UI a −5 dB; sobrevive à limpeza da cena e não se repete em menos de 650 ms |
| Gravar checkpoint | Não dispara som de viagem por si só |
| Recompensas simultâneas | Um jingle por lote no mesmo frame; prioridade nível, missão, tutorial, objetivo, descoberta, item, XP, moedas |
| Falha ao salvar | Cancela comemoração ainda pendente; mantém `progress.save_error` |

Os buses, o limiter existente, os volumes do jogador e as regras de silêncio ao perder foco foram preservados. Viagem respeita o controle de volume de UI, inclusive zero, sem reabrir o volume da música. A alteração não concede XP, dinheiro ou itens e não altera a gravação de recompensas.

## Evidências

- `mural_transition_checks.gd`: 47 verificações de gate, remoção de camada, foco, input, áudio e layout, sem falhas.
- `result_settlement_checks.gd`: 8 verificações de regressão da recompensa persistida, sem falhas.
- 24 capturas nativas: loading, saída parcial e fade reduzido; 1280×720, 1920×1080, 1024×768, 1280×800; texto 100/150%.
- 24 medições nativas de glifos dentro da área segura, sem falhas; etiqueta a 24 px da borda. A primeira execução detectou altura interna insuficiente; corrigida antes das capturas finais.
- Galeria gerada por `tools/build_mural_transition_gallery.py`, que verifica as dimensões de cada PNG. Verde atrás da saída parcial é fundo de inspeção, não um mapa do jogo.

Limites: teclado, mouse e controle simulados. Não houve playtest completo de campanha nem ensaio auditivo em alto-falantes/fones; as verificações de áudio comprovam roteamento, prioridade e silêncio, não qualidade perceptual da mixagem. O ambiente emite avisos de acesso a `user://logs`/shader cache; o teste de regressão também conserva avisos antigos de importação de props. Não são falhas funcionais detectadas nesta etapa.

Próxima etapa: PIP-138, auditoria consolidada de acessibilidade.
