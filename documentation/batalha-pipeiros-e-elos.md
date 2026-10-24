# Batalha — pipeiros e elos

A apresentação dos duelos com dois participantes agora mostra pipeiro e parceiro como identidades separadas. Os nomes, vitórias e retratos ficam no alto. A integridade da linha e a energia do parceiro ficam na base; somente o jogador local tem comandos e custo/recarga disponíveis. O rival não expõe suas habilidades ou recargas. Golpes, manobras e proteções continuam perceptíveis pelos efeitos atuais da engine, após sua ativação.

## Cena

- Cenários, Soulmonsters e personagens aprovados são reutilizados. Os parceiros ficam maiores; o avatar do jogador usa a aparência salva no Avatar Studio. Os NPCs usam os sprites existentes do mundo.
- Carretéis são desenhados na origem da linha devolvida por `eng.line`, sem deslocar os segmentos usados para cruzamentos. Movimento humano é apenas apresentação. Não há previsão de intenção da IA.
- A câmera reserva espaço para a HUD e para os humanos abaixo da linha. Entrada e projeção continuam passando por `worldView`; regras, colisões e recompensas permanecem na engine/servidor.
- Partidas com mais participantes continuam usando a apresentação anterior. Encontro selvagem não inventa um treinador: mostra a criatura e identifica a condição selvagem.
- Oponentes online sem aparência replicada usam uma silhueta identificada pela inicial. Replicação de aparência não faz parte desta mudança. Não foi criado um retrato fictício para representar um jogador remoto.
- A barra de ações mantém os controles existentes e acrescenta o ataque ao grupo visual do duelo. Custos e recargas vêm dos valores já usados pela engine. Não há seleção por turnos.

## Entrega local

Os dois builds incluem `src/battle-duel-client.js`. Checagem de sintaxe e compilação, sem execução de testes ou validação jogando, conforme orientação do usuário. Ainda sem publicação no Git/Render. A prévia local serve para a revisão do usuário.


## Auditoria posterior

A revisão real no navegador encontrou e corrigiu sobreposições de Canvas, posição do carretel, rótulos duplicados e contador de rodada. Os testes focados de combate também foram executados com autorização de auditoria do usuário. Resultados e limites em `documentation/auditoria-batalha-2026-10-24.md`; a indicação anterior de ausência de testes descreve apenas a entrega inicial.
