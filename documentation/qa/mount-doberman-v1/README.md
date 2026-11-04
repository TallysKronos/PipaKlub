# Doberman C — integração estática

01/11/2026. Assets criados com image_gen a partir da C refinada e da referência autoral de Kael. Runtime: duas folhas RGBA de 1536×1024, com oito vistas estáticas cada. A transparência foi verificada no arquivo e nas capturas. Os recortes reais e encaixes ficam no manifesto, não são inferidos pela posição do conteúdo a cada frame.

O rig mantém a montaria e o cavaleiro separados com um Marker2D de assento por direção. Na vista frontal, o cavaleiro fica atrás da criatura; nas demais, a camada do cavaleiro aparece à frente. A primeira folha apresentou rabiolas cruzando recortes: foi gerada uma correção de layout e os recortes inferiores norte/nordeste foram limitados para excluir fragmentos vizinhos. Não se declara que a ferramenta gerou uma grade de produção perfeita.

Conferência visual: `directional-fit.png` (oito encaixes ampliados), `street.png`, `trail.png` e `morro.png`, capturas nativas a 1280×720. O resultado é uma base estática para animação, não uma montaria final. A perspectiva gerada ainda é mais lateral que o ideal em certas vistas; refinar contato das pernas/camadas próximas ao produzir o ciclo no ComfyUI. O desenho do Kael montado é novo, não substitui as folhas a pé.

## Verificações executadas

- `mount_checks.gd`: 588 verificações, zero falhas no runtime nativo e no PCK. Três áreas, montar/desmontar, tecla B, pausa, oito direções, parentesco do socket, velocidade, escada, sustentação e câmera. Inclui 480 passos simulados de deslocamento montado e corrida.
- `companion_sprint_checks.gd`: 2.864 verificações, zero falhas.
- `lobby_checks.gd`: 66 verificações, zero falhas.
- `campaign_checks.gd`: 206 verificações, zero falhas.
- `care_city_checks.gd`: seis verificações nativas, zero falhas.
- Verificador de referências de cena: 6.896 arquivos, zero erros, quatro avisos preexistentes (três imports órfãos de provas e um caminho ilustrado legado).

Um ensaio headless de cuidados não percorreu a transição visual e foi repetido no runtime nativo; o headless não é evidência válida dessa animação.

Saves de teste isolados. Montaria temporária, sem desbloqueio, nome canônico, item ou recompensa inventados. Sem push.

Projeto e próximo contrato de animação: [arquitetura de montarias](../../overworld/montarias/ARQUITETURA.md).
