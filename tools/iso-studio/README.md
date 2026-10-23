# Iso Studio — bancada de grade isométrica

Execute `npm run studio:iso` e abra http://127.0.0.1:5241/. Ferramenta local, independente do servidor do jogo, sem contas nem banco. Segue a [especificação da grade](../../art/grade-isometrica/especificacao.html): projeção 2:1, célula de piso 64 × 32 px, 1 célula de altura = 32 px.

## Para que serve

Encaixar na grade cada peça gerada pelo GPT, Codex ou artista, conferir as regras e montar o cômodo. Também sai daqui o pedido para gerar a próxima peça.

## Fluxo

1. **Cômodo.** Comece por **Quarto do Kael** (10 × 8, paredes de 5, caixas da tabela de medidas) ou ajuste células e parede. A casca (piso e paredes vazios) é opcional; **Referência da casca** baixa a grade vazia para pedir a casca, e o painel diz o tamanho exato que ela precisa ter.
2. **Pedir a peça.** Selecione a peça, ajuste pegada, altura e âncora, e use **Baixar caixa de referência** (caixa sombreada em 4×, com a âncora) e **Copiar pedido** (texto pronto, com medidas e tamanho final). Envie os dois ao gerador.
3. **Encaixar.** Arraste o PNG para a área de trabalho, ou para a lista de peças (cria uma peça com o nome do arquivo; `guarda-roupa.png` cai na peça `guarda-roupa`). O encaixe automático escolhe a redução inteira (1/2, 1/4…) e alinha a base e o lado esquerdo. Ajuste fino com arrastar ou setas (Shift: 8 px). A fonte inteira aparece translúcida por trás.
4. **Conferir.** O painel **Conferência** aplica as regras a cada mudança:
   - **R1/R5** pixels fora da caixa, marcados em vermelho na peça;
   - **R1** inclinação medida das arestas de baixo, comparada com 2:1 (reprova acima de 1 px a cada 32);
   - **R3** margens: a peça precisa preencher a caixa;
   - **R5** pixel junto à âncora (peça flutuando);
   - **R7** redução não inteira (reprova), halo e semitransparência, bloco de pixel diferente do resto do conjunto;
   - **R9** fundo opaco ou xadrez (transparência falsa).
   Na lista, verde é aprovada, amarelo tem avisos e vermelho está reprovada.
5. **Montar cena.** Arraste peças e o boneco do Kael pela grade (setas: 1 célula; Alt: meia). A ordem de desenho segue as pegadas, então dá para ver o Kael passar na frente e atrás de cada móvel. A cena aponta pegadas fora do quarto, sobrepostas ou objeto de parede fora da parede.
6. **Exportar entrega .zip.** Gera a estrutura da especificação: `assets/world/<cenario>/` com cada PNG já no tamanho da caixa, `casca.png` e `manifest.json`; `art/<cenario>/` com `revisao-grade.png`, `conferencia.txt` e o projeto. Peças reprovadas também saem, mas o relatório e a mensagem avisam.

**Salvar projeto** baixa um `.isostudio.json` com as imagens incorporadas; **Abrir** recarrega. O navegador guarda uma cópia automática. Ctrl+Z / Ctrl+Shift+Z desfazem e refazem.

## Limites

- A conferência é geométrica. Ela não julga estilo, paleta nem direção da luz; isso continua na revisão artística.
- A medida de inclinação usa a borda de baixo da silhueta. Em móveis com pés finos ela pode ficar sem medida; a conferência avisa "não medida" em vez de aprovar.
- O encaixe automático só aceita reduções inteiras. Se nenhuma servir, a escala fracionária é aplicada para visualização e marcada como reprovação (R7): peça a imagem de novo no tamanho certo.
- Coordenadas da âncora: canto frontal da pegada para móveis; canto mais baixo para objetos de parede (u na parede direita, v na esquerda), com elevação em células.
