# PIP-72 — Resultados e recompensas

Implementação local na interface Godot. Sem push, merge ou alteração de status no Linear.

Preservado o layout de tamer, três espaços de Soulmonsters e recompensas aprovado pelo responsável nas revisões anteriores, em vez de substituir pela proposta antiga de cartões isolados 220×260 da demanda.

## Complementos

- Vitória mantém a moldura ilustrada aprovada. Derrota e recuo usam placa neutra, sem respingos festivos ou acentos vermelhos.
- Recuo identificado como VOCÊ RECUOU; derrota recebe incentivo legível em faixa própria.
- Continuar compacto à direita, com glyph atualizado quando muda o dispositivo. Removido o texto longo truncado no Morro.
- XP do tamer e parceiro anima uma vez; subida do parceiro indicada explicitamente. Reservas continuam sem XP, pois troca/participação ainda não existe nas regras.
- Recompensas entram com intervalo de 90 ms; movimento reduzido revela tudo junto com fade breve. NOVO! depende da ausência real do item no inventário.
- Estrelas e passagem de primeira conclusão do Morro agora aparecem, calculadas pelas regras existentes.
- Lacertubo mostra sua rabiola concedida. A rabiola de Nina permanece no chão para coleta: não é listada como prêmio já recebido.
- Nenhuma raridade foi inventada: os itens atuais não fornecem classificação raro para a prévia.

## Verificação

Revisão renderizada dos estados vitória, derrota, fuga, Morro e Lacertubo em 1280×720, 1280×800, 1920×1080 e 2560×1080. Capturas normais e com movimento reduzido em mockups/revisao/pip72.

campaign_checks: 206 verificações sem falhas. morro_transaction_checks: 51 sem falhas. Layout ampliado cobre os cinco casos, nomes longos, texto mínimo de 14, alturas, posição do botão e decoração sem recorte retangular. Fixtures e armazenamento isolados; as capturas não equivalem a um playtest humano completo.

Resultado final do layout com assertions adicionais e nomes longos/movimento reduzido: 1604 verificações, zero falhas. Renderização normal e reduzida: 1576 verificações cada, zero falhas antes das assertions adicionais (sem mudança visual posterior).
