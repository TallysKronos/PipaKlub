# Parque dos Ventos — lote de plantas A/B/C

29/10/2026 · `codex/mapa-mundi` · **plantas e fluxo propostos, antes da arte final e da campanha**.

Base: `REGIOES-E-PARTES.md` da revisão remota `f3df6373`, área de prova `e02169eb`, decisão do criador de preservar Nina no início e pedido de manter a referência com a identidade de mangá 2D simples. IDs de áreas, cenas e objetos antigos são preservados.

## Fluxo regional

Rua dos Ventos → **A Jardim das Pipas** ↔ **B Clareira do Papel** ↔ **C Veredas do Encanamento**. Depois da vitória, um acesso na borda do patamar de C volta para A. A região pode ser revisitada; o boss não deve reaparecer e a recompensa de missão não deve ser concedida de novo.

O retorno ao mapa de Kronasta ainda depende de uma cena de mapa de mundo que não existe nesta branch; preservamos `quintal` como saída de A. Não criamos um destino fantasma para satisfazer um diagrama.

### A · Chegar e querer ajudar

- Planta: `jardim-das-pipas.tmj`, cena `park-trail`, 60×44. Dois patamares úteis acessíveis por rampas largas; dois maciços de mata alta contêm a entrada e formam recintos.
- **Uma revelação:** Nina voltou sem a rabiola de Carcará. Proposta de fala: “Eu voltei sem o Carcará… A rabiola dele ficou perto dos canos.” Não explicar cerol, Bando, Elo ou laboratório nesta visita.
- Entrada e Nina no vale baixo; bifurcação abre ramais para o coreto e para o mirante leste. Os ramais recompensam curiosidade; a saída norte segue para B sem mato obrigatório.
- Marco principal: coreto no platô oeste. Secundários: placa da entrada e árvore florida. A praça de descanso fica embaixo, sem objeto cobrindo Nina.
- Três eventos de item: papel no alto oeste (escondido), linha junto ao recuo (visível), papel no ramal leste (brilho). São propostas de materiais existentes da oficina, quantidade 1; ainda não creditados ao jogador. Os dois baús antigos continuam como peças separadas.
- O vestígio pós-resgate anterior permanece com o mesmo ID, mas só deve ser exposto na releitura da missão. A prévia de desenho ainda não aplica esse portão.

### B · Escolher o desvio e atravessar

- Planta: `clareira-do-papel.tmj`, cena `park-clearing`, 64×48. Três patamares exploráveis, um maciço de mata e duas opções de aproximação no vale.
- **Uma revelação:** o rastro alcança os canais de barro. O evento é uma observação curta; não é uma narração que manda o jogador ir ao próximo ponto.
- Riacho raso encaixado entre margens altas; duas pontes de três células de largura sobre cinco de comprimento. Cabeceiras em chão firme, sem cachoeira ou poço fictício. Há uma alternativa pelo circuito alto, conferida mesmo retirando ambas as pontes do ensaio. O caminho até C não exige pisar no mato.
- Marco principal: ponte sobre a clareira do riacho; secundários: banco de descanso e platô do achado. O nome “ponte” não concede um sistema novo de travessia ou salto.
- Três itens: papel no patamar sudoeste (escondido), linha no oeste (brilho), papel no leste (visível). Um descanso fica antes da travessia e outro num recuo elevado.
- O jogador pode explorar os platôs e voltar à trilha sem repetir um corredor inteiro. A e C têm saídas em bordas distintas e nos dois sentidos.

### C · Preparar, enfrentar, recuperar e voltar

- Planta: `veredas-do-encanamento.tmj`, cena `park-veredas`, 64×48. Aproximação baixa, patamar de descanso, pátio elevado e baús em ramais distintos.
- **Uma revelação:** o encontro de Lacertubo está ligado ao acesso dos canos antigos; a rabiola de Nina está no pátio. A explicação das Ruínas profundas fica para depois.
- Marco principal: pátio com canos/biruta. Os canos são conteúdo já previsto, não uma nova construção pintada escondendo o relevo. As rampas e os contornos físicos sustentam o pátio.
- Lacertubo usa o evento antigo ID 36 (`parkBoss`) com `ocultar_apos = guardianDefeated`. A rabiola de Nina mantém ID 42 (`veredasTail`), separada do drop próprio do boss. O brilho só deve aparecer após a vitória.
- Saída comum volta a B; o novo atalho na borda leste do alto aponta a A e requer `guardianDefeated`. Nina recebe a devolução no Jardim. O evento antigo de Nina em C está preservado como fase posterior/inativa na primeira visita, não é autorização para duplicá-la em duas cenas.
- Três itens comuns de preparação, sendo um escondido, além dos cinco baús antigos e da recompensa principal de missão. Nada disso implica novos efeitos ou quantidades de recompensa na campanha.

## Linguagem espacial e visual

- A referência informa maciços de terreno, caminhos entre platôs e mata em grupos. As formas são autorais, sem copiar a planta de outra franquia.
- Grade 64×32; nível = 64 px; áreas finitas abaixo de 72×56. Pelo menos 40% da superfície total fica acima do nível zero, com contagem separada do alto realmente alcançável.
- Árvores em grupos de cinco, moldura de quatro células e caminhos/portais sem troncos bloqueando. A captura distante não substitui leitura na câmera de jogo.
- Mangá 2D simples: contorno azul-escuro, base de cor e uma sombra; grama de baixo contraste, detalhe nas bordas e objetos. Sem ruído fotográfico, bevel, aparência de maquete ou sombreado volumétrico.
- O kit atual aparece somente como estudo de montagem. Paredões de alvenaria, plano curto de rampa e ponte quadriculada são provisórios: o próximo recorte visual precisa substituí-los por peças naturais de barranco, margens e rampas que preservem a mesma geometria.

## Métricas e limites

O auditor regional confere: três partes, saídas de ida/volta, atalho condicionado, três itens por parte e um escondido, 40% de relevo, preservação dos IDs, ausência de peças sobrepostas, rampas nos dois sentidos e acesso a todos os eventos/baús sem mato obrigatório.

**Não está aprovado ainda:** tempo de 1–3 min por parte e 4–8 min de exploração. A travessia mínima direta é curta; o roteiro de visitas, desvios e interações deve ser cronometrado. Não inventamos um labirinto obrigatório só para inflar tempo. O relatório distingue esse aviso de um erro geométrico.

Os metadados de missão e retorno são dados propostos. Converter as plantas não conecta automaticamente os flags, itens, estado do boss, inventário ou saves da campanha. A mudança de coordenadas exige migração antes de substituir os mapas oficiais. As ferramentas desta entrega não fazem essa substituição.

## Entrega e reprodução

- `node tools/mapa-studio/parque-abc.mjs`: gera somente as três plantas e JSONs de revisão.
- `node tools/mapa-studio/conferir-parque-abc.mjs`: conferência regional com avisos explícitos.
- `godot --path godot --script res://tools/parque_abc_capture.gd`: capturas com renderer real, sem saves.
- Revisão: `art/overworld/revisao/parque-abc/index.html` e `RELATORIO.md`.
- As versões anteriores das plantas foram preservadas em `antes-*.tmj` na pasta de revisão.

## Rotas e ambientação — revisão atual

B e C possuem acesso baixo e passagem alta com entradas próprias, permitindo reencontro de caminhos. A mantém o percurso inicial aceito. Nas próximas regiões, trabalhar com rede de áreas e ramais opcionais, sem repetir uma cadeia obrigatória. Barrancos, água, pontes, buritis, margens e canos existentes foram aplicados; consultar as capturas Godot atuais e o relatório para limites de integração.
