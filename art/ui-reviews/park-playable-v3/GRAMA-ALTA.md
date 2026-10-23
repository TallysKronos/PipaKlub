# Capim alto interativo — Parque dos Ventos

Prévia: http://127.0.0.1:5241/

- Moitas de 29–44 unidades de altura, cinco folhas curvas, três tons e variação determinística. Apenas os habitats existentes recebem capim alto.
- Cada moita entra na ordenação por profundidade dos pés: folhas à frente encobrem as pernas; folhas atrás permanecem atrás do personagem.
- Proximidade do jogador e do Rabbito abre as folhas lateralmente. Recuperação gradual ao sair; brisa independente da passagem.
- Caminhar dentro de um habitat solta três pequenas folhas a cada 13 unidades percorridas. Elas sobem, giram, caem e desaparecem em 0,65–1,05 s. Máximo de 72 partículas simultâneas.
- Áreas sobrepostas não duplicam moitas nem a emissão. Parado não emite. Teleporte e carregamento não geram rajadas.
- Movimento reduzido mantém a abertura instantânea, sem partículas voando. Diálogos pausam a simulação; pausar somente o vento mantém a reação da caminhada.
- Renderização Canvas; não exige atlas novo, não altera colisões, saves ou probabilidades de encontro. A integração continua limitada ao passeio local desta prévia.

Validação: 42 testes passaram (world-tall-grass, park-exploration, world-isometric, park-coherence, world-navigation e world-map). Verificação visual no navegador: entrar no capim, caminhar, acompanhar Rabbito e parar.

## Integração no cliente do jogo

O cliente principal usa world-tall-grass e world-tall-grass-renderer nos habitats com encounter_zone, com projeção ortogonal e ordenação pela base dos pés. A prévia usa os mesmos módulos com projeção isométrica. O estado é reiniciado ao trocar de cena/conta; diálogos pausam a simulação. Ambos os builds (servidor e Pages) incluem o código compartilhado. Os encontros selvagens continuam no consumidor original stepWildExploration.

O layout isométrico completo, tarefa local e família Soulgen continuam como prévia; não substituem silenciosamente a campanha. A inspeção visual foi feita na prévia. Não houve sessão autenticada no mapa principal nem confirmação de deploy em produção neste trabalho.
