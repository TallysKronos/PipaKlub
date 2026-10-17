# Invocação do Javali de Biscoito

Nome provisório; ID estável: `javali-biscoito`.

## Fluxo

O jogador precisa ter visto o Pipamon, possuir sua rabiola pronta e ainda não possuir sua Soul vinculada. No Sr. Assis: Invocar Pipamon → card do Javali → selecionar rabiola → Usar → Ascendente. O feitiço é a espiral `7 → 4 → 1 → 2 → 3 → 6 → 9 → 8 → 5`, sem nós intermediários inesperados. O padrão fica disponível pela consulta do feitiço.

A rabiola sai de circulação ao iniciar. Três erros a consomem definitivamente. Abandono, fechamento ou expiração danificam o item, que só pode ser descartado. O acerto concede exatamente uma Soul vinculada; repetição da requisição retorna a mesma recompensa. Outra rabiola não serve como alternativa e uma segunda Soul do mesmo modelo é bloqueada sem consumir a rabiola restante.

## Arte e catálogo

Nova rabiola RGBA de 1254×1254, derivada da referência do criador por image_gen. O arquivo final foi conferido visualmente; a versão inicial com detalhe solto foi descartada da integração. Transparência preservada, sem redimensionar o original. O catálogo declara suas dimensões; a interface usa a mesma apresentação dos demais itens. A Dex descreve origem em evento, sem anunciar um drop selvagem que ainda não existe. URLs com hash e publicação em Worker e Pages seguem o fluxo atual.

## Migração e entrega

Aplicar `012_javali_biscoito.sql` e depois `013_javali_summoning.sql` pelo processo habitual de migrações do banco. A 013 registra apenas o feitiço próprio; a receita com a própria rabiola usa a regra existente. Não habilita alternativas nem concede itens em produção.

Entrega de rabiolas usa exclusivamente a função administrativa já existente `public.grant_summon_tail`, modelo `javali-biscoito`, origem `event` e referência única de entrega. A mesma referência é idempotente. Não expor credenciais administrativas ou essa função ao cliente. Não foi criado um evento, loja ou sistema de drops automaticamente.

O script local aplica as migrações e concede quatro rabiolas de demonstração ao Beto, com referências fixas, e registra o avistamento. Os testes pelo navegador usaram uma para três erros, uma para abandono/descarte e uma para sucesso. Resta uma pronta, bloqueada pela Soul já obtida. Os dados de produção não foram acessados ou alterados.

## Auditoria

- Builds Worker e Pages concluídos; artefato válido.
- Suíte completa: 110 testes aprovados, zero falhas.
- Teste real de PostgreSQL cobre migração idempotente, feitiço, avistamento, consumo imediato, cauda incompatível, permissões, três erros, abandono/descarte, expiração, repetição da tentativa e bloqueio de duplicação sem consumir a reserva.
- Playwright: card disponível, imagens carregadas, seleção/uso, três erros, abandono, item danificado e descarte, consulta/desenho da espiral, sucesso confirmado e exatamente um Javali no inventário. Após o sucesso, card bloqueado. Sem erros no console.

Sem merge nem deploy em produção.
