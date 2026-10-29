# Mapas do overworld: especificação (regras `overworld-1`)

Este documento cobre as áreas grandes do jogo: a Rua inicial, as Veredas, o Pátio dos canos e as próximas. Interiores (quarto, oficina, casas) continuam no Iso Studio, conforme `art/grade-isometrica/especificacao.html`. A engine é a nossa, JavaScript/Canvas. O **Tiled** serve só como editor de planta, e o jogo continua lendo JSON.

Regra de ouro, a mesma de `documentation/continuidade-terreno-isometrico.md`: **primeiro a planta, depois a arte**. A planta é feita em cores lisas: onde se anda, onde tem desnível, onde tem rampa e ponte. Ela é conferida automaticamente e percorrida com o Kael. Só depois dessa conferência a arte é pintada por cima. Vegetação nunca esconde junta quebrada.

**Regiões em partes:** a revisão de 29/10/2026 acrescenta [REGIOES-E-PARTES.md](REGIOES-E-PARTES.md): no mínimo A/B/C, itens por parte e critérios contra mapas planos. O lote atual do Parque usa essas regras; condições de campanha e tempos ainda pendentes são registrados na revisão regional. As referências à engine JavaScript abaixo são históricas; a migração para Godot foi autorizada posteriormente pelo criador.

## 1. Fluxo de trabalho

| Etapa | Quem | Ferramenta | Sai |
| --- | --- | --- | --- |
| 1. Planta (blockout) | Dono / Claude | Tiled + tileset `rascunho` | `art/overworld/mapas/<area>.tmj` |
| 2. Conferência | automático | Mapa Studio (`npm run studio:mapa`) | Lista OK / AVISO / ERRO; andar com o Kael |
| 3. Referência | Mapa Studio | botão **Baixar referência para o Codex** | `<area>-referencia.png` (sem textos) e `<area>-legendas.png` |
| 4. Pintura de conceito (paintover) | Codex | pedido A (seção 7) | `art/overworld/conceitos/<area>-conceito.png` |
| 5. Kit do bioma | Codex | pedido B + Iso Studio para as peças | `art/overworld/kits/<bioma>/` |
| 6. Montagem no jogo | Claude | conversor `overworld-1` → cena (seção 8) | área jogável |
| 7. Revisão | todos | jogo, desktop e celular | screenshots antes/depois |

Se uma etapa reprovar, volta-se para a **planta**. Não se conserta na arte.

## 2. Grade e projeção

- Mapa **isométrico** no Tiled, célula **64×32 px** (losango 2:1). Desligue "Mapa infinito".
- `u` = coluna do Tiled: na tela, desce para a **direita**. `v` = linha: desce para a **esquerda**.
- Tela: `x = (u − v)·32`, `y = (u + v)·16 − altura·64`. 1 nível = 64 px de parede, ou seja, 2 células de altura do Iso Studio (32 px cada). Peças de interior e de overworld usam a mesma régua.
- Direções na tela: `v−` fundo-direita, `u+` frente-direita, `v+` frente-esquerda, `u−` fundo-esquerda.
- Tamanho: até **96×96 células** por arquivo. Acima disso, divida em áreas ligadas por eventos `saida` (a conferência avisa). Uma rua comprida vira 2 ou 3 arquivos.

## 3. Camadas (nomes exatos)

| Camada | Tipo | Conteúdo |
| --- | --- | --- |
| `chao` | tiles | Um material por célula (propriedade `material` do tile). Célula vazia = buraco, gera aviso. |
| `altura` | tiles | Vazio = nível 0. Tiles `nivel 1..3` ou `rampa u+ / u- / v+ / v-`. |
| `pecas` | objetos (ponto) | Árvores, pedras, baús, postes, casas. Propriedades abaixo. |
| `eventos` | objetos (ponto) | `entrada`, `npc`, `saida` e outros gatilhos. Propriedades abaixo. |

O objeto fica na célula onde o ponto cai. No Tiled isométrico, `x` e `y` do objeto são medidos em unidades de 32 px por célula; o Mapa Studio já faz a conversão. Para colocar na célula certa, ative **Ajustar à grade** e clique no meio do losango.

