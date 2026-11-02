# Área segura no interior do papel

Regra adicionada após a revisão do dono na PIP-133. O limite externo de um painel não é a sua área de leitura.

1. Reserve as regiões fixas da ilustração (cantos, dobras, traços e colagens). Depois delas, mantenha **mais 8 px de espaço livre**.
2. Derive textos, barras e ícones da mesma área interna. Meça texto com a fonte real (ascendente, descendente, altura e largura), não por uma linha-base estimada.
3. A densidade da arte pode variar para manter as dobras proporcionais; **não comprima a tipografia junto com a arte**.
4. Se o conteúdo não couber, aumente o painel ou reorganize a composição. Não empurre valores para o contorno nem reduza a fonte silenciosamente para cumprir uma altura antiga.
5. Atalhos sobrepostos à borda são adornos/controles explícitos, separados da área de leitura. Retratos que saem do painel têm espaço lateral reservado; não podem atravessar letras ou barras.
6. Confira 100% e 150% nas quatro resoluções. A auditoria deve verificar glifos, barras, ícones e colisões, além dos retângulos externos.
7. A margem interna não garante que um painel esteja fora do caminho de personagens, linhas ou alertas. Faça também revisão da composição no contexto do combate.

Implementação compartilhada: `godot/scripts/ui_mural/paper_layout.gd`. O corte fixo de referência é 60 px; o inset é `ceil(60 × densidade + 8)`. Batalha usa densidade 0,35 (**29 px internos**); ações, 0,30 (**26 px**). A moldura é desenhada em escala própria e o texto segue a escala de acessibilidade. A coleta de auditoria fica desligada em produção; o capturador habilita e limpa os registros.

A PIP-133 aplica a regra aos componentes que migra. A migração dos demais consumidores será verificada nas suas tarefas; este documento não afirma que toda a interface antiga já foi corrigida.

