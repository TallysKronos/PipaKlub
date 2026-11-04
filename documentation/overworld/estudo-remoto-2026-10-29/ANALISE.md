# Estudo de mapas — análise e impacto no Jardim

29/10/2026. Foram buscadas as branches `claude/historia` e `claude/mapa-prova`. O trabalho local foi preservado. Os documentos, a planta, o modelo de conferência e as capturas necessários estão copiados nesta pasta; não houve merge do renderer remoto na campanha.

Revisões analisadas:

- História/regiões: `f3df6373316305ff0c9dec449d1229f2cd0c4526`.
- Prova Bosque dos Ventos A: `e02169eb73eb2f25ca6c15f1dddac97db2d10763`.

## Conclusão

O estudo explica uma deficiência estrutural do nosso Jardim: o relevo estava concentrado numa plataforma e as árvores estavam distribuídas como objetos individuais sobre uma base aberta. Isso produz a sensação de tabuleiro decorado. A prova melhora a leitura ao fazer o caminho passar **entre massas de terreno**, usar mata para definir bordas e dar ao cenário uma moldura contínua.

Minha recomendação é adotar essa composição e a estrutura regional A/B/C. Não recomendo copiar o renderer inteiro: o estudo propõe TileSets, mas a prova ainda usa milhares de nós e mistura por shader. O ganho visual é real nas capturas; a arquitetura final e a jogabilidade regional ainda não foram demonstradas.

## O que veio do Git

| Material | Conteúdo | Estado observado |
|---|---|---|
| `REGIOES-E-PARTES.md` | Kronasta como mapa de mundo; cada região com no mínimo A/B/C; itens e critérios de relevo | Nova especificação, com verificações ainda manuais |
| Bíblia atualizada | Incorpora Kronasta e as partes regionais | Mantém a tabela antiga de desbloqueios do parque; precisa considerar a decisão posterior de preservar Nina cedo |
| `godot-tilesets-profundidade.md` | Uso de atlas, camadas por nível, origens de profundidade e terrenos 16/47 | Proposta técnica; não confundir com o que o protótipo implementou |
| `kronasta-bosque-a.tmj` | Área de prova 52×44 com platôs, rampas e itens | Parte A independente; B/C não aparecem no índice analisado |
| `kronasta_forest.gd` e shader | Desenho especial para o bioma floresta | Prova visual ligada ao renderer remoto, não um kit genérico de TileMap pronto |
| Capturas remotas | Entrada, área inteira, platôs e rampas em arte/geometria | Evidência produzida na outra branch; não são novas capturas executadas nesta análise |

## O que medimos

`medir.mjs` leu as plantas e executou os modelos JS de conferência, sem executar os geradores remotos nem alterar arquivos de jogo. Os resultados completos estão em `medicoes.json`.

| Medida | Jardim local | Bosque de prova |
|---|---:|---:|
| Grade | 40×32 | 52×44 |
| Células em nível acima de zero / total da planta | **10,94%** | **43,18%** |
| Meta nova de platôs | Não atende 40% | Atende pelo critério de área total |
| Células alcançáveis | 1.027 | 1.136 |
| Peças | 37 | 939 |
| Árvores cadastradas | 23 | 754 |
| Eventos `item` | **0** | **6** |
| Baús como peças | 2 | 0 |
| Caminho mínimo até a saída seguinte | 51 passos | 45 passos |
| Tempo mínimo teórico a 3 células/s | cerca de 17 s | cerca de 15 s |
| Caminho até a saída sem mato obrigatório | Sim | Sim |
| Auditor geométrico básico | OK | OK com o modelo da própria prova |

Percentual de platôs foi calculado sobre todas as células, incluindo mata elevada. Isso não significa que 43,18% seja terreno explorável no alto. Devemos manter separadas as metas de volume visual e de exploração em altura.

