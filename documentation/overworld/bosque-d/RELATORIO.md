# Bosque D — Retalho

## 1. Arquivos e intenção
Brief ASCII em art/overworld/briefs/bosque-d-retalho.md, gerador tools/mapa-studio/desenhar-bosque-d.mjs, TMJ/JSON novo, extensão norte do mapa C preservando IDs, registro no índice. 48×40, cota1 com dois patamares2 e rampas4células para v-. Kit florestal existente; novo asset só para Retalho (fonte/prompt/QA em art/characters/retalho/game-v1, pacote godot/assets/campaign/retalho-v1).

O gerador D aplica a extensão C idempotentemente. Ao regenerar C pelo gerador antigo, rodar também desenhar-bosque-d.mjs para reaplicar a ligação. Não executar build geral que reescreve kits alheios.

## 2. Resultado automático
CONFERÊNCIA ZERO QUEBRA: SEM ERRO · 0 erros · 0 avisos
Platô67,5% · 3 itens (1 escondido) · 16 células compiladas de rampa · 0 inalcançáveis · 0 degraus soltos.
Auditoria inclui região A/B/C/D, direções/cotas/piso das ligações e percurso largo até todos os eventos. Todas as rampas sobem v-. Não há mureta, ponte, água, margem ou poço nesta extensão.

## 3. Capturas
54 PNGs geométricos +54 com arte em captures/{geometria,arte}. Incluem geral, jogo, pés/topos de todas as células de rampa, cantos de platô. Ligação C:4por modo em captures/ligacao-c-{geometria,arte}. Total116.
Revisão por pranchas reduzidas de detalhes e amostras nativas de rampas/cantos, entrada e ligação C. Personagens ocultos nas capturas de juntas. Capturas de campanha com atores/HUD em ../../qa/retalho-bosque-d. Defeito de borda na entrada encontrado em ampliação e corrigido com sealBoundary: fecha faces da cota1 até o chão externo0, sem ocultar com árvores. Demais regiões não recebem esse fechamento novo. Conjuntos D refeitos após a correção.

## 4. Percurso e testes
bosque_d_navigation_checks:1502 verificações, zero falhas, caminhante e seguidor reais em C e D, todos os eventos/rampas e retorno. retalho_campaign_checks:43 sem falhas; retalho_flow_checks:18 sem falhas, janela1280×720, caminhar C→D, interação, duelo22, pista visível após carregamento, fuga do rival e retornoC salvo. Resultados de combate forçados para conferir persistência/fluxo, não dificuldade.
Morro9386, Feira78, Cais139 e Node6 sem falhas. A suíte geral do overworld foi executada e refeita após o fechamento da borda:464461 verificações sem falhas. Nenhum artefato de teste alheio deve ficar no commit.

## 5. Itens e história
Três materiais já existentes: papel, linha e cola; papel escondido no patamar oeste. Mata de encontro fora da trilha obrigatória: espécies comuns existentes provisórias, Nv.20–22. Não foram criadas espécies selvagens novas.
Retalho usa a forma original A escolhida pelo dono como antiga parceira de Heleana, sem contar essa origem ao jogador. Duelo22, fala da bíblia “Quem tem dono é fraco.” e pista do nó de expedição após vitória. Retalho sai do mapa ao vencer; derrota/fuga permitem tentar novamente. Sem captura, prêmio de item ou XP inventado para o duelo de história. Vitória/pista/remoção e retorno usam o mesmo recibo de gravação. A possessão não foi inserida nesta cena.

## 6. Integração
Checkpoint/validador aceitam D; acesso pelo norte de C exige conclusão permanente do Cais. Não existe viagem rápida direta paraD. Sprite estático adaptado em112px e combate320px; animações do catálogo repetem o único quadro explicitamente, sem fingir rig. Nome de asset retalho-original não concede espécie colecionável. Serviço dedicado e validação de cena/modelo/Nv22. Erro de índice de kit de capim corrigido usando fallback Veredas quando a floresta só carrega kit comum. Filtro de NPCs do Bosque aceita assets storySpritePath explícitos sem usar identidade humana inexistente.

## 7. Diferenças e decisões pendentes
A regra genérica de partesD propõe NPC avisando sobre risco. Não foi inventado NPC novo sem bíblia; o objetivo informaNv22 e a confirmação do duelo permite recuar. Sem novo marco arquitetônico: a clareira elevada e a silhueta de Retalho são a atração principal. Não existe animação de fuga: ele sai após a transição de resultado, descrita no diálogo. A foto do arquivo do ateliê e a progressão narrativa da Vila Operária são a próxima etapa; não foram antecipadas ou dadas como prontas.

## 8. Não verificado
Não foram examinados todos os116PNG individualmente em tamanho nativo. Cantos da moldura atrás de copas têm geometria exposta no modo simples, mas parte da arte continua ocluída na captura. Não há prova de acabamento final de cada canto sob vegetação. Sem teste prolongado de controle físico, Steam Deck/exportação, campanha inteira desde o prólogo ou balanceamento. Sem animação/rig Soulgen. Sem aprovação artística automática dos novos sprites/mapa.
Avisos preexistentes: safe-save ao importar, shader_compiler de _painted_floor em headless, recursos/ObjectDB ao encerrar Morro. Nenhuma proteção desativada. Sem push, merge ou deploy.