### Materiais (`chao`)

| material | anda | uso |
| --- | --- | --- |
| `grama` | sim | chão padrão |
| `terra` | sim | trilha; trilha sem saída e sem nada no fim gera aviso |
| `mato` | sim | mato alto: zona de encontros |
| `agua` | **não** | rio, lago |
| `rocha` | **não** | paredão, bloqueio natural |
| `ponte` | sim | tabuleiro de ponte; precisa de terra firme nas duas pontas |
| `piso` | sim | pedra, pátio, praça |
| `calcada` | sim | calçada da Rua inicial |
| `asfalto` | sim | rua (o carro é um evento, não o chão) |

O material é só **revestimento**: ele não decide se há barranco. Quem decide é a camada `altura`.

### Peças (`pecas`)

| propriedade | padrão | significado |
| --- | --- | --- |
| `asset` | nome | `arvore`, `pedra`, `bau`, `poste`, `casa-…`; o mesmo id do Iso Studio |
| `pegada` | `1x1` | células ocupadas, `AxB` (A em u, B em v), a partir da célula do ponto |
| `bloqueia` | `true` | se ocupa o chão |
| `interacao` | — | `abrir`, `ler`, `sentar`…; com interação, precisa ser alcançável |

### Eventos (`eventos`; o tipo vai no campo *Class*/*Type*)

| tipo | propriedades | regra |
| --- | --- | --- |
| `entrada` | `destino` (opcional: a área para onde a entrada leva de volta) | **obrigatório**, exatamente onde o jogador aparece; precisa ser chão andável |
| `npc` | `fala`, `texto` (o que aparece ao conversar) | precisa ser alcançável (na célula ou numa vizinha) |
| `saida` | `destino` (id da cena do jogo, ex.: `park-veredas`) | precisa ser alcançável |
| outros | livres | também precisam ser alcançáveis |

## 4. Desníveis, rampas e pontes

1. **Nível** é um andar inteiro. Barrancos aparecem sozinhos onde um vizinho é mais baixo, com a altura da **diferença**: de 2 para 1 a parede tem um nível, não dois. Entre vizinhos do mesmo nível não há parede, mesmo com materiais diferentes.
2. **Rampa** fica no nível de **baixo** e sobe um nível no sentido da seta. A célula da frente da seta precisa ser o nível de cima, e a de trás, o nível da rampa. A parede é recortada onde a rampa encosta, e os lados da rampa viram cunhas.
3. **Rampa larga** = várias células de rampa lado a lado com a mesma seta. Dá para andar de lado entre elas, mas não sair pela lateral para o chão.
4. **Ponte** = material `ponte` sobre a água. No eixo mais comprido, as duas pontas encostam em chão andável. Pontes elevadas (com pilares) são outra peça e ficam para depois.
5. Só se passa de um nível para outro por rampa (ou, no futuro, escada como peça). A conferência reprova evento ou baú que só se alcança "pulando".

## 5. Conferência automática (Mapa Studio e testes)

**ERRO** bloqueia a próxima etapa. **AVISO** é para pensar.

| regra | nível |
| --- | --- |
| Mapa não isométrico, célula diferente de 64×32, infinito, camada `chao` ausente | erro de leitura |
| Material desconhecido | ERRO |
| Sem `entrada`, ou entrada em chão bloqueado | ERRO |
| Evento ou peça com interação inalcançável a partir da entrada | ERRO |
| Rampa sem pé no nível dela ou sem chegada no nível de cima | ERRO |
| Ponte sem terra firme nas duas pontas | ERRO |
| Peça fora do mapa | ERRO |
| Células sem chão | AVISO |
| Área andável de 6+ células sem acesso (plataforma solta, margem sem ponte) | AVISO |
| Ponte que não atravessa água | AVISO |
| Trilha de terra que termina sem nada | AVISO |
| Peça sobre a água | AVISO |
| Mapa maior que 96×96 | AVISO |

Além da lista, **ande com o Kael** pelo mapa: clique para ir, use as setas para testar degrau a degrau. Teste geométrico não substitui a conferência visual.

