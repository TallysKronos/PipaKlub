# Cais Velho — integração da campanha

## Entregue
Cinco sprites estáticos gerados por image_gen, preservando a identidade das pranchas aprovadas, com alpha original e margens completas. Fontes, prompt e QA em art/characters/cais-overworld-v1; empacotador tools/package-cais-npcs.py. Runtime em godot/assets/npc-ds/cais-v1. Sem rigs ou animações novas.

Cais desbloqueia após Feira. Quatro desafios e Marisol Nv.21, quinto emblema, título, defesa e reconquista. Viagem regional entra pela parte A; B/C são acessadas andando. Descanso B custa12 moedas apenas quando necessário. Atalho C→A usa histórico permanente de vitória. Objetivo regional mostra adversário/progresso. Nove materiais existentes com recibos de coleta. Sem novas revelações ou parceiros canônicos: rosters existentes provisórios.

## Verificado
- cais_campaign_checks:139 verificações sem falhas. Vitória, fuga, derrota, persistência de batalha, bloqueio da campeã, quinto emblema, defesa perdida, requalificação, reconquista sem duplicar emblema, nove itens sem duplicação, descanso e escrita falhando sem débito.
- cais_flow_checks:42 verificações sem falhas em janela nativa1280×720, caminhante real, interação/confirmação, cinco duelos, retorno às cenas, emblema e atalho salvo. Capturas nesta pasta. Resultados de combate forçados para validar fluxo/persistência, não balanceamento.
- cais_navigation_checks:2090 verificações sem falhas, incluindo nova posição do Neril.
- district_checks:451; feira_campaign_checks:78; kronasta_atlas_checks:187; morro_map_checks:9386; overworld_checks:454762; Node model:6 testes. Todos sem falhas.
- Gerador A/B/C:0 erros,0 avisos. Geometria preservada; somente posições de Neril/Rhuna e propriedades de arte alteradas.

## Revisão e limitações
Inspecionadas capturas nativas dos cinco personagens nas partes A/B/C e resultado de Marisol; Neril e Rhuna foram afastados das casas após constatar oclusão. Prévia dos cinco sprites inspecionada no tamanho de consumo. Concepts aprovados e variantes anteriores preservados. Falta aprovação artística destes sprites pelo dono. Sem teste prolongado com controle físico, nova campanha inteira desde o prólogo, export Steam/Deck ou teste de dificuldade/economia. O Industrial ainda é prévia; não há interiores visitáveis das casas do Cais nem novo boss selvagem. Capturas geométricas anteriores continuam válidas para juntas pois pisos, paredes e escadas não mudaram.

Avisos preexistentes durante execução: safe-save na importação; shader_compiler de _painted_floor em modo sem janela; ObjectDB/recursos ainda em uso ao encerrar Morro. Os processos retornaram0 e as suítes reportaram zero falhas. Proteções do editor preservadas. Relatório de geometria alheio e UIDs regenerados alheios revertidos/removidos antes dos commits. Sem push, merge ou deploy.

Correção posterior: falas do Cais normalizadas para pares [locutor,texto], como exige o consumidor. Antes, uma string simples fazia o menu selecionar apenas seu segundo caractere. Quinze verificações de conteúdo acrescentadas à suíte.
