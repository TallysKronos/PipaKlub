# Refinamento do percurso até o guardião

Implementação local: duelos opcionais com XP única, descanso funcional, objetivos por região, explicação do nível recomendado e indicadores de estrutura/XP no HUD. Curva de nível e XP dos selvagens preservadas. O elenco dos cinco duelos reaproveitados foi rejeitado pelo usuário; os novos conceitos estão em `art/characters/parque-pipeiros-v1/` e ainda precisam de aprovação e produção dos sprites.

Antes, o caminho dependia de cerca de 49 vitórias selvagens para 1260 XP (Nv.8). Agora as seis primeiras vitórias dos duelos somam 1260 XP. Os encontros de exploração acrescentam progresso, sem ser necessários para fechar a lacuna. Ignorar os duelos continua permitido; enfrentar o guardião abaixo do recomendado também.

Recompensas únicas: Assis 70, segundo duelo 110, terceiro 170, quarto 220, quinto 300, sexto 390. Não há XP ao conversar, descansar, fugir, perder ou repetir vitória já registrada. Treinadores não derrubam rabiolas. Os duelos avançam de adversário Nv.2 a Nv.7, com defesa, puxão e esquiva progressivos; os selvagens mantêm a IA anterior.

Bancos recuperam linha e estrutura de toda a equipe, sem moedas ou XP, com validação de proximidade e altura. Parceiro incapacitado não dispara novos encontros aleatórios. Objetivos indicam descanso, Nina, treino local, avanço, coleta separada da rabiola e devolução. A tela do boss informa nível atual e recomendado, preservando a decisão do jogador.

## Evidência

- Simulação com seis duelos + 12 selvagens: Nv.8 com 1568 XP antes do boss; vitória no guardião, coleta da rabiola e devolução à Nina.
- Simulação sem encontros aleatórios, descansando nos bancos entre desafios: seis vitórias únicas dão exatamente 1260 XP, Nv.8; resgate completo testado.
- Testes de jornada, primeira recompensa, repetição, recuperação, proximidade, altura, serialização e recarga por disco.
- Testes existentes: campanha 206; progressão 423; pacing 473; fluxo do jogador 7. Sem falhas nas verificações funcionais executadas. O teste antigo de fluxo ainda emite aviso de recursos em uso ao encerrar.
- Revisão nativa de oito estados em 1280×720, 18 verificações sem falhas; `ui-report.json`. Diálogo pausa a exploração, cancelar devolve o controle, treino sobrevive à recarga do save, descanso cura e aviso do boss usa o nível real.

As capturas usam saves fictícios em `tmp/`, sem tocar nos slots do usuário. Simulação automatizada e revisão visual não equivalem a uma sessão humana completa nem garantem o mesmo ritmo para todos os jogadores. O começo narrativo não recebeu novos cortes ou cutscenes nesta revisão; seus testes de fluxo foram reexecutados.
