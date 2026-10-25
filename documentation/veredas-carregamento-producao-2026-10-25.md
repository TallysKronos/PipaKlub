# Entrada nas Veredas — diagnóstico de produção

O carregamento das Veredas oficiais inclui a consulta `player_veredas(text)` para recuperar baús já abertos. Em produção, a consulta de catálogo confirmou que tanto essa função quanto `veredas_chest_claims` estão ausentes. A migração 029 não foi instalada. Os 23 recursos de imagem conferidos no endereço público responderam HTTP 200.

O cliente tratava qualquer retorno falso dessa consulta como falha de arte. A correção distingue a indisponibilidade do progresso e preserva o bloqueio de entrada: não ignora a consulta nem concede recompensas no cliente. Uma resposta antiga também não pode substituir o erro da cena atual.

## Publicação preparada

Aplicar, mediante autorização específica, `supabase/migrations/029_veredas_exploration.sql`, que já contém uma transação. Ela registra cinco baús com recompensas únicas, encontros selvagens das Veredas e uma rabiola de Lacertubo na primeira vitória. Quem já venceu pode receber essa rabiola uma única vez ao consultar as Veredas. Acrescenta uma tabela com RLS e funções com permissões restritas; permite ao jogador autenticado consultar e reivindicar seus próprios baús. Não altera senhas nem apaga coleções ou campanhas.

Conferir a existência da tabela/funções e suas permissões após a aplicação, publicar o cliente com a mensagem corrigida e aguardar o commit correspondente ficar Live no Render.

Nenhuma alteração no banco de produção foi executada durante o diagnóstico. A liberação depende da autorização para a 029. O piloto funciona localmente porque seu servidor instala automaticamente todas as migrações, incluindo a 029; isso não comprovava sua instalação em produção.

## Aplicação autorizada

Após a confirmação “publique”, a migração 029 foi aplicada ao Supabase de produção em sua transação original. A consulta posterior confirmou a função instalada, RLS da tabela ativo, chamada concedida a `authenticated`, chamada negada a `anon`, acesso direto à tabela negado ao jogador e registro de encontro permitido a `pipa_server`. Builds Worker e Pages concluídos; sem nova suíte automatizada nesta publicação. A atualização independente do Soulgen que entrou na main foi preservada no merge.
