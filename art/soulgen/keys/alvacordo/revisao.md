# Alvacordo — revisão para Soulgen

Fonte: adulto aprovado, concept-v4 da família papel-collie. Geração pelo imagegen integrado, sem referências externas como input. Prompt, fonte gerada e recortes preservados em `cutout-rig-v1/`.

13 peças sólidas, sem cavidades de encaixe aparentes. A gola acompanha a cabeça inteira. Cada ombreira e suas fitas pertencem ao braço superior correspondente; mãos ficam nos antebraços. Arcos têm seus suportes e linha vermelha completos, separados dos antebraços. Rabiola inclui cauda, fio, nó e ambas as abas. Coxas não repetem joelheiras. Na montagem, abertura das pernas e posição dos joelhos foram ajustadas para não se cruzarem. Cabeça/gola cobrem a terminação do pescoço do torso.

O arco erguido ultrapassava alguns pixels da linha nominal da grade de geração. O recorte recupera a ponta em uma faixa transparente da célula abaixo, antes da cabeça seguinte, sem apagar ou redesenhar o arco. Recortes usam alpha conectado para remover os pontos de fundo; RGB da arte é preservado. As três faces completas foram registradas na mesma janela do rosto normal, com gola atrás do focinho.

Ações: guarda, passo, tensão cruzada, dano, vitória e derrota. Os nomes descrevem poses de estudo, não habilidades canônicas implementadas. Arcos herdam os movimentos dos antebraços; pernas têm joelho hierárquico; loops fecham na mesma pose.

Revisão em imagens renderizadas com fundos claro e escuro. 129 frames exportados a 12 fps, sem pixels nas bordas de células; juntas verificadas por amostragem a 30 Hz. Testes estruturais e HTTP locais cobrem carregamento, imagens, hierarquia e projeto portátil. Ainda requer aprovação visual do autor; teste manual do navegador indisponível nesta sessão. Não integrado ao jogo e sem push.

Arquivos: `cutout-rig-v1/alvacordo.soulgen.json`, `alvacordo.portable.soulgen.json`, `preview.html`, `review.png`, `review-full.png`, `study-atlas.png`, `export.json` e `validation.json`. No editor, preset `alvacordo`, com autosave isolado. Mover, pivôs, desenho e borracha permanecem disponíveis.