## 6. Passo a passo no Tiled (primeira vez)

1. Instale o Tiled ≥ 1.10 (mapeditor.org).
2. **Arquivo → Abrir** `art/overworld/mapas/veredas-piloto.tmj`. O tileset `../tiles/rascunho.tsj` abre junto.
3. Para uma área nova: **Arquivo → Novo mapa** → Orientação *Isométrica*, formato *CSV*, ordem *direita-abaixo*, tamanho em células (ex.: 48×40), **64×32**, sem infinito. Salve como `art/overworld/mapas/<area>.tmj`. Em **Mapa → Adicionar tileset externo**, escolha `art/overworld/tiles/rascunho.tsj`. Crie as 4 camadas da seção 3. Em **Mapa → Propriedades**, adicione `nome` (texto) e `regras = overworld-1`.
4. Pinte: o balde de tinta na camada `chao` com `grama`; o pincel para trilhas e rio; na camada `altura`, os patamares com `nivel 1`; depois as rampas.
5. Árvores e eventos: **Inserir ponto** (atalho I) na camada certa, preencha *Name*, *Class* e as propriedades.
6. Salve (Ctrl+S) e, no Mapa Studio, clique em **Recarregar mapa**.

Gerar o piloto de novo (sobrescreve as edições): `npm run mapa:piloto`.

## 7. Pedidos ao Codex

### Pedido A: pintura de conceito sobre a planta

```
Você vai pintar a arte-conceito de uma área do overworld do PipaKlub em cima de uma planta pronta.
Anexos: <area>-referencia.png (planta sem textos) e <area>-legendas.png (mesma planta com nomes e coordenadas).
Leia antes: WORLD-ART-DIRECTION.md, DIRECAO-DE-ARTE.md e documentation/continuidade-terreno-isometrico.md.

Regras que não mudam:
- Mesma câmera isométrica 2:1 e mesmo enquadramento da referência. Sobreponha as duas imagens: as bordas de rio,
  trilha, patamar e rampa precisam cair nos mesmos pixels (tolerância de 4 px na escala exportada).
- Onde a planta tem barranco marrom, a pintura tem barranco. Onde não tem, não invente parede, degrau ou queda.
- Rampa continua rampa, com as duas pontas encaixadas nos dois níveis. A ponte apoia nas duas margens.
- Árvores, pedras e baús ficam nas mesmas células. Pode variar a espécie e o tamanho dentro da pegada.
- Nada de personagens, UI, texto ou moldura.
- Luz vinda do alto à esquerda. Face sudeste (direita) média, face sudoeste (esquerda) mais escura, como na planta.

Bioma: <Veredas: cerrado/vereda com buritis, riacho raso, terra vermelha, pedras de arenito; Rua inicial:
bairro de periferia brasileira, calçada, muro, poste, fio, pipa enroscada>.

Entregue: art/overworld/conceitos/<area>-conceito.png (mesmo tamanho da referência) e uma lista curta de
variações que você sugere para o kit (seção B).
```

### Pedido B: kit do bioma (peças que o jogo monta)

```
Agora transforme o conceito aprovado de <area> num kit de peças para o jogo montar automaticamente.
Grade: losango 64×32 px. 1 nível de altura = 64 px de parede (2 células de altura do Iso Studio). Fundo transparente, PNG.
Use o Iso Studio (npm run studio:iso) para alinhar cada peça na grade e exportar a pegada.

1. Chão por material (grama, terra, mato, água, piso, calçada, asfalto, conforme o bioma):
   - 4 variações lisas 64×32 que se repetem sem costura;
   - transições para cada par que encosta no mapa (ex.: grama/terra), em 16 peças por par
     (autotile de cantos: cada canto do losango é A ou B). Nomes: <a>-<b>-<máscara 0..15>.png,
     com bit 1 = canto de cima, 2 = direita, 4 = baixo, 8 = esquerda.
2. Barranco: face sudeste e face sudoeste para 1 nível (64 px), mais os cantos externo e interno,
   em 2 variações cada. A textura repete na vertical para 2 e 3 níveis. A borda de cima casa com a grama.
3. Rampa: 4 direções (u+, u-, v+, v-), tampo inclinado + cunhas laterais. Encaixe nos dois níveis.
4. Ponte de madeira: tabuleiro nos dois eixos, cabeceira em terra e água por baixo.
5. Peças (Iso Studio): árvore 1x1 (3 variações), buriti 1x1, pedra 1x1 (3), baú 1x1, arbusto sem colisão.
   Cada peça com ponto de apoio no centro do losango e sombra de contato separada.

Entregue em art/overworld/kits/<bioma>/ com um kit.json listando arquivo, tipo, máscara/direção e pegada.
Não pinte o mapa inteiro como uma imagem só: o jogo precisa das peças.
```

