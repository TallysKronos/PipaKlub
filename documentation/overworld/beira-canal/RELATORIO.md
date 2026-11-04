# Beira-Canal v1 — mapas e campanha

## 1. Arquivos

Planta de intenção: `art/overworld/briefs/kronasta-beira-canal.md`. Gerador determinístico: `tools/mapa-studio/desenhar-kronasta-beira-canal.mjs`. Três fontes Tiled e três JSON compilados `kronasta-beira-canal-a/b/c`, registrados no índice. Terreno, casas, bancos e água reaproveitam os kits existentes; bombas e bobinas têm montagem nativa em `canal_structures.gd` e manifesto `kits/beira-canal-v1/kit.json`.

Elenco em `godot/assets/npc-ds/beira-canal-v1`; fontes, referências e limites em `art/characters/beira-canal-v1/README.md`. Integração nos adaptadores de distritos, atlas, objetivos, saves, encontros e Planar. `canal_gate.gd` controla Grampo, comporta e descanso. Não altera servidor, conta online ou banco de dados.

## 2. Conferência automática

```text
kronasta-beira-canal-a
CONFERÊNCIA ZERO QUEBRA: SEM ERRO · 0 erros · 0 avisos
Platô 72.3% · 3 itens (1 escondidos) · 12 células de rampa · 0 inalcançáveis · 0 degraus soltos
kronasta-beira-canal-b
CONFERÊNCIA ZERO QUEBRA: SEM ERRO · 0 erros · 0 avisos
Platô 72.3% · 4 itens (1 escondidos) · 18 células de rampa · 0 inalcançáveis · 0 degraus soltos
kronasta-beira-canal-c
CONFERÊNCIA ZERO QUEBRA: SEM ERRO · 0 erros · 0 avisos
Platô 82.3% · 3 itens (1 escondidos) · 28 células de rampa · 0 inalcançáveis · 0 degraus soltos
```

O gerador verifica rampas para a câmera, pés/chegadas, degraus soltos, bolsas isoladas, corredores obrigatórios de duas células, árvores soltas, muretas sobre acessos, itens, mato contornável e continuidade entre partes. Nenhuma junta é escondida para corrigir geometria. A navegação encontrou um caso não percebido pela planta: a fronteira exata de uma abertura retangular de água bloqueava uma cabeceira. Em canais alinhados à grade, a célula de apoio agora decide a fronteira; células de água continuam bloqueadas. Mapas de margem curva preservam a checagem pelo contorno.

Saídas de testes:

```text
BEIRA CANAL: 80 checks, 0 failures
BEIRA CANAL FLOW: 60 checks, 0 failures
BEIRA CANAL NAVIGATION: 2702 checks, 0 failures
NINA GLIDE: 32 checks, 0 failures
BAMBUZAL CAMPAIGN: 143 checks, 0 failures
BAMBUZAL FLOW: 38 checks, 0 failures
CAMPAIGN CHECKS: 207 checks, 0 failures
CAMPAIGN VIEW CHECKS: 25 checks, 0 failures
NINA ORDER: 19 checks, 0 failures
GREEN EXAM: 19 checks, 0 failures
OVERWORLD 372298 checks; 0 failures
Morro maps/views: 9386 checks, 0 failures
Mapa Studio: 6 testes aprovados
```

O HUD foi corrigido antes desta região: 652 verificações headless, quatro resoluções (1280×720, 1280×800, 1920×1080 e 2560×1080), mais 163 verificações nativas em 1280×720. O carregamento já não espera um sinal de render ausente no modo headless; o teste suspende o atualizador de objetivos ao usar texto sintético. Objetivos longos e legendas dos atalhos ganharam espaço.

## 3. Capturas

`documentation/overworld/beira-canal/planos/` enumera 43 enquadramentos de A, 60 de B e 80 de C. As duas versões estão em `captures/<a|b|c>/<geometria|arte>/`: **366 imagens 1280×720**, com vista geral, entrada, centro, platôs, saídas, pés/chegadas de escadas, cantos, pontas/encontros de guarda-corpo e cabeceiras/margens. Detalhes em zoom 2,3, sem personagens nas juntas. Não há cachoeira ou poço natural nesta região; o canal construído é retangular e rebaixado 12 px, usando um contorno único para recorte e faces.

