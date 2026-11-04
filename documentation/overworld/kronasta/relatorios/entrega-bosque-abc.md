# Bosque dos Ventos A/B/C — entrega de mapas, 30/10/2026

Branch: `codex/mapa-kronasta-bosque`, criada sobre `claude/mapa-prova` em `3eab9544`.
Trabalho pelo agente construtor-de-mapas e revisão complementar no mesmo branch. Sem merge, push ou deploy.

## 1. Arquivos criados e alterados

- Briefs e plantas ASCII: `art/overworld/briefs/kronasta-bosque-{a,b,c}.md`.
- Plantas Tiled: `art/overworld/mapas/kronasta-bosque-{a,b,c}.tmj`.
- Dados compilados: `godot/assets/overworld/maps/kronasta-bosque-{a,b,c}.json` e `index.json`.
- Geradores: `tools/mapa-studio/desenhar-kronasta-bosque.mjs`, `desenhar-bosque-partes.mjs`, wrappers `desenhar-kronasta-bosque-b.mjs` e `desenhar-kronasta-bosque-c.mjs`.
- Conferência: `conferencia-bosque.mjs`, `conferencia-bosque.test.mjs`, `conferir-regiao-bosque.mjs` no mesmo diretório.
- Renderização: `godot/scripts/overworld/kronasta_forest.gd`, novo `forest_structures.gd`, `godot/shaders/kronasta_ground.gdshader`.
- Compilador: `tools/import-overworld.mjs` preserva o atributo `forest` gravado no Tiled, incluindo estruturas medidas. Não foi executado `build()` dos kits.
- Prévia: `godot/scripts/overworld/view.gd` respeita `chegada_u/v` nas transições, valida os valores e usa o spawn quando forem inválidos. Não altera campanha/saves.
- Modelo de movimento: `godot/scripts/overworld/map_model.gd` respeita o contorno medido da água dentro das células das margens curvas; o tabuleiro da ponte permanece atravessável.
- Testes: `godot/tests/bosque_arrival_checks.gd`, `bosque_traversal_checks.gd`, `bosque_water_checks.gd`.
- Capturas: `godot/tools/bosque_region_capture.gd`, `tools/mapa-studio/capturas-bosque.mjs`, `verificar-capturas-bosque.mjs`; planos, capturas e evidências sob `documentation/overworld/kronasta/`.

A mantém a planta de terreno. Corrigidos contraste dos topos, pedras repetidas, máscara dura no mato e vegetação sobre a entrada. A página existente foi deslocada de (12,10) para (11,10), liberando a chegada da rampa. IDs dos objetos restantes e eventos antigos foram preservados, reservando os números das pedras removidas.

B tem riacho curvo, ponte de três células apoiada nas duas margens, poço efetivamente recortado, água a −24 px, lábio a +64 px e queda de 88 px. Usa o mesmo contorno para recorte, faces e água. Há duas subidas sucessivas até o nível 2.

C tem clareira, platô de descanso com bancos do kit existente, marco de madeira com fitas, escada e mureta de borda com altura uniforme. Contornos de B/C foram normalizados em blocos 2×2 após a revisão encontrar serrilhado de uma célula.

## 2. Resultado automático

Saída de `node tools/mapa-studio/conferir-regiao-bosque.mjs`:

```text
kronasta-bosque-a
CONFERÊNCIA ZERO QUEBRA: SEM ERRO · 0 erros · 0 avisos
Platô 43.2% · 6 itens (3 escondidos) · 16 células de rampa · 0 inalcançáveis · 0 degraus soltos

kronasta-bosque-b
CONFERÊNCIA ZERO QUEBRA: SEM ERRO · 0 erros · 0 avisos
Platô 41.8% · 3 itens (1 escondidos) · 12 células de rampa · 0 inalcançáveis · 0 degraus soltos

kronasta-bosque-c
CONFERÊNCIA ZERO QUEBRA: SEM ERRO · 0 erros · 0 avisos
Platô 56.7% · 3 itens (1 escondidos) · 14 células de rampa · 0 inalcançáveis · 0 degraus soltos
```

