# Trailer v2 · roteiro (2:20)

13/11/2026 · 140 s, 1920×1080, 30 fps. Linguagem de página de mangá e de comics: quadros com
sarjeta (gutter) de papel, quadros que se abrem, racham e deslizam, linhas de velocidade,
retícula e onomatopeias desenhadas. Tudo o que aparece é do jogo de verdade (nada de recurso que
não existe, como a "enroscada", que ainda não foi feita).

Regras de texto: frases curtas, concretas, sobre coisas que só existem neste jogo. Nada de
"uma aventura épica", "prepare-se", "o destino", "como nunca antes". As falas dos personagens são
falas reais do jogo.

## Estrutura

| Tempo | Bloco | O que mostra | Linguagem de quadrinho |
| --- | --- | --- | --- |
| 0:00–0:08 | Abertura | Página preta. Um quadro vertical se rasga: mãos do Kael amarrando a rabiola no carretel. A linha estica. | Rasgo de papel; onomatopeia **TSK** quando o nó aperta |
| 0:08–0:16 | Kronasta | Quadro largo do céu de Kronasta com pipas; câmera desliza. Letreiro: **Kronasta. Doze bairros, um céu.** | Painel panorâmico com moldura grossa |
| 0:16–0:22 | Primeiro passo | Motivo nº 1: Kael e Rabbito saindo da Vila. Letreiro: **O Rabbito foi o primeiro.** | Faixa horizontal de largura total |
| 0:22–0:50 | A caminhada | **Motivo recorrente**: o mesmo quadro (Kael andando para a direita, mesma posição na tela) em 8 biomas, cada um com outro companheiro. Cortes no ritmo da música; a cada 2 cortes, um letreiro do estágio: **Bebê. Criança. Jovem. Adulto.** | O quadro desliza como página virando; a sarjeta passa pela tela |
| 0:50–1:02 | Particulares | Página com 4 quadros ao mesmo tempo, cada um com uma palavra: **Monte.** (Dóber) · **Reme.** (Capiboia no Pântano) · **Plane.** (Carcará da Nina nas setas) · **Mergulhe.** (Abismo). Depois **Cave.** e **Suba no vento.** na Serra. | Grade 2×2 que se recompõe; quadros entram com "pop" |
| 1:02–1:12 | Evolução | Ritual de evolução: silhueta, luz, a escolha entre três ramos do Azulão. Letreiro: **Três caminhos. Você escolhe um.** | Três quadros verticais lado a lado, um para cada ramo; dois se apagam |
| 1:12–1:34 | O duelo | Duelo no Mirante: corte, esquiva, **CRÍTICO** (o letreiro real do jogo), e o especial do Rabbito. No impacto, um quadro congelado em preto e branco com retícula. Em seguida, 6 campeões em sequência rápida e o letreiro **12 bairros. 12 campeões.** | Quadros em diagonal; impact frame P&B; onomatopeias **ZAAK**, **FWUSH**, **KRAK** |
| 1:34–1:50 | Gente de Kronasta | Retratos mangá com uma fala real cada: Tufanocorte, Retalho, Grampo, Nina, Gollia, Rato (o Rato em silhueta). | Quadro de retrato com balão de fala; corte seco entre eles |
| 1:50–2:02 | Muitos | Desfile: as criaturas andando em fila e depois a grade inteira de folhas de overworld se afastando até virar um mosaico. Letreiro com o número real de criaturas. | Zoom-out que transforma a página em mosaico |
| 2:02–2:12 | O lendário | Ruínas D: o chão treme, os pilares caem, uma silhueta enorme se ergue e **ruge**. A onda do rugido racha todos os quadros da tela. Corte seco para branco. | Quadros rachando; onomatopeia gigante **GRRRAAAOOO** atravessando a página |
| 2:12–2:20 | Fecho | Kael e Rabbito de costas, olhando o Estádio. Logo **SoulMonsters · Elo das Ruínas**. Data ou "em breve". | Última página, quadro único |

## A caminhada: os 8 cortes

| Ordem | Bioma (cena) | Companheiro | Estágio | Folha |
| --- | --- | --- | --- | --- |
| 1 | Jardim das Pipas (`park-trail`) | Farpim | Bebê | v2 pronta |
| 2 | Bosque (`kronasta-bosque-a`) | Gambalhote bebê | Bebê | v2 pronta |
| 3 | Vila Campina (`planicie-d`) | Papisco | Criança | v2 pronta |
| 4 | Gruta do Moinho (`caverna-c`) | Vertim | Criança | v1, pedir v2 |
| 5 | Vulcão (`vulcao-a`) | Trincaguarda | Jovem | v1, pedir v2 |
| 6 | Serra Gelada (`serra-gelada-a`) | Urso-polar jovem | Jovem | v1, pedir v2 |
| 7 | Abismo (`abismo-b`) | montado na Capiboia | — | sprite de nado existente |
| 8 | Palafitas (`kronasta-palafitas-b`) | Alvacordo | Adulto | v2 pronta |

Captura de cada corte (7 s, para sobrar na montagem):

```
godot --path godot --resolution 1920x1080 --fixed-fps 30 --write-movie corte.avi \
  -s tools/trailer_capture.gd -- --shot=motivo --scene=<cena> --partner=<id> [--at=u,v] [--zoom=1.8] --secs=7
```

O modo `motivo` esconde o HUD e o minimapa, aproxima a câmera e procura sozinho o trecho reto
mais longo para a direita da tela; `--at` fixa o ponto de partida quando a cena pede (por exemplo,
para fugir de uma árvore na frente do Kael).

## Trilha

Uma faixa de 2:20 com estes marcos:

| Tempo | Marco |
| --- | --- |
| 0:00–0:16 | Introdução contida (só um instrumento) |
| 0:16 | A batida entra junto com o primeiro passo |
| 0:22–0:50 | Pulso regular, um acento a cada 3,5 s para os cortes da caminhada |
| 0:50 | Virada para a seção de quadros simultâneos |
| 1:12 | Seção mais intensa: o duelo |
| 1:34 | Respiro para os retratos |
| 2:02 | Silêncio de 1 s antes do rugido; o rugido sem música |
| 2:12 | Acorde final no logo |

Sem faixa nova, eu monto uma edição de 2:20 a partir de `vento-aventura.ogg` (87 s), repetindo a
seção de pulso; funciona, mas os marcos ficam menos precisos.

## Decisões para o dono

- **Spoiler do lendário — decidido em 13/11/2026:** o dono confirmou somente silhueta e rugido,
  sem nome nem revelação da aparência. A bíblia guarda o Eremor como revelação do Ato 6.
- **O Rato:** a aparência dele ainda está pendente na bíblia; no trailer ele aparece em silhueta.
- **Número de criaturas:** o letreiro usa o número real de folhas de overworld no jogo na hora da
  montagem (hoje, 178 integradas).
