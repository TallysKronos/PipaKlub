# Parque dos Ventos — auditoria de uso

Data: 22/10/2026. Objeto: prévia local `http://127.0.0.1:5241/`, revisão de arte 2D. Inspeção exploratória pelo próprio agente no navegador; não é pesquisa com participantes externos. Nenhum comportamento do jogo foi alterado nesta auditoria.

## Avaliação

O cenário já tem unidade visual, hierarquia e uma circulação compreensível. A experiência oferece caminhada e contemplação. Para sustentar exploração, precisa tornar seus pontos de interesse utilizáveis e oferecer consequências às ações do jogador. As principais dificuldades encontradas são foco do teclado, interpretação dos cliques e perda de visibilidade do protagonista.

## Percurso efetivamente testado

1. Recarregar e tentar andar com seta direita antes de clicar no cenário.
2. Clicar no painel da placa, esperar a chegada e tentar E/Enter.
3. Usar “Ir ao coreto” e clicar na região de sua escada/entrada.
4. Clicar no capim e atravessá-lo com D.
5. Pausar o vento, tentar voltar a andar com D enquanto o botão mantém foco e pressionar Escape.
6. Retomar o vento, abrir a visão geral, clicar além da cerca e inspecionar as bases de colisão.
7. Retornar à vista próxima e solicitar caminhada até o descanso.

Observação feita no viewport efetivamente capturado de 1166×884. Não foram testados aparelho móvel, controle físico, outras redes, produção, persistência ou FPS. Áudio não foi avaliado por escuta; a ausência de implementação de áudio foi verificada no módulo da prévia.

## O que funciona

- Clique no chão inicia deslocamento; setas/WASD respondem quando o Canvas tem foco. A câmera acompanha o protagonista.
- “Ir ao coreto” completou o percurso e exibiu a mensagem de chegada.
- Colisões rejeitam destinos bloqueados e cliques fora da área transitável, com aviso explícito. Isso não prova encaixe perfeito de toda silhueta ilustrada.
- Visão geral permite compreender a estrutura inteira; voltar à vista próxima funciona.
- Pausa e retomada do vento funcionam. Copa, biruta, bandeirolas e pipa acrescentam movimento discreto.
- Coreto é um marco reconhecível. Cerca e vegetação delimitam o parque; piso claro e caminho dourado organizam a circulação.
- A família gráfica ficou mais coesa e próxima do 2D limpo pedido pelo usuário.

## Problemas reproduzidos

| ID | Prioridade | Reprodução / observado | Efeito no jogador | Recomendação |
|---|---|---|---|---|
| U01 | Alta | Após recarregar, seta direita não move. Após clicar no Canvas, D move. Depois de pausar o vento, D deixa de mover enquanto o botão tem foco. | O comando anunciado parece falhar. | Definir foco inicial de exploração e política de devolução de foco após controles. Preservar Tab/teclado para operar a interface. |
| U02 | Alta | Clique no desenho da placa vira deslocamento para o chão atrás dela. E/Enter não abre o mapa. | O objeto promete uma ação que não responde; o jogador vai a um ponto inesperado. | Separar seleção de objeto de clique no terreno, exibir indicação de interação e aproximar do lado correto. |
| U03 | Alta | Depois do clique no painel, o corpo fica encoberto pela placa; só parte da cabeça permanece visível. | Perda de localização e sensação de desaparecimento. | Oclusão consistente também para placa/mobiliário: silhueta, transparência contextual ou indicador do jogador. |
| U04 | Alta | Região visual da escada/entrada do coreto retorna “Área bloqueada”. | A arquitetura sugere passagem, mas a navegação impede. | Decidir se o coreto é acessível; modelar escada/piso ou comunicar claramente a função decorativa. Rever o banco à frente do acesso. |
| U05 | Média | Após a chegada por clique, caminhada manual com D mantém o texto “Você chegou”. | Feedback deixa de representar a ação atual. | Atualizar/cancelar mensagem de chegada ao retomar controle manual e mostrar marcador do destino. |

Evidência de U02/U03: `board-occlusion.png`. Evidência da exploração do capim: `grass-no-interaction.png`. Evidência da visão geral e rejeição de destino externo: `overview-limits.png`.

## Ausências da prévia, separadas de falhas

- O capim foi atravessado sem batalha, animação reativa ou outra consequência. O módulo só trata deslocamento; isto não diagnostica o sistema de encontros do jogo principal.
- Placa, descanso e saídas não têm ações de gameplay ligadas nesta página. O botão leva ao local de descanso, sem executar descanso.
- Não há objetivo de chegada, NPC, diálogo, coleta, parceiro Soulmonster acompanhando, recompensa ou ciclo de retorno à oficina.
- Escape não abre menu. Não há salvar/carregar nesta prévia, e ela informa que não altera saves.
- Não há sons de passos, vento ou interação implementados na página.
- Ferramentas de auditoria e downloads do Soulgen são adequados para revisão, mas não são a interface final de exploração.

## Acabamento visual e sensação de jogo

Estas são avaliações do auditor, não bugs objetivos:

- O protagonista é mais pixelado e tem menos poses que os props. Unificar resolução aparente, linha, escala e direções de caminhada deve vir antes de adicionar mais enfeites.
- As árvores repetem a mesma silhueta e o mesmo movimento; a faixa externa parece uma fileira regular. Duas ou três variações de copa/tronco e agrupamentos assimétricos melhorariam a naturalidade mantendo a família.
- O capim é uma mancha verde relativamente retangular, com poucas lâminas pequenas. Precisa ser reconhecido como habitat à distância, com borda e movimento próprios.
- O cenário tem vários objetos, mas pouca atividade independente do jogador. Um NPC usando o parque e um Soulmonster visível ajudariam mais que aumentar a densidade decorativa.
- A pipa e os remates dão tema de pipa ao parque. Falta a presença de criaturas para ligar imediatamente a cena à identidade de Soulmonsters.
- As saídas precisam comunicar destino. Falta saber por que seguir por cada caminho e quando uma área está bloqueada por progresso.
- A câmera tem aproximação fixa na exploração, deslocamento sempre para o mesmo lado e recortes nos extremos. Vale avaliar limites e antecipação pela direção de caminhada durante a integração real.

## Ordem recomendada

1. Foco de teclado, seleção de objetos, visibilidade do protagonista e acesso ao coreto.
2. Um pequeno ciclo completo: NPC no coreto → tarefa clara → coletar material ou encontrar criatura → retorno com recompensa.
3. Interação real com placa/descanso, saídas identificadas e indicação contextual de ação.
4. Protagonista e parceiro no mesmo acabamento do cenário; caminhada mais convincente e sons.
5. Variação de vegetação, capim reativo e detalhes ambientais.

Critério de sucesso proposto: um jogador novo consegue começar a andar sem descobrir um requisito de foco, identifica um objetivo, usa um objeto e recebe um resultado, mantendo o protagonista localizável durante todo o percurso. Validar isso com uma pessoa externa após as correções.
