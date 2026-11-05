# Revisão dos atos finais — 04/11/2026

Base de revisão 07e4a7de. Branch codex/refino-atos-finais.

## Alterações

- Gollia entra antes da fala, com segmento validado pelo modelo de colisões e alternativa instantânea em movimento reduzido.
- Quatro Ventos com posições separadas, quadros de idle e recorte por transparência. Trovareta continua usando Raio de Sol como arte provisória. Falta o desenho próprio aprovado.
- Atores temporários são removidos ao encerrar ou cancelar o diálogo.
- Tempestade com chuva diagonal e clarões espaçados. Movimento reduzido mantém efeito estático.
- Cena de campeão reúne Heleana, Assis e Tyler e desloca Kael para o corredor antes dos créditos.
- Shader de gramado amostra TEXTURE diretamente, sem passar o sampler interno por função.

## Verificações executadas

- Atos finais, 94 verificações sem falhas.
- Estádio, passou.
- Tyler, 20 verificações sem falhas.
- Retalho, 15 verificações sem falhas.
- Staging, presença, separação, limpeza, chamada repetida e entrada de Gollia sem falhas.
- Interface da chave, quatro duelos, encerramento e retorno à cidade, 42 verificações sem falhas.
- Overworld, 565281 verificações sem falhas e sem o erro de compilação anterior no shader.

As vitórias do teste de interface são simuladas. Estes resultados não substituem uma partida humana contínua dos atos 4–6. As capturas mostram trechos preparados com saves isolados. O encerramento ainda usa os movimentos disponíveis e não inclui novas animações desenhadas de aplauso nem uma transmissão de TV completa. A arte própria de Trovareta segue pendente.

## Continuidade entre cenas

- Objetivo das Ruínas após Eremor aponta para o Alto do Mirante e sugere recuperar a equipe.
- Objetivo do Mirante após a classificação aponta para o Estádio pelo mapa da cidade.
- Lobby explica o atendente, a próxima rodada e a possibilidade de preparação.
- Grampo comenta a decisão de Platyx; Tyler reconhece a jornada compartilhada; Faye marca a final da chave; Jamile retoma a transmissão de TV do prólogo.
- Conclusão da Torre tem fitas de vento e passagem de luz antes do texto de resultado.
- Capangas recuam apenas por segmento livre, na mesma altura, depois de Gollia intervir.
- Atualização do mapa aguarda a remoção dos atores temporários.
- Atos finais agora têm 97 verificações sem falhas, incluindo os destinos do HUD.
- Cenas da Torre e de Gollia passaram nas duas saídas de interface, confirmar e cancelar, sem deixar atores temporários ou o jogador travado.
- Interface da chave e encerramento passaram novamente em 42 verificações com resultados de batalha simulados.

Os novos diálogos são propostas editoriais integradas para revisão. A transmissão da TV foi retomada na fala de Jamile, mas ainda não existe uma cena de transmissão ao vivo completa.

## Transmissão do campeonato

O encerramento tem agora a identificação Pipa TV ao vivo, faixa de campeão e o filtro CRT já usado pelo jogo. O enquadramento permanece no lobby com Kael e os três acompanhantes. O diálogo conserva o foco; o grafismo sai antes dos créditos. A opção de movimento reduzido remove a entrada em fade.

Verificado no Godot a 1280x720. A repetição da chave e do encerramento passou nas 42 verificações. As vitórias são simuladas no teste. Esta cena não inclui um retorno cinematográfico ao quarto do prólogo.

## Epílogo da flor

Entrega visual, reação de Tyler, câmera próxima e saída por rotas livres no ateliê atual. O laboratório com escada própria segue pendente. A apresentação retoma após interrupção sem duplicar a flor. Saves antigos que já entregaram o item podem assistir à nova apresentação uma vez.

25 verificações sem falhas. Captura com movimento ativado em tyler-flor.png. O teste usa progresso preparado, sem representar uma partida humana contínua.

## Quatro Ventos — convergência

As quatro emissões partem dos respectivos participantes e convergem no ponto do evento da torre, com pulso central e dissipação. Movimento reduzido exibe a convergência brevemente sem deslocamento nem clarão. O teste de encenação passou sem falhas, incluindo nove novas verificações de origem e destino e limpeza nas duas opções. Captura preparada com HUD oculto em torre-convergencia.png.

F23 permanece parcial: o cenário ainda precisa de uma torre física e de mostrar a consequência na cidade. Esta mudança cobre a emissão conjunta, sem afirmar que conclui a construção do mapa.

## Torre física — atualização

A Torre do Vento agora existe no paredão do cume. Reutiliza o pilar ilustrado do kit Câmara do Elo com um receptor de quatro velas. A pegada em rocha de cota 7 preserva o percurso. Os feixes terminam no receptor, que passa a girar e acender. O estado é restaurado por geradorLigado. A câmera enquadra a ativação e retorna ao jogador. A consequência sobre os Desalmados na cidade segue pendente.

Conferência e limitações em torre/RELATORIO.md.

## Recuperação da cidade — F23

A consequência do gerador agora é mostrada no Centro e no Condomínio, com energia, retorno das cores e do movimento e transição para o dia. As criaturas continuam presentes após o duelo e depois de carregar. 25 verificações da integração passaram nos dois modos de movimento. Capturas e limitações em cidade-restaurada/README.md.

## Trovareta — arte integrada

O atlas Soulgen aprovado substitui Raio de Sol no Bosque, na batalha e na torre. Foram corrigidos o Rato oculto pelo barranco e a permanência de Navalha/chuva depois da libertação. 17 verificações da apresentação e três testes de rig/importação passaram. Capturas e limites em trovareta/README.md.

## Libertação da Trovareta — sequência completa

A quebra da linha, partida em voo, fim da tempestade e entrada do Rato agora antecedem o diálogo. A pendência é salva com a vitória e só se encerra após a conversa, permitindo retomada. 28 verificações passaram nos dois modos de movimento. Capturas e limites em trovareta/libertacao/README.md.

## Reunião dos campeões — F20

Os oito campeões agora participam da reunião, com separação por silhueta e destaque do interlocutor no cenário. Câmera, cancelamento, falha ao salvar, retirada e liberação do Exame Vermelho foram verificados. 118 verificações passaram nos dois modos de movimento. Dona Neve usa o professor como mock autorizado. Capturas e limites em reuniao/README.md.
