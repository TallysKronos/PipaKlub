# Caverna do Mural — entrega v1

## 1. Arquivos
Gerador `tools/mapa-studio/desenhar-caverna-mural.mjs`, brief `art/overworld/briefs/caverna-do-mural.md`, três TMJ e JSON compilados. Renderer de calcário e piso quente restrito a `forest.mural`, painel mural-v1 com origem e prompt preservados. Integração em checkpoint, atlas, história, front_end e serviço mural_story. Testes mural_campaign, mural_navigation e mural_flow.

## 2. Conferência automática

### Parte A

CONFERÊNCIA ZERO QUEBRA: SEM ERRO · 0 erros · 0 avisos
Platô 80.1% · 3 itens (1 escondidos) · 10 células de rampa · 0 inalcançáveis · 0 degraus soltos

### Parte B

CONFERÊNCIA ZERO QUEBRA: SEM ERRO · 0 erros · 0 avisos
Platô 100.0% · 3 itens (1 escondidos) · 10 células de rampa · 0 inalcançáveis · 0 degraus soltos

### Parte C

CONFERÊNCIA ZERO QUEBRA: SEM ERRO · 0 erros · 0 avisos
Platô 100.0% · 3 itens (1 escondidos) · 10 células de rampa · 0 inalcançáveis · 0 degraus soltos

A taxa de platô é a métrica absoluta do auditor (inclui a moldura elevada); não significa 100% de terreno caminhável na mesma cota. As três plantas têm duas cotas caminháveis ligadas por rampa para v−, com progressão regional 0→1→2→3.

## 3. Capturas
`captures/{a,b,c}/{geometria,arte}/`: área inteira, entrada, centro, câmara baixa/alta, nicho, saídas, pés/topos de rampas e cantos. A:73 por modo; B:65; C:78. Total432 PNGs de mapa. Quatro capturas adicionais em `documentation/qa/mural-v1/` mostram percurso e diálogo.

Revisão: três gerais em arte; todas as imagens de arte em pranchas reduzidas; pranchas geométricas das rampas e capturas gerais. A geometria foi conferida antes do mural. Corrigidos degrau artificial na rocha e teto de primeiro plano que encobria o caminho. Recorte de teto é convenção de interior, com borda curta contínua; preto representa rocha não mostrada, não abismo transitável. Não há pontes, muretas, água ou poços nesta região.

## 4. Percurso e testes
Caminhante/seguidor reais sobre cada item, NPC, saída e célula de rampa, ida e volta:1754 verificações, zero falhas. Fluxo nativo:19 verificações, zero falhas (porta verdadeira→A→B→C, caminhada a Tyler, leitura, interrupção e retomada). Serviço:27 verificações, zero falhas, incluindo ordem das etapas, distância/cena inválida, persistência, idempotência, descanso e falha de escrita com reversão.
Regressões: overworld425734; Morro9386; atlas181; Feira78; Node6, todas sem falhas. Diagnósticos existentes: compilador de shader em _painted_floor no modo sem janela; Morro informa objetos/recursos ainda em uso ao encerrar. A importação também emitiu aviso de safe-save. Nenhuma proteção foi desligada. O fluxo nativo do mural encerrou sem esses erros.

## 5. História, itens e revelações
Três materiais existentes por parte (cola, vareta e papel), um escondido por parte. Tyler existente, sem redesenho. Mural em três etapas: visitante/ovo; oferta voluntária da linha; reação da Rabiola Antiga. Não revela identidade do visitante nem a origem do Rabbito. Retalho opcional omitido. Sem boss, nova espécie, XP ou nova concessão da categoria Verde. Contradição de cronologia: a campanha já concede Verde na missão da Nina; foi preservada para não duplicar recompensa nem apagar progresso.
Acesso exige Feira concluída, flag e item de apito verdadeiro. Saída curta do salão exige leitura concluída; caminho de volta por B e A permanece disponível.

## 6. Integração
Código de campanha executado no escopo autorizado pelo dono para continuar a história. Não houve alteração de batalha, servidor, economia online ou deploy. Mapas anteriores não recebem o novo shader/recorte, que é condicionado a forest.mural.

## 7. Pontos para revisão do dono
Aprovar a proposta pictográfica do mural. Próxima região de campeonato permanece o Cais; não foi construída nesta etapa. Os sinais de entrada e vento previstos no brief ainda são sugeridos pela disposição da rocha, sem assets dedicados ou animação.

## 8. Não verificado
Não foi feita inspeção individual em tamanho nativo de cada uma das432 imagens; os detalhes foram revisados por pranchas e amostras, portanto o acabamento visual não recebe aprovação final. Não houve sessão manual longa com controle físico, Steam Deck ou build exportada. O teste de fluxo usa fixture local com pré-requisitos preparados; não repete desde o prólogo. Sem avaliação de duração narrativa com jogadores externos. Não implementa movimento dramatizado, dublagem, música própria, animação da luz da rabiola ou Soulgen para Tyler. Reaproveita formações do kit de cavernas. Sem merge/push/deploy nesta etapa.
