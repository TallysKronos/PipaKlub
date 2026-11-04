# Exame Azul · Pátio da Liga · primeira versão jogável

## 1. Arquivos criados e alterados

Mapa novo `parque-patio-liga`: brief em `art/overworld/briefs/`, gerador `tools/mapa-studio/desenhar-patio-liga.mjs`, fonte Tiled e compilado Godot. Registro no catálogo, checkpoint, save, atlas e adaptador do Parque. Jardim recebe uma ligação da campanha, sem alteração de sua planta.

Mecânica em `blue_exam.gd`, `blue_escort_model.gd`, `blue_control_model.gd`, `blue_exam_guide.gd` e `blue_control_view.gd`. Integrações no frontend, diário, carteira, inventário e HUD. Bíblia e proposta atualizadas com a decisão do dono. Testes novos `blue_exam_checks.gd` e `blue_yard_walk_checks.gd`; regressões de orientação e atlas ajustadas ao novo requisito.

## 2. Resultado automático

```text
CONFERÊNCIA ZERO QUEBRA: SEM ERRO · 0 erros · 1 avisos
Platô 98.4% · 3 itens (1 escondidos) · 16 células de rampa · 0 inalcançáveis · 0 degraus soltos
AVISO [Partes da região] Auditoria local: ligações da região NÃO verificadas nesta chamada.
ANEXO D: região Parque A/B/C preexistente; ligação explícita pelo Jardim e mapa regional.
```

O aviso é justificado no brief: anexo D de região A/B/C existente, não uma nova região isolada. Os testes da campanha verificam ida/retorno, elegibilidade, piso terra e cota 0 das duas pontas. Não foi refeita uma auditoria regional completa de todos os mapas antigos.

Resultados (zero falhas):

| Suíte | Verificações |
| --- | ---: |
| Exame, janela nativa | 50, antes dos dois últimos checks de retorno/material |
| Exame, versão final headless | 47 |
| Percurso real do controlador no pátio | 197 |
| Orientação do exame | 29 |
| Atlas | 194 |
| Retalho: cuidado | 35 |
| Retalho: confiança | 92 |
| Overworld | 507283 |
| Morro | 9386 |
| Modelo Mapa Studio / Node | 6 testes |

A suíte do exame percorre a condução pelo controlador real, recarrega um marco intermediário, simula as fases do controle e aciona a interface até a concessão. Prova com banco de 30 parceiros sem saúde, sem Retalho, preservando moedas/materiais; idempotência e falha de gravação antes de observação e promoção. O clique de voo foi enviado pela janela/GUI, não somente por chamada direta de função. A interface bloqueava esse clique na primeira revisão: corrigida com superfície própria de entrada.

Os testes gerais emitiram avisos preexistentes: carregamento de imagens do ateliê inadequado para exportação, condição do compilador de shader em `_painted_floor` no teste headless, e recursos/ObjectDB ainda ativos ao encerrar algumas suítes. Os contadores terminaram com zero falhas; isso não equivale a uma exportação sem avisos.

## 3. Capturas

`mapa/geometria/` e `mapa/arte/`: **47 PNGs por versão**, 1280×720, sem personagens nas juntas. Incluem área inteira, entrada, centro, observação, condução, controle, saída, cantos, pés e chegadas das duas escadas, pontas/encontros de muretas. Plano reproduzível em `planos/parque-patio-liga.json`.

Pranchas `mapa/*-conferencia-1..4.jpg`: revisão de todas as capturas em contato. Vista inteira também revista individualmente. Não houve inspeção individual de cada PNG no tamanho original. Sem água, ponte ou poço: essas categorias não se aplicam. Área nova: sem antes/depois.

`fluxo/01-bancada.png` a `05-aprovacao.png`: apresentação na campanha, observação, condução, controle e confirmação de categoria. Revistas visualmente, incluindo a janela do controle.

## 4. Percurso

Controlador de clique do Kael percorreu da entrada a cada evento e item, retornando ao início, com passagens acima/abaixo de cada faixa das escadas. Condução também percorreu seus três marcos no adaptador real da campanha, acompanhando o Carcará, com progresso parcial recarregado.

Entradas: Jardim (34,31) → pátio (20,29); pátio (20,31) → Jardim (34,31). Ambas terra/cota 0. Seta discreta azul no Jardim após categoria Verde e conclusão histórica de Cais e Vila Operária. Perder título de bairro não retira qualificação. O mapa regional também oferece o anexo.

## 5. Itens, pistas e revelações

Três materiais opcionais: papel de seda escondido (7,23), linha encerada (33,9), cola de reparo (33,26). Não são prêmios da prova.

Exame: observação de cansaço → descanso; três marcos de acompanhamento; sustentação por 2 s, alívio ao sinal e três defesas deliberadas. Erros repetíveis sem custo/dano; etapas aprovadas persistem; exercício de controle incompleto reinicia ao sair. Ao se afastar do Carcará, ele espera e pode voltar ao último marco seguro.

Dona Cida registra `leagueBlue` e um certificado na mesma operação, uma vez. Sem XP, captura, transferência de parceiro ou capacidade de banco alterada. Carcará emprestado nunca entra no banco. Retalho não é requisito e não é concedido nesta prova. Repetir treino não gera recompensa.

## 6. Integração

Fluxo, persistência e HUD foram incluídos no escopo autorizado da campanha. Não houve alteração de combate, servidor, economia online, migração Supabase, deploy, merge ou push. Saves antigos sem `blueExam` continuam válidos; o campo é opcional e validado quando presente.

## 7. Dúvidas para o dono

Nenhuma decisão de história bloqueando esta versão: local e espécie aprovados. Próxima revisão recomendada: arte própria de Dona Cida e direção visual do espaço de avaliação.

## 8. O que não foi verificado

Controle físico, Steam/Steam Deck, exportação distribuível, teste com jogador externo e balanceamento de dificuldade. O controle foi verificado com eventos de entrada e modelos, não com uma pessoa segurando um gamepad. Não foi realizada revisão animada dos pés/sombra do Kael sobre cada junta; percurso automatizado e capturas sem atores não substituem essa inspeção.

A arte de Dona Cida ainda não existe aprovada: ela é identificada pelo posto e pelos diálogos, sem reutilizar a aparência de outro NPC. O pátio usa kit aprovado existente e está funcional, mas ainda é uma primeira montagem visual, sem uma nova coleção de assets exclusivos. O alívio e as defesas são uma simulação isolada de avaliação, não uma batalha. Capacidade futura do Varal/remonta e categorias seguintes não foram implementadas nesta entrega.
