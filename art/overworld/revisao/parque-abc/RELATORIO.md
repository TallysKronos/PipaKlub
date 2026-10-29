# Parque A/B/C — plantas regionais, 29/10/2026

**Revisão atual do riacho:** [água animada existente e vala contínua — v4](REVISAO-AGUA-V4.md). Atualiza o tamanho das pontes, a extensão da água e as contagens da v3.

**Atualização visual mais recente:** [pisos, riacho e pontes mangá v3](REVISAO-MANGA-V3.md). A descrição abaixo preserva o histórico das plantas; os pisos pintados, a água raster e o tabuleiro da ambientação v2 foram substituídos. As capturas atuais mostram a revisão v3.

**Escopo entregue:** fluxo narrativo proposto e três plantas conectadas, compiladas para a prévia independente do Godot. Não é a integração da missão à campanha nem aprovação final da arte. A referência espacial veio do estudo trazido pelo criador; o alvo de acabamento continua mangá 2D simples.

## O que mudou

| Parte | ID mantido | Dimensão | Função | Relevo acima do nível zero |
|---|---|---|---|---:|
| A | `jardim-das-pipas` | 60×44 | Nina, chegada, coreto, exploração introdutória | 41,78% |
| B | `clareira-do-papel` | 64×48 | Riacho, duas pontes, circuito alto e descanso | 43,82% |
| C | `veredas-do-encanamento` | 64×48 | Aproximação, pátio elevado de Lacertubo, retorno | 43,52% |

Maciços altos contêm a circulação; os caminhos passam entre eles e sobem por rampas. Os platôs oeste têm dois acessos, permitindo voltar à trilha por outro ponto. Os dois lados das pontes de B apoiam em terra firme. A margem oeste se liga ao patamar sudoeste, criando uma alternativa alta real. O teste bloqueia a ponte central e depois todas as pontes, e confirma que ainda existe uma rota de B a C.

Cada parte tem três eventos `item`, incluindo um escondido, usando os identificadores `linha` e `folha` dos materiais da oficina. Quantidade 1 é proposta de dados, sem concessão de itens ou novo efeito no jogo. Os baús existentes foram preservados separadamente. Há nove eventos de item comuns no total; a rabiola de Nina não foi duplicada como material genérico.

Os objetos antigos mantêm seus IDs, pegadas e ações. Não removemos Assis, Nina, a interação da rabiola ou o boss. As coordenadas mudaram: é necessário migrar posições antigas antes de substituir os mapas oficiais da campanha. O evento novo de Nina em A usa o nome exato `Nina`, exigido pelo cadastro visual atual, evitando a substituição incorreta pelo sprite de Assis.

## Fluxo da história

O brief atual está em `art/overworld/briefs/parque-dos-ventos-abc.md`:

1. A: conhecer Nina e compreender o que ela perdeu; não explicar toda a trama.
2. B: seguir sinais até os canais, optar por desvios e se preparar num descanso seguro.
3. C: encontrar Lacertubo, vencê-lo, recolher a rabiola de Carcará e voltar pelo atalho até Nina em A.

O novo atalho C→A tem o metadado `requer=guardianDefeated`; o boss tem `ocultar_apos=guardianDefeated`; a rabiola mantém `veredasTail` e o requisito de vitória. A recompensa própria do boss continua conceitualmente separada. O evento legado de Nina em C foi reservado para uma fase posterior/inativa na primeira visita, evitando autorizá-la narrativamente em dois lugares ao mesmo tempo.

**Essas condições são dados de planta. A prévia independente atual não as executa.** Elas não comprovam desaparecimento do boss, entrega, inventário, crédito de recompensa ou persistência. Nenhum save real foi aberto ou modificado.

## Conferências feitas

- Três partes com `regiao=parque-dos-ventos` e `parte=A/B/C`.
- Auditor básico do Mapa Studio: OK nas três, sem erro ou aviso geométrico.
- Auditor regional adicional: dimensões, 40% de altura, IDs preservados, três itens e um escondido, peças sem sobreposição, todas as rampas nos dois sentidos e todos os eventos/baús com rota de ida e volta sem mato obrigatório.
- Grafo: A↔B↔C; C→A condicionado em dados. A preserva a saída para `quintal`; a tela do mundo de Kronasta ainda não existe nesta branch e não foi fingida como destino pronto.
- 48 destinos de interação/saída/baú conferidos pelo modelo; 33 células de rampa com passagem e altura central verificadas.
- Mapa Studio: 7 testes do modelo/servidor passaram. Godot: ver logs `teste-overworld.log` e `teste-morro.log`; as contagens finais são gravadas ali.
- 13 capturas reais do Godot: visão geral geométrica e com kit, três câmeras na escala de jogo, juntas de rampas em 3× e ponte em 3×. Nas juntas, personagens ficam ocultos. Nas câmeras de escala, personagens são fixtures de revisão, não uma sessão de campanha.
- Seis PNGs exportados pelos botões do Mapa Studio: referência sem texto e legenda de cada parte. O inventário foi regenerado pelo gerador oficial.

