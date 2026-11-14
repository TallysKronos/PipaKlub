# Ilustrações de TCG · benchmark do Digimon Card Game e prompt para o Codex

13/11/2026.

## 1. Benchmark

### O que cada tipo de carta mostra

| Tipo | O que a ilustração mostra | Para nós |
| --- | --- | --- |
| Digimon | A criatura na pose ou ação característica dela, no ambiente dela | Carta de Soulmonster |
| Tamer (domador) | O personagem, quase sempre em pose de retrato, muitas vezes com o parceiro | Carta de Pipeiro: o pipeiro com o Soulmonster dele |
| Option | Um momento, uma cena ou um golpe (às vezes arte reaproveitada do anime e de artbooks) | Carta de Momento |
| Alternativa / paralela | Mais encenada e íntima: o domador e o parceiro sentados juntos à noite; o domador em pose forte com o lineart dourado do parceiro atrás | Carta rara |

As cartas de domador variam de retrato estilo quadrinho a retrato estilo anime; as alternativas
são mais dramáticas que as normais, mas ainda em cena reconhecível. Há ilustradores de traço
limpo e outros de pintura espessa sem lineart; o nosso alvo é o primeiro grupo.

### Traços comuns das boas ilustrações

(Observação geral sobre cartas de TCG de criaturas; os sites de referência estão bloqueados nesta
sessão, então confira com cartas reais antes de fechar.)

- **Fiel ao modelo:** a criatura tem as proporções, a anatomia e as cores do design oficial.
  Ninguém "reinventa" o personagem para a carta.
- **Um assunto principal**, legível de longe; no máximo um secundário.
- **Câmera natural:** altura dos olhos ou leve contra-plongée; lente "normal". Nada de olho de
  peixe nem encurtamento extremo.
- **Fundo com profundidade mas calmo:** menos saturado e menos detalhado que o assunto.
- **Luz com direção clara** e uma paleta controlada, puxando para a cor da carta.
- **Efeitos só quando há ação**, e poucos.
- **A arte ocupa a carta toda, mas a parte de baixo recebe a caixa de texto:** o que importa fica
  no meio e no alto.

### O que está saindo errado nas nossas ilustrações

Comparado com as pranchas aprovadas (`art/creatures/rabbito-family-v1/ESTILO-APROVADO.md`) e com
as ilustrações do trailer v2 (`art/trailer-v2/kronasta-ceu-r4.png`):

- perspectiva exagerada (criaturas enormes e distorcidas em primeiro plano);
- criaturas fora do modelo (formas que não existem no catálogo);
- redemoinhos, rastros e efeitos demais ao mesmo tempo;
- saturação no máximo em tudo, sem hierarquia;
- assuntos demais disputando a atenção.

Para o trailer isso funciona; para carta, não.

## 2. Prompt para o Codex

---

Crie o piloto das **ilustrações de carta (TCG)** de SoulMonsters · Elo das Ruínas: 6 ilustrações,
**sem moldura, sem HUD, sem texto, sem números, sem logo e sem marca d'água**. A moldura da carta
é feita depois, por cima.

### Estilo (obrigatório)

- O estilo mangá aprovado do jogo: contorno escuro azul-marinho contínuo e nítido, massas amplas de
  cor com sombra cel simples (2 a 3 tons por material), poucas dobras que expliquem construção,
  sem ruído, sem textura pintada por cima, sem tesselação de pequenos detalhes. Referência:
  `art/creatures/rabbito-family-v1/ESTILO-APROVADO.md`.
- **Fiel ao modelo:** cada personagem e criatura igual à referência oficial (abaixo). Coloque a
  referência ao lado na revisão e corrija qualquer diferença de proporção, cor ou forma.
- **Contenção, à moda das cartas de Digimon:** um assunto principal; câmera na altura dos olhos ou
  em leve contra-plongée, lente equivalente a 35–50 mm, horizonte reto; nada de olho de peixe,
  encurtamento extremo ou criatura gigante em primeiro plano. No máximo 2 elementos de efeito, e só
  quando há ação. Fundo menos saturado e menos detalhado que o assunto. Uma direção de luz clara.

### Formato

- 1500 × 2100 px (5:7, retrato), arte até a borda, com 45 px de sangria em cada lado.
- **Área segura:** o assunto principal (rostos, olhos, mãos, a ação) fica nos 62% de cima. Os 38%
  de baixo recebem a caixa de texto: ali só chão, fundo ou continuação calma da cena.

### As 6 ilustrações

