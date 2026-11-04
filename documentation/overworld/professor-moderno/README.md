# Reforma do ateliê do Sr. Assis

## 1. Arquivos criados e alterados

Branch `codex/atelie-professor-moderno`, derivada da reforma da casa. Brief, fontes, prompts e QA em `art/professor-moderno-v1/`; kit em `godot/assets/campaign/professor-moderno-v1/`; renderer `professor_modern.gd`. RoomView seleciona o renderer pelo ID da sala; frontend usa a nova prévia no cartão de save. Preset Windows inclui os arquivos brutos do kit. Ferramenta `professor_modern_capture.gd` e teste `professor_modern_checks.gd`.

Conservados integralmente os dados de `content.rooms.professor`: planta de 14×11, câmera, cinco bloqueios, cinco hotspots e posições da encenação. O quarto e a casa continuam com seu renderer próprio. O exterior do ateliê, o NPC e as regras de jogo não foram redesenhados. Regras de regiões A/B/C e platôs naturais não se aplicam à reforma deste interior existente.

## 2. Resultado automático

```text
PROFESSOR MODERNO 37 checks; 4510 reachable samples; 0 unreachable walkable samples; 0 failures; no save access
CASA MODERNA 79 checks; bedroom 1807, home 4680 reachable samples; 0 failures; no save access
CAMPAIGN CHECKS: 206 checks, 0 failures
CAMPAIGN VIEW CHECKS: 30 checks, 0 failures
OVERWORLD 313979 checks; 0 failures
Morro maps/views: 9386 checks, 0 failures
node --test tools/mapa-studio/model.test.mjs: 6 pass, 0 fail
```

Todos os processos terminaram com código 0. O teste geral de views informa 8 instâncias e 1 recurso em uso ao sair; o diagnóstico de recurso já foi observado antes desta reforma. O teste geral do overworld também emite a condição do compilador de shaders em `_painted_floor`, no renderer externo não alterado. O teste específico do ateliê e suas capturas nativas não emitiram erros de script/shader. O relatório geométrico compartilhado gerado pelos testes foi revertido.

## 3. Capturas

Individuais nativas em 1280×720; detalhes em zoom 2×, sem personagens encobrindo juntas.

- `antes-*`: ateliê anterior.
- `geometria-*`: piso, paredes e volumes chapados antes da arte.
- `arte-*`: vista geral, versão sem atores, biblioteca, estudo, oficina, mesa, arquivo, entrada e canto de paredes; poses atrás/à frente das mesas.
- `frontend-hud.png`: ambiente na tela real de exploração, com HUD, Assis, Kael e Rabbito, em progresso isolado.
- `antes-depois.png`, `kit-contato.png`, `detalhes-contato.png`: revisão comparativa.
- `evidence.json`: dimensões e hashes, incluindo igualdade das cinco fontes e cópias de runtime.

```powershell
godot --path godot --script res://tools/professor_modern_capture.gd -- --name=arte
# Para geometria: KAEL_ROOM_GEOMETRY=1 e --name=geometria
godot --path godot --script res://tools/professor_modern_capture.gd -- --frontend
godot --headless --path godot --script res://tests/professor_modern_checks.gd
```

## 4. Percurso

Busca no `_safe` real do personagem, com malha de 16 unidades: todos os cinco hotspots alcançáveis desde a entrada, nenhuma amostra caminhável isolada. Conferidas as colisões dos cinco móveis e a profundidade à frente/atrás das mesas em posições válidas. O frontend foi executado em estado isolado, na posição de entrada próxima à rua; não foi uma sessão manual completa com controle físico. Não foram exercitados invocação, aula ou diálogo inteiro nesta revisão visual.

## 5. Itens, pistas e revelações

Nenhum novo item ou informação de história. Preservadas biblioteca/Pipa Dex, estudo de técnicas, Oficina das Almas e o encontro com Assis. Desenhos de pipas, livros, rabiolas e iluminação de inspeção são decoração funcional. Não foram expostos Tyler, foto da expedição, DNA ou Elo.

## 6. Integração

Integrado ao consumidor Godot e ao cartão de save. Sem mudança de IDs, recompensas, checkpoints ou migração. Nenhum pedido adicional ao integrador.

## 7. Dúvidas para o dono

Sem bloqueios. Aguardando avaliação estética final. Recomendação: manter o contraste entre pesquisa digital e montagem artesanal, que distingue o ateliê da casa.

## 8. O que não foi verificado

Não houve exportação Windows/Steam, teste com controle físico, atualização do legado web, reforma do exterior ou sessão manual integral. O shader de recorte foi conferido nas capturas, mas não em todas as GPUs. As regras de invocação e primeiro voo foram preservadas, não revalidadas em uma partida completa. Sem push ou deploy nesta entrega.
