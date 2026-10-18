# Primeira jornada — implementação da base visual

18/10/2026. Ambiente local, branch feature/ui-kit-consistente. Sem deploy e sem mudança de regras econômicas.

## Implementado

- Quintal com arte em proporção preservada preenchendo a tela, sem faixas ou duplicação desfocada. Pontos de interação limitados à área visível.
- Destinos mostram nomes ao passar o mouse ou receber foco; deixam de competir permanentemente com cenário e criaturas. Nomes acessíveis continuam presentes.
- Informações passivas sem molduras de ação; sombreado discreto no cenário protege a leitura do HUD.
- Diálogos com hierarquia de narrador, título, fala e ação. Cabeçalho e rodapé deixam de competir com conversa e escolha inicial.
- Parceiros com seleção forte, demais opções discretas e uma descrição contextual. Repetição deixa explícito que não muda coleção ou equipamento.
- Primeira escolha confirmada pelo servidor apresenta acolhimento do parceiro antes de entrar no voo. Não antecipa concessão de propriedade.
- Instruções do primeiro voo seguem mouse/teclado, toque ou controle Xbox/PlayStation. Troca de dispositivo atualiza a instrução sem reiniciar a lição.
- Orientação na batalha compactada para liberar o centro de ação; sucesso da lição recebe destaque. Área reservada à barra de comandos quando controle ativo.
- Atlas mantém a composição única de papel e bambu já revisada.
- Auditoria isolada ampliada com mapa e primeiro voo: 17 telas × 7 tamanhos.

## Evidências

167 testes aprovados. Build do servidor e estático concluídos; artefato validado. Matriz de 119 casos com zero erros de geometria detectados. As verificações de geometria não certificam legibilidade artística nem uma sessão completa com controle físico.

Revisão manual no navegador: quintal, conversa e repetição do professor, mudança entre parceiros, descrição contextual, entrada no treino e retorno. A conta usada é local; não houve alteração de dados de produção. A confirmação inicial persistente tem teste de integração com resposta simulada do servidor; a revisão manual usou repetição segura em conta já existente.

## Continuidade do roadmap

Este fechamento implementa a base de apresentação e ajustes da primeira jornada; não encerra o mapa de maturidade inteiro. Continuam pendentes: sessão externa de observação, validação de TV/controle físico, encenação adicional dos personagens, auditoria de áudio, adaptação integral do ritual ao controle e revisão de todos os estados econômicos e de rede. Não há declaração de prontidão para console.

Arquivos de evidência da conversa: primeira-jornada-quintal.png, primeira-jornada-dialogo.png, primeira-jornada-parceiro.png, primeira-jornada-treino.png e primeira-jornada-matriz.json.
