# R42/R47 — feedback de recuperação e erro na interface

05/11/2026. Base `2a0c10a4` mais este refinamento.

## Problemas observados

- Os cards apresentavam uma descrição genérica para corrupção, formato incompatível, versão futura e erro de acesso. O jogador não tinha orientação específica na própria lista.
- Backup válido não se distinguia claramente de uma continuação normal.
- O teste funcional encontrava o diálogo de recuperação, mas a captura gráfica revelou que o filme da abertura (z=100) cobria o aviso (z=80). A mesma falha escondia erro de gravação nesse contexto.
- O rótulo “Tentar novamente” ficava truncado na largura padrão do botão.

## Correções

- Mensagens compartilhadas entre frontend e card em `save_messages.gd`, sem mudar o formato de save.
- Card com backup identifica o ponto anterior e oferece **Recuperar**. Após carregar, o aviso informa que o progresso retomado pode ser anterior.
- Corrupção, versão futura e formato incompatível têm motivos distintos e não habilitam retomada/exclusão automática.
- Erro de acesso oferece **Tentar novamente**. A ação reconsulta o armazenamento, continua segura se o erro persistir e funciona quando o acesso é restaurado.
- Avisos sistêmicos ficam acima do filme, pausam o estado narrativo/vídeo e restauram o estado anterior ao fechar. Referências fracas evitam restaurar uma sala diferente durante troca de tela.
- Contagem de avisos mantém o fundo pausado enquanto houver outro modal. Fechar um diálogo inferior não rouba o foco do superior. Ao desmontar a sala, não se tenta focar controles fora da árvore.
- O botão de retry tem largura suficiente para o texto inteiro, mantendo o kit existente.

## Evidências e testes

| Prova | Resultado |
| --- | --- |
| Frontend, headless | **35 checks, zero falhas**: motivos dos cards, backup/estado anterior, teclado, gamepad, falha de gravação, pausas, modais sobrepostos, retry e formato incompatível. |
| Renderizador real | **33 checks, zero falhas** no momento das quatro capturas a 1280×720, OpenGL Compatibility/GTX 1650. Dois checks de formato incompatível foram acrescentados depois sem alterar o layout capturado. |
| Diálogos | 629 checks, zero falhas. |
| Menu do título | 350 checks, zero falhas. |
| Resiliência de save | 152 checks, zero falhas. |

Os eventos de teclado/gamepad são injetados na viewport real, não comprovam periférico físico. As fixtures usam pastas únicas no perfil de teste; nenhum save do jogador é alterado. Os erros de acesso/gravação são injetados pelo teste; corrupção e versões inválidas são arquivos reais de fixture.

Capturas revisadas:

- `slots.png`: recuperação, versão futura e corrupção na lista.
- `recovered.png`: aviso acima da abertura pausada (pode ainda estar no primeiro frame preto do vídeo).
- `write-error.png`: mensagem de falha sobre o filme pausado, sem avanço do estado.
- `read-error.png`: retry completo e foco com glifos de controle.

Logs e resumo numérico acompanham o diretório. A suíte está no runner/CI e rejeita os diagnósticos de recursos vivos ao encerrar.

## Limites

**Concluído localmente este recorte de feedback R42/R47.** Não equivale a revisão de todas as mensagens do jogo, tela em todos os formatos, hardware de controle real ou falha física do disco. A pausa modal recebeu regressão de diálogo/menu; sua apresentação em todos os chefes/cuts ainda pertence ao playtest transversal. A candidata Windows precisa ser exportada novamente com estas mudanças antes de repetir o teste comercial. Não houve merge nem publicação Steam.
