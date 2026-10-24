# Auditoria da batalha — 24/10/2026

## Problemas encontrados e corrigidos

1. **Retratos e miniaturas por cima de textos:** `.arena canvas` tornava todo Canvas da arena absoluto e ocupava os espaços de texto dos novos cards. A regra global agora é restrita a `#sky`, inclusive cursor e tremor. Os Canvas da HUD ficam no fluxo de seus cards.
2. **Carretel sobre a face:** a altura do personagem colocava a origem real da linha junto à cabeça do sprite chibi. O apoio foi ajustado em relação a `eng.line(p).a`, preservando a origem do segmento de combate.
3. **Informação duplicada:** os rótulos de nome e barras do desenho antigo permaneciam sobre as criaturas junto com a nova HUD. No duelo de dois participantes, essa duplicação foi retirada; outros modos mantêm a apresentação anterior.
4. **Rodada fora da moldura:** estilos antigos de posição absoluta ainda deslocavam `roundInfo`. O contador e o texto da rodada agora participam do fluxo interno da placa.
5. **Seletor opcional do balão:** o novo balão do treino não usa botão de voltar, mas a decoração consultava o seletor ausente. Foram adicionadas guardas para seletores opcionais. O problema foi encontrado nos testes de integração de comandos da página.

## Verificação executada

- Navegador local em **1131 × 884**, duelo contra Zeca, usando os controles reais.
- Ataque e movimentação por mouse: cruzamento válido, dano recebido e causado; HUD mostrou linha do jogador em 68%, rival em 56%, energia em 56% após o trecho exercitado.
- Habilidade por teclado acionada durante combate.
- Esquiva e rebicada pelos botões: consumo de energia e classes de recarga confirmados após cada comando.
- Pausa com confirmação do servidor; retomada/saída e retorno ao mapa pelo fluxo normal. Resultado de derrota foi salvo no banco local e preservou a vitória anterior.
- Medição DOM: **sem sobreposição entre retrato/miniatura e bloco de texto nos quatro cards** da nova HUD.
- Nenhum erro de console capturado no trecho de batalha revisado.
- `node --test combat.test.mjs normal-line-skills.test.mjs`: **29 passaram, 0 falharam**, após a correção do seletor opcional. Não foi rodada a suíte completa.
- Compilação de Worker e Pages concluída.

## Evidência e limites

Imagem: `art/ui-reviews/battle-duel-2026-10-24/duelo-corrigido.png`.

Esta revisão cobre o duelo local de dois participantes. Não comprova composição em celular, controle físico, rede entre máquinas ou todas as criaturas/rivais. As poses humanas ainda reutilizam os sprites existentes de exploração; uma família de poses específicas de batalha é um refinamento artístico futuro. Oponentes online sem aparência replicada continuam com silhueta explícita, conforme a implementação documentada. Não houve publicação no Git/Render.