Os tempos são limites teóricos de percurso, sem pausas, leitura, batalhas ou exploração. O deslocamento por teclado pode diferir do A* em quatro direções. Não equivalem a um playtest cronometrado. Mesmo assim, mostram que o requisito de **1–3 minutos para atravessar cada parte** não está demonstrado apenas por aumentar suas dimensões. Precisamos medir esse objetivo e decidir o que é tempo de travessia e o que é tempo de conteúdo.

## O que funciona melhor na prova

1. **O relevo organiza a circulação.** Os blocos altos contêm caminhos e ramais. Nosso Jardim tem uma plataforma isolada como exceção dentro de um grande chão baixo.
2. **O paredão possui leitura de topo, face e base.** Textura, borda de grama e contato dão sustentação. Não é necessário render 3D para obter esse volume em 2D.
3. **As trilhas têm variação de largura e contorno.** O desenho abandona a repetição de corredores retangulares. Deve continuar correspondendo à superfície realmente andável.
4. **A mata forma massas e moldura.** Isso cria recintos e continuidade além da câmera, em vez de árvores igualmente espaçadas pelo chão.
5. **As recompensas justificam os ramais.** Há itens nos platôs, junto à trilha e fora do percurso direto. O mato permanece opcional no caminho até a saída.
6. **A escala é avaliada perto do personagem.** A captura em zoom de jogo informa mais sobre legibilidade que uma vista distante de toda a planta.

## Pontos que ainda precisam ser resolvidos

### A prova não implementa o TileSet descrito no estudo

No modo floresta, `view.gd` chama `Forest.build()` no lugar da montagem por TileMap. `kronasta_forest.gd` cria um `Node2D` com `Polygon2D` para cada célula do mapa e da moldura. O shader mistura superfícies com máscaras suavizadas. Não há neste caminho o atlas de 47 encaixes nem a pintura nativa via `set_cells_terrain_connect` prometidos na proposta.

Isso é adequado como prova visual, mas não devemos declará-lo como a migração técnica concluída. Também há tensão entre a crítica do estudo à mistura por shader e o mecanismo usado na própria prova. Minha leitura: preservar o resultado visual como alvo e validar a solução de produção separadamente.

### Há uma dependência de rampas longas que não pode ser copiada só como mapa

A planta opta por `rampa_comprimento = 2`. O parser remoto expande cada semente em trechos com `rampFrom` e `rampTo`, e o modelo Godot remoto recebe a mudança correspondente. Nosso parser atual ignora essa propriedade.

**Foram encontradas 16 células com alturas diferentes entre os dois parsers**, embora ambos devolvam OK no auditor básico. Por exemplo, em (14,9) a altura central é 0,75 na prova e 0,5 no modelo local; em (15,9) é 0,25 contra 0. Copiar apenas o TMJ faria a rampa curta reaparecer silenciosamente. A integração precisa transportar parser, compilador, modelo e desenho em conjunto, com regressão dos mapas antigos.

### A/B/C ainda são regra e intenção, não uma região pronta

As saídas da prova apontam para `kronasta` e `kronasta-bosque-b`. Esses destinos não estão no índice de áreas/cenas analisado. Isso é esperado numa prova A isolada, mas impede afirmar que a região tenha ida, volta e atalho funcionando.

O Morro é uma exceção expressa: preserva cinco partes e Mikka na última. Não deslocar a campeã para a Laje só para fazer C virar sempre o final. O Parque encaixa diretamente nos três IDs existentes: Jardim A, Clareira B e Veredas C.

### Item cadastrado ainda não significa recompensa persistente

A prova tem seis eventos de item e itens escondidos, superando o mínimo em dados. O renderer desenha brilho para os visíveis/brilho, mas o `interact()` analisado só trata baú e saída de modo específico; os demais eventos produzem mensagem e sinal. Não foi demonstrado consumo, inventário, estado de coleta, condições narrativas ou retomada após carregar save.

Nosso Jardim tem dois baús, mas nenhum evento `item`: portanto não atende literalmente à regra de três itens por parte, incluindo um escondido. Não devemos contar automaticamente baús como três itens de chão nem inventar IDs e efeitos para preencher a quota.

