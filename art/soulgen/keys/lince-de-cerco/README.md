# Lince de Cerco — família no Soulgen

Quatro presets independentes: `lince-de-cerco-baby`, `lince-de-cerco-child`, `lince-de-cerco-young` e `lince-de-cerco` (adulto).

Cada diretório `cutout-rig-v1` contém fonte, prompt, PNGs separados, registro dos recortes, projeto editável, cópia portátil com imagens embutidas, prévia HTML, atlas e validação. O bebê possui cinco peças; criança e adulto nove; jovem oito. A dobradiça extra do jovem fica como peça sobressalente, sem duplicação na montagem.

As seis ações são repouso, deslocamento, investida, dano, vitória e derrota. Os rostos de ataque, dano e alegria substituem a cabeça inteira, com dimensões registradas. A rabiola inclui os fios. Peças mantêm a proporção da fonte.

No editor, use Montagem para mover peças e marcar pivôs; o pincel/borracha edita o PNG selecionado. A gravação automática fica no navegador, separada por forma. Salvar projeto baixa uma cópia portátil. Exportações e animações são para revisão; esta entrega não altera o jogo.

Foram renderizados 119 frames por forma, em fundos claros e escuros, sem cortes nas bordas do atlas. A validação técnica não substitui a aprovação artística do autor. O navegador local não estava disponível para um teste manual da interface nesta sessão.

`prepare-family.py` prepara os recortes a partir das fontes registradas em `family-config.json`. `build-family.mjs` monta e exporta os quatro rigs; não sobrescreve importações identificadas por `author-import.json`.
