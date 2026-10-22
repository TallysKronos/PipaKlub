# Brief · Carcará (pose-chave em pixel art)

**Status:** pendente · **Entrega:** `art/soulgen/keys/carcara/` · **Formato:** ver `art/soulgen/README.md`

## Quem é

Carcará, "O primeiro voo". Habitat: telhados e correntes quentes. Antes de ter nome, era uma pipa remendada esquecida sobre um telhado; um menino amarrou nela a linha do avô e prometeu fazê-la voar de novo, e a promessa acordou uma alma no papel. Procura quem está aprendendo; espera a rajada certa e ensina que um bom corte começa na calma. **Os remendos não são defeito: cada um guarda a lembrança de alguém que tentou de novo.** (Pipa Dex, `assets/pipa-dex.json`)

Referência pintada atual: `assets/creatures/basicos-v2/carcara.png`. Ela define identidade (cores, partes, personalidade), não o estilo: a pose-chave é **pixel art**.

## O que desenhar

Uma única pose de repouso em vista **3/4 virada para a esquerda**, levemente de cima, asas abertas.

- **Corpo:** pipa em losango (vela de papel) sobre duas varetas de bambu cruzadas, com o nó da linha no topo. O papel tem volume: os quatro painéis pegam luz diferente.
- **Identidade de carcará:** capuz escuro no alto da vela, terminando em V sobre os olhos (olhar firme, calmo); rosto creme; bico amarelo-alaranjado em gancho, apontando para o lado em que olha.
- **Olhos pequenos**, 1–2 px de largura com 1 px de brilho. A criatura se lê pela silhueta, não por olhos grandes.
- **Remendos:** 2–3 retalhos de papel em tons diferentes com pontos de costura (1 px alternado), pelo menos um visível.
- **Asas:** penas em três fileiras (cobertura clara, secundárias, primárias longas com pontas escuras), cada pena legível. A asa de trás aparece parcialmente atrás do corpo.
- **Rabiola:** duas fitas presas por um laço sob a vela, de comprimentos diferentes, caindo para trás e para um lado, com borlas franjadas. Nada que pareça pernas.

## Regras de pixel art

- Grade 96×96 por camada; criatura dentro da célula central 64×64. Classe de tamanho **média**: silhueta do repouso com 36–54 px de altura.
- **No máximo 15 cores** no total, incluindo o contorno. Sugestão de distribuição: contorno 1; corpo 4; rosto 2; capuz/pontas 2; asa e rabiola 3; bico 2; uma livre.
- Rampas com deslocamento de matiz: sombras puxam para vermelho/roxo e ficam mais saturadas; luzes puxam para amarelo e ficam mais claras.
- Luz única do alto à esquerda. **Contorno seletivo:** escuro no lado da sombra e embaixo; no lado iluminado, o tom mais escuro da própria parte.
- Sem semitransparência, sem antisserrilhado contra o fundo, sem pixels soltos.
- Margem: nada encosta na borda da célula; deixe ao menos 3 px.

## Camadas e pontos

- `body.png`, `wing-near.png` (a asa do lado direito da imagem, mais perto de quem vê), `wing-far.png`, `tail.png`, `face-normal.png` (pode ser vazio), `face-blink.png`, `face-fierce.png`, `face-hurt.png`, `face-happy.png`.
- Rostos: só os pixels que mudam em relação ao `body.png` (olhos fechados, sobrancelha mais baixa, olhos em `> <`, olhos `^ ^`).
- Pivôs no `key.json`: o pixel do ombro de cada asa (onde ela gira) e o pixel do laço da rabiola.
- Âncoras: `head` no meio da testa, `center` no cruzamento das varetas, `effect` no bico, `tail` no laço.
- Variante `noturno` na mesma ordem da paleta: vela lilás, asas azul-violeta, capuz azul-noite, rosto creme frio.

## Referências de estilo (estudo, não cópia)

Sprites de Pokémon Mystery Dungeon: Explorers e de Digimon World DS, pela leitura em tela pequena, pelo volume e pelo contorno colorido. **Não copie pixels do PMD SpriteCollab** (licença CC BY-NC 4.0, não comercial). Ver o manual `MANUAL-DE-ASSETS.md`.

## Pronto quando

```
python3 tools/soulgen/keyanim.py art/soulgen/keys/carcara art/soulgen/out
python3 tools/soulgen/keyanim.py art/soulgen/keys/carcara art/soulgen/out noturno
python3 tools/soulgen/lint.py art/soulgen/out/carcara.json art/soulgen/out/carcara-noturno.json
```

passam sem erro, e os GIFs em `art/soulgen/out/` mostram a criatura legível em repouso, voo, habilidade, dano e vitória.
