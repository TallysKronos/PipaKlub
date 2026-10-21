# Morro do Sol integrado à jornada padrão

Data: 21/10/2026. Integração local sobre `ed3432e`, com as correções da auditoria anterior preservadas. Sem push, deploy ou migração de banco nesta etapa.

## Comportamento

Entrar no Morro do Sol pelo mapa da cidade agora abre o percurso de cinco áreas ilustradas, sem exigir parâmetro na URL:

1. Praça da Chegada — Zeca.
2. Escadaria da Sombra — Bia.
3. Laje dos Ventos — Juninho e Lia.
4. Mirante da Caixa-d’água — Tião.
5. Parque dos Ventos — encontro final.

Os identificadores de encontros, a coleção, os checkpoints e a liquidação das recompensas continuam usando os contratos existentes. Cada passagem depende do snapshot confirmado da própria conta. Uma vitória otimista/local não remove a barreira. Retornar da batalha mantém a área e a posição. A saída da última área abre o encerramento da demo.

Sair de uma partida não acrescenta mais `?overworld=pilot` à URL normal. Links antigos com esse parâmetro continuam funcionando. Para auditoria de arte, `?overworld=legacy` seleciona o mapa antigo e `?overworld=blockout` seleciona o estudo modular; esses modos explícitos persistem ao sair da partida.

O botão secundário do encerramento diz “Continuar explorando”, correspondente à ação de fechar o diálogo e permanecer no bairro.

## Validação

- Builds Worker e Pages concluídos; artefato ESM validado.
- Suíte completa: **297 testes aprovados**, registrada em `tmp/morro-integration-full.log`.
- Após o ajuste do texto do encerramento e a inclusão da verificação de troca de conta, **20 testes direcionados aprovados**, em `tmp/morro-integration-tests-final.log`.
- O teste integrado da UI percorre as cinco áreas com snapshots de vitória simulados: bloqueio inicial, rejeição de salto, recusa de vitória apenas local, retirada da barreira após confirmação, retorno da batalha, percurso de ida/volta, final da demo e recusa de acesso ao trocar de proprietário.
- Testes geométricos existentes verificam os caminhos, as barreiras fechadas, a liberação e o seguidor nas cinco áreas.
- No navegador integrado a 1280 × 720, a conta fictícia já iniciada na auditoria anterior entrou pela cidade e abriu a nova Praça da Chegada na URL `/`. Selecionar a próxima área e interagir com a escadaria antes de vencer manteve o personagem na primeira área, com “Vença Zeca para seguir”.
- Evidência visual: `art/ui-reviews/morro-integrado-2026-10-21/praca-bloqueio.png`.

Os testes de snapshots simulados não equivalem a cinco vitórias manuais no navegador nem a recompensas conferidas em produção. Não foram usados dados do proprietário ou do Supabase real. Permanecem os testes externos de aparelhos/redes e as demais pendências visuais descritas na auditoria anterior.
