// Integration scenarios for trading/combat need owned tradable items. Signup
// no longer supplies them: seed the scenario explicitly, never production.
export async function seedCollection(db,owners){
 for(const owner of owners){
  for(const model of ['basica','mata','azulao','raio'])await db.query('insert into public.player_kites(owner_id,model_id,permanent) select $1,$2,$3 where not exists(select 1 from public.player_kites where owner_id=$1 and model_id=$2)',[owner,model,model==='basica']);
  await db.query("update public.player_profiles set equipped_kite_id=(select id from public.player_kites where owner_id=$1 and model_id='basica' limit 1) where id=$1 and equipped_kite_id is null",[owner]);
 }
}
