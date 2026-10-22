# Skills de desenvolvimento incorporadas

Instaladas em 21/10/2026, com escopo local ao PipaKlub:

- `create-game-assets`: produção consistente, manifestos e auxiliares de imagens.
- `game-ui-ux`: layout, navegação e organização de telas.
- `performance-optimization`: diagnóstico orientado por medições.
- `pipaklub-production`: adaptação local, com referências específicas para a engine JavaScript/Canvas, o kit ilustrado e os testes existentes.

A descoberta usa `.agents/skills/` e o encaminhamento em `AGENTS.md`. As novas skills estarão disponíveis para descoberta automática no próximo turno; os arquivos já podem ser lidos diretamente. Não foi instalado o roteador externo ou o restante das 74 skills. Não há dependência nova no jogo nem mudança de engine, combate, banco ou produção.

## Origem e atualização

Fonte: [gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills), revisão `0a70cfc64672d512c5b5b6006b5dcb5cf90dbdbd`. Os três diretórios importados foram preservados, incluindo suas referências e ferramentas. A adaptação fica separada para permitir atualização revisável.

Licença Apache-2.0 e avisos originais em `.agents/vendor/awesome-gamedev-agent-skills/`. `source-lock.json` registra caminhos e SHA-256 dos arquivos externos e da licença. Esses termos cobrem as skills importadas; não concedem direitos sobre personagens, imagens ou engines citadas.

Para atualizar: inspecione a revisão nova, compare somente as três famílias instaladas, preserve LICENSE/NOTICE, revise os exemplos contra a engine vigente e regenere o registro de origem depois de conferir o diff. Não execute instaladores ou scripts novos sem lê-los. O registro identifica a versão instalada; não realiza downloads nem atualizações automáticas.

## Verificação desta instalação

As quatro skills foram verificadas com o validador de frontmatter. Os dois auxiliares de imagem foram lidos e exercitados em assets existentes, produzindo relatório de dimensões/alpha e prancha de prévia em `tmp/gamedev-skills-validation/`. Também foi exercitada a rejeição de dimensões incorretas. Isso verifica a instalação e ferramentas, não constitui nova aprovação artística dos assets nem teste de desempenho do jogo.

Próxima aplicação sugerida: usar a referência de interface na próxima correção de HUD e a de assets nas próximas famílias de sprites/tiles. Otimizações devem começar com uma cena medida, sem pressupor que a instalação tornou o jogo mais rápido.
