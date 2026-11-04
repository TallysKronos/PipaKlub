# Ritmo do primeiro percurso

## Encontros durante a caminhada

Não estão mais restritos ao mato. Terra e grama também contam deslocamento; mato conta 1,6 vez a distância. O contador acumula entre trechos de terreno elegível, sem reiniciar em cada borda de tile. Ficar parado, conversar, celebrar item ou pausar não avança a contagem.

| Área | Distância sorteada, em células | Níveis selvagens |
| --- | --- | --- |
| Jardim das Pipas | 18–26 | 1–3 |
| Clareira do Papel | 14–22 | 2–4 |
| Veredas do Encanamento | 12–19 | 5–7 |

Além da distância, são necessários quatro segundos de caminhada em terreno elegível após a pausa de proteção. O intervalo exato depende da rota, do mato e da velocidade; não é um temporizador que dispara uma batalha enquanto o jogador está parado.

Ao construir a vista, há seis segundos de caminhada protegida. Depois de fugir, são oito; depois de perder, doze. A proteção de persistência do domínio também respeita esses valores. Reiniciar a vista ou carregar o save pode conceder novamente a proteção inicial, mas não concede recompensas.

Praças/piso construído, pontes e rampas não iniciam encontros. Há áreas tranquilas de três células ao redor de NPCs, itens, entradas e saídas; 2,5 ao redor de baús e cinco no entorno do boss. Essas exclusões são verificadas tanto pelo controlador quanto pelo domínio que inicia a batalha.

## Progressão e Lacertubo

O primeiro boss novo é nível 8, com 210 de linha/estrutura e ataque base 1,12. Mantém a armadura, os avisos dos ataques e a vulnerabilidade após seus golpes. A vitória concede 220 XP. O aviso de preparação mostra o nível 8 e orienta observar a abertura da guarda.

Após a pesquisa sobre Digimon World 3, a recompensa regional fixa foi substituída por espécie e nível do adversário. A regra é `base + (nível − 1) × incremento`; a mesma espécie no mesmo nível rende o mesmo XP em qualquer área, sem redução automática baseada no nível do jogador.

| Espécie | Base / incremento | XP Nv.1 | XP Nv.3 | XP Nv.6 |
| --- | --- | --- | --- | --- |
| Carcará | 10 / 3 | 10 | 16 | 25 |
| Mata verde | 14 / 4 | 14 | 22 | 34 |
| Raio de sol | 18 / 5 | 18 | 28 | 43 |

Lacertubo usa base 80 e incremento 20, resultando nos 220 XP de seu nível 8. A recompensa é fixada ao iniciar a batalha, compartilhada entre prévia e liquidação e gravada com o recibo da operação. Fugir não dá XP.

O custo do próximo nível para um parceiro de nível L é `20 + 15L + 5L²`, somado cumulativamente. Estatísticas, coleção, barra de resultados, limite de crédito e som de nível usam a mesma fonte em `partner_levels.gd`.

| Nível | XP total necessário |
| --- | --- |
| 2 | 40 |
| 3 | 110 |
| 4 | 220 |
| 5 | 380 |
| 6 | 600 |
| 7 | 890 |
| 8 | 1260 |
| 50 | 221480 |

No cenário determinístico de calibração, oito vitórias no Jardim, doze na Clareira e vinte e nove em Veredas, alternando níveis e uma mistura de espécies, levam o mesmo parceiro ao nível 8 em 49 vitórias / 1268 XP. Isso é uma referência de esforço partindo de zero, não uma obrigação de 49 batalhas. É possível enfrentar e vencer o boss abaixo do nível recomendado. Trocar o parceiro equipado distribui o progresso entre eles. O ritmo final ainda precisa de avaliação humana; estes números são uma adaptação própria, não uma reprodução da curva de Digimon.

A inspiração foi a combinação de recompensas por inimigo, crescimento do custo por nível e incentivo a avançar de área, documentada no [guia de EmeraldPhoenix](https://gamefaqs.gamespot.com/ps/562323-digimon-world-3/faqs/18310) e no [bestiário de TheFulgorah](https://gamefaqs.gamespot.com/ps/562323-digimon-world-3/faqs/66315). Maestria de assinatura é uma etapa futura, separada de XP base; não foi criada uma barra sem efeito de gameplay.

A diferença de nível afeta golpes de linha, corpo e assinatura. O combatente de nível menor causa menos dano e recebe mais: três níveis de diferença = 10%; cinco = 25%; dez ou mais = 50%. Valores intermediários interpolam suavemente. Um parceiro bem acima do adversário não ganha um multiplicador adicional de ataque; a penalidade é aplicada ao de nível menor.

Saves `demo-1` são convertidos para `progression-2`, preservando o nível e a fração de progresso da barra (arredondada para baixo em no máximo um XP novo). O total numérico de XP muda para representar o mesmo avanço na nova escala. A conversão é idempotente, passa pela validação existente e só é persistida no próximo commit atômico; consultar um save não reescreve o arquivo.

Combates já suspensos mantêm os atributos e níveis do snapshot anterior e o prêmio regional da revisão anterior. O novo perfil vale para novas batalhas; nenhuma coleção foi reiniciada. Não houve alteração do schema nem do formato do inventário.

## Evidência e limites

- 473 verificações específicas de ritmo, 423 da curva/migração/transações, 206 da campanha, 20 dos efeitos e recompensas do HUD, 51 das transações do Morro e 103 da integração gráfica: zero falhas após esta revisão.
- O teste de integração percorre o controlador real em terra, verifica que ficar parado preserva a proteção, inicia o encontro, foge e retorna ao ponto salvo. Nesse caso o limiar de distância é reduzido explicitamente para isolar proteção e elegibilidade; não é uma medição da frequência padrão.
- Simulação com comandos de ataque/defesa iguais, Rabbito íntegro: nível 1 venceu em 22,4 s, com 26,8 de linha; nível 8 venceu em 17,7 s, com 80,7. O controlador automatizado reage com precisão; isso não estima o desempenho de um jogador iniciante. Ambos podem ganhar, mas o parceiro despreparado tem margem de erro menor.
- Capturas nativas de 1280×720 conferidas após o ajuste. Perfis de teste são isolados em `tmp/`.

Próxima avaliação humana: frequência percebida no caminho principal, desgaste ao chegar em Veredas e clareza da preparação do boss. Cutscenes de apresentação ficam para a etapa seguinte; a proteção ao redor dos personagens já evita interrupções por encontros nesse espaço.
