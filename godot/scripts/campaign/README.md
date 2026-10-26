# Campanha local — PIP-60

Serviços conectados ao menu, narrativa, oficina, exploração e encontros. Não há dependência de conta/servidor. Consulte `../../README.md` para o estado completo.

## Contratos

- `state.gd`: envelope v1 com versões de conteúdo/regras, slot, revisão, checkpoint e dados puros. Três slots fixos, abertura no passo zero, nenhum parceiro ou material concedido. Validação estrutural não é verificação de legalidade de parceiros.
- `save_store.gd`: `create_slot`, `load_slot` e `save_slot`. Novo slot não substitui arquivo existente. Saves atualizam apenas a revisão carregada; revisão obsoleta retorna `stale`. Cópia temporária é relida e comparada antes da substituição; backup anterior é preservado. Windows depende do backup durante a substituição; não há promessa de durabilidade contra queda de energia/fsync.
- `session.gd`: Node que as futuras cenas poderão manter como serviço. Devolve cópias do snapshot; só muda memória e emite `changed` após sucesso no disco. `commit_operation` grava alteração e recibo juntos. Repetir o mesmo ID retorna `already_applied`; o chamador deve conservar um ID estável para a mesma operação e jamais aplicar a recompensa fora desse snapshot. Isso evita reaplicação no estado local carregado, mas não certifica ganhos online nem impede restaurar saves antigos manualmente.

## Persistência e recuperação

`user://campaign/slot-1.json` até `slot-3.json`, separados de `veredas-prototype-v1.json` e do pátio. Arquivo principal inválido/ausente permite carregar backup válido com `recovered: true`. A carga não regrava arquivos. O próximo save mantém o backup bom e arquiva o principal danificado por hash antes da substituição. Temporários incompletos não viram progresso automaticamente.

Arquivo principal ou backup com schema futuro, versões desconhecidas ou erro de leitura bloqueia a gravação; não usar fallback silencioso que perca dados de uma versão mais nova. Corrupção sem backup retorna erro e não cria jornada nova no mesmo slot. Não há exclusão de slots nesta unidade.

Escritor é local/síncrono em um processo. Não há locks entre instâncias, sincronização Steam Cloud ou resolução de conflitos entre PCs. Recibos não são prova de aquisição legítima online. Migrações serão explícitas quando existir schema anterior de campanha; saves dos protótipos não são tratados como v0.

## Verificação

Autorização explícita do responsável em 25/10/2026: 141 verificações de regras/persistência e 17 de integração passaram em diretórios isolados. Fixtures geradas do JavaScript original cobrem oficina, movimento dos quatro tipos e trechos das duas fases do boss. Não substituem equivalência integral ou playtest completo.
