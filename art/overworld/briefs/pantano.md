# Pântano — prévia independente autorizada, 30/10/2026

## Revisão de percurso e arena, autorizada em 30/10
Manter A; substituir as plantas provisórias B/C por áreas próprias, preservando IDs. Remover todas as árvores decorativas da água. Sem inventar espécie/nome do boss: pergunta enviada ao dono, ambiente pode ser construído com lago vazio enquanto isso.

### B — travessia deslocada (blocos 48×40)
```
 [aterro1/item]  saída24,0  [aterro1/item]
      rampa v− -- curva de terra -- rampa v−
 ~~~~~ canal sinuoso ~~~~~ ponte34,19..27 ~~~
 [aterro1/mato]     desvio pela direita   [aterro1]
      rampa v− --- entrada24,39 --- rampa v−
```
Abrir na entrada → desviar à direita até ponte estreita → abrir na margem norte. Três materiais alcançáveis, um escondido; mato opcional. Dois marcos secundários de mata, sem árvore plantada em água.

### C — clareira do lago circular (48×40)
```
  moldura elevada1 / mata, atalho para A24,0
 [maciço1] ----- volta seca ----- [maciço1]
 [item]      lago circular         [item]
 [mato]       centro24,18           [mato]
 [rampa v−]   água−24             [rampa v−]
        clareira de chegada0 / contemplação
                  entrada24,39
```
Marco principal: lago circular de raio8,5 células, borda baixa e rebaixo real. Um anel largo de terra firme permite contornar sem atravessar água; sem ponte sobre o boss. Árvores enquadram o exterior; clareira central limpa. Névoa/ondulações de atmosfera não podem cobrir a margem nem sugerir chão. Três itens nos terraços laterais, sem item dentro d'água. O boss e o combate dependem de definição posterior; nenhum gatilho de vitória será inventado.

Sem chefe, NPC canônico ou revelação. IDs `kronasta-pantano-a/b/c`; nomes descritivos de trabalho: Entrada alagada, Curva dos cipós, Clareira das raízes. Não conectado à campanha. Referências em `documentation/overworld/pantano/pesquisa-direcao.md`.

## Planta antes da arte
Cada parte 48×40. A apresenta água e travessia; B estreita a passagem entre raízes; C abre uma clareira seca com árvore antiga. Marco principal: árvore de raízes expostas no terraço norte; dois bosques secundários laterais.
```
                 saída v- (24,0) para seguinte
 [terraço1 / item]    trilha0    [terraço1 / árvore]
           rampa v-       rampa v-
   margem curva -- terra firme -- margem curva
 ~~~~~~~~~ água -12 / passarela0 ~~~~~~~~~~~~~~~~
   margem curva -- cabeceira -- margem curva
 [aterro1 / escondido] trilha0 [aterro1 / item]
           rampa v-       rampa v-
                 entrada v+ (24,39)
```
Quatro acessos de duas células, todos para v−, com pé e duas chegadas livres. A/B/C têm variações do canal e massas de vegetação; relevo em blocos2×2. A→B→C pela trilha terra0; C tem atalho independente para A. Pelo menos40% platô e três itens, um escondido. Mato opcional no topo, fora do caminho obrigatório. Água não caminhável. Canal contínuo atravessa moldura, sem poço artificial retangular.

Ritmo: abertura da entrada → passarela de 3 células → margem aberta com vista para o marco. Becos: materiais, vista e descanso descritivo, sem novas mecânicas. Moldura4 células e anel exterior. Margens compartilham contorno com recorte real, água12px abaixo e face de barro. Ponte apoiada em margens, não em vegetação.

Arte: água verde-petróleo, musgo oliva, barro castanho, trilha areia úmida clara; copa em massas, cipós ancorados, contorno azul-escuro, sombra em planos. Árvores próximas às rotas baixas/arbustos, sem ocultar rampas. Kit reaproveita chão e barranco; nova árvore e água específica. Capturas geométricas antes da produção artística, depois jogo e juntas sem atores. Primeira revisão visual em A antes da propagação artística.
