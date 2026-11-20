# Torre do Vento — marco do gerador

Refino pontual de kronasta-montanha-c, sem alterar planta, cotas, rampas, itens ou saídas.
Função canônica: os Quatro Ventos devolvem as almas e encerram a noite do cerol (§7.6).

## Planta de intenção

```text
                 fundo / v-
       rocha nível 7, já bloqueada
            [TORRE 29,6]
       -------------------------
          clareira nível 6
       Vento    receptor     Vento
                  Kael
       Vento                 Vento
                  |
          trilha de chegada / volta
```

Pegada da torre 2×1 em (29,6), sobre rocha contínua de nível 7. A base usa o
pilar ilustrado do kit Câmara do Elo, com dimensões de aproximadamente 100×140 px.
O receptor é um cata-vento de quatro velas com contorno escuro e cores dos Ventos.
Nenhuma nova passagem ou recompensa. A base inteira fica fora da área caminhável.
A sequência de abertura/estreitamento/clareira e os becos do mapa são preservados.

Conferência: base em mesma cota nos dois apoios, não sobre rampa; toda a colisão já
vem da rocha. Energia termina no receptor real, sem deslocar o jogador. O marco
permanece após sair e voltar; ativação usa geradorLigado. Movimento reduzido mantém
o estado aceso sem rotação. Esta entrega não redesenha toda a região nem seus pisos.

Limitação editorial: a transformação dos Desalmados na cidade continua fora deste
refino pontual. A arte de Trovareta ainda é provisória.
