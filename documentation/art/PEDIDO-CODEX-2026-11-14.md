# Pedido ao Codex · 14/11/2026

Antes de tudo: **parta da branch `claude/unificacao`** (faça pull dela). Ela já junta tudo: os
concepts das 14 regiões, a HUD azul, a revelação animada, o laboratório em pixel art, as
ilustrações das cartas, as 194 folhas v2, o trailer v2 e o ritual de evolução. Crie as suas
branches a partir dela; branches que partem de uma base antiga geram conflito em cada merge.

## 1. Laboratório do Sr. Assis v2 · etapa 1

- O lote ampliado está pronto: `art/professor-laboratorio-v2/lote/LOTE.md` (u 0,5 → 14, v -10 → -1,
  13,5 × 9 células, entrada em (7,25; -1), planta em `lote-celulas.png`).
- Suba a ficha de tradução da etapa 0 (`traducao.md`) que ficou só na sua máquina.
- Siga para a etapa 1 (blockout em cinza na câmera do jogo, sobre o concept) e pare para aprovação.
- Leia o guia de estilo de cenário (item 2) antes da etapa 2: o laboratório v2 é a primeira peça
  feita nessas regras.

## 2. Guia de estilo de cenário

Leia `documentation/art/GUIA-DE-ESTILO-CENARIO.md`. Resumo: o concept define o conteúdo e o clima; o
jeito de desenhar vem dos personagens (mesmo pixel do Kael, paleta mestra, contorno só na
silhueta, sombra cel com a luz do alto à esquerda, nada menor que 2 px, cenário um pouco menos
saturado que os personagens) e toda entrega traz o teste de convivência.

Tarefa: crie a **extensão de cenário da paleta mestra** (`art/overworld/estilo/paleta-cenario.hex`,
`.gpl` e `.png`): rampas de 4 a 5 tons para vegetação, terra, pedra e concreto, água, telhado,
madeira pintada e vidro, no mesmo espírito das 48 cores dos personagens. Prove refazendo a loja
da Vila (`godot/assets/overworld/kits/bairro-inicial-v2/buildings/shop.png`) no pixel do Kael, com
acabamento à mão, e entregue o teste de convivência ao lado de
`art/overworld/estilo/teste-convivencia-loja.png`. Pare para aprovação.

## 3. Regiões dos concepts (depois dos itens 1 e 2 aprovados)

Para cada região de `art/overworld/conceitos/`, nesta ordem: Rua dos Ventos, Morro do Sol, Parque
dos Ventos, Bosque. Para cada uma:

1. Ficha de tradução e blockout (`documentation/art/PIPELINE-CONCEPT-PARA-JOGO.md`, etapas 0 e 1).
2. **Peça-teste:** um prédio e dois props do concept nas regras do guia, com o teste de convivência.
   Pare para aprovação.
3. Só então o kit inteiro. A montagem no mapa e a captura no jogo ficam com o Claude.

## Como entregar

- Um commit por etapa, título em português ("Laboratório v2: blockout", "Paleta de cenário: …").
- Em cada parada, diga o que está pronto e onde.
- Não apague nem sobrescreva fontes; versões novas em pastas novas (`-v2`, `-v3`).
