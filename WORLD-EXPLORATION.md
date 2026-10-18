# Exploração local — Quintal e Morro do Sol

## Resultado

O quintal recupera a casa, varanda, pipas expostas, portão, banca, círculo e mural originais, no acabamento de RPG 2D da nova interface. O Morro do Sol tem uma ilustração da mesma família e circulação por patamares, escadas e acessos externos. A escada de entrada da laje foi corrigida na arte antes do traçado de navegação.

O planejamento anterior à geração está em `WORLD-ART-DIRECTION.md`. Fundos finais: `assets/world/identity-v2/quintal.png` e `morro.png`. Prompts completos e correção localizada: `assets/world/identity-v2/prompts.json`. Foi usada a ferramenta integrada image_gen. O original da primeira geração do morro permanece em `morro-source.png`, fora do allowlist de arquivos do jogo.

## Controles e limites

Clicar/tocar no chão escolhe o ponto mais próximo das passagens cadastradas. “Caminhar até…” oferece os destinos também por teclado. O botão Interagir, ou E quando não há campo de texto ativo, abre a função do lugar próximo. O passeio pode ser pausado/retomado nas configurações. Movimento reduzido troca posições sem animação de deslocamento.

Os grafos em `manifest.json` determinam as conexões. Dijkstra escolhe o caminho; cliques distantes não deslocam o personagem em linha reta por casas. O parceiro acompanha o histórico do mesmo percurso. A câmera acompanha o personagem e respeita as bordas; o quintal tem um enquadramento mais aberto em desktop. A escala de Kael e do parceiro acompanha a escala arquitetônica de cada fundo. Professor, Nozinho e personagens são desenhados por ordem dos pés no chão.

Em celular na vertical, uma faixa inferior abriga destinos e atalhos. A câmera usa a altura real da janela de exploração, mantendo o personagem visível também na borda inferior do mundo.

Esta é uma exploração local com fundos ilustrados e caminhos definidos, não um mundo multiplayer sincronizado ou uma malha completa de colisão por pixel. NPCs de combate ainda são representados por pontos de interação; não foram criados sprites humanos novos para os cinco adversários. Não há interiores ou novas missões inventadas.

## Progressão e batalhas

O atlas da cidade abre a exploração ao entrar no Morro do Sol. Beira-Mar e Campanários mantêm suas telas existentes. O menu Trilhas abre o morro quando ele é o próximo distrito da jornada; depois mantém o fluxo de outros bairros.

O bairro pode ser percorrido livremente: a ordem dos duelos não bloqueia a passagem pelas ruas. Os cinco encontros continuam bloqueados pelo progresso real. A interação mostra o briefing antes da batalha; iniciar usa o endpoint e as regras anteriores. Não há concessão de vitórias, XP, moedas ou itens pela caminhada. O nome da campeã permanece oculto enquanto seu encontro está bloqueado.

Voltar de uma partida do morro preserva a posição da exploração. Sair para a coleção ou outro menu suspende o passeio; retornar retoma o lugar. Trocar de conta limpa os personagens, trajetos e cena anteriores. Os novos cenários usam hash, cache e allowlist e entram no build estático.

## Verificação e prévias

`world-navigation.test.mjs` verifica conexão dos destinos, aderência de cada trecho às arestas, deslocamento e seguidor, limite de tempo, movimento reduzido e câmera. `first-flight.test.mjs` cobre entrada pelo atlas, encontros bloqueados, briefing, retorno e troca de usuário. A suíte completa passou em 188 testes antes do ajuste final de escala do parceiro; os testes específicos foram repetidos após os ajustes.

Prévia sem conta real: `/menu-audit?screen=courtyard&w=1104&h=650` ou `/menu-audit?screen=world-morro&w=1104&h=650`. Esta entrega não aplica migração nem publica no Render.

A revisão manual percorreu a entrada e a laje, abriu o briefing de Zeca sem iniciar batalha e conferiu bloqueios. As 14 verificações de geometria (dois lugares em sete tamanhos de 320×568 a 1440×900) terminaram sem erros detectados. Capturas e relatório ficam em `art/world-identity-v2/`.
