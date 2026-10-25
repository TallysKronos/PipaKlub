# Veredas ilustradas: navegação revisada

## Primeira árvore independente

A árvore grande da trilha oeste agora usa transparência real e chão reconstruído, sem sua antiga máscara poligonal. A cena reutilizável e a origem das imagens estão em [tree-test/README.md](tree-test/README.md). Botão **Árvore**: inspeção direta; **F4**: ocultar/mostrar apenas essa árvore e conferir o chão limpo. A colisão continua ativa durante esse teste visual. As outras árvores ainda usam os recortes anteriores.

Cena inicial: `res://scenes/illustrated_veredas.tscn`. Execute `godot/Iniciar.ps1` da raiz. O projeto Godot continua experimental e separado do cliente JavaScript e dos seus saves.

## Arte e geometria

O fundo 1536×1024 é a edição ImageGen da referência aprovada, sem personagens nem baús. Origem e prompt em `provenance.txt`. A imagem continua intacta nesta revisão de movimento.

A geometria ativa é `routes-v2.json`. `routes.json` registra a primeira tentativa de faixas estreitas e NÃO é consumido pela cena. Agora o piso usa polígonos de suporte, com obstáculos separados nas raízes, rochas, barranco e canos. As copas não são usadas como colisão; máscaras de primeiro plano com base de profundidade escondem o personagem ao passar atrás das árvores. Algumas áreas ocultas pela ilustração ainda dependem de validação visual de autoria.

O mesmo módulo `scripts/illustrated_ground.gd` responde ao teclado, clique e seguidor. O contato dos pés usa uma elipse de 12×6 px, amostrada no centro e oito posições periféricas. AStar tem células de 4 px e folga adicional de 1,5 px para evitar rotas raspando nas bordas. Conexões diagonais não cortam cantos. O movimento usa subpassos de até 2 px e desliza pelas tangentes dos obstáculos. Clique consome o orçamento inteiro de movimento do quadro, incluindo múltiplos pontos de rota; não há pausa intencional por célula. A suavização só liga pontos com linha livre para os pés.

Rabbito reproduz as pegadas reais, mantendo cerca de 32 px de distância pelo percurso, sem perseguir a posição atual em linha reta. As bases de profundidade e máscaras das árvores foram revisadas. Kael e Rabbito mantêm os sprites/atlas existentes; Nina é a pose estática existente.

## Áreas acessíveis

Entrada, duas margens, mato, duas pontes, mirante, encosta, duas rampas e pátio superior. A liberação do chão superior é exploratória: ainda não incorpora combate ou missão do jogo original. Nina possui diálogo de teste e há um baú demonstrativo, sem economia real. O boss não foi recolocado nesta cena.

## Controles

- WASD/setas ou analógico: movimento. Clique no chão válido: caminhar.
- E/Enter ou A: conversar/fechar diálogo/abrir baú.
- M: visão geral; Esc: pausa; F3: pisos verdes, obstáculos vermelhos e pontos de verificação.
- Botões superiores: atalhos de inspeção.

## Verificação

`godot/Iniciar.ps1 -Test` retorna código diferente de zero se falhar. Verifica dez marcos alcançáveis nos dois sentidos, raízes/pedras/água/barrancos proibidos, segmentos de rota livres e travessia com o controlador real em passos de 1/60 s, incluindo seguidor e velocidade por clique. A sequência passa por Nina, ponte sul, entrada, mirante, pátio e volta à entrada. Os pontos proibidos incluem a face do barranco do mirante, cuja geometria foi corrigida após inspeção do overlay.

`--proof --overview --debug-ground` captura o chão permitido sobre a arte. `--at=x,y` permite inspecionar uma posição em detalhe; `--nina` escolhe a clareira. Os testes não substituem o playtest humano de todas as bordas. Não há persistência, combate, animação da água ou inventário real nesta cena.
