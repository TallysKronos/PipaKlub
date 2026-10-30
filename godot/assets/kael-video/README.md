# Kael · família derivada de vídeo

Origem e quadros selecionados: `art/characters/kael-video-eight-directions-v1/` e `art/characters/kael-video-jump-v1/`. Referências do Kael fornecidas/aprovadas pelo usuário; vídeos gerados com MiniMax H3 local. Ver os manifestos e workflows dessas pastas para rastreabilidade, sem atribuir licença a conteúdo legado.

Filtro nearest, transparência binária, paleta comum de 32 cores. Caminhada: 64×96, pivô 32,94. Salto: 96×112, pivô 48,110, mesma escala do corpo. O espaço transparente adicional evita cortar os braços.

Consumidor: `scripts/kael_video_avatar.gd`, compartilhado por `scripts/avatar.gd` nas cenas da campanha e nos protótipos que usam esse avatar. Quarto, ateliê, bairro, trilha, clareira, Veredas e Morro usam caminhada em oito direções. Os controladores preservam os pontos de apoio; a compensação de corpo de 1,12 mantém a altura aproximada do avatar anterior, enquanto as Veredas conservam sua escala já revisada de 0,78.

`jump.json` registra os tempos da animação sem loop; deslocamento e altura são controlados no mapa. O salto continua limitado aos dois barrancos autorizados nas Veredas. `item.json` descreve a comemoração dos recebimentos confirmados nessa área. Escadas reutilizam o ciclo de passos direcional; não há uma animação nova de mãos agarrando uma escada vertical.

## Repouso e corrida

`kael-idle-eight.png` e `kael-run-eight.png`: mesma grade 64×96, pivô 32,94, oito colunas de fases e linhas S, SO, O, NO, N, NE, E, SE. Idle de 2.200 ms com pés fixos e respiração discreta; corrida de 640 ms com oito poses próprias, braços flexionados e voo. Fontes editáveis, referências e workflows em `art/characters/kael-locomotion-v1/`.

Na exploração, segurar Shift corre a 1,8×; o botão do HUD ou L3 alterna o modo. A tecla acompanha o remapeamento de esquiva, mantendo essa ação na batalha. Caminhada, colisões e geometria são as existentes. O parceiro acompanha os passos aceitos do jogador. Item, salto e escadas preservam suas animações prioritárias; diálogos, pausas e movimentos de cutscene não recebem o multiplicador.