Os manifestos foram revistos em pranchas pareadas entre geometria e arte; escada alta de B, escada e guarda-corpo de C, e cabeceira de A também foram abertos em tamanho nativo. Não se afirma que cada arquivo foi reaberto individualmente em tamanho nativo. As pranchas temporárias ficam fora do repositório; os PNGs originais ficam versionados.

`documentation/qa/beira-canal-v1/` mostra o fluxo real: chegada, miolo, arena, combate de Kleie, recompensa, Grampo no controle, duelo contra Platyx e Planar no desvio. A água do bairro recebe tom estagnado antes da comporta e volta à cor clara após a abertura, ao retornar à área.

## 4. Percurso

O controlador real e o seguidor andaram de cada entrada a todos os eventos e células de rampa/escada, ida e volta. O teste nativo percorre as ligações A↔B↔C, conversa e confirma pelos diálogos, abre combates, salva resultados, retorna às Veredas, enfrenta Grampo, destranca a comporta e volta a Kleie. Também atravessa o desvio de Planar na parte B. O caminho pela ponte normal permanece disponível.

Vitórias/derrotas são preparadas pelo teste para exercitar retomada e liquidação; não é prova de dificuldade ou de que alguém venceu jogando normalmente. Derrota e fuga contra Grampo não avançam; a vitória é permanente, sem ressuscitar Lacertubo ou repetir sua rabiola. O serviço de descanso verifica alcance, saúde, preço (12 moedas) e falha de gravação sem cobrança. Os testes verificam terceiro emblema, repetição sem pagamento duplicado e perda de título com requalificação.

## 5. Conteúdo e continuidade

A: Vaeli (12) e Noxen (12). B: Soryn (13), Eriska (14), descanso, controle do problema hidráulico e material no desvio de Planar. C: Kleie (15), duas escadas, guarda-corpo e atalho de retorno após a vitória. Os nomes foram criados com a autorização do dono, evitando nomes comuns/repetidos.

Quatro vitórias → controle nas Veredas → Grampo/Platyx (14) → comporta → Kleie. O empréstimo de Nina continua temporário, sem criar Carcará no banco. Os selvagens de desenvolvimento são Lacertubos jovens (12–14), usando arte e rabiola já existentes; sapo-cano e Platyx selvagem ainda não foram integrados.

Conflito registrado: a bíblia coloca Lacertubo junto da porta depois de Beira-Canal, mas a campanha já exige vencê-lo para devolver a rabiola de Nina. Preservou-se essa vitória e usa-se a volta às Veredas para Grampo/comporta; o guardião não reaparece. A porta das Ruínas continua fechada, reservada ao arco do apito. Ganhar Kleie registra Feira do Largo como próximo bairro; seu mapa ainda não abre, pois não está construído.

## 6. Integração

Campanha, objetivos, validação dos novos checkpoints e combate suspenso foram integrados. Saves anteriores sem os novos campos continuam válidos; as flags novas são aditivas e os recibos impedem repetição de operações. O título histórico e o emblema permanecem após perder a posse atual. Tudo é local: a validação estrutural não certifica recompensas numa economia online.

## 7. Pendências de direção

Aprovação artística definitiva de Vaeli, Noxen, Soryn, Eriska e das propostas de Grampo/Platyx; ajustes de ritmo e dificuldade após uma partida manual. Recomenda-se revisar o elenco e a duração das três partes antes de abrir o bairro seguinte.

## 8. Limites reais da revisão

Sem controle físico, Steam Deck, exportação de distribuição, conta online, teste de rede ou medição em outro hardware. A revisão visual foi em desktop 1280×720. Não há interiores para as casas. Poses dos moradores são estáticas; Platyx tem quatro quadros de repouso reaproveitados nas outras ações, sem rig ou animações específicas de ataque/dano. A ampliação individual de todas as 366 capturas não foi feita; todas foram vistas em pranchas, com detalhes representativos em tamanho nativo.

O editor emitiu aviso de safe-save da configuração; as proteções não foram desativadas. As suítes gerais ainda emitem diagnóstico de shader legado e recursos em uso no encerramento, embora terminem com código 0. Esses avisos não são apresentados como corrigidos. Artefatos de teste gerais e metadados alheios foram restaurados/removidos antes dos commits. Sem merge, push ou deploy.
