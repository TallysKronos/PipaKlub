# Auditoria do Kael — revisão 2

## Problemas encontrados

1. Braços estreitos e afastados do tronco, com contornos fechados no ombro. A auditoria de pivôs da revisão 1 aprovava a conexão lógica sem verificar a arte.
2. Alças douradas repetidas nas peças dos braços e no corpo, reforçando a aparência de partes soltas.
3. Perfil com encaixe circular pintado no corpo, exposto no extremo do gesto mesmo quando havia pixels de sobreposição.
4. Resíduo de alpha baixo no fundo de um cabelo gerado, visível na prancha.
5. Só existia uma direção; não era possível avaliar identidade e escala entre vistas.

## Resultado

Articulação reposicionada, peças com sobreposição, bases de roupa repintadas e gestos menos amplos. Frente, costas, perfil direito e esquerdo espelhado disponíveis no Studio. Oito camadas, 45 atlas de vistas e 64 aparências. Recortes por peça mantêm seleção e foco utilizáveis no editor.

Comparação sincronizada: `http://127.0.0.1:5245/kael-review.html`. É uma ferramenta de revisão com as mesmas imagens, amostragem e renderer do Studio. Permite selecionar ação, alternar aparência, pausar, reiniciar e buscar um instante comum às quatro vistas.

31 testes do Studio passaram. Verificação raster independente: 144 casos de sobreposição em duas roupas e quatro direções; nenhum caso com separação, e um braço deliberadamente deslocado foi detectado pelo controle negativo. O relatório vincula SHA-256 dos PNGs e do preset. Isso não transforma sobreposição em aprovação artística automática.

Inspeção no navegador: repouso, caminhada nas quatro vistas, extremo do aceno de perfil, costas com pele escura/roupa terracota/cabelo ondulado e reabertura real do JSON portátil. O torso foi repintado depois de o gesto revelar o falso encaixe. A comparação final permite nova revisão pelo usuário.

Exportação: 480 quadros, PNG transparente 2048×3840, células de 128 px a 12 FPS, 24 sequências com metadados. Fontes, prompts, projeto portátil e reprodução: `art/soulgen/keys/kael-v2/README.md`.

## Limites

Não integrado ao overworld nem à persistência de aparência. Braço ainda é uma única articulação: aceno e comemoração contidos; gestos amplos pedem antebraço separado. Rosto neutro, sem variantes expressivas nesta etapa. Perfil esquerdo espelhado pressupõe roupa sem detalhes laterais exclusivos. Não houve push nem deploy.
