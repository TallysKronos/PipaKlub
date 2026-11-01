# Feira do Largo — etapa de construção dos três mapas

## 1. Arquivos

Brief art/overworld/briefs/kronasta-feira.md; gerador tools/mapa-studio/desenhar-kronasta-feira.mjs; plantas art/overworld/mapas/kronasta-feira-{a,b,c}.tmj; compilados godot/assets/overworld/maps/kronasta-feira-{a,b,c}.json e índice. Renderer novo market_structures.gd e kit feira-v1/kit.json. Integração de montagem em kronasta_forest.gd e view.gd isolada por forest.market. Teste feira_navigation_checks.gd.

## 2. Conferência automática

Saída do gerador, zero erros e zero avisos nas três partes:

- A: platô 68,0%; 3 itens, 1 escondido; 16 células de rampa; zero inalcançáveis ou degraus soltos.
- B: platô 68,0%; 3 itens, 1 escondido; 24 células de rampa; zero inalcançáveis ou degraus soltos.
- C: platô 80,4%; 3 itens, 1 escondido; 32 células de rampa; zero inalcançáveis ou degraus soltos.

Checagens compartilhadas: rampas u+/v+, bolsões, corredor obrigatório, árvore solta, apoio e chegada, muretas, região/partes/itens e continuidade das ligações. Checagem adicional da Feira: toda pegada de banca deve ficar em um único nível, sem rampa. Corrigida banca B que cruzava a cota lateral; guarda-corpo do mercado alto acrescentado.

Testes: navegação 3.146 verificações, zero falhas; overworld 401.536, zero falhas; Morro 9.386, zero falhas; Node Mapa Studio 6 testes, zero falhas. O diagnóstico preexistente do compilador de shader em _painted_floor e os avisos de recursos no encerramento do Morro continuam presentes. Nenhuma proteção foi desabilitada.

## 3. Capturas

planos/kronasta-feira-{a,b,c}.json lista todos os enquadramentos; captures/<parte>/<geometria|arte> contém as versões 1280×720. A: 49 por modo; B: 74; C: 84, total 414 imagens previstas. Capturas sem personagens nas juntas, entrada/centro/saídas, platôs, cada boca de escada, cantos de barranco, encontros/pontas de mureta e grupos de bancas.

Revisadas as três vistas inteiras e todas as capturas em 28 pranchas comparativas reduzidas; amostras de juntas também abertas em resolução nativa: A rampa-pe-12-29, B mureta-junta-15-17, C rampa-topo-22-10. Não foi reaberto individualmente cada PNG em resolução nativa. Não há água, ponte ou poço nesta região. Nenhuma área anterior substituída.

## 4. Percurso

Teste com controlador e seguidor reais, por caminhos calculados, da entrada a todos os eventos/saídas e todas as células de rampa, ida e volta. Altura/caminhabilidade do jogador e seguidor verificadas durante a simulação. Não foi uma sessão manual completa com controle físico. Ajuste final da mureta não altera a navegação; foi conferido pelo gerador e recapturado.

## 5. Itens e história

Cada parte reserva papel-seda, linha-encerada e cola-reparo, incluindo um escondido. Veyra/Orven em A, Zafri/Nymel em B, Dona Zulmira em C; secundários autorizados pelo dono. Marcadores de Lalau em A e Grampo em B. A nova identidade aprovada de Grampo é referenciada. As falas atuais são de preparação, não implementam o golpe. Nenhuma nova revelação da família de Kael.

## 6. Integração narrativa pendente

Esta entrega é a construção física em prévia, não a campanha Feira concluída. Não foi marcada playable no catálogo nem liberada a viagem de saves existentes. Próxima etapa: compra idempotente do apito falso; teste na porta e retorno com Lalau; duelo Lalau 16; Grampo/Platyx 17 e apito verdadeiro; quatro duelos do bairro e Dona Zulmira 18; recompensa única, defesa de título, descanso, liberação da Caverna. Preservar promoção Verde já realizada no código atual em vez de repetir o exame citado adiante na bíblia.

## 7. Decisões

Sem pergunta bloqueante pendente. Os nomes secundários foram autorizados na conversa. Aparência de Lalau, Zulmira e novos pipeiros ainda deve ser produzida/revisada; os marcadores não são aprovação de personagens.

## 8. Não verificado / limites visuais

Bancas têm geometria e cores chapadas com toldos listrados: são a primeira montagem visual, não acabamento pintado definitivo. Casas reutilizam o kit existente e não têm interiores. As partes compartilham o eixo urbano, B acrescenta o mercado alto e C o largo de dois níveis; maior variedade de fachadas, mercadorias e sinalização fica para o passe de arte. O fundo preto é intencional como solicitado pelo dono; as bordas do mapa aparecem em vistas amplas. Não foram testados economia, batalhas, apitos, câmera entre cenas pelo fluxo real da campanha ou exportação nesta etapa. Sem push, merge ou deploy.
