-- New collections use existing administrator-only event grants and account binding.
begin;
insert into public.kite_models(id,name,color,rarity,soul,acquisition) values
 ('hiponilo','Hiponilo',2,'especial','hiponilo','event'),
 ('marulume','Marulume',1,'especial','marulume','event'),
 ('jarabrasa','Jarabrasa',0,'especial','jarabrasa','event'),
 ('jaguarluar','Jaguarluar',1,'especial','jaguarluar','event'),
 ('azulongo','Azulongo',3,'especial','azulongo','event'),
 ('auriflama','Auriflama',1,'especial','auriflama','event'),
 ('umbrocasco','Umbrocasco',2,'especial','umbrocasco','event'),
 ('nevagume','Nevagume',0,'especial','nevagume','event'),
 ('rexal','Rexal',0,'especial','rexal','event'),
 ('tricerafan','Tricerafan',2,'especial','tricerafan','event'),
 ('pteralis','Pteralis',1,'especial','pteralis','event'),
 ('stegaru','Stegaru',2,'especial','stegaru','event'),
 ('guaravento','Guaravento',3,'especial','guaravento','event'),
 ('micofolha','Micofolha',1,'especial','micofolha','event'),
 ('capimansa','Capimansa',2,'especial','capimansa','event'),
 ('tatutrama','Tatutrama',2,'especial','tatutrama','event'),
 ('yaguaru-memoria','Yaguarú',0,'rara','yaguaru-memoria','event'),
 ('araruna-memoria','Araruna',1,'rara','araruna-memoria','event'),
 ('caimbira-memoria','Caimbira',2,'rara','caimbira-memoria','event'),
 ('tamoata-memoria','Tamoatá',3,'rara','tamoata-memoria','event'),
 ('herravento','Herravento',0,'especial','herravento','event'),
 ('platofolha','Platofolha',2,'especial','platofolha','event'),
 ('celofita','Celofita',1,'especial','celofita','event'),
 ('riovela','Riovela',3,'especial','riovela','event')
on conflict(id) do update set name=excluded.name,color=excluded.color,rarity=excluded.rarity,soul=excluded.soul,acquisition=excluded.acquisition;
commit;
