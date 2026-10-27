# Parque — composição e legibilidade

Pedido: refazer os mapas para recuperar interesse e clareza da ilustração, reduzindo excesso de árvores. Esta revisão usa a skill `level-design` junto ao fluxo de assets do projeto.

## Referências pesquisadas

- [Jim Brown, Epic Games — The Importance of Nothing, GDC 2014](https://gdcvault.com/play/1020169/The-Importance-of-Nothing-Using): o resumo oficial da palestra trata da aplicação do espaço negativo a jogos e níveis. A página da palestra estava em manutenção durante a pesquisa; não se declarou que o vídeo inteiro foi assistido. [Slides originais](https://media.gdcvault.com/GDC2014/Presentations/Brown_Jim_Importance_Of_Nothing.pdf).
- [Jeremy Price — Applying the Elements of Design and Principles of Design in Level Art](https://www.gamedeveloper.com/art/applying-the-elements-of-design-and-principles-of-design-in-level-art): o autor aborda ênfase, proporção, ritmo, economia e a necessidade de conferir composições a partir de diferentes posições da câmera.
- [Valve — Dota 2 Character Art Guide](https://help.steampowered.com/en/faqs/view/0688-7692-4D5A-1935): guia oficial de personagens que recomenda balancear formas complicadas e alta saturação com áreas de descanso. A transferência desses princípios para os cenários do Parque é uma decisão nossa, não uma recomendação específica da Valve para este mapa.

## Diagnóstico

Havia três populações de árvores: 44 objetos das duas plantas, preenchimento automático nas células de bosque e novas árvores automáticas fora do mapa. O resultado repetia a mesma silhueta alta e contrastante por todo lado. A grama tinha detalhe semelhante ao dos encontros e não proporcionava descanso. As copas da frente encobriam bancos e caminhos, exigindo transparência com frequência.

## Decisões implementadas

- Somente 13 árvores no Jardim e 14 na Clareira, escolhidas por composição. Eliminar completamente os dois preenchimentos automáticos de árvores.
- Reduzir as árvores comuns de 160 para 132 px de altura visível; as floridas permanecem um pouco maiores, 144 px. Normalização uniforme a partir das fontes existentes, sem alterar a forma dos troncos.
- Levar a árvore florida central do Jardim para o jardim lateral do banco leste e a árvore central da Clareira para a borda leste. Isso libera a vista sobre o capim. Colisões dessas árvores seguem os objetos da planta.
- Usar massas baixas de arbustos e um material de bosque próprio para explicar a borda bloqueada, em vez de uma parede de copas altas.
- Criar nova grama de baixo contraste e concentrar detalhe nos encontros e pontos de interesse. Coreto, flores e papéis de pipa continuam sendo os acentos locais.
- Manter eventos, bancos, postes, placas, acessos e células de encontro. A retirada de árvores em chão andável libera suas antigas células; isso é uma alteração deliberada dos obstáculos, não apenas ocultação visual.
- Aplicar sombras projetadas das árvores ao chão para unir os props ao cenário. Não mudar alturas, rampas ou conexões entre mapas.

Contagem de 44→27 refere-se exclusivamente aos objetos das duas plantas. Não se inventou uma porcentagem total de redução que incluísse as árvores automáticas antigas sem contá-las.

## Conferência

Revisar o mesmo conjunto de câmeras do estágio anterior, incluindo plano geral, entrada, coreto e encontros. Capturas em `antes/` preservam a versão rejeitada; `depois/` guarda a revisão. A importação e a renderização nativa são verificações de produção, sem executar suítes de testes ou simular a campanha. Captura 1280×800 confere o formato do Steam Deck; não substitui teste em hardware físico.
