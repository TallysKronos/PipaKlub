# Identidade do Pipeiro — versão 2

**Atualização posterior:** a navegação foi simplificada a pedido do usuário: a identidade agora contém somente Perfil e Histórico. Emblemas e Configurações têm acesso direto pelo Lobby do Pipeiro. Ver `../lobby-v1/README.md` e `../lobby-v1/identidade-simplificada.png`. As capturas desta pasta documentam a revisão anterior.

Implementação nativa baseada no rascunho do usuário: cabeçalho angular ciano, moldura azul com ferragens laranja, navegação lateral, foto de papel com fita, nome/registro, nível e barra de XP, dados da jornada, cinco posições de equipe e resumo da coleção. A arte do Kael e os ícones existentes foram reutilizados; texto e controles permanecem independentes da decoração.

## Dados e navegação

- Perfil: nome e registro reais, moedas, nível/XP do tamer, tempo salvo, emissão da identidade, local e marco atual.
- A barra mostra o progresso dentro do nível vigente; nível 100 informa nível máximo.
- Time: até cinco parceiros do save, com retrato e nível calculado pela curva oficial dos Soulmonsters.
- Coleção: espécies presentes na equipe, emblemas conquistados e documentos/insígnias permanentes. Não apresenta um total de Pokédex ou moeda premium que o jogo não possui.
- Conquistas: doze posições, estado real de cada emblema, detalhes e abertura do porta-emblemas existente.
- Histórico: somente marcos suportados por dados do save, sem inventar capítulos ou datas de eventos.
- Configurações: abre a página nativa já existente. Voltar/Escape mantém o fluxo de retorno da campanha.

O retrato continua sendo Kael, conforme o personagem jogável atual; o nome fictício e os valores do rascunho não foram copiados para o save. Não foi acrescentada edição de nome ou loja de moedas.

## Verificação

- `pipeiro_identity_checks.gd`: 78 verificações, zero falhas.
- `identity_layout_checks.gd`: 125 verificações, zero falhas.
- `emblem_case_checks.gd`: 60 verificações, zero falhas.
- Renderização nativa conferida a 1280×720, 1920×1080 e 1024×768; capturas das duas primeiras resoluções nesta pasta.
- Nome longo com reticências e tooltip, equipe com cinco parceiros, nível máximo, conquista e posição bloqueada.
- As abas exibem somente uma página de cada vez; textos visíveis e botão de retorno permanecem na janela.

As verificações de navegação são automatizadas. Não representam teste de controle físico. A composição usa uma referência 1280×720 escalada uniformemente dentro da janela, com Containers para o conteúdo interno e margens preservadas.

## Capturas

- `perfil-1280x720.png` e `perfil-1920x1080.png`.
- `conquistas-1280x720.png` e `historico-1280x720.png`.
- `perfil-nome-longo-equipe-cheia.png`.

O pacote local `godot/exports/demo-test-2026-10-31/` foi atualizado. O executável carregou o PCK fora do projeto e renderizou a nova identidade, com saída 0 e sem erros no log de execução. Evidência: `perfil-pacote.png`. Continua sendo o pacote interno com runtime local, sem templates oficiais de release.