O gerador de cada parte imprime a conferência regional. As verificações complementares cobrem direção das rampas, pés e duas células de chegada, degraus soltos, bolsões inacessíveis, rotas obrigatórias com duas faixas contínuas, vegetação isolada, sobreposição de peças/eventos nos acessos, muretas, três partes, itens e correspondência de direção/material/cota das ligações. A travessia principal continua possível removendo todas as células de encontro do grafo. Checagem de árvores usa uma janela aproximada de jogo; não substitui a revisão de copas projetadas.

Resultados dos testes:

| Teste | Resultado |
|---|---|
| `node --test tools/mapa-studio/model.test.mjs tools/mapa-studio/conferencia-bosque.test.mjs` | 13 testes, 0 falhas |
| `godot/tests/overworld_checks.gd` | 69.154 verificações, 0 falhas, saída 0 |
| `godot/tests/morro_map_checks.gd` | 9.386 verificações, 0 falhas, saída 0 |
| `godot/tests/bosque_arrival_checks.gd` | 11 verificações, 0 falhas |
| `godot/tests/bosque_water_checks.gd` | 79 pontos de margem protegidos, 108 pontos de ponte atravessáveis, 0 falhas |
| Percurso A | 41 destinos, 82 trajetos, 0 falhas |
| Percurso final B | 29 destinos, 58 trajetos, 14.620 quadros, 0 falhas |
| Percurso final C, com bancos | 35 destinos, 70 trajetos, 17.220 quadros, 0 falhas |
| Integridade das capturas | 909 PNGs, todos 1280×720, nomes correspondentes aos planos |

Ambiente: Godot 4.7.2 Windows; capturas OpenGL Compatibility, NVIDIA GTX 1650. Os testes headless de regressão emitem diagnóstico de compilação de shader em `_painted_floor` (outros biomas) e mensagens de recursos ainda em uso ao encerrar. As asserções passam, mas os logs não são silenciosos; estes diagnósticos NÃO foram corrigidos nem considerados prova de renderização desses outros biomas. Testes próprios do Bosque e capturas finais sem erro de script. Logs preservados em `logs/` junto deste relatório.

## 3. Capturas

Diretórios relativos a `documentation/overworld/kronasta/`:

| Parte | Plano | Capturas por versão | Versões |
|---|---|---:|---|
| A | `planos/kronasta-bosque-a.json` | 115 | `captures/kronasta-bosque-a/{geometria,arte,arte-terreno}/` |
| B | `planos/kronasta-bosque-b.json` | 115 | `captures/kronasta-bosque-b/{geometria,arte,arte-terreno}/` |
| C | `planos/kronasta-bosque-c.json` | 73 | `captures/kronasta-bosque-c/{geometria,arte,arte-terreno}/` |

Cada plano enumera vista inteira, entrada/centro/platôs/saídas em zoom de jogo, pés e topos das rampas e os cantos por faixa de cota. B acrescenta as duas cabeceiras, tabuleiro, cinco trechos de margem, todos os vértices do poço, lábio, impacto e margem próxima. C acrescenta boca de escada e encontros/pontas de mureta.

Todos os detalhes usam zoom ≥2 e não têm Kael, seguidor ou NPC cobrindo juntas. `arte-terreno` retira a vegetação e peças apenas na captura, mantendo terreno, rampas, escada, mureta, água e ponte. Não altera a planta ou a composição normal. É uma evidência adicional às versões normal e geométrica.

Inventário com tamanho, SHA-256 de cada PNG e do mapa compilado: `capturas.json`. Verificação reproduzível: `node tools/mapa-studio/verificar-capturas-bosque.mjs`. Ela confirma arquivos/resolução; não julga qualidade visual.

Comparação de A com o commit-base, nos mesmos enquadramentos e com texturas importadas: `comparativo-a/{antes,depois}/` e pranchas `area-inteira-antes-depois.png`, `entrada-antes-depois.png`. Esses comparativos usam a ferramenta anterior e incluem HUD/atores; as 909 capturas de conferência são separadas e sem atores.

