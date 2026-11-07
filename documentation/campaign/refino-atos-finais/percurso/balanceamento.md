# Balanceamento das lutas · 07/11/2026

Continuação de [lutas-reais.md](lutas-reais.md). Lá o XP passou a acompanhar os rivais, e o Kael
fica de 0 a +2 níveis de cada um. Aqui o assunto é a dificuldade de cada luta.

Tudo foi medido com o bot de `tools/duel_bot.gd`, com o Kael 1 nível acima do rival:

- **bot 4:** jogador casual;
- **bot 6:** jogador atento;
- **bot 8:** jogador experiente.

```
godot --headless --path godot -s tools/story_balance.gd -- --level=+1 --runs=12
godot --headless --path godot -s tools/duel_balance.gd -- --stages=all --level=+1 --skills=4,6,8 --runs=8
godot --headless --path godot -s tools/district_calibration.gd -- --runs=12 --stages=all
```

## O que estava errado

| Achado | Medição |
| --- | --- |
| Os duelos de história não tinham curva. | Do Navalha (Nv.30) à Jamile (Nv.50), os 22 duelos duravam 14 s e terminavam em vitória de qualquer bot, com 65% da linha sobrando. O chefe com nível tinha a linha de um parceiro comum (cerca de 115; o chefe original do Parque tinha 210), e a leitura dele era fixa em 6/7. |
| Os chefes começavam já na fase 2. | A fase 2 entrava em 55% de 250, o valor do chefe original. Com cerca de 115 de linha, o chefe nunca passava pela fase 1. |
| Bairros fáceis demais no começo e duros demais no fim, com picos. | Do Bambuzal ao Cais, o bot 4 vencia 100%. Da Serra em diante, o bot 4 ficava em 0%. O bot 6 caía de repente em duelos isolados: porto-4 0%, mirante-3 12%. |
| Leitura com degrau. | Muitos rivais passam de 100% para perto de 0% com um passo só de leitura (5 → 6). Por isso a fórmula por nível criava os picos. |
| O campeão das Palafitas não perdia. | O Veskoro ficava parado durante todo o golpe (aviso, impacto e recuperação, 3,7 s a cada 6,7 s). Venceu 100% mesmo com a leitura 10. |
| Os campeões perdiam peso. | Da Serra em diante, os campeões disputavam 2 rodadas, como os tenentes. |
| As moedas caíam. | Feira-5 pagava 70 e Cais-1 pagava 18. |

## O que mudou

**Duelos de história** (`encounter_model.gd`, só para chefe com nível de campanha; o chefe do
Parque continua igual):

- A linha do chefe é multiplicada por ×1,9 no Nv.30 e chega a ×2,7 no Nv.50.
- O dano do chefe é multiplicado por ×0,65 e chega a ×0,73: as lutas ficam mais longas sem que o
  Kael caia mais rápido.
- A leitura é 4 + (nível − 30)/6, com +1 na fase 2. Uma leitura maior encurta a abertura depois de
  cada corte.
- A fase 2 entra em 55% da linha do próprio chefe.
- Cada derrota seguida no mesmo duelo baixa um passo de leitura e 10% do dano, até 2 vezes
  (`Progression.story_assist` e `storyLossStreak`). Uma vitória zera a contagem, como no
  `districtLossStreak` dos bairros.

**Bairros** (`districts.json` e `morro_model.gd`):

- Cada rival tem a leitura calibrada no campo `"ai"`. A ferramenta procura a leitura mais próxima
  de uma curva-alvo, usando a média do bot 4 e do bot 6:
  - tenentes: 90% (Nv.9) → 65% (Nv.43);
  - campeões: 80% → 50%.
- A fórmula antiga (`district_ai_formula`) só vale para estágios sem o campo.
- Todo campeão disputa 3 rodadas.
- O Veskoro só para durante o aviso e o impacto. Na recuperação, ele se move (leitura 7).
- As moedas seguem pelo menos 2 × nível + 10 (×1,5 para campeões) e nunca diminuem ao longo da
  campanha.

## Resultado

### História

| Trecho | bot 4 | bot 6 | bot 8 | Duração |
| --- | --- | --- | --- | --- |
| Mormaço, Tufanocorte e ato 4 (Nv.27–33) | 100%, 36–45% da linha | 100%, 52–60% | 100%, 65–73% | 20–26 s |
| Ato 5: galpão, Gollia, Copa (Nv.34–37) | 100%, 20–33% | 100%, 49–52% | 100%, 61–69% | 21–29 s |
| Ruínas (Nv.40–45) | 91–100%, 10–19% | 100%, 28–39% | 100%, 54–61% | 24–32 s |
| Chave do Estádio (Grampo, Tyler, Faye) | 75–91%, 8–9% | 91–100%, 16–22% | 100%, 50–53% | 26–34 s |
| Jamile (Nv.50) | 25% (100% após duas derrotas) | 100%, 11% | 100%, 46% | 28–33 s |

### Bairros

| Trecho | bot 4 | bot 6 | bot 8 |
| --- | --- | --- | --- |
| Bambuzal e Beira-Canal | 62–100% | 100% | 100% |
| Feira, Cais, Industrial, Palafitas | 37–87% | 87–100% | 100% |
| Serra, Centro, Lajes, Porto | 25–62% | 100% | 100% |
| Mirante | 25–62% | 87–100% | 100% |
| Campeões de Lajes, Porto e Mirante | 0% na 1ª tentativa; 41–100% depois de 2 derrotas; 100% depois de 3 | 100% | 100% |

O jogador atento deixa de bater em picos de 0%. O casual passa de 0% para 25–62% no fim da
campanha e vence os campeões finais em até quatro tentativas.

## O que ainda falta

- **Percurso com lutas reais** do começo aos créditos, com estes valores
  (`campaign_walker.gd --fight=6`).
- **Playtest com pessoas.** Os bots 4 e 6 são estimativas. A curva casual do fim (25–62% nos
  bairros) é a mais incerta.
- **Selvagens do Parque abaixo do nível no ato 3.** Continuam como estão, porque são a fonte de
  rabiolas.
- **Moedas sem uso.** Só o Kit de Remendo (12) as consome. Uma loja ou outro uso de moedas é
  decisão de design.
