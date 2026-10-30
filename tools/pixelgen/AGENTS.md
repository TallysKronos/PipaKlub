# Pixelgen para agentes

Ferramenta para criar e animar os personagens do Soulmonsters por comandos. O projeto é um arquivo `.pixelgen.json`: abre igual na bancada (`npm run studio:pixel`), onde o responsável revisa e retoca.

## Direção atual: Soulmon DS

O usuário rejeitou a leitura dos lotes grandes de Kael e pediu uma direção próxima de Pokémon Ranger DS. **Não usar as bibliotecas de Kael v1/v2 nem o modelo genérico de cabeça grande como arte aprovada.** Os exemplos antigos abaixo são demonstrações técnicas, não o padrão artístico atual.

Para personagens novos: `pixel new personagem.pixelgen.json --profile soulmon-ds-v1 --body jovem --name Nome`. Corpos disponíveis: jovem, adulto e robusto; dimensões: 48×64 (padrão) ou 32×48. A base cria oito direções vazias, camadas, poses-guia, ficha e paleta editável, não uma figura automaticamente pronta.

Desenhe e revise uma pose em 1× antes de marcar `profile arquivo --base-reviewed true`; faça e revise um ciclo curto antes de marcar `--cycle-reviewed true`. Só depois expanda a biblioteca. Não marque sem olhar. Use `check` para cabeça grande/solta, proporção, apoio e paleta, sem confundir aprovação técnica com artística. Roupas, pele, cabelo e acessórios são próprios de cada personagem. O conceito v3 é uma referência visual, não uma folha nativa pronta para conversão automática.

`pixel pack idle.pixelgen.json walk.pixelgen.json --out pacote` monta documentos separados sem redimensionar, exigindo mesmo personagem, célula, paleta e pivô. Contratos, guias e limites em [CHARACTER-DS.md](CHARACTER-DS.md).

```sh
npm run pixel -- help
```

Leia antes o [`ESTILO-PIXEL.md`](ESTILO-PIXEL.md): proporção, contorno, cor, luz e animação do jogo, com as fontes.

## Fluxo obrigatório: desenhar → olhar → conferir

0. **Ficha do personagem primeiro.** Ela fixa os números que valem em todas as direções:
   ```sh
   npm run pixel -- sheet nina.pixelgen.json --set nome=Nina --set cabecas=2.5 --set altura=54 --set base=61 \
     --set cores=16 --set rampas=tinta,pele,cabelo,roupa --set referencia=idle-S-1 --set preenchimentoMax=0.75
   ```
   Também aceita um JSON (`sheet nina.pixelgen.json ficha.json`). Os campos são `nome`, `cabecas`, `altura`, `base` (linha dos pés), `larguraMax`, `cores`, `rampas`, `preenchimentoMax` (silhueta-alvo), `referencia` (quadro que define cabeça e membros), `partes` (nomes das camadas, se forem outros) e `notas`.
1. **Crie o projeto e as rampas antes de desenhar.** Cada material tem uma rampa do escuro para o claro (3 a 5 tons): `tinta` (contorno), `pele`, `cabelo`, `roupa`… Use a cor como `"pele:1"`, nunca hex solto no meio do desenho.
2. **Desenhe por partes, uma camada por parte**: `Perna de trás`, `Perna da frente`, `Braço de trás`, `Tronco`, `Braço da frente`, `Cabeça` e `Cabelo` (opcional). As receitas animam movendo essas camadas, e a op `copy` reaproveita a cabeça e o tronco entre quadros. "Frente" é o membro mais perto da câmera.
3. **Marque a pose** do quadro parado (op `pose` ou comando `pose`). O esquema legado tem 9 pontos: `topo` (alto da cabeça), `queixo`, `ombroTras`, `ombroFrente`, `maoTras`, `maoFrente`, `quadril`, `peTras` e `peFrente` (o pixel do pé que toca o chão). Confira com `render --pose`.
   Para bases DS novas, use o esqueleto de 14 juntas (também pescoço, cotovelos e joelhos), `skeleton --complete`, apoio por quadro e editor por arraste. Preserve `.pixelgen.json`: Aseprite não armazena esse rig. O rig guia desenho, não converte recortes em pixel art final. Ver CHARACTER-DS.md.
4. **Gere os ciclos pelas receitas** e depois ajuste à mão:
   ```sh
   npm run pixel -- recipe nina.pixelgen.json idle S --base idle-S-1 --replace
   npm run pixel -- recipe nina.pixelgen.json walk S --base idle-S-1
   npm run pixel -- recipe nina.pixelgen.json run E --base idle-E-1 [--stride 1.5]
   ```
   A receita cria `<movimento>-<dir>-1..n` no fim, com os tempos do jogo e a sequência. Ela inclina pernas e braços a partir do quadril e do ombro, faz o sobe e desce do corpo, levanta o pé que passa e move os pontos da pose junto. Se houver camada `Contorno`, ela é refeita em volta. **O resultado é um rascunho de tempo e espaçamento:** redesenhe joelho, pé e mão nos quadros de contato e passagem antes de entregar. `--replace` refaz um ciclo que já existe. O próprio quadro base pode estar entre os substituídos, como no idle.
