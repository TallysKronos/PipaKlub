# Playtest narrativo de Soulmonsters

Base `57c20e10`, Godot 4.7.2 no Windows, perfil descartável. Esta rodada combina progressão automatizada, checkpoints dirigidos, capturas do jogo e leitura das falas. O próximo marco é uma partida contínua no executável de distribuição.

## O que funcionou

- **Prólogo.** O objetivo de disputar a liga aparece logo na TV. O presente da mãe cria a oportunidade para a primeira decisão de Kael, e a nomeação chega logo depois do nascimento. Nas capturas do quarto, Kael, Heleana e Rabbito ficam separados. A sequência de progressão gravou e retomou o parceiro nomeado.
- **Retalho e Heleana.** Os testes confirmaram as duas vertentes. Aceitar Retalho leva à confissão com ele na equipe. Recusar leva ao reencontro em casa. A suíte de confiança também verificou retomada da escolha e adoção com a campanha cheia. As vitórias e derrotas desse teste foram preparadas como estados de combate.
- **Câmara do Elo.** A fala de Grampo sobre confundir a cabeça baixa de Platyx com um “sim” dá peso à mudança de lado. A resposta ao Rato conecta esse arco à escolha dos parceiros. A encenação e a libertação de Trovareta passaram em testes separados.
- **Campeonato e epílogo.** A fala de Jamile sobre a final da TV fecha o arco iniciado no quarto. A campanha volta à cidade após os créditos e preserva o título se a gravação falhar. A flor pode ser entregue mais tarde, e o epílogo retoma sem duplicar o item.

## Ajustes por prioridade

| Prioridade | Cena | Evidência e ajuste |
| --- | --- | --- |
| Alta | Pódio | O texto descreve Jamile amarrando a fita e Rabbito puxando a ponta. A rotina de vitória posiciona o elenco e Rabbito, mas o gesto da fita ainda depende do texto. Mostrar a fita passando para o carretel e a reação de Rabbito. Preservar a fala sobre a TV e retirar a descrição dos gestos quando estiverem visíveis. |
| Alta | Câmara do Elo após Eremor | O diálogo de vitória informa ao mesmo tempo que a chave quebrou, que Rato fugiu e que o grupo passou. Conferir esse enquadramento em movimento antes de decidir o que cortar. Dar um plano curto aos pedaços da chave e à saída do grupo. Se a fuga não for visível, manter uma observação curta em vez de três informações no mesmo bloco. |
| Média | Bancada no prólogo | Kael explica em uma fala o corpo de papel, a regra da rabiola e o fato de ter inventado Rabbito. O quarto já apresenta a bancada e o desenho. Manter a dúvida essencial e deixar a entrada de Heleana responder pelo presente. Conferir o ritmo com deslocamento real até a mesa. |
| Média | Entrega da flor | Na captura, a flor está visível nas mãos de Tyler. O corpo do diálogo ainda repete “Tyler:” e separa “Vamos ver o” de “Rai” em linhas distintas. Usar um único bloco com Tyler como falante e dar uma pausa à reação antes do convite para ver Rai. |

## Evidência e lacunas

579 verificações passaram nas suítes de campanha, Beira-Canal, Retalho, Heleana, história final, libertação de Trovareta, créditos e epílogo. A suíte de encenação final também retornou zero falhas. A primeira tentativa de Retalho encontrou a classe de teste `FailedStore` ausente. Ela foi restaurada e a segunda execução passou em 97 verificações.

Capturas locais a 1280×720 do quarto, nascimento, nomeação e entrega da flor. Os passos do quarto foram abertos em estados preparados, sem simular o deslocamento entre eles. A captura da flor veio do fluxo executado na suíte do epílogo.

Ainda falta percorrer uma campanha única do prólogo ao pós-jogo no executável Windows. Esse percurso precisa cobrir o ritmo entre bairros, os duelos com resultado obtido por jogo, a ordem alternativa de sidequests e a saída/reabertura durante os créditos. Os resultados atuais justificam uma rodada de refinamento narrativo antes de selecionar cenas para o trailer.

## Ajustes aplicados (05/11)

| Cena | O que mudou |
| --- | --- |
| Pódio | Rabbito puxa a ponta da fita dourada (a linha se estica até ele) depois que Jamile a passa para o carretel. O diálogo mantém a fala sobre a TV e não narra mais os dois gestos. |
| Câmara do Elo após Eremor | Um plano curto mostra a chave do Elo caindo em cinco pedaços no altar (com câmera e sem animação, se o movimento estiver reduzido). A fala de vitória ficou com duas linhas: a chave quebrada, a fuga do Rato e a saída do grupo, sem repetir o que a cena mostra. |
| Bancada no prólogo | "Pronto, Rabbito! Agora só falta a sua rabiola… Mas onde eu acho a rabiola de um Pipamon que eu mesmo inventei?" Fica a dúvida essencial; o presente da Heleana responde. |
| Entrega da flor | Um único bloco com Tyler como falante, uma pausa ("…") antes do convite e "o Rai" sem quebra de linha. |
| Nina no Jardim | Entre o aviso do Jurandir (Porto Novo concluído) e o resgate nas Ruínas, Nina não aparece mais no Jardim conversando como se nada tivesse acontecido. |
| Falas repetidas | Nina e Tyler alternam duas falas por visita e mudam com a história (antes do ato 4, ato 4 em diante, depois do resgate, depois do registro do laboratório, campeão). A promessa da "pipa que eu estava construindo", que nunca se cumpria, saiu. |
| Epílogo (§13) | Ver a bíblia: Elo na câmara, Assis aceita o Tyler, Heleana volta a pesquisar (três vertentes da Retalho), gancho pós-créditos. |
