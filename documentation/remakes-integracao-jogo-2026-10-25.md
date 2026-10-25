# Integração dos remakes aprovados

As dez espécies recebidas até `f7d08be` substituem os atlas ativos: Nozinho, Guaravento, Micofolha, Capimansa, Tatutrama, Flautrevo, Trinca-brasas, Alvaneve, Chaspiral e Hiponilo. As fontes aprovadas não foram reconstruídas nem alteradas. O pacote `assets/creatures/remakes-soulgen-v2/` contém atlas de batalha, acompanhamento, retratos derivados e procedência. O exportador reproduz todas as ações com o sampler/renderizador do Studio e preserva `artTransform` e dimensões manuais.

Integração pelo atlas global e pelos manifestos de retratos e acompanhantes: Dex, coleção, Oficina e batalha usam a mesma arte ativa. Nozinho recebeu reprodução com os tempos do atlas, enquadramento fixo nas animações de batalha e a pose do remake no banner de assinatura. As conversas existentes continuam funcionando com os aliases greet/happy.

Conferido: exportação sem poses tocando a borda, comparação visual da prancha das dez espécies, Nozinho na Pipa Dex, novos retratos de Guaravento/Micofolha/Capimansa/Tatutrama/Alvaneve/Chaspiral/Hiponilo e seleção de Habilidade/Vitória do Hiponilo. Evidências em `artifacts/remakes-integration/`. Revisão no navegador em 1131 × 884. Não foi homologada cada animação de cada espécie em batalha ou todas as direções no mapa.

Builds Worker e Pages concluídos, com os novos PNGs e URLs com hash. Não houve suíte automatizada, mudança de regras ou banco, concessão de criaturas, commit, push ou publicação nesta entrega. O servidor local permanece em http://127.0.0.1:5262/.
