-- Own-tail recipe: spiral constellation. No cross-Pipamon alternatives or production grants.
begin;
insert into public.summon_spells(model_id,pattern)
values ('javali-biscoito',public.normalize_summon_path(array[7,4,1,2,3,6,9,8,5]::smallint[]))
on conflict(model_id) do nothing;
commit;
