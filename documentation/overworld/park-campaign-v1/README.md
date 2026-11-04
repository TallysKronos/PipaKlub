# Parque modular na campanha

Jardim das Pipas, Clareira do Papel e Veredas do Encanamento agora usam o renderer e o controlador dos mapas modulares revisados durante a campanha. A prévia de arte continua independente.

## Comportamento

- Entradas e saídas usam as posições dos mapas, incluindo a chegada elevada da Clareira em Veredas e o atalho de retorno ao Jardim após vencer Lacertubo.
- A missão começa com Nina no Jardim. A rabiola só aparece após vencer o guardião; recolher e devolver são etapas separadas.
- Itens e baús gravam a recompensa com o recibo da operação. Baús abertos e itens já recolhidos permanecem assim ao recarregar.
- Encontros podem acontecer em grama, terra e mato, com peso maior no mato. Conversas, entradas, saídas, pontes, rampas, praças e o entorno imediato de baús e do boss são protegidos. Veja [o ajuste de ritmo](ritmo.md).
- Vitória e fuga retornam ao ponto de encontro; derrota mantém o parceiro e retorna à entrada da área.
- A câmera usa a posição projetada com a altura do terreno. O HUD, minimapa e mapa da área recebem a geometria modular.
- Trocas de área usam a cobertura de carregamento existente antes de construir a próxima vista e a removem após renderizar o primeiro quadro.

## Compatibilidade de saves

O marcador de coordenadas `parque-overworld-v1` distingue células novas de pixels do mapa antigo. Saves sem esse marcador migram para o marco semântico mais próximo e caminhável. A posição antiga não é preservada exatamente, pois os layouts mudaram. Inventário, parceiros, missões e baús preservam seus IDs e seu progresso. Não houve reinicialização dos saves nem alteração da versão do schema.

As regras de XP agora usam `progression-2`. Saves `demo-1` convertem a escala de XP preservando o nível e a fração já preenchida da barra. A fonte única da curva e os testes de migração estão descritos em [ritmo.md](ritmo.md).

Combates antigos continuam aceitos; seu retorno passa pela mesma migração. Saves novos e combates suspensos novos mantêm suas coordenadas nativas.

## Validação

Godot 4.7.2, captura nativa OpenGL, 1280×720:

- `res://tests/park_campaign_integration.gd`: **103 verificações, zero falhas**. Frontend e controlador reais; caminhada nas duas pontes, entradas elevadas, missão, itens únicos, baús, combate contra Lacertubo resolvido por comandos simulados, encontro fora do mato, fuga, derrota e leitura do save por outra instância do Store. Os resultados de combate não são forçados.
- `res://tests/park_pacing_checks.gd`: **473 verificações, zero falhas**, cobrindo terrenos elegíveis, locais protegidos, progressão por espécie/nível, penalidades de nível e combate simulado.
- `res://tests/progression_curve_checks.gd`: **423 verificações, zero falhas**, cobrindo curva, migração de saves em disco, barra proporcional, idempotência, combate antigo suspenso e consistência das recompensas.
- HUD de recompensas: **20 verificações**; transações do Morro: **51 verificações**, todas sem falhas.
- `res://tests/campaign_checks.gd`: **206 verificações, zero falhas**, com `--test-root` apontando para `tmp/` do workspace.
- O teste de integração usa perfis sintéticos e diretórios exclusivos dentro de `tmp/`. Não usa o save pessoal do jogador.

As capturas foram abertas e inspecionadas. O teste gráfico também percorre a cobertura/revelação de carregamento; o teste headless não renderiza essas transições. A mensagem sobre cache de shaders indisponível no sandbox não impediu a renderização nem os testes.

## Capturas

- [Jardim e HUD](01-jardim.png)
- [Clareira](02-clareira.png)
- [Travessia das pontes](03-pontes.png)
- [Chegada elevada em Veredas](04-veredas.png)
- [Combate real resolvido](05-batalha.png)
- [Devolução da rabiola para Nina](06-nina-resgatada.png)

O resumo da execução está em `report.json`. Estes testes verificam integração e persistência; não substituem uma rodada de avaliação humana de dificuldade ou ritmo da campanha.
