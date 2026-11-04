# Recompensas por adversário — 31/10/2026

Decisão do dono: o Soulmonster de um treinador rende o mesmo XP de um selvagem da mesma espécie e nível. O diferencial é dinheiro e XP extra do tamer. Substitui a meta anterior de chegar ao nível 8 só com seis duelos.

Aplicado aos seis treinadores do parque. Curva de nível, XP dos selvagens, atributos e regras do Morro preservados.

| Treinador | Espécie / nível | XP parceiro | Moedas | XP extra tamer |
| --- | --- | ---: | ---: | ---: |
| Assis | Carcará / 2 | 13 | 20 | 11 |
| Iara | Mata verde / 3 | 22 | 25 | 14 |
| Nilo | Carcará / 4 | 19 | 30 | 17 |
| Dora | Raio de sol / 5 | 38 | 35 | 20 |
| Cauê | Mata verde / 6 | 34 | 40 | 23 |
| Celina | Raio de sol / 7 | 48 | 45 | 26 |

Total: **174 XP do parceiro**, antes 1260; 195 moedas; 111 XP extra de tamer. O tamer mantém também `floor(XP do parceiro / 5)` por vitória. Bônus iniciais definidos por nível: moedas `10 + 5 × nível`, XP extra tamer `5 + 3 × nível`.

Prévia e transação compartilham regras. Só vitória paga. Recibo impede duplicação. Duelos antigos suspensos continuam válidos, mas o XP pendente é normalizado pela espécie/nível. XP já recebido não é removido. IDs e ranks de combate preservados.

Validação: campanha 206; curva XP 423; ritmo 433; interface/retorno 7; rota sem aleatórios 96; rota mista 157 verificações, sem falhas. A suíte antiga de interface ainda avisa sobre recursos não liberados ao encerrar.

Sem aleatórios, o controlador perdeu para Cauê no nível 2: retorno sem prêmio e possibilidade de tentar de novo verificados. Com 12 encontros extras, terminou os treinadores no nível 5 (482 XP), não no 8. O controlador de comandos precisos ainda venceu o boss abaixo do recomendado; não equivale à dificuldade humana. Não houve novo playtest humano neste passe.
