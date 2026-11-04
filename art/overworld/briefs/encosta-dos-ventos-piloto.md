# Encosta dos Ventos — laboratório de mobilidade

Prévia independente autorizada: não é uma região canônica, não substitui mapas nem altera campanha,
inventário ou saves. Uma área concentra os três testes antes de levar a mecânica às regiões A/B/C.
Três cotas (0/1/2), saltos curtos contextuais, descida unilateral e volta por rampas. Kael atual e parceiro.

Planta em coordenadas u/v (o fundo corresponde a u-/v-):
```
       u →
v  borda rochosa / bosque contínuo
↓  +----------------+--+-----------+
   | mirante 2      |  | platô 1   |
   | item/vista    R2  |           |
   |---------------|  |           |
   | platô 1 / trilha J ↔ J / item |
   | item oculto   |  |           |
   +-------R1------+  +--D----R3---+
           ↑             ↓    ↑
   abertura 0 — trilha de retorno
             entrada / descanso
```
R1/R3 sobem v- por quatro células; R2 sobe u- por quatro células. J cruza três
células no mesmo nível; D desce um nível, sem subida automática. O corredor rebaixado
entre os platôs é chão real de nível 0, não uma falsa ponte. Nada permite atravessar
paredes andando. O jogador precisa confirmar a travessia no ponto preparado.

Ritmo: chegada aberta → rampa de duas células → platô amplo → salto opcional →
abertura no outro lado → descida curta que fecha o retorno. A alternativa por R3
permite voltar mesmo sem usar salto. Marco: mirante elevado com biruta. Becos têm
vista/item de teste; três marcadores (um oculto), sem recompensa real. Mato apenas
nos desvios. Moldura de rocha parece bloqueio; bordas livres continuam visíveis.

Conferência: planta normal deve alcançar todas as áreas e itens pelas rampas;
links especiais são atalhos opcionais auditados à parte. Não ampliar o grafo normal
com arestas de salto: clique e setas continuam respeitando barrancos. Reentrada
durante travessia recupera a última posição firme em memória, sem gravar na conta.

Arte: reaproveitar kit floresta/terrenos, sem novos PNGs. Capturar estrutura primeiro,
depois arte; boca de cada rampa e cantos sem ator sobreposto. Encontros, água,
pontes e muretas não existem neste piloto, portanto seus detalhes não se aplicam.
