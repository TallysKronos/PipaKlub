# Percurso com lutas reais · 05/11/2026

Nos percursos anteriores (`atos-1-3.md`, `atos-4-6.md`), o caminhante resolvia cada duelo com a vitória direto no modelo. Nesta rodada um bot assume os controles e joga cada luta até o fim no modelo real do jogo (`tools/duel_bot.gd`). O bot lê as linhas do mesmo jeito que a IA dos rivais: mira no cruzamento, espera o foco e puxa. No nível 6 ou mais, ele também espera o escudo da Mata verde baixar. Depois de uma derrota, cuida do parceiro com Kit de Remendo (Equipe → Cuidar) e tenta de novo. O XP vem só das lutas jogadas, sem saltos de nível.

```
godot --path godot -s tools/campaign_walker.gd -- --from=lohan --fight=6
godot --headless --path godot -s tools/duel_balance.gd -- --stages=all --level=+1 --skills=4,6,8 --runs=6
```

## O que a medição mostrou (antes das correções)

| Achado | Evidência | Correção |
| --- | --- | --- |
| Os duelos de história não davam XP, e a tela de resultado prometia XP do parque. | `story_win` não existia; a prévia caía no XP regional (até 80). | Toda vitória paga uma fração do custo do nível do rival (`partner_levels.win_xp`). A parte é maior quando o Kael está atrás e menor quando está à frente. A prévia mostra o mesmo valor que é creditado. |
| Os bairros levavam o Kael só ao Nv.23 no Mirante, cujo campeão é Nv.44. | Soma das recompensas de `districts.json`. | A mesma regra; o valor autoral fica como mínimo. |
| A IA dos rivais chegava ao máximo (10) no Nv.14 e ficava assim até o fim. | `ai_level = nível − 4`; com 1 nível de vantagem, o bot nível 7 perdia quatro vezes seguidas para a Veyra. | A leitura sobe um passo a cada 6 níveis. Os campeões ficam um passo acima (2 no Bambuzal, 9 no Mirante). |
| O escudo da Mata verde (−60% de dano quando ameaçada) não tinha sinal. | Sem esperar o escudo, o bot perdia todos os duelos contra a Mata verde. Esperando, vencia de 50% a 87%. | Anel de folha e o aviso "Defesa da folha · espere baixar". |
| A Tainá venceu 5 vezes seguidas e o Tervan 9, e cada derrota rendia 20 XP. | Percurso Serra → Porto Novo. | Cada derrota seguida baixa um passo a leitura do rival de bairro (até três). Perder paga 30% do XP da vitória, e vencer zera a contagem. |
| O parceiro entrava em lutas encadeadas com a armação gasta e caía em 10 s. | Navalha e Capanga com 29% de armação. | O convite do duelo avisa quando o parceiro está abaixo de 50%. |
| Depois de "Aprender Cavar", o Kael ficava parado. | O aviso aberto pelo callback da confirmação devolvia a pausa da própria confirmação. | `_confirm_park` repassa a liberação ao aviso. |
| Depois de soltar a Nina nas Ruínas (e no Aracati), o Kael ficava parado. | O aviso devolvia a pausa de uma encenação curta. | As duas encenações liberam a própria pausa antes do aviso. Uma pausa que já existia antes de um aviso continua valendo (`autosave_recovery_checks`). |
| No cume da Serra, o botão apontava para o Tatutrama ou o Tufanocorte ao lado da terra fofa. | Empate de distância. | Objetos vencem empates; depois da lição, o tatu cede a vez. |
| Os selvagens de Cais, Aracati, Vila Operária, Pântano e Serra eram de Nv.1 a 8. | Níveis de prévia. | Os selvagens seguem a faixa de nível de cada região. |

## Resultado com as correções

| Trecho | Lutas | Derrotas | Pior sequência | Campeões (Kael × rival) |
| --- | --- | --- | --- | --- |
| Bambuzal → Serra (atos 1–4) | 50 (10 selvagens) | 2 | 1 | Lohan 14×12, Kleie 16×15, Zulmira 18×18, Marisol 21×21, Bruno 25×24, Caio 28×27 |
| Serra → Porto Novo (ato 4–6, antes do amortecedor) | 61 | 25 | Tervan 8 | Dona Neve 30×30, Leo Antena 34×33, Tainá 37×36 |
| Porto Novo → créditos e epílogo | 26 | 7 | Jurandir 2 | Jurandir 40×40, Ícaro 45×44, Jamile 48×50 |

O Kael acompanha os rivais com 0 a +2 níveis, sem treino à parte. O último trecho foi do Porto Novo aos créditos e às quatro páginas do epílogo sem nenhum problema. Cada derrota se resolveu em uma ou duas tentativas.

## O que ainda falta

- **Final com pouco peso.** Os duelos 1 contra 1 de história (Estádio, Ruínas) se decidem em cerca de 14 s: a Jamile, Nv.50, cai com 63% da linha do Kael. Esse formato é tudo ou nada. Com mais linha para o rival, o bot passa a perder em 12 s, então não é questão de ajustar números. Proposta: usar na chave do Estádio o formato de rodadas dos bairros.
- **Selvagens do Parque abaixo do nível.** No ato 3 ainda aparecem selvagens de Nv.2 a 8, que só interrompem. Eles não foram cortados porque são a fonte de rabiolas para montar parceiros.
- **Nível 6 do bot.** O bot nível 6 é uma estimativa de jogador atento. Só um playtest com pessoas confirma a curva.
