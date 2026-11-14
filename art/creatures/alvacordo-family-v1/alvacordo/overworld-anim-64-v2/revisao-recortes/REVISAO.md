# Correção dos recortes — 05/11/2026

A revisão anterior aceitou conectividade em oito vizinhos como se garantisse continuidade anatômica. Estava errada: o arco mantinha mão e braço conectados mesmo quando o punho estava cortado por uma faixa transparente. O fundo preto também ocultava esses vazios.

Corrigidos punhos da direita da imagem em idle4–6, walk3/7 e victory3–7. Recomposto volume curto do punho com sombra da paleta original. Removidos resíduos do braço abaixado em victory3–6, mais os pixels expostos nos extremos da transição victory2/7. Total95pixels em11quadros. Mantidos rosto, escala, poses, tempos e demais pixels.

Antes preservado em antes.aseprite/antes.png. Depois em depois.png. Comparativos clara e magenta: primeira linha antes, segunda linha depois; exemplos globais4,11,20,23. Na comparação cega a.png é corrigido, b.png é original. O crítico inicialmente inverteu os rótulos na conclusão; conferiu novamente os arquivos e confirmou A,8/10 sem bloqueadores restantes. Nenhuma edição de pixels após essa confirmação.

Fontes, atlas e4GIFs/filmstrips atualizados. verificações de alpha nos punhos e ausência dos resíduos em verificar_recortes.py da pasta de família. Inspeção por frames em fundos contrastantes; sem playtest em jogo.
