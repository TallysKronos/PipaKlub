# Campanha local — PIP-60

Serviços conectados ao menu, narrativa, oficina, exploração e encontros. Não há dependência de conta/servidor. Consulte `../../README.md` para o estado completo.

## Contratos

- `state.gd`: envelope v1 com versões de conteúdo/regras, slot, revisão, checkpoint e dados puros. Três slots fixos, abertura no passo zero, nenhum parceiro ou material concedido. Validação estrutural não é verificação de legalidade de parceiros.
- `save_store.gd`: `create_slot`, `load_slot` e `save_slot`. Novo slot não substitui arquivo existente. Saves atualizam apenas a revisão carregada; revisão obsoleta retorna `stale`. Cópia temporária é relida e comparada antes da substituição; backup anterior é preservado. Windows depende do backup durante a substituição; não há promessa de durabilidade contra queda de energia/fsync.
- `session.gd`: Node que as futuras cenas poderão manter como serviço. Devolve cópias do snapshot; só muda memória e emite `changed` após sucesso no disco. `commit_operation` grava alteração e recibo juntos. Repetir o mesmo ID retorna `already_applied`; o chamador deve conservar um ID estável para a mesma operação e jamais aplicar a recompensa fora desse snapshot. Isso evita reaplicação no estado local carregado, mas não certifica ganhos online nem impede restaurar saves antigos manualmente.

## Roteiro de Kronasta

`kronasta_story.gd` é a espinha da campanha descrita em `documentation/historia/BIBLIA-DA-HISTORIA.md` (v2). Só lê o save, nunca grava:

- `PLACES`: os lugares do mapa de Kronasta (12 bairros, regiões naturais, Ruínas e estádio), com ato, nível sugerido e, quando já existe mapa, a cena de entrada.
- `BEATS`: os passos da história que já existem no jogo (prólogo, Nina, Lacertubo, devolver a rabiola, Mikka, Bosque). O primeiro passo aberto é o objetivo mostrado no HUD, no bairro e no parque depois do resgate.
- `state()`: `aberto`, `vencido`, `fechado` ou `em-breve`. Lugares cuja história ainda não foi construída aparecem como "em breve" e não têm viagem.
- Distrito Industrial, Pântano e Montanha são **prévias de QA**: os mapas existem, mas os bairros que os abrem na bíblia ainda não. Só abrem em build de desenvolvimento (`OS.is_debug_build()`; `SOULMONSTERS_QA=0` simula o jogador) e usam níveis provisórios de selvagens (`park_pacing.gd`). Num export de release ficam "em breve".
- **Viagem livre, história única**: lugares liberados podem ser revisitados; duelo ou chefe de história vencido não começa de novo (`morro.gd` devolve `already_applied`; o Lacertubo e os treinadores do parque já eram únicos).
- `category()` fica em Rabiola Branca e `neighbourhoods_won()` conta só o Morro do Sol, até os exames e os bairros seguintes existirem. Nada aqui inventa progresso.

As regiões ficam em `park_checkpoint.gd` (`REGIONS`, `region_of`, `is_kronasta`). A viagem, a descoberta (`<regiao>Parte<X>Descoberta`, recibo `<regiao>-discovered-<parte>-v1`) e os itens dos mapas ficam em `bosque_campaign.gd`. A tela "Região de Kronasta" (pausa → Mapa) lista tudo por ato. Uma cena nova precisa entrar também na lista de cenas válidas de `state.gd`.

## Persistência e recuperação

`user://campaign/slot-1.json` até `slot-3.json`, separados de `veredas-prototype-v1.json` e do pátio. Arquivo principal inválido/ausente permite carregar backup válido com `recovered: true`. A carga não regrava arquivos. O próximo save mantém o backup bom e arquiva o principal danificado por hash antes da substituição. Temporários incompletos não viram progresso automaticamente.

Arquivo principal ou backup com schema futuro, versões desconhecidas ou erro de leitura bloqueia a gravação; não usar fallback silencioso que perca dados de uma versão mais nova. Corrupção sem backup retorna erro e não cria jornada nova no mesmo slot. Não há exclusão de slots nesta unidade.

Escritor é local/síncrono em um processo. Não há locks entre instâncias, sincronização Steam Cloud ou resolução de conflitos entre PCs. Recibos não são prova de aquisição legítima online. Migrações serão explícitas quando existir schema anterior de campanha; saves dos protótipos não são tratados como v0.

## Verificação

Autorização explícita do responsável em 25/10/2026: 141 verificações de regras/persistência e 17 de integração passaram em diretórios isolados. Fixtures geradas do JavaScript original cobrem oficina, movimento dos quatro tipos e trechos das duas fases do boss. Não substituem equivalência integral ou playtest completo.
