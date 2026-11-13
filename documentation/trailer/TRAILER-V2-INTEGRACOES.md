# Integrações para a gravação pelo Claude

Base desta entrega: `claude/unificacao` em `59ab40f1`, preparada na branch
`codex/trailer-v2`. O trabalho local de animações em `codex/estudos-designs-soulmonsters`
permanece na sua worktree e não foi sobrescrito.

## Ritual de evolução

Fonte publicada: `origin/codex/soulflight-evolucao-arte`, commit
`fbcea50278a0b15e4f3f8d50903424ec25325dc2`.

O commit contém o ritual, seu cenário e alterações de integração/testes. Contém também
Soulflight experimental: o trailer não deve ligar `PIPAKLUB_SOULFLIGHT=1` por acidente.
O protótipo ainda tem pendências de controle físico, duelos em grupo e desempenho,
documentadas em `documentation/campaign/SOULFLIGHT-EXPERIMENTAL.md` nessa branch.

O relato de testes da branch inclui `evolution_checks`, `soulflight_checks` e `morro_checks`.
Isso é evidência histórica do autor, não uma execução nova nesta entrega. Depois do merge,
executar `godot --headless --path godot -s tests/evolution_checks.gd`, conferir o ritual no
renderer e confirmar os três ramos que serão mostrados no roteiro.

## Kits de terreno

Fonte publicada: `origin/codex/kits-tiles-v1`, ponta
`98ac9b6f959169f80b6fe6885469e7f8013f882c`, precedida por `8d3a17a0`.

Há kits de Morro, Cavernas de Cristal e Planícies, com fontes, pranchas e relatório em
`documentation/qa/kits-tiles-v1/RELATORIO.md`. O relatório registra 23 texturas e 17 peças
verificadas. Os commits são de assets: não prometem aplicar materiais aos mapas, nem
validar navegação/colisão no Godot. A montagem dos materiais nos planos da gravação precisa
ser conferida depois de integrar a branch.

## Responsabilidade de integração

As duas pontas continuam fora de `claude/unificacao` na data desta conferência.
Conforme o pedido original, o Claude faz os merges e resolve conflitos, principalmente
em `content.json` e nos scripts de campanha. Nenhum merge em `main` foi executado.
Os novos assets do trailer são entregues separados por item para permitir revisão.

## Decisão de revelação

Confirmada pelo dono em 13/11/2026: **somente silhueta e rugido, sem nome nem aparência**.
A animação normal é fonte de produção; usar a variante de silhueta no plano final.
Rato continua em silhueta conforme o roteiro. Não inventar falas: usar texto efetivo do jogo.
