# Avatar Studio — boneco de papel

Execute `npm run studio:avatar` e abra http://127.0.0.1:5242/. Ferramenta local, sem contas nem banco. Segue a [especificação do avatar](../../art/avatar/especificacao.html): quadro de 256 × 256 na autoria (128 × 128 no jogo), pivô (128, 224), personagem com 192 px (96 no jogo).

## Para que serve

Transformar a animação gerada pelo Codex num corpo base congelado, com pivô, paleta-chave e âncora da cabeça, e montar por cima as camadas de cabelo, acessório e roupa. A aparência (pele, cabelo, roupa) é trocada por paleta, sem arte nova.

## Direções

Quatro, todas diagonais da grade isométrica (26,57°): SE (frente-direita) e NE (costas-direita) são desenhadas; SW e NW são espelhos. `facingIso(dx, dy, anterior)` em `model.mjs` escolhe a direção do sprite a partir do deslocamento na tela, para o jogo usar na integração.

## Etapas

1. **Quadros.** Escolha ação e direção na lateral. Importe PNGs de 256 × 256 (em ordem de nome) ou uma folha com células de 256; quadros soltos de outro tamanho são encaixados pelo pé, sem ampliar. **Abrir piloto do Kael** carrega o andar do teste quadro a quadro em SE, só para testar a bancada (ele foi gerado de perfil). Marque a âncora da cabeça clicando no centro do crânio (setas: 1 px; vírgula e ponto trocam de quadro). **Registrar pés no pivô** desloca os quadros sem escalar. SW e NW espelham SE e NE até receberem quadros próprios.
2. **Paleta.** As cores da arte são agrupadas e cada grupo recebe grupo e tom da paleta-chave. A sugestão considera a cor e a altura em que ela aparece na figura (cabelo no alto, tênis embaixo); confira os azuis-marinhos e os tons de pele. À direita da prévia, vermelho é pixel sem grupo.
3. **Camadas.** Cabelo (frente e trás), acessório e mochila: uma imagem por direção, presa à âncora; clique na prévia para acertar o ponto que vai no centro do crânio. Roupa de modelo: um PNG por quadro. Ao importar, a camada é convertida para as cores-chave dos grupos permitidos (acessório nunca usa pele).
4. **Aparência.** Troque as rampas de cada grupo e veja a aparência escolhida ao lado de sete sorteadas, para conferir se uma troca de cor vaza para outro grupo.

**Baixar guia de quadros** gera a grade da animação (chão, pivô, topo da cabeça e linha dos olhos) e **Copiar pedido desta animação** traz o texto pronto para o Codex. Envie os dois junto com a folha de modelo.

## Conferência

Por ação e direção: tamanho da célula, pé no pivô (± 2 px na autoria), paleta (no máximo 0,5 % fora), alpha, âncora presente e sem salto maior que 6 px entre quadros vizinhos, altura estável (aviso acima de 2 %, reprovação acima de 5 %), deriva de cabelo e mochila entre quadros vizinhos (redesenho da IA), cabelo preso à cabeça e roupa dentro da silhueta.

## Exportar

**Exportar pacote .zip** gera `assets/avatar/<nome>/` em 1× (corpo base nas cores-chave, camadas, `manifest.json`, `paleta.json`) e `art/avatar/<nome>/` (prévia da aparência atual, `conferencia.json` e o projeto). A redução 2× → 1× copia um pixel de cada bloco, sem média, para preservar a paleta.

## Limites

- O piloto do Kael tem cabelo e mochila no corpo base, porque foi gerado assim. Ele serve para testar a bancada e o movimento; o corpo base definitivo vem com a cabeça raspada (especificação, seção 8).
- A conferência é técnica. Naturalidade do movimento e fidelidade ao personagem continuam na revisão artística.
- O jogo ainda não lê o pacote; a composição da aparência no jogo é o passo seguinte, depois da arte aprovada.
