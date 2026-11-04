# Kael → Tyler · pétalas de cerejeira

Continuação solicitada pelo usuário após aprovação do Tyler V3. Referência de composição: imagem de mangá enviada em 28/10/2026, com personagem visto em perspectiva inclinada. Emprega esse enquadramento e atuação contida, preservando a roupa e identidade próprias de Tyler; não copia personagem, uniforme, texto ou símbolos da referência.

## Fontes

- Quadro do Kael: `art/pipa-tv-cinematic-v5/fontes/pipatv-v5-kael-final.png`, extraído do filme V4 aprovado.
- Cena nova: `art/pipa-tv-cinematic-v5/fontes/pipatv-v5-tyler-cerejeira.png`, criada com image_gen usando Tyler V3 e Saber V2. Personagens sob cerejeira, caminho de pedra, perspectiva inclinada e pétalas em primeiro plano.
- Identidade de Tyler: `art/tyler-manga-v3/tyler-sheet-v3.png`. Cabelo preto e três tufos brancos na lateral, sem mecha central.
- Identidade de Saber: `art/tyler-saber-manga-v2/saber-sheet-v2.png`.
- Workflow e prompts: `art/pipa-tv-cinematic-v5/`. H3 local, sem nós pagos; 20 passos, 6 segundos e 0,4 MP solicitados, seed 2810202610. Duração e dimensões efetivas devem ser lidas de `montagem.json` ao concluir.

O wipe solicitado usa pétalas que cobrem a lente, mudando de local durante a oclusão; não é transformação de Kael em Tyler. Câmera lateral suave, pequeno olhar e movimento de tecido, sem exposição de história futura.

## Entrega e continuidade

Prévia do trecho isolado e montagem após a abertura V4. Exportação de revisão 1280×720 com proporção preservada; não representa geração HD nativa. Fontes e versões anteriores preservadas.

Não altera o filme ativo no Godot: ele termina no quarto e entrega o controle ao jogador. Antes de substituir esse recurso, decidir onde o novo plano de Tyler retorna ao Kael para não quebrar a passagem ao quarto. Esta entrega é geração e edição de vídeo, sem gameplay, alteração de saves, testes de jogo ou publicação.

Geração concluída: job `37821aec-3d02-4868-95a5-2c8fd3a3a60d`, fonte preservada em `art/pipa-tv-cinematic-v5/video-original/05-tyler-petalas/37821aec_000.mp4`. A oclusão por pétalas revelou os dois personagens corretamente. Contudo, o modelo apagou o cenário para preto no final, efeito não solicitado; esse trecho foi removido na edição.

`transicao-revisada.mp4` usa os primeiros 3 segundos e sustenta o último quadro limpo por 1,5 segundo, encerrando como uma ilustração de mangá. A sustentação não é nova animação gerada. Duração editada: 4,5 segundos. Som original aparado com fade de saída curto. O enquadramento limpo foi inspecionado em `revelacao-limpa.png`. A cortina contém flores inteiras além de pétalas; não é um passe isolado com alpha. O modelo preservou o contraste geral do cabelo, mas o detalhe exato dos três tufos não tem precisão de rig.

Metadados medidos da edição e caminhos de entrega em `montagem.json`. Nenhuma mudança no recurso ativo do jogo nesta entrega.
