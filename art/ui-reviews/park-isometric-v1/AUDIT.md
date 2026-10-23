# Revisão do piloto — 22/10/2026

## Verificado

- 34 testes passaram: `world-isometric`, `park-coherence`, `world-navigation`, `world-map`.
- Projeção e inversa em três escalas; cliques mantêm coordenadas de mundo.
- Todas as quatro zonas de saída/interação do Jardim têm rotas válidas; cada passo permanece na geometria segura. Destino sobre um sólido é rejeitado.
- Profundidade considera a soma dos eixos projetados e preserva desempates/pisos.
- Quatro rigs passam no validador Soulgen. 180 amostras por rig: retângulos dentro da tela lógica, bases imóveis, início/fim do loop iguais. Projetos portáteis com PNGs incorporados também válidos.
- `npm run audit:world` passou para o Quintal modular existente (regressão; não é aprovação estrutural automática deste piloto).
- Inspeção no navegador nativo: carregamento, percurso completo ao descanso com mensagem de chegada, controle com seta direita, visão geral contendo todas as árvores, colisões visíveis, pausa e retomada do vento.
- Copas comuns sem ornamentos repetidos; uma árvore é marco com pipas. Bandeirolas ligadas ao coreto; tronco e mastro permanecem apoiados no chão.

## Evidências

- `coreto-review.png`: vista próxima no navegador.
- `overview-review.png`: visão geral com todos os props enquadrados.
- Fontes, recortes, dimensões e relatório estrutural dos rigs: `../../soulgen/keys/park-wind-v1/`.

## Limites

É estudo separado da cena publicada. A arte usa bases de colisão existentes; o ajuste final por objeto e interação deve acontecer na integração ao jogo. Não foram executados testes de campanha, contas, trocas, servidores, aparelhos móveis ou medições de FPS. Kael mantém quatro vistas existentes. O mapa continua fisicamente ortogonal; a nova apresentação é dimétrica.

`prefers-reduced-motion` inicia com vento parado e câmera sem interpolação; a mudança de preferência é tratada no código. A preferência de sistema não foi alterada neste teste manual.
