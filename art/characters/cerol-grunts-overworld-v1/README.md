# Cerol Hunters — grunts no overworld

Grunt feminino e masculino a partir das pranchas da equipe. Mesmo contrato do Kael e dos líderes: células de 64×96, pivô 32,94, ordem S, SO, O, NO / N, NE, E, SE e filtro nearest. Alturas-alvo: feminino86px e masculino88px. Ronne continua menor e Malvadocia mantém mais volume; as roupas dos grunts não recebem as golas e mantos dos líderes.

As faixas e equipamentos têm lados anatômicos definidos no brief. Feminino: antebraço esquerdo, canela direita e carretel no quadril direito. Masculino: antebraço direito, canela esquerda e carretel no quadril esquerdo. Na prancha de conceito feminina a faixa dorsal da canela é inconsistente; a base de jogo segue a perna anatômica direita.

## Arquivos e origem

`fontes/` preserva as imagens geradas pela ferramenta integrada. `brief.json` registra prompts, identidade e associação das células. Normalização pelo Pixelgen existente, com alpha binário, paleta limitada e limpeza de pequenos componentes soltos, seguida de edição/exportação no Aseprite headless. Não se trata de desenho manual integral dos clusters.

`pacote/<id>/` contém PNG transparente, atlas, projeto Pixelgen e documento Aseprite com oito tags `idle-*`. São oito poses estáticas por personagem, não ciclos de caminhada. `qa.json` verifica os pixels das exportações nativas, margens, apoio, alpha e cores; a revisão visual é registrada em `visual-review.md`. O pacote não posiciona personagens em mapas nem altera encontros ou saves. Aprovação artística do usuário para as bases de overworld ainda pendente.
