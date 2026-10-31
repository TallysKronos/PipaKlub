# Montanha — prévia independente, 30/10/2026

Referência enviada pelo dono: terraços altos conectados por passagens, como Training Peak. Estudar estrutura, não copiar planta/arte. Não introduzir nome canônico, boss ou história. IDs `kronasta-montanha-a/b/c`; nomes de trabalho Sopé, Encosta e Cume. Mesma linguagem 2D mangá/cartoon do pântano, com rocha, capim de altitude e marcos pétreos novos.

## Planta antes da arte (56×48 por parte)
```
                    A/B saída24,0 / C mirante final
    beco de item ---- faixa superior (base+2) ---- marco
                  rampa v− na frente da faixa
    item/mirante ---- faixa intermediária (base+1)
                  rampa v− no outro extremo
    descanso ------ faixa inferior (base) ------ beco
                            entrada
```
A: entrada esquerda13,47 → rampa12,36 → travessia para direita → rampa42,20 → saída24,0.
B: entrada24,47 → desvio à direita → rampa40,36 → travessia para esquerda → rampa12,20 → saída24,0.
C: entrada24,47 → rampa12,36 → rampa42,20 → mirante24,10; retorno opcional por segunda sequência de rampas36,36 e16,20, formando laço caminhável, sem teleporte.

Altura absoluta: A0→2, B2→4, C4→6. Ligações material terra e mesma cota em ambas as pontas. Cada avanço exige subir; não é mapa plano com montanhas de fundo. Fileiras de relevo largas, contornos com retornos em blocos2×2 e faixas de caminhada explícitas. Rocha fora dos terraços bloqueia; sem muro invisível em caminho aparente. Caminho3–5 células; ramais2–3; dois patamares livres nas chegadas e pé de terra na mesma cota. Toda rampa sobe u−/v−. Pelo menos40% em platô, três itens por parte, um escondido, todos alcançáveis. Mato opcional em recessos. Becos terminam em item/vista; não fingir saída.

Ritmo por parte: base aberta → passagem de subida → banco de terreno amplo → curva estreita → vista superior aberta. Um marco principal no alto de cada parte (crista ou pináculo), dois secundários no máximo. Vegetação baixa perto das juntas. Cume com vista e laço de retorno, sem vitória inventada. Não usar teleporte para encurtar a descida.

Reaproveitar projeção, movimento, faces e sombras medidos. Tiles de altura0–6 e rampas com nível-base explícito ficam em tileset inline próprio, sem alterar rascunho/kit alheio. Capturas de TODOS os níveis, inclusive3–6. Arte só após blocagem e percurso. Textura nova de rocha em cores chapadas/cel shading; UV contínuo nas faces, sem pintar juntas falsas. Conferir cantos, patamares, cunhas e apoio do marco sem atores nas juntas. Entrega com prints por parte e limites de verificação.

## Revisão 2 — composição de montanha contínua
A versão anterior foi rejeitada visualmente: pistas suspensas, repetição de pedras, partes parecidas, ausência de recompensa visual no cume. Preservar as conexões e as rampas reais; reconstruir a sustentação como maciço contínuo com contorno irregular. Rocha bloqueada deve parecer maciço, sem vegetação disfarçando junta.

Planta de intenção (cotas absolutas, v- sobe):
```
A SOPÉ                    B ENCOSTA                    C CUME
      saída n2                  saída n4                marco rochoso n6
  mirante---trilha          beco---cotovelo              clareira oval
      rampa v- n1→2          rampa v- n3→4             /rampa     rampa\
 jardim / ramal-item      saliência / ramal-item       trilha   retorno
      rampa v- n0→1          rampa v- n2→3             \rampa     rampa/
 entrada + abrigo verde    entrada + patamar n2            entrada n4
```
A: alargar bolsões de vegetação baixa e permitir diagonais no percurso central, com maciço fechando o fundo. B: maior presença de rocha, trajetória recortada por saliências e patamares estreitos. C: clareira superior mais ampla, vegetação rara, marco em escala maior e panorama visível. Três becos mantêm os itens, um escondido por parte. Todo elemento distante e panorama é cenário; a silhueta caminhável continua derivada do mapa e validada por física. Sem novos personagens ou revelações canônicas.