Revisão realizada: pranchas de todos os enquadramentos geométricos e de terreno, pranchas da composição com arte, e abertura nativa dos detalhes críticos de rampas, ponte, poço, escada, marco e muretas. Essa revisão encontrou e corrigiu: margem passando sobre a ponte; margem cortando a queda; escada deixando a rampa de terra aparecer; bancos incompletos; mureta com altura variável e contornos serrilhados. Não foi feita uma abertura individual em resolução nativa de cada um dos 909 PNGs; essa limitação fica explícita.

## 4. Percurso: o que foi andado

`bosque_traversal_checks.gd` instancia a prévia real com arte e chama o movimento físico até cada item, NPC, saída, rampa, pé e segunda célula do patamar, voltando ao spawn depois de cada destino. C inclui aproximação dos bancos bloqueantes. Verifica a cada quadro os segmentos do Kael e seguidor, chão caminhável e projeção dos pés; também verifica que o seguidor não fique para trás. Não é apenas uma consulta ao grafo.

Para repetir uma parte: `godot --headless --path godot --script res://tests/bosque_traversal_checks.gd -- --part=c`. Sem `--part`, percorre A/B/C. Nenhum item, moeda, batalha ou save é concedido/alterado.

O teste de chegada cobre retorno B→A, coordenadas explícitas de C, seguidor, valores ausentes, fracionários, texto, fora do mapa e posição bloqueada. A passagem usa a chegada declarada quando válida.

Não houve sessão humana com teclado/controle nem observação visual contínua da oclusão de Kael/seguidor em cada junta. As capturas estáticas e o teste de apoio não comprovam sozinhos essa oclusão.

## 5. Itens, pistas e revelações

A preserva Dito e os seis itens: moedas×30, papel×2, vareta×1, cola×1, linha encerada×1 e a página `pista-caderno-heleana-1`. A página já existia; não se inventou conteúdo ou consequência para ela.

B: papel×2 escondido no alto, cola×1 na margem e varetas×2 no desvio de encontro. C: papel×3 como recompensa principal de materiais, varetas×2 escondidas e cola×1 na clareira. IDs e quantidades estão nos eventos Tiled/compilados.

A bíblia não definia a narrativa do Bosque B/C. Foi adotada a opção apresentada ao dono antes da construção: região opcional, nomes Desvio do Riacho e Clareira do Marco, sem novo chefe, personagem ou revelação principal. O marco não é relíquia das Ruínas. O platô indica uso por moradores ausentes.

## 6. Pedidos ao integrador

1. Integrar os três mapas ao fluxo oficial da campanha e ao mapa-múndi; a entrega atual é a prévia de overworld.
2. Persistir a descoberta da clareira para liberar o atalho C→A. Na prévia, o atalho já é atravessável; não foi implementado bloqueio/desbloqueio em saves.
3. Conectar os eventos de item/encontro e a página antiga aos serviços de recompensa/história. A prévia apenas demonstra acesso e interação.
4. Fazer playtest humano com controle, observando copas/platôs na frente e atrás do Kael e seguidor, nas duas direções.

## 7. Dúvidas para o dono

Nenhuma dúvida bloqueia a construção aprovada. Recomenda-se manter o Bosque como exploração opcional até o roteiro definir a função da página do caderno; não transformar o marco em revelação principal sem decisão narrativa.

## 8. O que não foi verificado

- Liberação persistente do atalho, concessão de itens, encontros e progressão no jogo oficial: fora do escopo da skill, sem alterações nesses sistemas.
- Playtest humano com controle, oclusão em movimento de todos os atores, desempenho de lançamento/Steam, tela estreita e outras GPUs.
- Inspeção nativa individual dos 909 PNGs; a cobertura completa foi revisada em pranchas, com detalhes críticos abertos em tamanho nativo.
- Os diagnósticos headless de outros biomas citados na seção 2 permanecem. Não declarar a suíte livre de mensagens do engine.

Capturas, plantas e percurso automático estão entregues para revisão. A aprovação final de integração/jogabilidade depende dos pontos explicitados acima.
