# Exame Azul — proposta jogável

Estado: primeira versão jogável implementada. Local aprovado: Pátio da Liga no Parque; espécie aprovada: Carcará de avaliação emprestado. As opções abaixo preservam o estudo inicial; a implementação usa cansaço/descanso, três marcos de condução e três fases de controle. Ver `documentation/qa/blue-exam-v1/RELATORIO.md` para resultados e limites.

## Princípio

Dona Cida avalia qualquer candidato segundo o mesmo procedimento. Retalho, seus resgates, a família de Kael e a composição do banco não participam dos requisitos. A orientação no ateliê continua sendo apenas uma explicação.

Inscrição: categoria Verde e conclusão histórica dos bairros 5 e 6; perder o título de um bairro não apaga a qualificação. O Soulmonster de avaliação é emprestado pela Liga e nunca entra no banco. Sua condição é simulada: a prova não gasta itens, altera saúde, concede XP ou exige espaço no save.

## Cenário aprovado

Decisão: pátio de treinamento da Liga ligado ao Parque, com um Carcará de avaliação padronizado. É um anexo de uma região que já tem A/B/C, não uma região de mapa único. Alternativa: avaliação provisória no ateliê de Assis, sem antecipar uma sede nova da Liga.

```
               [controle: campo de vento protegido]
                               |
 entrada / Dona Cida -- [condução: trajeto em laço]
             |                 |
 [observação e cuidados] -- [área de espera / saída]
```

Separar os três espaços visualmente. Nenhuma prova usa abismo, água perigosa, cronômetro global ou beco que aprisione o parceiro. O jogador pode observar antes de iniciar e sair sem perder o progresso já confirmado.

## 1. Observação

O jogador examina o Soulmonster antes de escolher o cuidado. Mostrar sinais concretos na arte e no texto, sem depender apenas de cor. A interação oferece três cuidados com descrições curtas, não um botão opaco de “resposta correta”.

Casos propostos para a mesma competência:

| Sinal | Cuidado adequado | Erro explicado |
| --- | --- | --- |
| Cansaço, movimentos lentos, armação íntegra | Descanso | Forçar mais treino não resolve o cansaço |
| Vareta desalinhada, pouca sustentação | Apoiar e reparar a armação | Apertar a linha não endireita a estrutura |
| Linha desfiada, estrutura íntegra | Substituir a linha danificada | Remendar o papel não resolve a linha |

Primeira versão: um caso fixo e anunciado, aplicado igualmente aos candidatos. Não é sorteio de dificuldade. Um cuidado inadequado produz explicação e permite observar novamente; não machuca um parceiro real. Aprovação exige a observação seguida do cuidado adequado.

## 2. Condução

O jogador acompanha o parceiro emprestado por três marcos em ordem. O parceiro tem ritmo próprio; apertar interação em três placas sem acompanhá-lo não vale como condução.

Proposta inicial: velocidade do parceiro menor que a caminhada normal, distância confortável de até três células e tolerância de três segundos fora da distância. Sinalizar distância antes de interromper. Se o candidato se afastar demais, o parceiro para e a etapa volta ao último marco seguro; não há dano, cobrança ou perda da observação já aprovada. Ficar parado junto dele não reprova por tempo.

Cada marco exige ambos próximos, na mesma cota e com passagem real. O modelo deve conferir percurso e progressão, não confiar só numa chamada de “cheguei”. Distância, pausas e texto precisam continuar legíveis em controle e teclado.

## 3. Controle

Pequeno exercício de voo com o mesmo parceiro emprestado, em área segura. Não é uma batalha em que basta tirar a vida do adversário.

Sequência proposta:

1. Manter a pipa dentro de uma faixa ampla durante dois segundos.
2. Ler uma rajada anunciada e aliviar a tensão, recuperando energia antes de continuar.
3. Responder a três sinais de prática, sem comandos de risco durante o aviso de pausa.

Sinais visuais e texto acompanham o som. Sem exigir acertos de poucos frames. Errar um sinal dá feedback e repete essa sequência; não libera a categoria por derrotar um boneco. A implementação pode reaproveitar entrada, desenho de linha e avisos do treino atual, mas precisa ter objetivos próprios e exibir o parceiro da Liga, sem fallback visual para Rabbito.

## Resultado e repetição

Somente Dona Cida registra a aprovação, depois das três competências concluídas. Certificado, flag de categoria e recibo único precisam estar no mesmo snapshot. Confirmar duas vezes ou carregar o save não pode duplicar certificado nem outros benefícios. Uma falha de escrita mantém o resultado pendente para repetir a gravação, sem afirmar que houve promoção.

Repetição gratuita. Cada competência confirmada fica salva. Sair no meio de uma etapa reinicia somente a atividade ainda não confirmada; não aprova por ter aberto a tela. Depois da promoção, repetir como treino não paga recompensa. Não conceder benefícios de remonta ou Varal que seus respectivos sistemas ainda não implementem.

## Verificação prevista

- Candidato qualificado sem nenhuma flag de Retalho consegue realizar a prova.
- Candidato que possui Retalho, mas não os requisitos da Liga, não pula a qualificação.
- Inspeção sem cuidado, cuidado errado, marcos fora de ordem e chegada sem o parceiro não aprovam.
- Pausa, saída, recarga e redução de movimento preservam estados coerentes.
- Controle responde aos sinais reais do exercício, não a vitória de uma batalha comum.
- Falha de escrita, confirmação repetida e repetição após promoção não duplicam concessões.
- Capturas do local e das três etapas, navegação real pelo mapa e verificação de foco em teclado/controle.
- Balanceamento e teste físico de controle devem ser registrados separadamente dos testes automatizados.