5. **Olhe o resultado depois de cada etapa.** Nunca entregue sem ter visto os PNGs:
   - `render --frame N --zoom 8`: quadro ampliado com grade a cada pixel e linha forte a cada 8;
   - `render --silhouette`: **a pose precisa ler só pela silhueta**. Se braços e pernas não se separam do corpo, redesenhe a pose antes de pintar;
   - `render --grounds`: o quadro sobre grama, terra, calçada e noite, em 3× e no tamanho real (1×). O que vale é o 1×;
   - `render --sheet`: todos os quadros lado a lado, para comparar proporção entre direções;
   - `render --gif <sequência>`: a animação no tempo real;
   - `render --pose`: os pontos e ossos da pose por cima do quadro;
   - `render --onion`: o quadro anterior (verde) e o próximo (violeta) por baixo, para medir o deslocamento;
   - `ascii --frame N [--layer nome]`: a grade em texto com a legenda de cores, para corrigir pixels exatos.
6. **Rode `check` antes de entregar.** Ele sai com código 1 e lista os erros quando:
   - o contorno escuro cobre menos de 70% da borda;
   - falta contraste com grama, terra ou calçada;
   - há um quadro vazio;
   - os pés variam mais de 1 px numa sequência `idle`, ou um pé marcado se mexe no idle;
   - a figura foge da ficha: altura (±2 px), número de cabeças (±0,3), linha dos pés, cabeça diferente da referência (mais de 1 px), mais cores do que a ficha permite ou uma rampa obrigatória que falta.

   Os avisos pedem que você olhe de novo:
   - noite;
   - cores vizinhas parecidas;
   - pixels soltos;
   - figura pequena;
   - silhueta cheia demais;
   - membro com tamanho diferente da referência;
   - pé apoiado que anda em velocidades diferentes;
   - cor fora das rampas;
   - quadro sem pose.

## Convenções do jogo

- **Personagem no overworld:** 48×64, pés na mesma linha de base (2 px de margem embaixo) e cabeça grande.
- **Direções:** `S SO O NO N NE E SE`. Nomes de sequência `<movimento>-<direção>`, como `walk-S` e `idle-NE`; quadros `<movimento>-<direção>-<n>`. A bancada usa esses nomes para montar o seletor de direção e movimento.
- **Modelo de referência:** `node tools/pixelgen/examples/modelo-referencia.mjs saida.pixelgen.json` gera um personagem completo (vistas E e S, idle, walk e run) para comparar proporção, sombra e tempo. Use-o como gabarito até existir a biblioteca de poses aprovadas.
- **Movimentos:** `idle`, `walk`, `run`, `interact`, `attack`, `hurt`, `victory`, `defeat`, `fall`, `climb` e `swim`. As ações `victory`, `defeat`, `climb` e `swim` mudam a altura do corpo ou escondem parte dele, por isso ficam livres da altura e da linha dos pés da ficha.
- **Escada vertical (`climb-N`):** vista de costas. As mãos seguram os trilhos em x≈16 e x≈32, e as pernas alternam com a mão do lado oposto. A escada é peça do mapa e não entra no sprite. A prancha só a desenha por trás, para conferir o encaixe.
- **Nado (`swim-*`):** o corpo é cortado na linha d'água (y=43) e as ondinhas entram depois do contorno, sem tinta embaixo. A água é o tile do mapa.
- **Pranchas:** `render --board all` monta uma linha por sequência no cenário da ação (`climb` sobre o barranco com escada, `swim` na água, o resto na grama), com o tempo de cada quadro. Com `--gif`, a animação sai no mesmo cenário.
- **Ações do modelo:** `node tools/pixelgen/examples/modelo-acoes.mjs saida.pixelgen.json` gera vitória, derrota e nado nas 8 direções, mais a escada (`climb-N` e `climbdown-N`), com membros articulados (ombro → cotovelo → mão, quadril → joelho → pé). Use-o como gabarito dessas poses.
  - Cada ação é desenhada de frente (S) e de lado (E).
  - N sai da pose de frente vista de costas.
  - SE e NE são três-quartos: os membros do lado esquerdo da tela ficam na frente, e os do outro lado se recolhem para o corpo e escurecem um tom.
  - O, SO e NO são espelhos de E, SE e NE.
  - Um braço da frente levantado passa por cima da cabeça, para o punho erguido não sumir.
  - A escada só tem a vista de costas, porque escada vertical sempre se encara. A descida toca os mesmos quadros ao contrário (`direction: reverse`).
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
| `pose` | `frame`, `points: {topo:[x,y],…}`, `clear` | marca os pontos da pose (`null` remove um ponto) |
| `recipe` | `motion` (`idle`/`walk`/`run`), `dir`, `base`, `replace`, `stride`, `parts` | gera um ciclo a partir do quadro parado |

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
