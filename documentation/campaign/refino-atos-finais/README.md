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
