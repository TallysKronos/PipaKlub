# Kael no jogo — integração e jogabilidade

O avatar compartilhado agora usa os sprites derivados de vídeo: oito direções, filtro nearest, pivô nos pés e paleta comum. Não compõe o cabelo e as partes do avatar antigo por cima. Quarto, ateliê, bairro, trilha, clareira, Veredas e Morro foram exercitados com seus controladores reais.

O ciclo avança durante os passos e volta ao repouso ao parar. No quarto, pressionar movimento contra a parede não mantém a caminhada. A direção segue o deslocamento projetado no chão, sem deixar a altura de uma rampa alterar a orientação. A compensação de escala de 1,12 preserva a altura aproximada anterior; Veredas mantém 0,78, já revisada nos lotes de salto e item.

Foi corrigido um erro ao sair de uma cena durante a encenação: a verificação de validade agora aceita a referência liberada antes de tentar usá-la como nó. Não houve alteração da geometria, colisões, recompensas ou progressão.

## Validação

- `godot/tools/kael_gameplay_review.gd`: 231 verificações, zero falhas, sete cenas; movimento em oito direções, parada, pausa, apoio e escada urbana nos dois sentidos. Resultado em `review.json`, capturas 1280×720 e sequência `stair-*`.
- `godot/tests/campaign_view_checks.gd`: 30 verificações, zero falhas.
- `godot/tests/player_flow_checks.gd`: sete verificações, zero falhas.
- `park_landscape_checks.gd`: sem falhas.
- Revisões nativas `ledge_jump_review.gd` e `item_receipt_review.gd`: saída zero após a integração global.
- Modo interativo com `--verify-kael-playtest`: troca por F1, criação do perfil isolado, recompensa real do baú e início da comemoração confirmados (`pass=true`). O argumento é exclusivo para não acionar os testes antigos de `--smoke` de outras cenas.

`kael-escada.gif` mostra a passagem pela escada no jogo; `cenas.png` reúne as cenas. Os testes cobrem os percursos descritos, não todas as combinações da campanha.

## Teste interativo isolado

Execute `tools/overworld/open-kael-gameplay.ps1`. O lançador usa `godot/tools/kael_gameplay_play.gd` e cria um perfil fictício em uma pasta absoluta `tmp/kael-playtest-*` deste projeto, sem carregar o save pessoal.

WASD/setas movimentam; E/Enter interagem; Esc pausa. F1 troca/reinicia o cenário entre bairro, trilha, clareira, Veredas, Morro, quarto e professor. Nas Veredas, F2 posiciona perto do baú do mirante para testar o recebimento e os barrancos. F1 reinicia o estado fictício do cenário.

As escadas usam o ciclo direcional de passos existente. O salto permanece nos dois barrancos explícitos das Veredas, e a comemoração usa os recebimentos confirmados já integrados; não foram geradas novas animações neste lote.
