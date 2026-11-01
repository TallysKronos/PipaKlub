# Revisão dos corredores da loja

## 1. Arquivos e alteração

Mesas deslocadas para a direita; ilha central deslocada uma célula para abrir sua lateral esquerda; vitrine duplicada da direita retirada. Seu ponto de interação agora atende ao mostruário da estante do fundo. Mantidas duas mesas, dono, entrada, dimensão da loja e todos os produtos/mesmos assets. Alterados `shop_data.gd`, testes/capturas e a prévia do save.

O vão entre ilha e mesas passou de 2 para 4 células. Entre as mesas, de 1 para 2. A lateral entre expositor e ilha passou de 1,5 para 2,5. O teste exige uma faixa contínua de 3 células realmente livres para o jogador, considerando a margem de colisão, da entrada ao atendimento.

## 2. Resultado automático

```text
SHOP MODERNO 47 checks; 6696 reachable samples; 0 isolated walkable samples; 0 failures
SHOP FLOW 18 checks; doorway, movement, owner dialogue, save/resume, return; isolated directory
CAMPAIGN CHECKS: 206 checks, 0 failures
CAMPAIGN VIEW CHECKS: 30 checks, 0 failures
PLAYER FLOW: 7 checks, 0 failures
```

Teste específico e fluxo nativo sem erros de script/shader. Os testes gerais de views/fluxo continuam com diagnósticos de recursos no encerramento, já registrados na entrega anterior. Não foi necessário repetir os testes do renderer externo ou do Mapa Studio, cujos módulos não foram alterados nesta revisão.

## 3. Capturas

`corredores-geometria-*` e `corredores-arte-*`: geral, versão sem atores, detalhes e oclusão, em 1280×720. `corredores-antes-depois.png`: comparação. `fluxo/02b-corredor-livre.png`: jogador no corredor durante percurso real automatizado. Fluxo, prévia de save e hashes atualizados.

## 4. Percurso

Verificados seis pontos de interação, faixa larga de passagem e ausência de bolsões. O frontend percorreu entrada → meio do corredor → balcão → saída; conferidos diálogo, retomada e retorno ao bairro, além da conversa com Lia fora da porta.

## 5. História e itens

Nenhuma mudança de história, item, preço ou recompensa. Não foram geradas novas artes.

## 6. Compatibilidade

Um save antigo pode ter sido feito numa posição onde agora há uma mesa. A validação aceita posições antigas dentro do piso; o RoomView encontra o ponto livre mais próximo ao carregar. Novos checkpoints continuam impedidos de gravar uma posição dentro de móvel pelo Journey. Os testes cobrem validação antiga, recuperação efetiva no RoomView, escrita inválida e save/retomada normais. A posição original segura é mantida sem deslocamento.

## 7. Dúvidas

Sem bloqueios; aguardando avaliação visual dos corredores.

## 8. Não verificado

Não houve sessão manual com controle físico ou exportação Steam/Windows. O percurso foi automatizado no jogo; os testes usam diretórios isolados. Compras e jogo de cartas continuam fora desta etapa. Sem push, merge ou deploy.
