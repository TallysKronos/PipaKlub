# Lobby do Pipeiro

Menu de Esc no overworld baseado no rascunho do usuário. Grade 4×2 com bordas ciano, seleção dourada, detalhes de tinta, ícones existentes do jogo e uma faixa de descrição que acompanha foco e mouse. Fundo azul com retícula sobre o mundo pausado.

## Destinos

1. Pipamons: equipe e cuidados existentes; o cartão mostra o parceiro equipado.
2. Itens: inventário existente.
3. Missões: objetivos e estados derivados da jornada salva. A missão de Nina aparece somente após ser aceita.
4. Emblemas: porta-emblemas independente. Fechar restaura o lobby e seu foco.
5. Tamer (Perfil): identidade com Perfil e Histórico. Configurações e a grade de emblemas foram removidas dessa tela.
6. Oficina: consulta das rabiolas encontradas fora do ateliê; dentro do ateliê, usa o fluxo existente de montagem/restauração. Não teleporta o jogador nem permite montagem fora do professor.
7. Salvar: salva a posição atual e confirma sem sair do lobby.
8. Config.: configurações existentes de vídeo, áudio, controles e acessibilidade.

Mapa, Retomar e Sair ao título continuam disponíveis no rodapé. Recursos ainda não obtidos ficam indisponíveis, com explicação; a oficina fica bloqueada durante batalhas.

## Fluxo corrigido

Ao retornar de uma página para o lobby de um parque, a reconstrução reutiliza os assets carregados de forma síncrona. Antes, uma transição assíncrona podia apagar o lobby recém-criado. Para outras transições, o retorno espera a cobertura de carregamento terminar antes de restaurar a pausa.

## Validação

- `lobby_checks.gd`: 66 verificações, zero falhas. Três resoluções, onze acessos, pausa/retomada, destinos, save sem consumo de inventário, emblemas e retorno com foco.
- `pip76_checks.gd`: 82 verificações, zero falhas. Mapas, mochila, configurações e retorno.
- `emblem_case_checks.gd`: 61 verificações, zero falhas.
- `pipeiro_identity_checks.gd`: 60 verificações, zero falhas.
- `identity_layout_checks.gd`: 106 verificações, zero falhas.

Capturas nativas: 1280×720, 1920×1080 e 1024×768. Navegação automatizada, sem alegação de teste de controle físico. Os testes usam armazenamento isolado em `tmp/playtest-humanlike/appdata`.

## Capturas

- `lobby-1280x720.png`, `lobby-1920x1080.png`, `lobby-1024x768.png`.
- `identidade-simplificada.png`: apenas Perfil e Histórico.
- `missions.png`, `workshop.png`: páginas abertas pelos novos acessos.

O pacote interno em `godot/exports/demo-test-2026-10-31/` foi atualizado e executado fora do projeto: menu, mundo, identidade simplificada e lobby renderizados; saída 0 e log de execução sem erros. Evidência: `lobby-pacote.png`. O pacote continua usando o runtime local, sem templates oficiais de release.
