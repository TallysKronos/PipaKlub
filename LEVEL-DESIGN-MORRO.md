# Morro do Sol — estudo e proposta de level design

Data: 18/10/2026. Estado: proposta para prototipação; o mapa jogável ainda não foi reformulado por este estudo.

## Diagnóstico

O piloto validou navegação, colisões, escadas, profundidade e montagem de arte modular. Isso é uma base técnica útil. A experiência espacial continua pouco expressiva: o jogador atravessa espaços, mas quase não interpreta o bairro nem decide como explorá-lo.

A geometria caminhável principal se resume a quatro regiões conectadas em cadeia: praça (544 × 192), viela (160 × 192), escada (160 × 128) e patamar (544 × 128). Há muitos pontos no grafo de navegação, mas eles não representam escolhas significativas de exploração.

O cálculo das rotas mais curtas, usando a velocidade de 145 px/s, encontrou aproximadamente 128 px até Zeca e 1.216 px até Bia: 0,9 e 8,4 segundos de deslocamento contínuo. São medidas geométricas, não tempos observados de uma sessão. O problema não é a duração curta: aumentar distâncias sem acrescentar acontecimentos apenas prolongaria o vazio.

O piloto contém dois encontros; o bairro completo prevê cinco. A área de continuação futura termina em uma mensagem e não entrega uma descoberta. Casas e portas sugerem possibilidades maiores que suas interações atuais. As regiões retangulares, a repetição do chão e os NPCs isolados deixam evidente a montagem. O contraste entre NPCs ilustrados e Kael chibi também prejudica a unidade de escala.

O HUD ocupa espaço relevante em uma janela pequena. Precisamos avaliar composição e navegação com os painéis abertos e fechados. Um cenário pode funcionar numa captura limpa e perder legibilidade durante o jogo.

## Referências estudadas

### A Short Hike — curiosidade em um espaço compacto

Adam Robinson-Yu descreve caminhos menos óbvios, recompensas pela curiosidade e atividades que interrompem o ritmo da caminhada. Aplicação proposta: desvios curtos com acontecimentos próprios, sem expandir o bairro apenas para aumentar seu tamanho. Essa aplicação é nossa interpretação, não uma receita fornecida pelo autor.

