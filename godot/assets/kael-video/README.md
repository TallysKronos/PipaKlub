# Kael · família derivada de vídeo

Origem e quadros selecionados: `art/characters/kael-video-eight-directions-v1/` e `art/characters/kael-video-jump-v1/`. Referências do Kael fornecidas/aprovadas pelo usuário; vídeos gerados com MiniMax H3 local. Ver os manifestos e workflows dessas pastas para rastreabilidade, sem atribuir licença a conteúdo legado.

Filtro nearest, transparência binária, paleta comum de 32 cores. Caminhada: 64×96, pivô 32,94. Salto: 96×112, pivô 48,110, mesma escala do corpo. O espaço transparente adicional evita cortar os braços.

Consumidor: `scripts/kael_video_avatar.gd`, compartilhado por `scripts/avatar.gd` nas cenas da campanha e nos protótipos que usam esse avatar. Quarto, ateliê, bairro, trilha, clareira, Veredas e Morro usam caminhada em oito direções. Os controladores preservam os pontos de apoio; a compensação de corpo de 1,12 mantém a altura aproximada do avatar anterior, enquanto as Veredas conservam sua escala já revisada de 0,78.

`jump.json` registra os tempos da animação sem loop; deslocamento e altura são controlados no mapa. O salto continua limitado aos dois barrancos autorizados nas Veredas. `item.json` descreve a comemoração dos recebimentos confirmados nessa área. Escadas reutilizam o ciclo de passos direcional; não há uma animação nova de mãos agarrando uma escada vertical.
