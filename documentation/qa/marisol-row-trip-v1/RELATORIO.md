# Remar · capivara D de Marisol · primeira travessia prática

## 1. Arquivos

Novo adaptador `park_row_view.gd`, serviço `marisol_row_trip.gd`, modelo `row_motion.gd`, rotas `marisol-row-v1/links.json`, spritesheet `capivara-d-swim.png`, importação Godot e manifesto `swim.json`. Integração no frontend, validação do save, diário, atlas e acesso ao Pântano. Conteúdo da aula e Bíblia atualizados. Brief em `art/overworld/briefs/remar-pantano-a.md`.

Não foram modificados plantas Tiled, mapas compilados, alturas, margens, ponte, árvores ou itens. Os dois embarques são eventos da campanha adicionados somente pelo adaptador. Sem alteração de kits alheios.

## 2. Conferência automática

A suíte verifica as duas rotas autoradas: origem (16.5,25.5) e destino (16.5,18.5), com retorno invertido, no Pântano A. Segmento axial de 7 células; seis células internas água/cota0, sem peça sólida. Pontas caminháveis sem rampa, na cota0, com faixa lateral livre. Ambas alcançáveis por caminhada a partir da entrada; o rio continua intransponível para a navegação terrestre. Nenhuma geometria foi criada pelo código de animação.

Resultados: 42 verificações na revisão nativa; versão final headless 39 verificações, zero falhas. Aula de Marisol 18, Planar de Nina 32, atlas 194, confiança de Retalho 92, Morro 9386: zero falhas. Mapa Studio: seis testes passando. Teste geral do overworld executado separadamente, resultado ao final do relatório.

Cobertura: pré-requisitos e entrada de jogador fora de QA, banco sem parceiro de combate saudável, ida/volta, recarga, interrupção, rejeição de origem remota e token antigo, ausência de avanço ocioso, pausa, repouso, confirmação real da interface, falha na partida e na chegada, fechamento do aviso e repetição do desembarque. Nenhuma moeda, item, XP ou parceiro é concedido por repetir a travessia. O flag `canRemar` é concedido junto da chegada, não na aula teórica.

## 3. Capturas e asset

`geometria/` e `arte/`: sete capturas por versão, 1280×720, sem atores: área inteira, quatro enquadramentos de jogo e duas margens ampliadas a 2.3×. Plano em `plan.json`; pranchas `conferencia-*.jpg` revisadas em contato. Não se refez a auditoria de cada junta antiga do mapa, pois elas não foram alteradas.

`01-margem.png`, `02-travessia.png`, `03-chegada.png`: fluxo na janela nativa. A revisão detectou sobreposição da capivara e ordenação atrás do cenário; corrigida a separação e usado o mesmo nível de ordenação dos atores, com Y-sort do cenário. Captura final da travessia revista individualmente.

Arte gerada com image_gen, referência no D escolhido. PNG RGBA 1536×1024, grade2×2, quatro regiões768×512, 6fps, alpha0–254. Vazio transparente conferido; RGB residual do preview da ferramenta não é fundo opaco no jogo. Nenhum frame invade outro: bounds visíveis de cada célula registrados no manifesto. Há variação pequena de contorno/pose entre frames; não é rig Soulgen ou ciclo técnico aprovado pelo dono. Prompts e revisão em `art/creatures/capivara-boia/swim-v1/`.

## 4. Percurso

O controlador do Kael percorreu a margem próxima antes de embarcar. Embarque confirmado pelo diálogo da campanha; segurar Interagir ou o botão Remar avança a balsa durante pelo menos5s, soltar recupera o fôlego. Pausa não avança o modelo. A animação usa a capivara à frente, cabo, pequena balsa e ondas; o companheiro de combate fica oculto durante a travessia e retorna em solo firme.

A chegada é gravada antes de remover o transporte visual. Falha preserva a operação pendente e permite repetir após fechar o aviso. Reabrir a exploração com viagem pendente recupera a margem de origem sem crédito de prática. O checkpoint durante a travessia permanece na origem segura; não se salva Kael dentro da água.

Ambas as margens e o retorno foram verificados. Não foi realizado percurso manual por pessoa com controle físico nem revisão animada de todas as juntas do mapa antigo.

## 5. História, itens e pistas

Marisol ensina após o Exame Azul, como aprovado. Capivara D é apoio emprestado, sem entrar no banco do save ou nos20slots globais. Platyx continua exclusivo do arco de Grampo. Não se criaram encontros selvagens, itens, nome próprio ou revelações para esta capivara. A e B/C da exploração original seguem preservados.

A aula abre o Pântano para a prática também fora do modo QA, independentemente de Retalho. A ponte existente continua alternativa. O aprendizado de Remar não solta Mormaço e não concede categoria Vermelha; a história e o combate do guardião continuam pendentes.

## 6. Integração

Código da campanha e persistência incluídos no escopo solicitado, sem mudanças de batalha, servidor, Supabase, deploy ou merge. Campos de viagem opcionais e validados; saves anteriores continuam aceitos. Nenhum push nesta entrega.

## 7. Decisões pendentes

Nenhuma para usar o D na primeira travessia aprovada. Próximo passo de história: abertura do Ato4 e Mormaço. O guardião precisa de direção visual própria antes de ser apresentado; não foi substituído por um monstro genérico.

## 8. Não verificado / limitações

Controle físico, Steam Deck, exportação Steam, múltiplas máquinas, jogador externo e uma sessão longa de animação. As defesas e ataques não fazem parte desta travessia. Balsa/cabo/ondas são desenhos procedurais simples; acabamento de embarque e submersão ainda pode ser refinado. A capacidade de Remar atualmente atende somente o trecho autorado em Pântano A, não natação livre.

Avisos conhecidos: imagens do ateliê carregadas fora do caminho adequado para exportação, recursos/ObjectDB ativos ao encerrar algumas suítes e condição do compilador de shader `_painted_floor` no teste geral headless. A importação do novo PNG concluiu; o editor também emitiu um aviso de safe-save no ambiente. Isso não valida uma exportação distribuível.

Resultado final do teste geral: `OVERWORLD 507283 checks; 0 failures`.
