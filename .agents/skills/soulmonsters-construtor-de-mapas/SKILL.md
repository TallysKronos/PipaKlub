---
name: soulmonsters-construtor-de-mapas
description: Construa, corrija ou melhore áreas exploráveis do overworld do Soulmonsters no Godot (planta, relevo, platôs, barrancos, muretas, rampas, escadas, pontes, água, vegetação, itens, eventos e câmera), no padrão de Digimon World DS e Digimon World 2003, sem deixar junta quebrada. Use em qualquer tarefa de mapa de exploração, level design ou terreno isométrico.
---

# Construtor de mapas do Soulmonsters

Você entrega **lugares**, não chão com objetos espalhados. Um mapa bom tem as quatro camadas da
referência ao mesmo tempo:

1. **Estrutura:** platôs, barrancos, muretas, água e mata fechada desenham o espaço e dizem por
   onde se anda.
2. **Percurso:** caminho principal legível, desvios com motivo, laço de volta, risco que se escolhe.
3. **Acabamento:** toda borda fechada, todo canto encaixado, toda peça apoiada no chão certo.
4. **Vida:** chão em tons, massas de vegetação, marcos, rastros da história.

Se uma camada falha, o mapa não está pronto. A causa mais comum de mapa ruim aqui foi pular a camada
1: chão plano em grade com árvore solta por cima.

## Leitura obrigatória

Leia por inteiro antes do primeiro mapa e sempre que a tarefa tocar o assunto:

| Arquivo | Para quê |
| --- | --- |
| `AGENTS.md` | regras de continuidade, rampas, margens, poços e cachoeiras |
| `documentation/continuidade-terreno-isometrico.md` | contrato de volume, bordas expostas, cantos, rampas, pontes |
| `art/overworld/ESPECIFICACAO-MAPAS.md` | regras `overworld-1`: grade, camadas, materiais, peças, eventos |
| `art/overworld/REGIOES-E-PARTES.md` | região em partes A/B/C, itens, regras contra o mapa chapado |
| `documentation/historia/BIBLIA-DA-HISTORIA.md` | trajetórias, o que cada área revela e o que ela libera |
| [references/referencias-dwds-dw2003.md](references/referencias-dwds-dw2003.md) | o que copiar de Digimon World DS e 2003, em regras medíveis |
| [references/geometria-e-godot.md](references/geometria-e-godot.md) | projeção, cotas, rampas, barrancos, muretas, profundidade, arquivos e comandos |
| [references/receitas-de-bioma.md](references/receitas-de-bioma.md) | floresta, morro/bairro, vereda/água, ruínas/caverna |
| [references/conferencia-zero-quebra.md](references/conferencia-zero-quebra.md) | lista de conferência, capturas e relatório |

Discovery de origem, para consulta: `documentation/benchmark-digimon-world-ds/README.md`,
`documentation/benchmark-digimon-world-2003-exploracao-grind-2026-10-21.md`,
`documentation/overworld/analise-referencias-relevo-2026-10-28.md` e
`documentation/overworld/godot-tilesets-profundidade.md`.

Exemplo de referência já construído: `kronasta-bosque-a` (gerador
`tools/mapa-studio/desenhar-kronasta-bosque.mjs`, construtor `godot/scripts/overworld/kronasta_forest.gd`,
capturas em `documentation/overworld/kronasta/captures/`). Use-o como ponto de partida e supere-o:
os defeitos conhecidos dele estão na referência de conferência.

Se dois documentos se contradizem: instrução explícita do dono > `AGENTS.md` > esta skill >
`ESPECIFICACAO-MAPAS.md` > bíblia > o resto. Registre a contradição no relatório.

## Fluxo por área

Siga as etapas em ordem. Cada uma tem saída verificável; não avance com a anterior reprovada.

### 1. Brief (1 página, `art/overworld/briefs/<area>.md`)

