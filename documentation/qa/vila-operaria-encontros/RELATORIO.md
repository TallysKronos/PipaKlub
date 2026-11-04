# Vila Operária — encontros nas partes A/B/C

## 1. Arquivos

Gerador `tools/mapa-studio/desenhar-industrial.mjs`, Tiled/compilados das três partes, planos de captura e brief `art/overworld/briefs/vila-operaria-encontros.md`. Catálogo de campeonato, validação de encounter em state, adapter de NPC e objetivos atualizados. Ferramenta `godot/tools/vila_operaria_encounter_capture.gd` e testes de definição/campanha.

Somente cinco eventos NPC e câmeras foram adicionados. Comparação executada com HEAD: cells, zonas, cliffs, posição de spawn, pegadas, bloqueios e propriedades de peças inalterados nas três áreas. A recompilação normalizou nomes acentuados que estavam corrompidos nos compilados anteriores. Índice reordenado incidentalmente foi restaurado; nenhum kit.json alterado.

## 2. Automático

Gerador por parte:

```
A: SEM ERRO · 0 erros · 0 avisos · platô50.8% · 3 itens/1 escondido · 14 células de rampa · 0 inalcançáveis · 0 degraus soltos
B: SEM ERRO · 0 erros · 0 avisos · platô50.8% · 3 itens/1 escondido · 14 células de rampa · 0 inalcançáveis · 0 degraus soltos
C: SEM ERRO · 0 erros · 0 avisos · platô51.7% · 3 itens/1 escondido · 14 células de rampa · 0 inalcançáveis · 0 degraus soltos
```

Primeira tentativa de Teyra no topo da rampa foi reprovada; movido para42,25. Bruno colocado em29,13, longe do acesso central. Testes finais: Node industrial/model8 testes0 falhas; Godot definição62/0; campanha industrial60/0; distritos452/0; Cais139/0; Morro9386/0; overworld464486/0. Overworld headless emitiu aviso/erro de compilação de sampler em shader de piso preexistente, mas terminou com código0 e zero falhas; capturas nativas finais não emitiram esse erro.

## 3. Capturas

`arte/` e `geometria/`:16 capturas1280×720 por modo, total32. Cada modo contém gerais A/B/C, entradas e enquadramento de jogo+detalhe dos cinco NPCs. Revisadas diretamente as cinco posições de encontro com arte, detalhe de Bruno e amostras geométricas Rivka/Teyra/Bruno. Não declarar inspeção individual completa das32 imagens. As capturas não são nova certificação de todas as juntas do terreno; geometria não mudou. Ferramenta executada no renderer nativo OpenGL Godot4.7.2.

## 4. Percurso

`industrial_map_checks.gd` executou o controlador real por106 alvos,212 viagens de ida/volta,56840 passos: NPCs, itens, saídas, rampas e chegadas, zero falhas. Teste verifica movimento/apoio, não caminhada manual com joystick nem avaliação de câmera em movimento. Campanha60 checks valida iniciar por proximidade, rejeitar posição remota, suspensão/retomada, fuga/derrota, vitória e recibo único. Resultado de batalha é imposto pelo fixture, não prova balanceamento.

## 5. Itens e história

Vasken/Rivka A; Odrik/Teyra B; Bruno C. Materiais e três itens por parte preservados, sem novas revelações. Quatro duelos agora authored e quinto também definido, porém Bruno exige `pipaDragaoDesatadaVencida`. Apenas fixture de teste concede esse flag; código de produção ainda não o concede.

Roster temporário usa parceiros básicos existentes; não canoniza parceiros dos personagens. Níveis21/22/22/23/24. Recompensas provisórias28/30/32/34/36 moedas e260/280/300/320/340 XP base, processadas pelo serviço existente (primeira vitória dobra moedas; recibo impede duplicação). Ajustes de balanceamento aguardam combate real. Defesa/reconquista reaproveita sistema existente e sprite do desafiante substitui campeão pelo nome.

## 6. Próxima integração

Construir galpão D e acesso B↔D; integrar Gollia/Carretel Negro, derrota roteirizada de Retalho, intervenção de Tyler e duelo da Pipa-Dragão desatada. Depois habilitar região, pré-requisitos globais e progresso de história. `playable=false` e marca de prévia permanecem, para não publicar bairro sem clímax. Os encontros atuais são para QA após vitória no Cais.

## 7. Decisões

Nenhum nome ou nova revelação precisou de pergunta: elenco aprovado e bíblia usados. Manter IDs existentes e planta. Skill limita etapa de mapa; código de campanha adjacente foi implementado no escopo geral autorizado da continuação, sem exigir aprovação extra por essa separação de responsabilidades.

## 8. Não verificado

GalpãoD/boss ainda não implementados. Não houve playthrough manual, teste de equilíbrio, sprites animados, todos os ângulos, exportSteam ou fluxo desde prólogo. Acesso público permanece fechado. Relatórios versionados gerados pelos testes foram restaurados. Nenhum merge, push ou deploy.