## 8. Integração com o jogo

O jogo usa física ortogonal (retângulos `Walkable` com `level` e `elevation`) e projeta na tela com `toIso` (`src/world-isometric.js`). A física **não muda**: o conversor `src/overworld-scene.js` traduz a planta no build (`scripts/art-build.mjs`), e o desenho usa o mesmo renderer das Veredas.

**Como ver no jogo:** abra o jogo com `?overworld=veredas-piloto` (o nome do arquivo em `art/overworld/mapas/`). Na Clareira do Papel, a entrada das Veredas passa a levar para a planta; a saída norte da planta vai para as Veredas de verdade e a entrada volta para a Clareira. Sem o parâmetro, nada muda para os jogadores.

| planta | cena do jogo |
| --- | --- |
| 1 célula | quadrado de **64 px** ortogonais (2×2 nós de navegação de 32 px) |
| nível 1 | `level: 1`, `elevation: 96` (o padrão das Veredas) |
| células iguais vizinhas | um retângulo `Walkable` (junta na linha e depois desce) |
| grama · terra · mato · ponte · piso/calçada/asfalto | `grass` · `dirt` · `park-tall-grass` (com `encounter_zone`) · `bridge` · `sidewalk` |
| água e rocha | fora do `Walkable`; a água (com o vão sob a ponte) vira o rio desenhado |
| rampa | escada `stairs` com `connects_to` e `rise_to` |
| árvore · pedra · baú · banco, placa, flores, poste, lixeira, vaso | árvore do parque · arbusto (até ganhar arte de pedra) · baú · a peça de mesmo nome do pacote do parque |
| baú e NPC | ocupam a célula; a conversa é feita de uma célula da frente |
| `entrada`, `saida`, `npc`, peça com `interacao` | `Spawns`, `Exits` (`street_scene`), `Interactions` (`pilot_story` com o `texto`) |

O conversor recusa, com mensagem, o que o renderer atual ainda não desenha:
- rampa que não seja `v-` saindo do nível 0;
- nível 2 ou 3;
- ponte que cruza em `v`.

Baús de planta não dão recompensa e o mato alto não dispara encontros: as duas coisas ficam reservadas às cenas oficiais até a planta ser aprovada.

**Próximos passos:**
1. Kit do bioma (pedido B): o renderer passa a ler o autotile do chão e as peças do kit em vez das texturas fixas das Veredas.
2. Liberar no renderer rampas nas 4 direções, níveis 2–3 e pontes em `v`, com os testes de regressão de `veredas-renderer.test.mjs`.
3. Refazer a Rua inicial e o trecho real das Veredas nesse formato, área por área, comparando screenshots com a versão atual.

## 9. Arquivos

- `tools/mapa-studio/model.mjs`: leitura do Tiled, movimento, alturas, barrancos e conferência. Sem DOM; serve à bancada, aos testes e, depois, ao jogo.
- `tools/mapa-studio/`: a bancada (`npm run studio:mapa`, porta 5244) e os testes.
- `art/overworld/tiles/rascunho.tsj/.png`: tileset de planta.
- `art/overworld/mapas/veredas-piloto.tmj`: trecho piloto (ponte, rampa, mirante, Nina, 2 baús, saída).
- `src/overworld-scene.js` e `overworld-scene.test.mjs`: conversor da planta para a cena do jogo e os testes (rampa, ponte, acessos).
