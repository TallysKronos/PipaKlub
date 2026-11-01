# Planar com Nina — primeira travessia

## 1. Arquivos criados e alterados

Implementação da etapa posterior à promoção Rabiola Verde. `nina_glide.gd` controla permissão, operação persistida e recuperação; `park_glide_view.gd` apresenta a travessia apenas nas Veredas. `front_end.gd`, `state.gd`, objetivo da história, inventário e HUD integram o fluxo. Ligações autoradas em `godot/assets/campaign/glide-nina-v1/links.json`; intenção em `art/overworld/briefs/veredas-planar-nina.md`. Dois testes novos e atualização do teste de cronologia.

Não altera mapas compilados, pisos, barrancos, peças bloqueantes ou kits. Reutiliza o Carcará existente e a pose de salto do Kael; não cria um novo rig de voo.

## 2. Resultado automático

Saídas das suítes executadas:

```text
NINA GLIDE: 26 checks, 0 failures
NINA GLIDE FLOW: 24 checks, 0 failures
NINA ORDER: 19 checks, 0 failures
GREEN EXAM: 19 checks, 0 failures
CAMPAIGN CHECKS: 207 checks, 0 failures
CAMPAIGN VIEW CHECKS: 25 checks, 0 failures
OVERWORLD 343138 checks; 0 failures
Morro maps/views: 9386 checks, 0 failures
node --test tools/mapa-studio/model.test.mjs: 6 pass, 0 fail
```

As ligações validam: duas margens firmes na cota 0, sem rampa; acesso lateral livre; distância de 7 células; corredor alinhado, com água real, sem caminhada direta e sem peça sólida ou terreno mais alto. Ambas têm caminho normal desde a entrada. Essa conferência se aplica às novas ligações, não substitui uma nova auditoria integral da planta antiga.

As suítes gerais emitiram diagnóstico de compilação de shader em `_painted_floor`, avisos de recursos ainda em uso ao encerrar Morro e avisos do caminho relativo do log no Windows. Todas terminaram com código 0; esses diagnósticos não foram corrigidos por esta entrega. O fluxo nativo com imagens terminou sem esses diagnósticos. Relatório `geometry.json` gerado pelo teste foi restaurado; nenhum `kit.json` alterado.

Uma checagem adicional, `exploration_hud_checks.gd`, foi interrompida sem concluir, após acusar `FAIL one shared HUD: street` e `FAIL new objective returns`, além dos avisos de importação de imagens do professor. A origem dessas falhas não foi diagnosticada nesta etapa. Portanto não se declara aprovação da suíte geral de HUD; o HUD da travessia foi verificado no teste nativo específico (incluindo ocultar corrida durante o voo).

## 3. Capturas

Em `documentation/qa/nina-glide-v1/`, 1280×720:

- `01-decolagem.png`: chegada pelo caminho normal e sinalização.
- `02-planando.png`: Kael, Carcará emprestado e parceiro durante a travessia.
- `03-chegada.png`: pouso e objetivo seguinte.
- `04-detalhe-23.png`, `04-detalhe-16.png`: margens, zoom 2,2, sem personagem nas juntas.
- `05-geometria-travessia.png`: conjunto da ligação em cores chapadas.
- `06-geometria-23.png`, `06-geometria-16.png`: mesmas margens em geometria, zoom 2,2.

Inspeção visual das margens e da travessia concluída. Não há montagem antes/depois de terreno porque o terreno permanece igual.

## 4. Percurso

Teste nativo conduz o controlador da entrada até a seta sul, aciona o evento de interação real e confirma o diálogo. Verifica pausa, passagem sobre água não caminhável, autosave no ponto firme, recarga durante o voo, nova tentativa, pouso de ambos e volta pela ligação inversa. Não é apenas uma captura estática. Teste do serviço inclui falhas de gravação na saída e chegada, repetição de token e persistência após recarga.

Uma tentativa registra `player.ninaGlideFlight` versão 1 e checkpoint na origem antes da animação. A chegada grava checkpoint e recibo da operação juntos. Interromper recupera a origem sem completar o tutorial. Falha ao salvar a chegada mantém a operação pendente e permite tentar novamente. A ponte normal continua disponível.

## 5. Itens, pistas e revelações

Segue o empréstimo do Carcará da Nina após a entrega da rabiola e primeiro exame (§7.2 da bíblia). Exige as permissões `leagueGreen` e `ninaGlideLoanAvailable`; completar marca `ninaGlideTutorialDone`. Não concede criatura ao banco, moedas, XP ou item duplicável. Nenhum chefe ou revelação nova. O objetivo seguinte continua indicando Beira-Canal como conteúdo futuro.

## 6. Integração

Campanha e persistência implementadas pelo integrador na mesma entrega. Sem migração de banco: campo opcional validado na inspeção do save, compatível com saves anteriores sem a travessia. Exclusivo do save local da campanha; não representa validação de movimento no servidor online.

## 7. Dúvidas

Nenhuma definição narrativa pendente para esse trecho já previsto. Nova região, remonta e liberdade de voo permanecem fora desta etapa.

## 8. O que não foi verificado

Controle físico, Steam Deck, exportação de distribuição, rede/conta online e desempenho em hardware diferente não foram testados. O teste usa loja de saves isolada e entrada de evento/controlador programática, não botões físicos. Não foi refeito o levantamento de todas as juntas, itens, saídas e platôs distantes do mapa antigo. O parceiro reutiliza sua animação existente durante o deslocamento; animação específica de voo de cada espécie fica para acabamento futuro. Sem push, merge ou deploy nesta entrega.
