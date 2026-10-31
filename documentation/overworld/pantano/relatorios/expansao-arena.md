# Pântano — percurso próprio e arena submersa, 30/10/2026

## 1. Arquivos
Gerador `tools/mapa-studio/desenhar-pantano.mjs`, plantas/compilados A/B/C e índice de prévia; testes Node e Godot de água. Construtores `swamp_structures.gd`, `forest_structures.gd`, `kronasta_forest.gd`; shaders de chão e água. Kit com árvore ressecada nova, fonte/prompt/alpha preservados. A mantém planta anterior e perde árvores na água. B/C provisórias foram substituídas por plantas próprias, preservando IDs; não há duplicatas D/E. Brief em `art/overworld/briefs/pantano.md`.

## 2. Conferência automática
```
kronasta-pantano-a: SEM ERRO · 0 erros · 0 avisos
Platô40.8% · 3 itens (1 escondido) · 16 células de rampa · 0 inalcançáveis · 0 degraus soltos
kronasta-pantano-b: SEM ERRO · 0 erros · 0 avisos
Platô40.6% · 3 itens (1 escondido) · 16 células de rampa · 0 inalcançáveis · 0 degraus soltos
kronasta-pantano-c: SEM ERRO · 0 erros · 0 avisos
Platô49.2% · 3 itens (1 escondido) · 8 células de rampa · 0 inalcançáveis · 0 degraus soltos
```
B desloca ponte para u34 e conduz o jogador pela margem direita antes de voltar ao eixo de saída. C tem um lago circular de raio8,5 em(24,18), água−24px, anel seco e dois acessos aos terraços. A água não é atravessável e não há ponte sobre o boss. O mesmo contorno64 segmentos gera recorte do piso, margem e água. A circularidade foi solicitada explicitamente pelo dono; não representa um reservatório artificial ou templo. Nenhuma árvore decorativa é consumida dentro de água; teste confere que todas as pegadas de árvores ficam em material seco. Ligações A↔B↔C continuam por terra0; C→A é atalho independente.

## 3. Capturas
A51/B52/C47 vistas por versão; geométrica, arte e arte-terreno,1280×720:450PNG em `../captures/`. A/B mostram cabeceiras, margens e todas as rampas/cantos. C mostra16 setores ampliados do lago circular, todas as rampas/cantos, aproximação, duas voltas, arena e implantação ampliada de cada árvore ressecada. Sem atores nas juntas. Comparações antes/depois em `../captures/{a,b,c}/comparacao-expansao.png`. Manifesto/hashes: `capturas.json`.

Revisão por pranchas das novas plantas B/C e arte, mais inspeção nativa da arena, margens próxima/distante, árvore seca, rampas e ponte. Capturas geométricas feitas antes da arte; volumes simples mostram as novas pegadas de árvores secas. Correções não usam vegetação para ocultar juntas. A não recebeu alteração de relevo; água ficou livre das árvores apontadas pelo dono.

## 4. Percurso e testes
B:38 destinos/76 viagens/25.020 quadros/zero falhas. C:22 destinos/44 viagens/12.100 quadros/zero falhas, incluindo as novas pegadas2×2. Física da prévia em modo geométrico, com pés, seguidor, obstáculos, itens, rampas, saída e chegada; sem teleporte para destinos internos.120 viagens novas nas plantas B/C. A conserva a geometria já percorrida; não foi repetida a bateria completa de A nesta remoção de decoração.

Node17 testes passaram. Godot geral146.129 checagens/zero falhas; Morro9.386/zero; regressão Bosque79 pontos de margem protegidos/108 pontos transitáveis da ponte/zero falhas. Água do pântano:142 amostras de ponte em A,137 em B, nenhuma ponte em C, centro do lago bloqueado e aproximação seca transitável; zero falhas. Nenhuma amostra aquática dentro de célula caminhável fora de ponte nesta planta conservadora. Todas as arestas do grafo foram conferidas contra o contorno da água.

Asserções e saídas0; logs próprios em `testes/arena-*`. Persistem diagnósticos legados de shader e recursos na saída dos testes gerais. Capturas finais sem SCRIPT ERROR/SHADER ERROR, embora o sandbox possa impedir criação de cache/log de usuário. Relatório global gerado pelos testes foi revertido; kits alheios preservados.

## 5. Itens e história
Três materiais por parte, um escondido, todos alcançáveis. C move itens para terraços laterais; nada é coletável dentro do lago. Sem item canônico novo, NPC, recompensa ou revelação. O dono aprovou arena com presença sugerida por sombra e ondulações, deixando espécie/nome/combate para depois. A massa submersa não tem silhueta de criatura definida, rosto ou ataque. Paleta mais fria, centro escuro e ondulações concêntricas dão a atmosfera da arena. Duas árvores ressecadas ficam em terra firme.

## 6. Pedidos ao integrador
Definir o boss, sua arte, gatilho de encontro, combate, derrota/vitória e persistência em tarefa própria. Esta prévia não concede nada e não bloqueia saídas por combate fictício. Ao integrar à campanha, definir também o retorno e a posição de reaparecimento. Validar importação/inclusão dos PNGs no export, conforme limitação anterior do carregador de imagens de prévia.

## 7. Dúvidas para o dono
Sem bloqueio para a entrega do cenário. Espécie/nome/combate do boss intencionalmente em aberto, conforme resposta explícita. Aprovação artística ainda pendente. Recomendação: avaliar a leitura da aproximação e o tamanho do lago na câmera antes de desenhar o boss.

## 8. Não verificado
Boss real, combate, conta, recompensas, saves, campanha, áudio, controle físico, hardware Steam Deck e export empacotado. Não medir desempenho por esta captura. Animação de sombra/ondulações usa fase discreta do shader; foi inspecionada em capturas, sem sessão longa gravada. Nem todas as450 imagens foram abertas individualmente em tamanho nativo; pranchas complementam os detalhes críticos. Alpha da árvore seca foi amostrado e depende do recorte do consumidor para remover a névoa externa fraca. Não afirmar aprovação do dono, publicação ou novo capítulo canônico. Sem merge/push automático.
