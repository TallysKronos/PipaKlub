# Trailer v3 · cinemáticas, evolução e companheiros (2:20)

20/11/2026 · 140 s, 1920×1080, 30 fps, trilha `godot/assets/audio/music/trailer-v2/trailer-v2.ogg`
e rugido `eremor_rugido_01.wav` em 2:03. Tudo o que aparece foi gravado no jogo
(`godot/tools/trailer_capture.gd`) e composto em linguagem de mangá por
`tools/trailer/montar_trailer_v3.py` (quadros, sarjeta de papel, retícula, linhas de velocidade,
onomatopeias do pacote `art/trailer-v2`).

## Estrutura

| Tempo | Bloco | Plano(s) | Linguagem |
| --- | --- | --- | --- |
| 0:00–0:09 | Kronasta | `kronasta-ceu-r4.png` | Quadro que se abre da fresta; "Kronasta. Doze bairros, um céu." |
| 0:09–0:16 | Primeiro passo | `m01` (Rabbito) | Faixa larga; "O Rabbito foi o primeiro." |
| 0:16–0:31 | A caminhada | `m02` `m03` `m04` `m06` `m07` | Mesma faixa, página virando; Bebê. Criança. Jovem. Adulto. |
| 0:31–0:38 | Três faixas | `m08` `m10` `m11` | Três companheiros ao mesmo tempo, faixas inclinadas |
| 0:38–0:46 | Grade | `m09` `m12` `m13` `m14` | 2×2 com "pop"; "Um parceiro em cada bairro." |
| 0:46–1:02 | Evolução | `evo-rastro`, `evo-mestre` | Ritual real: Rabbito → Rastro dos Ventos; CINCO CAMINHOS; ritual do Mestre dos Fios; VOCÊ ESCOLHE UM. |
| 1:02–1:12 | Muitos | folhas `overworld-animations-v1` | Mosaico andando que se afasta; número real de folhas |
| 1:12–1:34 | Guardiões | `g-mormacoStory` `g-grutaBoss` `g-vulcaoBoss` `g-abismoBoss` `g-geleiraBoss` | Cinemáticas novas do jogo (`guardian_cinematic.gd`) |
| 1:34–1:42 | O Carretel Negro | `possessao` | Encenação real da possessão do Mormaço |
| 1:42–1:57 | Duelo | `duelo` | Quadro cheio e depois dois enquadramentos diagonais; ZAAK, KRAK |
| 1:57–2:02 | Especial | `impact-especial-rabbito.png` | Impact frame P&B; FWUSH; CRÍTICO! |
| 2:02–2:03 | Silêncio | — | Página preta |
| 2:03–2:12 | O lendário | `g-eremor` (silhueta) | Página do guardião com "???"; GRRRAAAOOO racha a tela |
| 2:12–2:20 | Fecho | `fecho-estadio.png` | SOULMONSTERS · ELO DAS RUÍNAS · EM BREVE |

## Cinemáticas novas no jogo

`godot/scripts/campaign/guardian_cinematic.gd`: a câmera se aproxima do guardião com tremor,
uma página de três quadros (retrato, nome, onomatopeia) se abre e se rasga de volta para o mapa.
Toca uma vez por sessão antes do primeiro desafio de Mormaço, Estratonte, Tricórdio, Coromar e
Borealvo; Esc pula. Sem efeito em save ou recompensa.

## Regravar

```
# um plano (ver tools/trailer: lote em PLANOS abaixo)
godot --path godot --resolution 1920x1080 --fixed-fps 30 --write-movie g-vulcaoBoss.avi \
  -s tools/trailer_capture.gd -- --shot=guardiao --id=vulcaoBoss --secs=12
# montagem
python3 tools/trailer/montar_trailer_v3.py --planos <pasta-dos-mp4> --saida trailer-v3.mp4
```

Planos: `evo-mestre` (`--shot=evolucao --from=rastro-dos-ventos --to=mestre-dos-fios --escolha=3`,
17 s), `evo-rastro` (`--from=rabbito --to=rastro-dos-ventos --escolha=2`, 13 s), `g-<id>` (`--shot=guardiao
--id=<id>`, 12 s; `g-eremor` com `--silhueta`), `possessao` (`--shot=possessao`, 10 s), `duelo`
(`--shot=duelo-mirante`, 16 s) e `m01`…`m14` (`--shot=motivo --scene=<cena> --partner=<id>`, 7 s):
park-trail/rabbito, kronasta-bosque-a/gambalhote-baby, planicie-d/papisco, caverna-c/vertim,
vulcao-a/trincaguarda, serra-gelada-a/urso-polar-young, kronasta-palafitas-b/alvacordo,
kronasta-pantano-a/capivara-boia, kronasta-mirante-a/raisoberano, kronasta-porto-b/jubarco,
kronasta-lajes-b/jaguarluar, kronasta-montanha-c/tufanocorte, kronasta-centro-a/farpim,
planicie-a/mestre-dos-fios.

## Pendências

- As HUDs novas (Dex e telas) não estão no repositório; quando chegarem, regravar `evo-*`.
- A abertura não usa `abertura-carretel.png`: tem carretel de madeira, e o dono pediu que o
  Carretel não tenha madeira.
