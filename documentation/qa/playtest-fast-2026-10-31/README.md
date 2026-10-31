# Verificação rápida da jornada — 31/10/2026

Base: 4a769304, branch codex/integracao-bosque-kronasta. Saves isolados. Teste automatizado da lógica e interfaces; não equivale a um jogador humano completando a campanha.

## Bloqueio encontrado e corrigido

Nilo não era criado: a âncora (32,39) estava distante demais do chão válido para o resolvedor de posição. Movida para (32,35), junto à trilha da Clareira. A conferência confirma suporte, acesso desde a entrada, conversa segura e início do duelo. IDs de save e recompensas preservados. O teste agora encerra com falha quando um duelo não inicia, em vez de abortar por acesso a encounter inexistente.

## Resultados

- Rota sem aleatórios: 91 verificações; zero falhas. Seis vitórias rendem 1260 XP e nível 8. Níveis após cada treinador: 2, 3, 4, 5, 6, 8.
- Rota mista: 115 verificações; zero falhas. Doze encontros adicionais, 1568 XP, nível 8.
- Ambas: batalhas simuladas por comandos, descanso, Lacertubo, coleta separada da rabiola, entrega à Nina, persistência e recarga das recompensas sem duplicação. A rota usa posições de interação para testar serviços; não executa toda a caminhada pela interface.
- Ritmo/encontros: 433 verificações; zero falhas.
- Curva de XP e migração: 423 verificações; zero falhas.
- Cuidados/reparos: 25 verificações; zero falhas.
- Filme do Lacertubo: 15 verificações; zero falhas.
- Pausa/retorno e estados da interface: 7 verificações; zero falhas. A suíte antiga ainda avisa sobre recursos não liberados ao encerrar.
- Fluxo de batalha: 797 verificações; zero falhas. Rodado com cópia temporária que carrega o front-end depois dos autoloads para evitar o erro de PixelgenSprites do runner antigo.

Total: 1906 verificações aprovadas. Não inclui execuções preliminares que falharam. Logs em tmp/playtest-humanlike/. Captura renderizada 1280x720: nilo-supported.png.

## Leitura de ritmo e diversão

A rota autoral oferece alternativa ao grind: seis duelos distintos bastam para o nível recomendado, sem exigir 49 encontros comuns. A simulação não mede tempo humano nem prova que esses duelos sejam divertidos. O controlador de combate consulta o estado exato do inimigo e vence Lacertubo até no nível 1; isso é indício para um próximo teste de dificuldade com comandos menos precisos, não motivo suficiente para aumentar atributos agora.

Na captura da Clareira, a vegetação do primeiro plano encobre quase todo o Kael na aproximação sul de Nilo. O NPC continua visível e a interação funciona, mas a leitura do jogador piora. Registrar para refino de oclusão. Não redesenhado neste passe rápido.

O início até a oficina não foi novamente percorrido integralmente. O runner antigo de jornada ainda presume o mapa antigo da rua. Abertura/vila têm a cobertura renderizada entregue em playtest-humanlike-2026-10-30. Avaliação humana de diversão, teclado em tempo real e percurso integral continuam pendentes.
