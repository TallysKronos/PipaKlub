-- Somente leitura. Não executar sem autorização para eventos e restrições da própria conta.
-- Nenhuma senha, hash, token, chave ou payload completo de auditoria é selecionado.
begin read only;

select is_sso_user, banned_until, deleted_at
from auth.users
where lower(email) = lower('tallys.roberto@hotmail.com')
limit 1;

select created_at, payload->>'action' as action
from auth.audit_log_entries
where payload->>'actor_id' = (
  select id::text from auth.users
  where lower(email) = lower('tallys.roberto@hotmail.com')
  limit 1
)
order by created_at desc
limit 10;

commit;