Fonte primária: [Crafting a tiny open world, PlayStation Blog](https://blog.playstation.com/2021/08/05/crafting-a-tiny-open-world-a-look-behind-the-scenes-at-the-creation-of-a-short-hike/).

### Firewatch — lugares que sustentam a história

Jane Ng apresenta marcos ligados à narrativa e momentos de descoberta entre eles. Relata também que o greybox não bastou para julgar caminhada e conversas: uma fatia representativa com arte e voz tornou a avaliação possível. Aplicação proposta: validar o percurso simples, depois testar uma pequena sequência com contexto e acabamento suficiente para sentir seu ritmo.

Fonte primária: [Making the World of Firewatch, apresentação GDC 2016](https://media.gdcvault.com/gdc2016/Presentations/Ng_Jane_MakingTheWorld.pdf), especialmente páginas 54–75.

### Link’s Awakening — escala e unidade visual

Yoshiki Haruhana explica a direção de diorama e o equilíbrio entre simplicidade, detalhes e escala dos personagens. Aplicação proposta: usar Kael como régua para portas, degraus, pessoas e objetos; reduzir detalhes que competem com a leitura do caminho. Não precisamos copiar materiais ou estética de miniatura.

Fonte primária: [Entrevista com Yoshiki Haruhana, Nintendo](https://www.nintendo.com/de-de/News/2019/Oktober/Grafikdirektor-Yoshiki-Haruhana-enthullt-was-hinter-dem-uberarbeiteten-Grafikstil-von-The-Legend-of-Zelda-Link-s-Awakening-steckt--1656228.html).

Esses textos e slides foram consultados. Este estudo não equivale a jogar novamente esses títulos ou assistir integralmente às palestras. Pokémon Emerald e HeartGold/SoulSilver ficam como referências para uma próxima análise comparativa de entradas de cidade, espaços sociais e atalhos; não foram usados como evidência medida nesta auditoria.

## Intenção do bairro

O Morro do Sol deve apresentar uma comunidade que vive de pipas: o jogador chega, conhece alguém, percebe um destino acima das casas e descobre pequenos acontecimentos ao subir. Ao sair, deve lembrar de lugares e pessoas, não de cinco botões de batalha.

Três pilares:

1. **Subida legível:** ver pistas do próximo lugar antes de chegar, com revelações graduais da paisagem.
2. **Bairro vivido:** ações locais, conversas e objetos que expliquem quem mora ali.
3. **Curiosidade com retorno:** explorar entrega informação, uma cena ou uma observação; não exige sempre moeda ou item.

A ordem das cinco batalhas permanece. A circulação pode permitir visita e descoberta antes de liberar o desafio correspondente. O líder continua escondido até o momento narrativo adequado; um marco pode anunciar o local da final sem revelar sua identidade.

## Macropercurso proposto

```text
Quintal → Praça de chegada → Viela → Escadaria → Laje → Mirante → Parque
              │               │         │        │
              └─ conversa     └─ pátio ─┘        └─ observação
                   opcional       lateral
              ↑                                   │
              └──────── atalho de retorno ─────────┘
```

Esquema conceitual: não define coordenadas, custos de produção ou conexão final com a geografia da cidade.

| Lugar | Função na experiência | Composição e acontecimento propostos |
| --- | --- | --- |
| Praça de chegada | Orientar e apresentar Zeca | Entrada protegida, área social compacta e visão parcial da subida. Zeca está associado a uma atividade local. |
| Viela | Comprimir e despertar curiosidade | Varais e fachadas enquadram o caminho. Um pátio lateral entrega uma conversa ou pequena cena e reconecta adiante. |
| Escadaria da sombra | Mudar altura e apresentar Bia | Trecho sombreado seguido de abertura. A posição de Bia relaciona encontro e terreno; não é apenas um NPC colocado no centro. |
| Laje dos ventos | Oferecer respiro | Horizonte mais amplo, sinais de vento e uma atividade de observação opcional. Abre um retorno conveniente à praça. |
| Mirante | Antecipar o clímax | Revela o Parque dos Ventos e a presença de uma disputa. Mantém o campeão desconhecido. |
| Parque dos Ventos | Encerrar o arco do bairro | Entrada e arena reconhecíveis. A revelação do líder acontece no contexto do encontro. |

Os cinco pontos de encontro devem ser associados a esses lugares conforme o roteiro existente. Nomes, ordem e estado das batalhas precisam continuar vindo dos dados da campanha; o esquema não autoriza substituir adversários silenciosamente.

## Primeira fatia a reconstruir

Fazer apenas chegada → Zeca → escolha na viela → Bia → retorno. O restante recebe uma planta coerente, sem produção final antecipada.

- Na chegada, mostrar uma saída clara e um marco da parte alta, sem setas permanentes obrigatórias.
- No encontro de Zeca, combinar aproximação, diálogo e batalha com transições curtas e retorno à posição correta.
- Após o encontro, oferecer caminho direto e desvio lateral. Ambos devem ter leitura própria; o desvio termina em uma descoberta concreta e volta à rota.
- Na escadaria, usar altura, sombra e enquadramento para construir a chegada a Bia.
- Depois, abrir uma conexão de retorno. Ela precisa reduzir um trajeto que o jogador realmente queira repetir.

O primeiro prêmio opcional pode ser diálogo ou registro de observação. Qualquer concessão de item, moeda ou progresso online exige validação e idempotência no servidor. Não introduzir recompensas persistentes apenas no cliente para preencher o cenário.

## Regras visuais e espaciais

- Definir largura de passagem e escala de portas/degraus a partir do personagem e do seu volume físico. Testar os valores no jogo antes de padronizar.
- Separar chão caminhável, obstáculo e fundo pela composição, contraste e contorno. A borda visual deve corresponder à colisão.
- Organizar fachadas em blocos e variar seus recuos. Evitar paredes repetidas que exponham uma grade rígida sem intenção urbana.
- Reservar silhuetas únicas para marcos: caixa-d’água, árvore, cobertura da praça e parque. Não dar a cada objeto o mesmo destaque.
- Manter o piso discreto perto do personagem e dos pontos interativos. Flores, bandeiras e pedras são acentos.
- Testar oclusão com pessoas e objetos em movimento; preservar leitura dos pés e da saída de áreas estreitas.
- Tratar portas: interação real, informação explícita de indisponibilidade ou desenho que não prometa uma entrada.
- Aproximar os NPCs do design chibi de Kael. Isso acompanha a nova montagem, mas não substitui o trabalho do percurso.
- Reduzir a cobertura permanente dos painéis. Objetivo e navegação assistida continuam disponíveis como ajuda.

## Ordem de execução

1. Desenhar duas plantas alternativas com as mesmas funções: uma subida com laço lateral e uma praça central com duas conexões. Comparar orientação, retorno e custo de arte.
2. Montar a candidata mais clara no Tiled usando blocos e o kit atual. Manter o contrato de colisão, escadas, interação e profundidade.
3. Jogar a fatia com diálogos e acontecimentos mínimos. Remover caminhos sem propósito antes de decorar.
4. Aplicar uma composição representativa e NPCs coerentes. Gerar assets específicos somente quando a planta indicar uma necessidade real.
5. Testar com pessoas que não conheçam o mapa; registrar decisões, hesitações e locais lembrados. Ajustar e repetir.
6. Expandir para os cinco encontros após a fatia funcionar. Replicar princípios nos outros bairros, preservando identidades diferentes.

## Critérios de aprovação

São critérios propostos, ainda não resultados de testes:

- Um jogador novo encontra Zeca e entende como continuar sem abrir uma lista de destinos. A ajuda pode estar disponível.
- O jogador distingue pelo menos três lugares por características do mundo, em vez de números de batalha.
- Existe uma escolha de exploração com consequência perceptível e um retorno útil; becos sem recompensa intencional são removidos.
- O próximo destino tem uma pista legível sem expor a identidade do campeão.
- Nenhum trecho exige caminhada longa sem orientação ou acontecimento. Avaliar por observação, sem impor duração universal.
- Nenhuma fachada convida a atravessar uma parede invisível; nenhum obstáculo decorativo contradiz a física.
- Desafio bloqueado continua bloqueado mesmo quando seu local pode ser visitado.
- Batalha e retorno preservam posição, progresso e recompensas; o modo piloto permanece isolado do fluxo normal até aprovação.
- A cena mantém leitura na janela de desktop com HUD e também com navegação assistida desligada.

Fazer uma primeira rodada qualitativa com aproximadamente cinco pessoas, sem instruir o caminho. Registrar primeiro movimento, erros, pedido de ajuda, desvio descoberto e lembrança dos lugares. Testes automatizados verificam regressões técnicas; diversão, orientação e identidade precisam dessa observação.

## Entrega desta etapa

Estudo e proposta de redesenho concluídos. Próxima entrega recomendada: duas plantas comparáveis e uma fatia jogável reconstruída da chegada até Bia. O mapa atual, a branch e os dados de campanha não foram modificados por esta documentação. Não houve publicação, merge ou deploy.

Atualização posterior: a primeira fatia foi implementada e auditada em [EXPLORATION-V2.md](assets/world/morro-pilot/EXPLORATION-V2.md). Os limites e resultados dessa implementação estão separados do estudo original acima.

Nova decisão explícita do responsável: o Morro passa a ser composto por cinco mapas, e a vitória no encontro atual libera fisicamente a passagem para o próximo. Essa decisão substitui a proposta inicial de visitar livremente todas as áreas antes de vencer os encontros. A implementação atual está em [morro-road-v1](assets/world/morro-road-v1/README.md), preservando o quintal e os cinco encontros existentes.
