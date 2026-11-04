# PIP-74 — Diálogos mangá

Entrega local; sem push, merge ou mudança no Linear.

## Componente e integração

hud_dialogue_surface.gd é a superfície compartilhada pela abertura, lições, balões de mundo e diálogos completos. hud_dialogue.gd substitui os AcceptDialog/ConfirmationDialog da campanha, incluindo Nina, reparo do Sr. Assis, Morro, confirmações e remapeamento de teclas. Mantém os sinais de confirmação/cancelamento para preservar as transações.

- Caixa de nanquim com pontas a aproximadamente 12°, texto Nunito e placa de nome separada.
- Retratos existentes, retícula estática apenas atrás deles e falante anterior a 65% de luminosidade. Os NPCs do Morro usam recortes dos assets disponíveis; não foram gerados novos bustos nesta etapa.
- Texto dividido em páginas de até três linhas. Juninho e Lia trocam retrato e nome por fala. Informações de missão/recompensa ficam identificadas como sistema.
- Até quatro escolhas nativas, com foco na opção marcada segura. As confirmações atuais mantêm a opção de adiar antes da ação. O foco anterior volta ao cancelar, quando ainda existe.
- HUD de exploração recolhida durante o diálogo e restaurada ao sair. A conversa bloqueia o clique no cenário; o fluxo existente pausa a movimentação.
- Balão ambiente de dois segundos ao se aproximar de Nina ou dos pipeiros do Morro, no máximo um por vez, sem pausar ou alterar a missão.
- Losango de avanço move quatro pixels em 600 ms. Movimento reduzido o mantém estático e desativa as linhas do grito.

## Tags para autores

As tags não aparecem no texto funcional; desconhecidas são removidas sem executar comandos.

| Tag | Apresentação |
| --- | --- |
| [emo=suor] | Gota de suor |
| [emo=raiva] | Veia de raiva |
| [emo=brilho] | Brilho |
| [emo=surpresa] | Exclamação |
| [emo=duvida] | Interrogação |
| [emo=suspiro] | Suspiro |
| [reacao=HÃ?!] | Reação curta em Bangers, até 16 caracteres |
| [voz=grito] | Borda de grito e concentração por 250 ms; estático com movimento reduzido |

Exemplo: `Nina: [emo=suor]Meu Carcará tentou me proteger…`

Separe as falas com uma linha em branco e identifique cada novo falante com `Nome: texto`. As histórias estruturadas existentes do Morro continuam sendo a fonte do texto. Não há novo formato de save.

## Verificação

Tags, paginação, corpo com mais de 30% de texto adicional, escolhas seguras, emissão única, balão ambiente e ausência de corte em quatro resoluções, com e sem movimento reduzido. Capturas em mockups/revisao/pip74. Fixtures são visuais e não substituem percurso jogado.

Percurso automatizado com progresso efetivamente conquistado, incluindo cinco desafios do Morro: 212 verificações, zero falhas. HUD geral: 81 verificações, zero falhas. Lições após compartilhar a superfície: 520 verificações, zero falhas. Sem controle físico validado.

Resultados finais: diálogo renderizado em quatro resoluções, 701 verificações sem falhas; revisão adicional 1280×720 após unificar a placa da abertura, 103 sem falhas; mapas e diálogos do Morro, 9386 sem falhas. A comparação geométrica de Control usa unidades lógicas da UI, pois a versão anterior media uma Window em pixels.
