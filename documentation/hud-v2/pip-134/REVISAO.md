# PIP-134 — Conversas no Mural

A fala usa papel claro com cantos reforçados; o nome fica numa tarja de tinta escura. O amarelo identifica a resposta com foco. A conversa mantém menos ruído que a batalha: não reutiliza warning de boss nem faixa de enroscada. Retratos, textos, emoções, opções e ações continuam vindo dos consumidores existentes.

## Implementação

- `hud_dialogue.gd`: caixa compartilhada com fontes nativas, retratos, falas paginadas em até três linhas e até quatro respostas. Texto 100/150%, movimento reduzido, retorno do foco anterior e restauração da HUD de exploração.
- Conteúdo do papel a 35 px das bordas; nome e respostas usam margem vertical de 29 px e horizontal de 32 px. Esses valores excluem os cantos de arte reduzidos e acrescentam os 8 px da área segura. A tarja se reposiciona quando seu tamanho mínimo muda.
- Respostas longas têm rolagem por foco; o botão focado inteiro entra na área visível. Parte de uma resposta adjacente pode aparecer cortada no limite da lista: ela permanece acessível por setas, controle ou rolagem. Não se reduz a fonte para caber.
- Confirmação emite uma vez. Escape em aviso com várias páginas avança a leitura antes de confirmar; opções explícitas não são escolhidas por Escape. Botões de cancelar continuam cancelando. Não há atraso de digitação obrigatório.
- Abertura: papel, nome, fala, campo de nome do parceiro e botão usam a direção Mural. Encenação, câmera, vídeo, escadas e progressão não foram reescritos. Balões ambientais e o coach compacto da aula conservam sua superfície existente nesta etapa.

## Conferência

| Prova | Resultado |
| --- | --- |
| `mural_dialogue_checks.gd` | 292 verificações, zero falhas |
| `dialogue_hud_checks.gd -- --quick` | 92 verificações, zero falhas |
| Matriz de diálogo | 1280×720, 1920×1080, 1024×768 e 1280×800; texto 100/150% |
| Interação nova | Eventos nativos injetados de teclado, mouse e controle; confirmar, cancelar, foco seguro, rolagem e restauração de foco |
| Capturas | Renderer OpenGL nativo; galeria em index.html; dimensões e hashes em integridade.json |

As imagens de fala/escolhas/dupla são fixtures com o fundo ilustrado já existente, sem representar uma sessão de exploração. As imagens de abertura usam a cena real com estado isolado de teste: chegada da mãe e nomeação do parceiro. Não usam saves do jogador. Nenhuma arte nova foi gerada; papel, retratos e fundo reaproveitam os assets do projeto. Textos e prompts não estão gravados em raster.

A conferência inicial detectou e corrigiu a expansão da tarja sobre a fala, a distância excessiva do botão de resposta e a fonte divergente na abertura ampliada. Inspeção visual complementa os testes de retângulos e linhas. O nome longo da tarja pode ter reticências e conserva o texto completo no tooltip.

Não houve controle físico, certificação de acessibilidade ou playtest integral da campanha. A execução legada ainda registra avisos de carregamento direto de imagens da casa/professor e recursos retidos ao encerrar; os testes desta tarefa passam, mas isso não certifica exportação. O ambiente também impede a escrita do log user://. A captura de abertura deve ser executada por resolução em processos separados para limitar a memória das cenas carregadas.

Sem mudança de balanceamento, recompensas ou formato de save. Sem push, merge ou atualização de ticket no Linear. Próxima etapa: PIP-135, menus.
