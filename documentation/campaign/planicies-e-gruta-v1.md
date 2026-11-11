# Planícies de Kronasta e Gruta do Moinho · região jogável v1

11/11/2026 · primeira região nova fechada do começo ao fim, para servir de molde às outras
(Vulcão, Serra Gelada, Abismo, Morro v3).

## Onde fica na campanha

- **Abre depois do Lacertubo** (flag `guardianDefeated`, Veredas, início do Ato 2). Antes disso,
  só no modo QA.
- Entrada pelo mapa de Kronasta (região "Planícies de Kronasta"), chegando na Planície A pelo oeste.
- Região lateral e opcional: não entra na sequência de objetivos da história (`kronasta_story.gd`).
  O objetivo do HUD nas seis áreas vem de `planicie_story.gd`.

## Níveis e criaturas selvagens

| Área | Nível | Espécies (peso) |
| --- | --- | --- |
| Planície A / B / C | 10–12 / 11–13 / 12–14 | Cristim 40, Papisco 35, Javali (criança) 15, Galhim 10 |
| Gruta A / B / C | 12–14 / 13–15 / 14–16 | Vertim 40, Ossito 35, Viúva (criança) 25 |
| Guardião (Gruta C) | 18 | Estratonte (adulto) |

- A arte é **provisória**: recorte dos concepts do plano de povoamento (`tools/package-planicies.py`
  → `godot/assets/campaign/planicies-v1/`). Quando a arte final chegar, troque o PNG e mantenha o id.
- Tabela em `tools/criaturas/gerar-encontros.py` (regiões `planicie` e `caverna`). A Caverna do
  Mural ganhou a chave própria `caverna-mural`, com a tabela de antes; em `wild_tables.gd` vence
  o prefixo mais longo.
- As rabiolas que as criaturas novas deixam ficam na bolsa, mas ainda não montam parceiros.

## Missões

1. **As pás do moinho** (Seu Bento, alto da colina dos Campos do Vento). O pedido revela três pás
   (`pa-do-moinho`): uma nas Colinas do Moinho, uma no círculo de pedras do Vale das Pedras e uma
   na galeria dos cristais da Gruta A. A entrega dá 60 moedas, 2 linhas enceradas e 1 Kit de Remendo.
2. **O Tito na gruta** (Iara, Colinas do Moinho). O pedido faz o Tito aparecer no beco dos cristais
   azuis da Gruta B. Achado, ele volta para casa (aparece ao lado da Iara), e a Iara dá 50 moedas
   e 2 Kits de Remendo.
3. **Estratonte** (ilha do Lago Subterrâneo, Gruta C). Guardião opcional, Nv.18. A primeira vitória
   dá a rabiola dele e o tira do lago.

Recibos: `planicie-moinho-pedido-v1`, `planicie-moinho-v1`, `gruta-tito-pedido-v1`,
`gruta-tito-achado-v1`, `gruta-tito-v1`; o duelo usa o tipo de encontro `gruta-boss`.

## Arquivos

- `godot/scripts/campaign/planicie_story.gd`: abertura, objetivo do HUD e as conversas.
- `godot/scripts/campaign/encounters.gd`: `start_gruta_boss` e a vitória.
- `godot/scripts/campaign/state.gd`: validação do `gruta-boss` e dos selvagens da região.
- `tools/gerar-mapas-planicie.py`: moradores, pás, Tito e guardião nos mapas.
- `godot/tests/planicie_story_checks.gd`: o fluxo inteiro (abertura, selvagem, missões, guardião).

## Pendente

- Arte final das oito formas e uma arena de batalha de caverna (hoje a gruta usa a arena padrão).
- Sprites próprios para o Seu Bento e o Tito (hoje usam os do Tião e do Juninho).
- Playtest humano: ritmo dos encontros, distância das pás, dificuldade do Estratonte.
