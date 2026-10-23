# Correção das fachadas e dos interiores de serviço

## Problema corrigido

A ampliação da Rua dos Ventos preservou fachadas antigas cujas inclinações não acompanhavam o chão. A distribuição do professor e da loja também continuava baseada no renderer legado, com posições e apoios independentes da nova grade. A presente revisão substitui esses três pontos; a ampliação da rua continua válida.

As fachadas da casa de Kael, do professor e da loja são exportadas de faces ortográficas na grade 64×32×32, com pinturas planas produzidas por image_gen. Bases, soleiras e quinas compartilham os mesmos eixos; portas têm pivôs medidos. As fachadas usam largura nativa, sem ajuste arbitrário para preencher uma caixa e sem deformação por coluna. A pegada sólida na rua deriva da mesma grade e da posição da porta, usando o adaptador da projeção legada da rua (32/0,82 unidades de mapa por eixo da célula). Fontes, prompts e três projetos editáveis do Iso Studio estão em `art/village-grid-v2/`.

## Interiores

Os dois ambientes têm 14×11 células, deixando o centro livre. Biblioteca e estudos ficam no fundo da casa do professor; mesas e baú ficam nas laterais. A loja tem balcão, prateleiras de linhas e papéis, bancada e expositor de pipas. Janelas e estudos de parede usam seus planos correspondentes. O professor e Nozinho têm apoios explícitos na mesma planta das colisões.

`src/service-interiors.js` fornece o projeto, os móveis, as pegadas e os mapas Tiled. `src/service-isometric.js` desenha as imagens nativas, ordena por pegadas, preserva a inversão de cliques e aplica transparência a objetos que encobrem o jogador. Os dois ambientes usam a mesma projeção do quarto/sala. IDs das cenas, ações e retornos para a rua são preservados; posições antigas fora do piso usam a recuperação existente para a entrada segura.

O texto da bancada da loja agora explica materiais e rabiola colocada por último, em vez de encaminhar o jogador à invocação antiga por constelação. Não foi criada mecânica nova nem alterado progresso, inventário ou recompensa.

## Verificação

- `village-grid.test.mjs`: quatro testes de entrega nativa, bases 2:1 medidas, hash do PNG auditado, pivôs de porta, projetos do Studio, posições/colisões, rotas com parceiro, câmera e cliques.
- `street.test.mjs`: pontos de colisão do professor/loja passaram a vir dos móveis reais da planta nova, preservando a verificação de bloqueio.
- `village-runtime.test.mjs`: 59 imagens registradas com URLs versionadas, dimensões e cópias do build.
- Verificação final após o ajuste da pegada sólida das fachadas: 51 testes direcionados aprovados, zero falhas, em `.local/village-grid-targeted.log`.
- Builds Worker e Pages concluídos. Resultados de testes direcionados e da suíte completa em `.local/village-grid-targeted.log` e `.local/village-grid-full-tests-network.log`.
- Suíte completa: 412 aprovações em 413 testes; permanece a falha anterior da conferência dos móveis da sala de Kael. A execução dos testes de servidor exige conexões a portas locais; a tentativa restrita registrou EACCES, resolvido ao executar com essa permissão.
- Capturas no navegador em `documentation/evidence/village-grid-v2/`. A revisão usa conta e banco locais isolados; não acessa o Supabase de produção.
- Revisão manual: entrada e retorno pela casa do professor, caminhada com Rabbito, conversa com Sr. Assis sem repetir o treino; entrada na loja, catálogo do balcão sem compras e acesso à bancada. A câmera e a inversão dos cliques usam a planta nova.

A pendência geométrica já registrada para móveis da sala de Kael é independente desta revisão e continua em `documentation/sala-kael-isometrica.md`. Não há push ou deploy nesta entrega. A câmera estreita tem cobertura automatizada; não houve teste em telefone físico.