A página do caderno da Heleana e o guarda Dito são conteúdo da prova. Não devem virar cenas canônicas da missão de Nina apenas por estarem nesse mapa de teste; é preciso conferir o momento da pista e suas condições.

### Desempenho ainda precisa de medição

O laço de terreno cobre `(52+18) × (44+18)` = **4.340 células**, contando a moldura de nove células. Só os pares de nó e polígono do chão representam 8.680 nós, antes de paredões, sombras, árvores, tufos, itens e personagens. A planta também contém 939 peças. Não medi FPS e isso não prova que o cenário esteja lento, mas justifica perfilar antes de torná-lo padrão para todas as regiões.

Uma meta de produção deve reduzir nós estáticos e preservar a ordenação. A moldura não pode crescer indefinidamente só para esconder o vazio; limites de câmera e vegetação de fundo fazem parte do orçamento.

### A direção visual ainda pede adaptação

A prova está mais próxima da organização espacial de Digimon World DS. Sua grama, sombreado e paredões são mais texturizados que o alvo de mangá com cor em massas aprovado para Soulmonsters. Eu adotaria **a construção espacial**, ajustando contraste, densidade e sombra à nossa identidade. Não recomendo nem o piso liso inteiro da nossa última revisão nem copiar toda a textura da prova sem comparação na escala do personagem.

O cuidado de trocar copas que encobririam a passagem por arbustos é útil. Precisa continuar respeitando a pegada física e não sugerir que uma passagem bloqueada é andável só porque a arte ficou baixa.

## Consequências para o que já fizemos

- Nosso mapa-múndi ainda é útil como grafo narrativo, mas Caverna, Coração, Santuário e outras regiões propostas como um arquivo precisam ser desdobradas em pelo menos A/B/C. Os nomes ainda são propostas; não criar novos IDs de regiões existentes sem migração.
- O Jardim atual é pequeno em volume vertical e muito distribuído em objetos soltos. Vale preservar eventos e intenção dos laços, mas refazer os maciços de terreno antes de mais pintura.
- Clareira e as partes antigas 24×16 estão abaixo da nova faixa 40×32–72×56; precisam de avaliação de expansão e ritmo. A exceção de cinco partes do tutorial não declara uma exceção de tamanho.
- Os bairros novos do plano tinham primeiro capanga no eixo e os outros três nas ruas. A regra nova pede dois em A e dois em B; os briefs devem refletir isso.
- A decisão direta mais recente do criador permanece: **preservar e aprofundar Nina no início**. A tabela de desbloqueios antiga da bíblia não revoga isso. Portões tardios podem abrir galerias e cenas posteriores sem impedir o resgate inicial.

## Sequência recomendada

1. Atualizar o plano regional com `regiao`, `parte`, ligações A↔B↔C e retorno após C, preservando os IDs existentes.
2. Transformar as regras manuais em conferências explícitas: contagem de partes/itens, condições, destinos, percentual de platôs e paridade das rampas. Um OK genérico hoje não cobre essas obrigações.
3. Refazer **somente o Parque A/B/C** como primeiro lote completo: Nina inicia a busca em A; B oferece rastros, descanso e caminhos alternativos; C entrega Lacertubo e recuperação da rabiola. Não expandir simultaneamente as 59 áreas propostas.
4. Reutilizar os kits aprovados de terrenos e validar um recorte pequeno com atlas/camadas no renderer de produção. Conferir rampas, cantos e personagem antes de qualquer cópia ampla de código.
5. Fazer uma caminhada cronometrada A→B→C→retorno, verificar coleta e salvar/retomar, e medir desempenho em câmeras de jogo. Só depois fixar o padrão para os demais biomas.

## Limites desta análise

Foram lidos documentos, código e capturas commitadas, e rodadas medições dos modelos JS em cópias locais. **Não executei o renderer remoto nem afirmei seus FPS, controles ou saves validados.** Não fiz merge, não substituí mapas locais e não publiquei alterações. Os arquivos de estudo estão disponíveis nesta pasta com revisão fixa em `origem.json`.
