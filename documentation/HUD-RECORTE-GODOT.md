# HUD Recorte — referência adotada para Godot

A referência visual enviada pelo usuário em 25/10/2026 está preservada em
HUD-Recorte-referencia.html. Ela substitui a proposta anterior Papel em Movimento.

Paleta: nanquim #0B1017, tinta #141E29/#22303F/#33475A, papel #F4E9D2/#D8C9AC,
coral #FF5A36 (rival/ação), ciano #2EC8E3 (jogador/elo), dourado #FFC23D
(recompensa/crítico), folha #6FD08C. Nunito para leitura, Barlow Condensed para
rótulos, Lilita One para títulos, Bangers para efeitos. Fontes locais com OFL.

Implementado: paleta e fontes centrais; família própria de molduras de nanquim,
botões com pontas fixas, foco ciano/papel, ícones de papel dobrado, interruptores
em losango, retícula, quatro adornos ilustrados de pipas/varetas/nós/rabiolas,
faixas de resultado com respingos, energia segmentada e ações com máscara diagonal
de recarga. As artes não contêm textos ou áreas clicáveis.

Aplicação: seleção de jornada, diálogos iniciais com retrato externo e nome
flutuante, equipe, mochila com categorias/lista/detalhe, configurações, controles,
oficina, treino, exploração do parque/Morro e combates selvagens/boss/Morro.
Pausa com cunha diagonal e navegação em escada. Minimap local em losango sem
marcadores de segredos. Área recolhe em 3s e objetivo em 4s; interação contextual.

Os ornamentos foram gerados com image_gen e integrados ao projeto. Os SVGs são
fontes editáveis próprias geradas por scripts/build-recorte-ui.mjs. Manifesto,
prompts e regiões: godot/assets/campaign/ui-recorte/manifest.json. Não há textura
de card completo esticada: molduras usam nove regiões e adornos ficam separados.

Leitura minuciosa e diferenças conscientes da referência estão registradas em
HUD-RECORTE-AUDITORIA.md. Não é uma captura do HTML usada como tela nem uma
declaração de que todas as animações sugeridas nele já existem na campanha.

Continuação em 26/10: transição de tinta de 450ms, dano e lettering em eventos
confirmados, prévia de recompensas com contagem de XP/barra/níveis, e opção
persistente para reduzir animações. Estes efeitos não alteram o relógio do
combate, não bloqueiam input e não escrevem recompensas no save.

As regras de montagem continuam obrigatórias: 9-patch com cortes em trechos retos,
cantos fixos, ornamentos independentes e proporcionais, texto separado da arte,
tamanhos mínimos, foco visível e conteúdo rolável. O HTML é uma referência visual;
seus scripts não foram executados nem tratados como instruções operacionais.
