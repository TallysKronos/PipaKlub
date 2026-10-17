# PIP-8 — Visuais de linha e acesso por conta

Em Minha conta → Visuais de linha, jogadores autenticados podem comprar e equipar cores, um padrão pontilhado e brilho. Catálogo inicial: clássica grátis, azul/coral por 30, menta por 40, pontilhada por 60 e dourada por 100 moedas das Trilhas. Compra não equipa automaticamente; a seleção é persistida na conta. Não há revenda ou transferência.

O preço vem do banco. Débito, propriedade e recibo são atômicos, com os mesmos bloqueios de carteira usados pelas Trilhas. Reenvios e duas compras simultâneas não cobram o mesmo visual novamente nem deixam saldo negativo. Respostas antigas das Trilhas não devolvem moedas gastas, pois o cache compara revisões. Há uma cópia confirmada do saldo e as compras aguardam o envio de resultados pendentes.

As moedas continuam sendo de um modo offline, incluindo saves antigos importados. A confirmação do saldo não comprova a execução de vitórias offline. A decisão nesta feature é aceitar essas moedas para cosméticos vinculados à conta, sem valor de troca ou efeito competitivo. Não usar esse mecanismo como comprovação para moeda paga, ranking ou concessão de pipas/rabiolas.

## Combate e online

O servidor inclui somente o visual equipado pela conta ao reservar entrada em sala; não aceita cor/padrão arbitrário no pedido do jogador. A função anterior de reserva é preservada como helper privado, incluindo bloqueios de trocas e equipamento. O visual viaja nos snapshots e na previsão de rede. Trocar de visual durante uma partida é bloqueado.

O desenho altera apenas o traço base. Permanecem iguais: geometria, dano, velocidade, energia, cooldowns, faixa vulnerável, centro dourado e ponta segura. Identificação dos jogadores mantém suas cores. O brilho é estático e desativado no modo leve.

## Regra de acesso solicitada

Visitantes podem usar treino/tutorial e jogar partidas padrão casuais por rodadas, rápidas ou por convite. Trilhas, Dex e funcionalidades da conta exigem login. Modalidades especiais e Vale pipa são bloqueadas também no servidor para visitantes. A seleção de formato/regra fica travada no padrão, e os botões restritos levam ao formulário de entrada/cadastro. Regras e privacidade continuam acessíveis.

Corrigida também a janela de convite, que agora fecha quando a partida começa, liberando os gestos na arena.

## Publicação e rollback

1. Aplicar `supabase/migrations/010_line_cosmetics.sql` depois de 001–009. Não executar duas vezes o arquivo bruto; usar o controle de migrações.
2. Publicar servidor e frontend juntos. Nenhuma variável secreta nova é necessária.
3. Conferir compra, saldo, equipamento e o visual visto pelo segundo jogador. Testar um visitante criando uma sala padrão e sendo impedido de acessar modos especiais.

Não houve migração nem deploy de produção. O ambiente local aplica 010 somente no banco isolado. Ana recebe 200 moedas de demonstração com uma operação fixa e idempotente, exclusiva de `scripts/local-trades.mjs`, sem efeito em produção.

Para rollback, voltar o aplicativo anterior e manter as tabelas, recibos e carteira. O wrapper da reserva é compatível com o contrato anterior; não apagar recibos ou reembolsar automaticamente.

## Validação

90 testes passaram. Casos incluem autenticação, permissões, preço forjado, saldo insuficiente, compras concorrentes, propriedade por conta, replay, bloqueio em partida, snapshots/previsão, física inalterada, saldo após resposta antiga e restrições de visitante. Builds de servidor/Pages e validação do artefato passaram. Compra e equipamento conferidos na UI local; linha coral observada pelo segundo jogador numa sala em tempo real. Visitante testado solicitando Trilhas e criando um convite padrão.

Esta branch parte do PR #4 das Trilhas na conta (dependente dos PRs #3 e #2). Sem merge/deploy automático.
