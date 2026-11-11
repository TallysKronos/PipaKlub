# Regiões laterais jogáveis · v1

11/11/2026 · Planícies e Gruta do Moinho, Vulcão, Serra Gelada e Abismo saem do modo QA. Cada uma
abre num ponto da campanha e tem criaturas selvagens próprias, duas missões de moradores e um
guardião. São opcionais: não entram na sequência de objetivos da história (`kronasta_story.gd`).
Nas áreas delas, o objetivo do HUD vem de `side_regions.gd`.

## Quando abre e o que tem

| Região | Abre depois de | Selvagens (nível) | Guardião |
| --- | --- | --- | --- |
| Planícies + Gruta do Moinho | vencer o Lacertubo (Veredas) | Cristim, Papisco, Javali, Galhim · Vertim, Ossito, Viúva (10–16) | Estratonte, Nv.18 |
| Serra Gelada | emblema da Dona Neve (Alto da Serra) | Urso-polar jovem, Nimbordo, Lupunhal, Lupregente (32–36) | Borealvo, Nv.38 |
| Vulcão | soltar a Rabiolava (Aracati) | Trincaguarda, Gevardente, Trinca-brasas (34–36) | Tricórdio, Nv.40 |
| Abismo | emblema de Porto Novo | Vortespira, Hipomoranga, Reciforte, Alvorvela (37–42) | Coromar, Nv.42 |

O Abismo continua exigindo um parceiro com montaria aquática (a Capiboia) para mergulhar.

## Missões

| Região | Buscar itens | Achar alguém |
| --- | --- | --- |
| Planícies | Seu Bento: 3 pás do moinho (Colinas, Vale das Pedras, gruta) | Iara: o filho Tito, perdido nas Galerias de Cristal |
| Serra Gelada | Seu Tomé: 3 flores de gelo (uma por trecho) | Bia: o irmão Caio, preso no Desfiladeiro de Gelo |
| Vulcão | Mestre Brasa: 3 pedras de brasa (ilha leste, mesa central, pico oeste) | Dona Cinza: o ajudante Caco, no alto da crista leste |
| Abismo | Seu Jacinto: 3 pérolas das marés (Labirinto, Cidade Afundada, Trono) | Celina: a mergulhadora Lia, na Cidade Afundada |

- Os itens e a pessoa perdida só aparecem no mapa depois do pedido (props `requer`). Achada, a
  pessoa some do lugar onde estava (`ocultar_apos`) e aparece ao lado de quem pediu.
- A recompensa é paga uma vez (recibos `*-pedido-v1`, `*-v1`), em moedas, Kits de Remendo e materiais.
- A primeira vitória sobre o guardião dá a rabiola dele e o tira do mapa.

## Como acrescentar uma região

1. Os dados entram em `REGIONS` de `godot/scripts/campaign/side_regions.gd`: cenas, marco de
   abertura, textos, flags, recibos e recompensas das duas missões e o guardião.
2. O guardião entra em `GUARDIANS` de `encounters.gd`. A validação do save (`state.gd`) e a
   vitória já leem dessa tabela; falta só o diálogo da ação no `front_end.gd`.
3. No gerador do mapa, use `quest_npc`, `quest_item` e `spot` (em `tools/gerar-mapas-morro.py`).
   Itens de missão usam ids a partir de 99001, para não mexer nos achados que já existiam.
4. Selvagens: arte em `tools/package-planicies.py`, tabela em `tools/criaturas/gerar-encontros.py`
   e níveis em `park_pacing.gd`.
5. Teste: acrescente a região em `godot/tests/side_regions_checks.gd`.

## Pendente

- A arte das criaturas é provisória: recorte dos concepts do plano de povoamento, em
  `godot/assets/campaign/planicies-v1/` e `regioes-v1/`.
- Não há arena de batalha de caverna, gelo, vulcão ou fundo do mar: as batalhas usam a arena padrão.
- Os moradores usam sprites existentes (Tião, Juninho, mãe, Zeca, Bia, Cauê, Celina, Lia, Nilo).
- As rabiolas das criaturas novas ficam na bolsa, mas ainda não montam parceiros.
- Ninguém jogou essas regiões ainda: falta ver o ritmo dos encontros, a distância dos itens e a
  dificuldade dos guardiões.
