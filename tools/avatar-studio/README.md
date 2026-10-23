# Avatar Studio — boneco de papel

Execute `npm run studio:avatar` e abra http://127.0.0.1:5242/. Ferramenta local, sem contas nem banco. Segue a [especificação do avatar](../../art/avatar/especificacao.html): quadro de 256 × 256 na autoria (128 × 128 no jogo), pivô (128, 224), personagem com 192 px (96 no jogo).

## Para que serve

Transformar a animação gerada pelo Codex num corpo base congelado, com pivô, paleta-chave e âncora da cabeça, e montar por cima as camadas de cabelo, acessório e roupa. A aparência (pele, cabelo, roupa) é trocada por paleta, sem arte nova.

## Direções

Quatro, todas diagonais da grade isométrica (26,57°): SE (frente-direita) e NE (costas-direita) são desenhadas; SW e NW são espelhos. `facingIso(dx, dy, anterior)` em `model.mjs` escolhe a direção do sprite a partir do deslocamento na tela, para o jogo usar na integração.

## Etapas

**? Como funciona** explica a bancada em quatro passos. À direita, **O que falta** lista os problemas por ordem de gravidade; **Ver** leva direto à etapa, animação, direção e quadro. Embaixo, a **prévia animada em tamanho real** mostra as quatro direções sempre andando com cabelo, mochila e cores; clique numa direção para editá-la.

1. **Desenhos.** Escolha a animação na lateral. Ela está agrupada em Essenciais, Casa (escada, sentar, acordar, pegar, conversar) e Pipa (empinar, comemorar, perder); cada uma mostra só as direções que usa. Importe PNGs de 256 × 256 ou uma folha com células de 256. Cada quadro tem três **pontos de encaixe**: cabeça (rosa), costas (laranja) e mão (verde). Arraste o ponto na imagem ou clique onde ele deve ficar; **Mover em todos os quadros desta direção** desloca o ponto no ciclo inteiro. **Pontos automáticos** mede a cabeça pelo rosto e faz as **costas seguirem a cabeça**, o que evita que a mochila trema. Nas animações de escada, a guia mostra o degrau atual e o próximo.
2. **Cores.** Cada cor do desenho recebe um grupo (pele, cabelo, jaqueta…). A sugestão considera a cor e a altura na figura; confira os azuis-marinhos e os tons de pele. Vermelho na imagem da direita é cor sem grupo.
3. **Peças.** Cabelo, boné, mochila (bolsa), alças, carretel (na mão) e roupa de modelo. Selecione a peça e **arraste-a na imagem**: as cópias translúcidas mostram onde ela fica nos outros quadros. Peças presas às costas ou à mão podem ter **balanço** de 1 ou 2 quadros. As direções da esquerda espelham as da direita.
4. **Visual final.** Troque as cores de cada grupo e compare com aparências sorteadas.

**Baixar guia para o Codex** e **Copiar pedido para o Codex** geram a grade e o texto da animação aberta, com a dica de movimento e a regra de cabelo e mochila separados. Pedido atual da mochila e das animações novas: [art/avatar/kael-v1/PEDIDO-MOCHILA-E-ANIMACOES.md](../../art/avatar/kael-v1/PEDIDO-MOCHILA-E-ANIMACOES.md).

## Conferência

Por ação e direção: tamanho da célula, pé no pivô (± 2 px na autoria), paleta (no máximo 0,5 % fora), alpha, âncora presente e sem salto maior que 6 px entre quadros vizinhos, altura estável (aviso acima de 2 %, reprovação acima de 5 %), deriva de cabelo e mochila entre quadros vizinhos (redesenho da IA), cabelo preso à cabeça e roupa dentro da silhueta. A mochila é conferida no tronco e acima da cintura; de frente, precisa aparecer atrás do ombro (ou ter alças) e, de costas, cobrir 65–85 % da largura das costas.

## Exportar

**Exportar pacote .zip** gera `assets/avatar/<nome>/` em 1× (corpo base nas cores-chave, camadas, `manifest.json`, `paleta.json`) e `art/avatar/<nome>/` (prévia da aparência atual, `conferencia.json` e o projeto). A redução 2× → 1× copia um pixel de cada bloco, sem média, para preservar a paleta.

## Limites

- O piloto do Kael tem cabelo e mochila no corpo base, porque foi gerado assim. Ele serve para testar a bancada e o movimento; o corpo base definitivo vem com a cabeça raspada (especificação, seção 8).
- A conferência é técnica. Naturalidade do movimento e fidelidade ao personagem continuam na revisão artística.
- O jogo ainda não lê o pacote; a composição da aparência no jogo é o passo seguinte, depois da arte aprovada.
