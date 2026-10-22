-- Somente leitura. Limitado à conta informada pelo proprietário do PipaKlub.
-- Não retorna senha, hash de senha, tokens, chaves ou dados de outras contas.
begin read only;

select id, email, created_at, updated_at, email_confirmed_at, last_sign_in_at
from auth.users
where lower(email) = lower('tallys.roberto@hotmail.com')
limit 1;

commit;