`conferencia.json` contém caminhos, número de passos, requisitos pendentes e avisos; `capturas.json` contém modos, tamanhos e zoom. O gerador só compilou as três plantas: não executou o build global que reescreve kits alheios.

## Avisos e limites de aceite

1. **Duração ainda não validada.** A rota mínima de A até B é cerca de 13,7 s; de B até C, 15,3 s, calculadas a três células por segundo, sem conteúdo. Isso ainda não demonstra 1–3 minutos por parte ou 4–8 minutos para explorar. Interações, desvios e missão precisam ser cronometrados. Não alongamos artificialmente um labirinto para declarar a meta atingida.
2. **Condições não ligadas à campanha.** `requer`, `ocultar_apos`, estados de item e `regiao/parte` ainda precisam de contrato de integração. O compilador atual não transmite todos os metadados do mapa como progressão, e a prévia não aplica os requisitos de fase.
3. **Arte provisória.** O kit existente mostra massas, escala e apoio. A parede de alvenaria, a ponte quadriculada e o plano de rampa não são o acabamento natural final. A próxima prova visual deve usar barrancos, bordas, margem e rampa próprios, com poucos tons e sem render volumétrico. A geometria precisa continuar idêntica.
4. **Câmera e oclusão.** A moldura física de mata foi cadastrada na planta. Limites da câmera e transparência de copas precisam de playtest na integração; a visão geral não comprova que nunca apareça fundo vazio ao jogar.
5. **Desempenho não medido.** As massas de mata são dados explícitos da planta; não importamos o renderer especializado de 754 árvores da prova remota. A implementação atual ainda precisa de medição antes de fixar o orçamento de tiles/objetos.

Não houve merge, push ou publicação. Não houve mudança no código de batalha ou saves. O renderer da prévia recebeu seleção de entrada pelo nome, eixo correto de ponte e acabamento pintado de baixo contraste. Nenhum código remoto de renderer foi importado.

## Próxima etapa concreta

Escolher um recorte de A/B contendo ramal alto, rampa, margem, ponte e personagem. Nele, acertar o TileSet/camadas e a arte 2D simples, conferir as juntas e a leitura em escala de jogo. Depois percorrer A→B→C→A com estados de missão, coleta e salvar/retomar integrados. A planta é a referência para essa integração, não um substituto dos seus testes.


## Atualização — assets e caminhos alternativos

A primeira planta foi preservada em seu percurso. B e C agora têm duas ligações independentes: trilha baixa pelas entradas principais e passagem alta com chegada própria. O teste `parque_connections_checks.gd` percorre a troca de mapa e o retorno, verificando as posições exatas. A conclusão vale para a prévia independente, não para o roteador da campanha.

Aplicados assets existentes da revisão `f3df6373316305ff0c9dec449d1229f2cd0c4526`: barrancos de arenito, tabuleiros de ponte, água, buritis, vegetação de margem e canos. As peças foram reposicionadas manualmente nas novas plantas; não copiamos os posicionamentos do mapa antigo. A vegetação alta bloqueia somente seu apoio lógico, e os acessos foram novamente conferidos. Chão e rampas compartilham a paleta clara, com pintura de baixo contraste em coordenadas contínuas; bordas e altura não são esticadas junto com o detalhe.

Validação: auditor regional sem falhas, 66.612 verificações do overworld sem falhas e teste de ida/volta pelas entradas altas sem falhas. 13 capturas reais regeneradas. Ainda há recortes de transição geométricos a refinar e o resultado aguarda aprovação visual. As seis exportações anteriores do Mapa Studio são históricas da planta anterior às portas altas; use as capturas Godot e JSONs atuais para esta revisão.

Diretriz para as demais regiões: conectar áreas como uma rede com ramais e reencontros, evitando obrigar A→B→C em todas as situações. Cada saída deve ter chegada própria, marco visual e rota de retorno; os requisitos narrativos precisam existir no estado da campanha antes de liberar atalhos.