| Nº | Tipo | Cena |
| --- | --- | --- |
| 1 | Pipeiro | **Tyler e Rai** na roda de pipas da Clareira do Papel, retrato de meio corpo: Tyler encostado num poste de varal de pipas, o Rai ao lado dele, os dois olhando para o mesmo ponto fora do quadro. Fim de tarde. |
| 2 | Soulmonster | **Rai fazendo algo característico dele** (siga a ficha e a habilidade dele), na Clareira, sem o Tyler. |
| 3 | Soulmonster · par A | **Rabbito no ateliê do Sr. Assis**, visto da porta: em cima da bancada, puxando com cuidado uma rabiola presa num grampo, ferramentas e retalhos de papel em volta. |
| 4 | Soulmonster · par B | **Rai no mesmo ateliê, no mesmo instante**, visto do lado oposto (da bancada para a porta e a janela): o Rai na estante de pipas, e o Rabbito pequeno e desfocado no fundo, na bancada, ligando as duas cartas. |
| 5 | Pipeiro | **Kael e Rabbito** no quintal da Vila, de manhã: o Kael ajoelhado amarrando a rabiola do Rabbito, os dois quase da mesma altura no quadro. |
| 6 | Momento | **"Reparo"**: as mãos do Sr. Assis consertando a armação de uma pipa na bancada do ateliê, a mesma bancada das cartas 3 e 4. |

### Regras das cartas em par (3 e 4)

São a mesma cena vista de dois ângulos, como plano e contraplano de cinema:

1. Antes de ilustrar, desenhe a **planta do ateliê** vista de cima: bancada, estante de pipas,
   porta, janela, luminária, e as duas câmeras marcadas, com pelo menos 120° entre elas.
2. Mesma hora, mesma luz (a luz da janela entrando na mesma direção nas duas), os mesmos objetos
   nos mesmos lugares.
3. Cada carta funciona sozinha; juntas, dá para reconhecer o mesmo lugar e o mesmo momento.
4. Um elemento de ligação visível nas duas (o Rabbito na bancada, uma rabiola vermelha pendurada).

O ateliê é o do andar de cima (`godot/assets/campaign/professor-moderno-v1/preview.png` e
`godot/assets/campaign/workshop-background.png`). Não mostre o laboratório escondido nem nada que
sugira a origem do Tyler (tanques, frascos, fichas com o nome dele): isso é revelação do Ato 5.

### Referências oficiais

- Kael: `godot/assets/campaign/portrait-kael-manga-v4.png`, `art/characters/kael/concept-refino-2026-11-05/prancha.png`
- Tyler: `art/characters/tyler/concept-v5/prancha.png`, `godot/assets/campaign/portrait-tyler-manga-v1.png`
- Rai: `godot/assets/campaign/tyler-clareira-v1/rai.png` e a família em `art/creatures/rai-family-v1/`
- Rabbito: `godot/assets/campaign/combat-rabbito.png` e `art/creatures/rabbito-family-v1/`
- Sr. Assis: `godot/assets/campaign/portrait-assis.png`
- Clareira do Papel: as capturas do mapa `clareira-do-papel` do jogo

### Processo e entrega

Em `art/tcg/ilustracoes-v1/<nº>-<nome>/`:

1. `miniaturas.png`: 3 estudos em tons de cinza (só valores, sem cor), para escolher a composição.
2. `final.png` (1500 × 2100) e `final-moldura-teste.png`, com um retângulo cinza simulando a caixa
   de texto nos 38% de baixo, para conferir a área segura.
3. `comparativo.png`: a ilustração ao lado da referência oficial de cada personagem.
4. `prompt.txt` e `revisao.md` com esta lista conferida:
   - [ ] fiel ao modelo (proporção, cor, forma) em todos os personagens
   - [ ] um assunto principal; câmera natural, horizonte reto, lente 35–50 mm
   - [ ] no máximo 2 elementos de efeito
   - [ ] fundo menos saturado que o assunto
   - [ ] assunto nos 62% de cima
   - [ ] nada de texto, moldura, HUD ou logo
   - [ ] (pares) planta do ateliê, mesma luz e mesmos objetos nas duas

Para o par 3/4, entregue também `art/tcg/ilustracoes-v1/atelie-planta.png`.

Faça primeiro só as miniaturas das 6 e pare para o dono escolher; depois as finais.

---

## Fontes do benchmark

- [TheGamer · Digimon Card Game: The Best Art From The Classic Collection EX-01](https://www.thegamer.com/digimon-card-game-tcg-best-art-classic-collection-ex-01/)
- [With the Will · Tamer Card Close & Parallel/Alt Art (EX-11)](https://withthewill.net/threads/tamer-card-close-parallel-alt-art-previews-for-digimon-card-game-booster-set-ex-11.35339/)
- [With the Will · Tamer Card Dan & Parallel/Alt Art (BT-25)](https://withthewill.net/threads/tamer-card-dan-parallel-alt-art-previews-for-digimon-card-game-booster-set-25.35909/)
- [With the Will · Tamer Card Mon & Parallel/Alt Art (EX-13)](https://withthewill.net/threads/tamer-card-mon-parallel-alt-art-preview-for-digimon-card-game-booster-set-ex-13.36737/)
- [げるもん · Digimon Card Illustration Summary Ver. 2024](https://note.com/gerukizoku/n/n45b5cc8c8f6a?hl=en)
- [Digimon Illustration Competition Pack](https://www.cardtrader.com/en/games/digimon/expansions/digimon-illustration-competition-pack/categories)
- [Connected Art Pokémon Cards · guia](https://magikart.in/blogs/magikart-blogs/connected-art-pokemon-cards-the-complete-collector-s-guide)
