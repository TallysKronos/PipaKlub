# Soulmonsters no overworld — 21/10/2026

## Entrega

Sete folhas originais de acompanhamento, produzidas com image_gen integrado a partir das identidades existentes e da câmera chibi de Kael. 56 desenhos no total, em PNGs com alpha real. Pacote: `assets/creatures/overworld-v1/`; prévia: `art/overworld-companions-v1/index.html`.

Cobertura da abertura e do Morro: Rabbito, Carcará, Mata verde, Azulão, Raio de sol e Nozinho. Nozinho é residente/participante do treino e não possui modelo equipável no catálogo atual. Nevagume foi incluído como compatibilidade adicional para coleções anteriores. Não é uma nova recompensa da demo. Espécies históricas de eventos e bairros posteriores mantêm o fallback anterior; esta entrega não cria formas de adquiri-las.

## Funcionamento

- Direções Sul/Oeste/Leste/Norte desenhadas, com seleção corrigida pelo manifesto quando a ordem visual gerada difere da pedida.
- Repouso de um quadro e locomoção de duas poses por direção, a 200 ms por pose; escala fixa por espécie e âncoras medidas.
- Seguidor usa o histórico de caminho já existente; sua orientação segue seu próprio deslocamento e se mantém quando para. Uma curva do protagonista não gira antecipadamente o companheiro.
- O histórico inicial incorpora o ponto válido de surgimento do parceiro para evitar o salto até a posição inicial do protagonista no primeiro movimento.
- Nozinho na casa do professor usa o mesmo pacote e olha na direção do jogador.
- Novos PNGs carregados sob demanda, com fallback para o renderizador anterior se ainda não carregaram ou se a espécie não está no pacote. Tentativas com falha ficam memorizadas para não disparar downloads a cada frame; recarregar a página permite tentar novamente.
- Arte de combate, aquisição, status e recompensas permanecem sob seus contratos existentes.

## Validação

Geometria: sete PNGs 1536×1024, oito recortes válidos cada, alpha transparente e margens mínimas verificadas pelo script `scripts/build-overworld-companions.py`. O script mede/copia e não altera os pixels gerados. Evidência em `validation.json`, com hashes SHA-256.

Build Worker e Pages executados. A suíte existente teve 295/297 testes aprovados no sandbox; os dois testes WebSocket falharam por EACCES no loopback e passaram ao serem repetidos com acesso local. Após o ajuste final do histórico inicial, os 14 testes direcionados de companheiros, atores, navegação e estrutura passaram. O novo arquivo de três testes entrou no comando `npm test` sem remover os scripts desktop existentes.

Inspeção no navegador: prévia com todas as folhas, quatro direções em escala normal/ampliada, controle de pausa e caminhada de Kael em curva usando o renderizador de runtime. Transparência e leitura conferidas sobre fundo claro e cenário existente. Revisão local dentro do jogo com conta Ana Local, em banco PGlite isolado `.local/overworld-companions-2026-10-21`, sem Supabase de produção. Fixtures de coleção e progresso foram preparadas exclusivamente nesse banco para inspeção visual; não são evidência de conquista legítima da abertura.

## Limites

Evidências salvas: `art/overworld-companions-v1/preview-local.png` e `art/overworld-companions-v1/nozinho-professor-local.png`. No jogo local, Rabbito percorreu a Rua dos Ventos até a loja; Nevagume foi equipado pela coleção e percorreu o caminho até o professor, com Nozinho visível no interior. As sete espécies foram examinadas nas quatro direções na prévia; isso não equivale a percorrer todas as áreas com todas elas.

Os ciclos são curtos, com duas poses; não representam corrida com quatro apoios nem voo completo. O acabamento segue sujeito à aprovação artística, particularmente consistência de volume e simplificação nos tamanhos pequenos. Não houve publicação, commit, migração ou concessão em contas reais. O pacote não cobre todo o catálogo histórico.

## Arquivos principais

- `src/world-actors.js`: seleção e desenho dos sprites, direção do seguidor e preparação de histórico inicial.
- `src/world-client.js`: integração no mapa e no residente Nozinho.
- `scripts/art-build.mjs`, `src/static-assets.js`: manifesto, cache e distribuição.
- `world-companions.test.mjs`: orientação, surgimento, recortes, âncoras, fallback, seleção e entrega de PNGs.
- `scripts/preview-overworld-companions.mjs`: servidor de revisão com lista restrita de arquivos e sem endpoints de conta.
- `assets/creatures/overworld-v1/prompts.json`: prompts e referências por espécie.
