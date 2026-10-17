-- New user-supplied Pipamon. No item distribution, summon recipe or inventory grant.
begin;
insert into public.kite_models(id,name,color,rarity,soul,acquisition)
values ('javali-biscoito','Javali de Biscoito',1,'especial','javali-biscoito','event')
on conflict(id) do update set name=excluded.name,color=excluded.color,rarity=excluded.rarity,soul=excluded.soul,acquisition=excluded.acquisition;
commit;
