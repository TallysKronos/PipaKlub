# Trabalho em segundo plano

Não há cron externo configurado neste código.

| Trabalho | Frequência | Controle e persistência | Operação |
|---|---|---|---|
| Flush de prêmios | Cerca de 400 ms, `src/progression.js` | Uma execução por processo, lotes de até 8, fila SQLite; IDs e liquidação SQL idempotentes | Retenta com backoff até 60 s; falhas registram status, sem credenciais |
| Expiração de solo | Dentro do flush | Confere presença antes de remover a tentativa ociosa; sem chamada pública de concessão | Pode liberar conta bloqueada por duelo abandonado |
| Tick multiplayer | 30 Hz, `src/realtime.js` | Somente salas com sockets; comandos sanitizados, chave privada na abertura | Encerrar com o servidor em SIGTERM |
| Renovação da interface | Timers no navegador | Não concedem prêmios; servidor continua sendo autoridade | Fechar aba encerra esses timers |

O reinício do serviço para os timers. O banco PostgreSQL mantém resultados liquidados, mas o arquivo local e sua fila não devem ser considerados duráveis no serviço gratuito sem uma estratégia de persistência. Consultar o log do serviço e o estado do resultado antes de prometer entrega após falha do host.
