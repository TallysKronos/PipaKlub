# Pedido ao Codex: mochila do Kael e animações novas

Siga a [especificação do avatar](../especificacao.html), seções 5 (ações), 5b (pontos de encaixe) e 5c (mochila). Confira tudo no Avatar Studio (`npm run studio:avatar`, **Abrir avatar Kael v1**): a lista **O que falta** precisa ficar sem avisos de Mochila antes da entrega.

## Já ajustado na bancada (não refazer)

- O ponto das **costas segue a cabeça** em todos os 24 quadros. Antes ele era medido na roupa e variava em 8 posições na frente-direita, e a mochila tremia.
- A bolsa de frente foi puxada para trás do ombro: encaixe SE em (50, 16). Entre 12 % e 39 % dela aparece, conforme o passo.
- A mochila tem **balanço de 1 quadro**: assenta depois do passo.

## 1. Mochila em duas peças

Entregue numa folha transparente, células de 256 × 256, na escala dos quadros do Kael v1:

| Célula | Peça | Vista | Regras |
|---|---|---|---|
| 1 | Bolsa | Frente-direita (SE) | Vista de trás e de lado, saindo atrás do ombro esquerdo da tela. Topo na altura do ombro. Só o volume que apareceria, sem alças. |
| 2 | Bolsa | Costas-direita (NE) | **55 a 70 px de largura** (65–85 % das costas do Kael), do ombro até acima da cintura. Bolso, zíper e o elo de pipa atuais. |
| 3 | Alças | Frente-direita (SE) | Duas faixas descendo dos ombros pelo peito, por cima da jaqueta, sem tronco desenhado. |
| 4 | Alças | Costas-direita (NE) | Faixas sobre os ombros, entrando por baixo da bolsa. |

Pedido sugerido:

> Pixel art no estilo exato do Kael da referência (mesmo contorno #0b1020 de 2 px, mesma luz da esquerda, mesmas cores da mochila atual). Folha 4 colunas × 1 linha, células de 256 × 256, fundo transparente real. Célula 1: só a bolsa da mochila vista da frente-direita, como apareceria atrás do ombro esquerdo de um garoto de 192 px de altura, topo na altura do ombro. Célula 2: só a bolsa vista de costas, com 60 px de largura e 64 px de altura, bolso frontal, zíper e o emblema de pipa dourado. Célula 3: só as duas alças vistas da frente-direita, descendo dos ombros pelo peito. Célula 4: só as alças vistas de costas, sobre os ombros. Sem corpo, sem cabeça, sem sombra no chão, sem textos. Use apenas as cores da paleta anexada.

Na bancada:
1. Em **Peças**, troque a imagem da bolsa nas duas direções.
2. Adicione a peça **Alças da mochila** e importe as duas imagens.
3. Arraste cada peça até encaixar, olhando a prévia animada.

## 2. Animações novas

Para cada uma, abra a animação na lateral da bancada, clique **Baixar guia para o Codex** e **Copiar pedido para o Codex**. O pedido já sai com o número de quadros, a direção, a dica de movimento e a regra de cabelo raspado e sem mochila. Ordem recomendada:

1. **Subir escada** (NE) e **Descer escada** (SE): 8 quadros cada, no lugar. A guia mostra o degrau atual e o próximo (16 px no jogo, 32 na autoria).
2. **Sentar** (4, uma vez) e **Sentado** (2, repete): SE e NE.
3. **Acordar (cama)**: 6 quadros, SE, uma vez. Usado na abertura.
4. **Pegar / tocar**: 4 quadros, SE e NE.
5. **Conversar**: 4 quadros, SE.
6. **Empinar a pipa** (6, NE e SE), **Comemorar** (6, SE), **Perder** (4, SE). Em Empinar, marque o ponto da **mão** em todos os quadros para prender o carretel.

Cada animação nova usa o mesmo corpo base, o mesmo cabelo e a mesma mochila em camadas. Não desenhe cabelo nem mochila nos quadros.