- Função na região (parte A, B ou C) e na história: o que se descobre aqui, qual pista fica para depois.
- **Planta de intenção** em ASCII antes de qualquer tile: entrada, saídas, caminho principal, desvios,
  platôs com cota, rampas e escadas com direção, água, mato de encontro, marco, descanso, itens.
- Um marco principal visível de longe e no máximo dois secundários.
- Ritmo: sequência de **abrir → estreitar → abrir**. Diga onde estão os estreitamentos.
- Por que cada beco existe (item, vista, NPC, pista). Beco sem motivo não entra.

### 2. Blocagem (geometria em cores chapadas)

- Gere a planta por script determinístico (`tools/mapa-studio/desenhar-<area>.mjs`), não à mão célula
  a célula. O script grava o `.tmj`, compila e imprime o resultado da conferência.
- Desenhe nesta ordem: moldura → platôs e cotas → água e poços → caminho principal → ramais → rampas e
  escadas → muretas → acessos e saídas. Só depois vegetação, peças e eventos.
- Aplique as regras de geometria (referência `geometria-e-godot.md`): blocos de platô de 2×2,
  rampas subindo para o fundo, sem degrau solto, sem bolsão inalcançável.
- Renderize no Godot em cores chapadas (nível por cor, rampa em laranja, mureta em cinza, água em azul)
  e capture. Esta captura é a prova da estrutura.

### 3. Conferência de planta

- `audit()` do Mapa Studio sem ERRO; cada AVISO corrigido ou justificado no brief.
- As checagens de região e de anti-chapado que o Mapa Studio ainda não faz, você faz no gerador e
  imprime (referência de conferência).
- Percorra com o Kael: toda rampa, escada, ponte, NPC, item e saída, nos dois sentidos.

### 4. Arte e montagem

- Reaproveite kits (`godot/assets/overworld/kits/*`). Peça nova só quando faltar, com `kit.json`.
- O construtor do bioma em `godot/scripts/overworld/` monta chão, faces, bordas, sombras, muretas,
  vegetação e peças a partir dos dados compilados. Arte nunca muda a geometria.
- Câmera de exploração natural em zoom 1.0; urbano conforme o kit aprovado.

### 5. Revisão em captura

- Vista geral, quatro enquadramentos de jogo e um detalhe ampliado (zoom ≥ 2) de **cada** junta
  listada na conferência, em versão chapada e com arte, sem personagem na junta.
- Prancha antes/depois quando a área substitui outra.
- Corrija e recapture até a lista fechar. Uma vista geral bonita não substitui os detalhes.

### 6. Entrega

- Testes de mapa do Godot e do Mapa Studio passando; artefatos de teste revertidos.
- Relatório no formato da referência de conferência, com o que **não** foi verificado.
- Branch própria, commits pequenos `Mapa <area>: <o que mudou>`. Sem merge, sem push em main.

## Perguntas que todo mapa responde

Se não consegue responder olhando a captura de jogo, o mapa não está pronto:

1. Para onde eu vou agora? (caminho principal pelo material e pela largura)
2. O que tem lá em cima? (platô visível com algo que puxa: brilho, baú, NPC, vista)
3. Como eu subo? (rampa ou escada visível da frente)
4. Onde é perigoso e onde descanso? (mato de encontro separado da trilha segura)
5. O que está trancado e por quê? (barreira com sentido no mundo, vista antes de liberar)
6. Como eu volto? (laço ou atalho que abre depois)

## Limites

Você altera plantas, geradores, dados compilados, kits, peças e construtores de cenário do overworld
(`godot/scripts/overworld/`, `godot/shaders/`, `godot/tools/` de captura). Não altera regras de batalha,
saves, servidor, Supabase, deploy nem fluxo de campanha. Pedidos de código fora disso vão no relatório.
Não apaga nem renomeia áreas ou IDs existentes sem plano aprovado. Prompts visuais e referências de
outras franquias servem para estudar composição; não copie desenho, textura nem planta.
