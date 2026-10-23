# Parque isométrico integrado ao jogo

## Implementação

Jardim das Pipas e Clareira do Papel usam a família park-isometric-v1 no cliente principal, sem parâmetro de prévia. Copas, birutas, bandeirolas e pipa usam o sampler real do Soulgen. Piso contínuo e capim são Canvas; objetos e personagens usam pivôs nos pés e profundidade projetada. As duas cenas preservam seus habitats, identidades de encontro e saídas originais.

Os cliques/toques voltam de coordenadas projetadas para o mapa ortogonal. Setas, WASD e analógico recebem a transformação inversa com velocidade normalizada. A câmera acompanha os pés e responde à largura disponível. Placa, coreto e bancos possuem alvos de interação; o teto do coreto abre visualmente quando o jogador entra. Cada banco tem sua própria aproximação. Sr. Assis aparece somente no Jardim, que contém o coreto.

Parceiro vem da coleção/equipamento autenticado. O caminho continua usando a navegação do mapa; o teste de checkpoints corrigiu também o histórico estacionário duplicado que sobrepunha parceiro e protagonista. Save, autosave, encontros e retorno da batalha continuam no código e RPCs existentes. Não há nova migração nem concessão local de itens no cliente.

## Verificação realizada

- 382 testes passaram no npm test, incluindo o novo park-runtime.test.mjs, builds de servidor/Pages, rotas, assets, controles e regressões.
- Auditoria estrutural padrão do mundo passou (essa auditoria cobre o Quintal; as rotas dos parques são verificadas nos testes próprios).
- No navegador, cliente real com autenticação e PostgreSQL local isolado: entrou pelo menu, clicou na placa e abriu mapa ao chegar; caminhou até Assis e conversou; passou do Jardim para a Clareira; chegou ao banco leste e descansou.
- Save manual confirmado pelo servidor local e restaurado na Clareira com Rabbito equipado. Autosave também restaurou a cena depois de recarregar o cliente.
- Percorrer o capim disparou encontro natural contra Mata Verde. Fugir confirmou o estado fled e +0 XP de recompensa do encontro. Voltou à posição do parque e Rabbito retomou o acompanhamento.
- Inspeção visual em 1280×720 e 768×885. Câmera/inversa também têm teste numérico em 390×700; não houve teste em aparelho físico nem controle físico.

Fixture reproduzível: LOCAL_TRADE_PORT=5242, LOCAL_TRADE_SLOT=park-isometric-audit e LOCAL_PARK_FIXTURE=1 ao iniciar scripts/local-trades.mjs; conta /local/ana. O servidor de produção não importa esse adaptador. Nunca executar fixture contra banco de produção.

## Limite de escopo

A tarefa de três fibras e seu kit continuam como estudo local da prévia. Não foram transformados em recompensa de campanha nem apresentados como itens reais da conta. O parque integrado usa as orientações, descanso e progressão de encontros já existentes.
