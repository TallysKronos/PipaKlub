# Aplicação ao overworld

Integração local em 18/10/2026. Assets selecionados em `assets/characters/overworld-v1/`; o professor e os cinco rivais usam recortes medidos e âncoras dos pés. Kael, Nozinho, Mikka, as ilustrações de diálogo e as regras de encontros foram preservados. NPCs parados usam poses de repouso e viram na direção do jogador; o ciclo de passo fica disponível ao renderer para deslocamentos futuros.

O professor carrega junto ao quintal; os rivais carregam ao abrir o Morro. Se uma folha falhar, o renderer mantém a arte anterior como alternativa; reabrir o lugar permite nova tentativa. O mesmo renderer entra no mapa completo e no piloto em camadas, mantendo a fila de profundidade existente.

Verificação: build de servidor e Pages concluídos, validação ESM aprovada e 228 testes passaram, incluindo os dois novos testes de assets/renderer. Inspeção no navegador com a demonstração isolada em `127.0.0.1:5206`, sem contas de produção. Professor visto ao lado de Kael no quintal; Zeca e Bia vistos no Morro; sem erros de console nessa inspeção. Evidências em `applied-quintal.jpg` e `applied-morro.jpg`. Não foi feito commit, push ou deploy nesta etapa.
