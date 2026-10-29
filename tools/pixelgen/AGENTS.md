# Pixelgen para agentes

Ferramenta para criar e animar os personagens do Soulmonsters por comandos. O projeto é um arquivo `.pixelgen.json`: abre igual na bancada (`npm run studio:pixel`), onde o responsável revisa e retoca.

```sh
npm run pixel -- help
```

## Fluxo obrigatório: desenhar → olhar → conferir

1. **Crie o projeto e as rampas antes de desenhar.** Cada material tem uma rampa do escuro para o claro (3 a 5 tons): `tinta` (contorno), `pele`, `cabelo`, `roupa`… Use a cor como `"pele:1"`, nunca hex solto no meio do desenho.
2. **Desenhe por partes, uma camada por parte**: `Pernas`, `Tronco`, `Braço de trás`, `Braço da frente`, `Cabeça`, `Cabelo`. É assim que a animação reaproveita a cabeça e o tronco entre quadros (op `copy`).
3. **Olhe o resultado depois de cada etapa.** Nunca entregue sem ter visto os PNGs:
   - `render --frame N --zoom 8`: quadro ampliado com grade a cada pixel e linha forte a cada 8;
   - `render --silhouette`: **a pose precisa ler só pela silhueta**. Se braços e pernas não se separam do corpo, redesenhe a pose antes de pintar;
   - `render --grounds`: o quadro sobre grama, terra, calçada e noite, em 3× e no tamanho real (1×). O que vale é o 1×;
   - `render --sheet`: todos os quadros lado a lado, para comparar proporção entre direções;
   - `render --gif <sequência>`: a animação no tempo real;
   - `render --onion`: o quadro anterior (verde) e o próximo (violeta) por baixo, para medir o deslocamento;
   - `ascii --frame N [--layer nome]`: a grade em texto com a legenda de cores, para corrigir pixels exatos.
4. **Rode `check` antes de entregar.** Ele sai com código 1 e lista os erros quando:
   - o contorno escuro cobre menos de 70% da borda;
   - falta contraste com grama, terra ou calçada;
   - há um quadro vazio;
   - os pés variam mais de 1 px numa sequência `idle`.

   Os avisos (noite, cores vizinhas parecidas, pixels soltos, figura pequena) pedem que você olhe de novo.

## Convenções do jogo

- **Personagem no overworld:** 48×64, pés na mesma linha de base (2 px de margem embaixo) e cabeça grande.
- **Direções:** `S SO O NO N NE E SE`. Nomes de sequência `<movimento>-<direção>`, como `walk-S` e `idle-NE`; quadros `<movimento>-<direção>-<n>`. A bancada usa esses nomes para montar o seletor de direção e movimento.
- **Movimentos:** `idle`, `walk`, `run`, `interact`, `attack`, `hurt`, `victory`, `fall`.
- **Tempos de referência:**
  - idle: 2 quadros, 700 e 350 ms;
  - walk: 4 quadros, 140/110/140/110 ms;
  - run: 6 quadros de 90 ms.
- **Espelhamento:** O, NO e SO podem nascer de E, NE e SE com `flip` (eixo x) na camada inteira. Confira depois se nenhum detalhe assimétrico (franja, mochila, cicatriz) mudou de lado sem querer.
- **Luz vinda de cima à esquerda:** o tom claro da rampa fica no lado esquerdo e no topo; o escuro, embaixo e à direita.
- **Contorno:** `tinta:0` por fora (op `outline`), depois o seletivo (`selout`) nas partes internas que precisam se separar.

## Operações (`draw <arq> ops.json`)

Uma lista JSON aplicada em ordem. Se uma operação falhar, nada é gravado e o erro diz qual foi (`Operação 3 (rect): …`).

Campos comuns:
- `frame`: índice, nome do quadro, nome de sequência, lista ou `"all"`. O padrão é o quadro 0.
- `layer`: índice ou nome. O padrão é a camada do topo.
- `color`: índice, `"#rrggbb"` ou `"rampa:tom"`; `0` é transparente.
- `size`: espessura do pincel. `clip: {x,y,w,h}` limita o desenho à área.

| op | campos | efeito |
| --- | --- | --- |
| `ramp` | `name`, `colors: ["#escuro",…,"#claro"]` | cria ou substitui uma rampa |
| `layer` | `add` (e `below`) ou `name` + `rename`/`visible`/`locked`/`remove` | camadas |
| `frame` | `add`, `copy`, `at`, `duration`, ou `target` + `rename`/`duration`/`remove` | quadros (`add` sem `copy` cria um quadro vazio) |
| `sequence` | `name`, `frames` (quadros vizinhos), `loop`, `direction` (`forward`, `reverse`, `pingpong`) | sequência de animação |
| `pixel` / `pixels` | `x`,`y` / `points: [[x,y],…]` | pontos |
| `line` | `points: [[x,y],…]`, `perfect` (padrão ligado) | linha contínua sem pixels dobrados nas quinas |
| `rect` | `x`,`y`,`w`,`h`, `fill` | retângulo cheio ou só a borda |
| `ellipse` | `cx`,`cy`,`rx`,`ry`, `fill` | elipse |
| `fill` | `x`,`y` | balde (4 vizinhos) na camada |
| `erase` | `rect` (opcional) | apaga a área ou a camada no quadro |
| `replace` | `from`, `to` | troca uma cor por outra na camada |
| `shift` | `dx`, `dy` | desloca a camada inteira |
| `flip` | `axis: "x"`/`"y"`, `rect` | espelha a camada ou a área |
| `mirror` | `axis` (coluna), `from: "left"`/`"right"` | completa a metade simétrica (vistas S e N) |
| `copy` | `fromFrame`, `fromLayer`, `rect`, `dx`, `dy`, `flip`, `opaque` | copia uma região de outro quadro ou camada (reaproveita a cabeça) |
| `outline` | `target`, `color`, `diagonal` | cria a camada `Contorno` por fora da figura |
| `selout` | `layer`, `target` | escurece a borda da camada com a própria rampa |

## Exemplo mínimo

```sh
npm run pixel -- new art/characters/nina/nina.pixelgen.json --size 48x64 --name Nina
npm run pixel -- ramp art/characters/nina/nina.pixelgen.json tinta "#141820"
npm run pixel -- ramp art/characters/nina/nina.pixelgen.json pele "#7a4a32" "#b9774f" "#e3a57a"
npm run pixel -- draw art/characters/nina/nina.pixelgen.json pose-idle-S.json
npm run pixel -- render art/characters/nina/nina.pixelgen.json --out /tmp/nina --frame 0 --zoom 8
npm run pixel -- render art/characters/nina/nina.pixelgen.json --out /tmp/nina --silhouette --frame 0
npm run pixel -- check art/characters/nina/nina.pixelgen.json
npm run pixel -- export art/characters/nina/nina.pixelgen.json --png nina-sheet.png --godot res://assets/characters/nina-sheet.png --tres nina.tres
```

Guarde os arquivos de operações (`pose-*.json`) junto do personagem. Eles são a receita da pose e permitem refazer ou ajustar sem redesenhar.
