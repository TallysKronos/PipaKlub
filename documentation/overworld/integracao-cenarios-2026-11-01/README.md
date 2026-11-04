# Integração dos interiores com a versão atual do jogo

Base local: `6a8faaa7` (`codex/loja-tcg-moderna`), incluindo casa, ateliê, loja e correção dos corredores. Atualizações recebidas de `origin/claude/unificacao` em `1d70c8ea`. Essa branch também contém a versão atual de `codex/pip84-bairro`. As branches dos cenários foram enviadas antes de iniciar a integração; nenhum commit local foi descartado.

Branch de entrega: `codex/integracao-cenarios-atualizados`. Sem merge em main ou deploy.

## Resoluções

- `room_view.gd`: mantém os três renderizadores de interiores e a recuperação de posição da loja; incorpora o Kael direcional novo, locomoção, acompanhamento do parceiro, marcador de interação e NPCs recebidos.
- `front_end.gd`: combina a loja e a prévia do professor com nomes/fluxos atuais do Bosque e as melhorias de HUD/campanha recebidas.
- `journey.gd` e `state.gd`: preservam o checkpoint/validação da loja e incorporam os novos espaços de coordenadas e partes do Bosque.
- `export_presets.cfg`: união dos filtros das duas versões e inclusão dos JSONs de ações do Kael novo. Exportação de executável não foi feita.

O editor importou os recursos recebidos para reconstruir o cache local. Metadados novos de importação e UIDs de fontes existentes acompanham a integração; cache `.godot` não é publicado. Os arquivos de importação existentes mantêm o conteúdo recebido do repositório.

## Kael confirmado

`avatar-proof.json` registra os quatro ambientes usando `kael_video_avatar.gd`. A imagem idle carregada foi comparada pixel a pixel com `assets/kael-video/kael-idle-eight.png`, com resultado verdadeiro em todos. As capturas `*-kael-atualizado.png` mostram quarto, térreo, professor e loja. Não são capturas do modelo paper-doll anterior. O dono recém-criado da loja conserva seu asset próprio; não foi redesenhado nesta sincronização.

## Verificações

```text
CASA MODERNA 79 checks; 0 failures
PROFESSOR MODERNO 37 checks; 0 failures
SHOP MODERNO 47 checks; 6696 reachable samples; 0 isolated walkable samples; 0 failures
SHOP FLOW 18 checks; doorway, movement, owner dialogue, save/resume, return
CAMPAIGN CHECKS 206 checks; 0 failures
CAMPAIGN VIEW CHECKS 25 checks; 0 failures
KAEL LOCOMOTION 222 checks; 0 failures
KAEL CITY/ROOM 11 checks; 0 failures
VEREDAS 72 targets; 144 trips; 36900 frames; 0 failures
PARTNER CARE 25 checks; 0 failures
Godot editor import: exit 0
```

Os testes de cidade/NPC foram repetidos após a importação: os erros iniciais de `.ctex` ausente desapareceram. Há avisos de leitura de PNG bruto nos construtores existentes e de recursos ao encerrar alguns testes; não representam uma exportação validada. As capturas finais e o fluxo da loja não emitiram erros de script/shader. Testes usam diretórios isolados dos saves reais.

Não foi testada uma campanha inteira manualmente, controle físico, exportação Windows/Steam ou operação online. Os testes de percurso não comprovam aprovação artística de todas as áreas recebidas. A sincronização preserva as novas versões recebidas, sem reauditar cada um dos milhares de arquivos importados.
