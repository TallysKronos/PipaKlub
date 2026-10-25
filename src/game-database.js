import pg from 'pg';

// The DB login can execute only the listed game functions, with no direct table access.
const operations=Object.freeze({
 server_kite_wear:['p_user','p_kite','p_match','p_line','p_hull'],
 server_workshop_v3:['p_user','p_action','p_job','p_tail','p_target','p_revision','p_request','p_state','p_result'],
 reserve_player_match:['p_user','p_match','p_code','p_mode'],
 release_player_match:['p_user','p_match'],
 settle_player_cut:['p_event','p_match','p_winner','p_loser','p_kite'],
 finish_player_match:['p_match'],
 register_trail_run:['p_user','p_match','p_stage'],settle_trail_run:['p_user','p_match','p_stage','p_won','p_rounds_lost'],settle_daily_challenge:['p_user','p_match','p_day'],
 register_wild_run:['p_user','p_match','p_zone'],settle_wild_run:['p_user','p_match','p_outcome']
});
export function createGameDatabase(env,{Pool=pg.Pool}={}){
 if(!env.PIPA_DB_HOST||!env.PIPA_DB_USER||!env.PIPA_DB_PASSWORD)return null;
 if(!/^pipa_server(?:\.[a-z0-9]+)?$/.test(env.PIPA_DB_USER))throw Error('Use the restricted pipa_server database role.');
 const pool=new Pool({host:env.PIPA_DB_HOST,port:Number(env.PIPA_DB_PORT||5432),user:env.PIPA_DB_USER,password:env.PIPA_DB_PASSWORD,database:'postgres',
  ssl:{rejectUnauthorized:true,...(env.PIPA_DB_CA?{ca:env.PIPA_DB_CA.replaceAll('\\n','\n')}:{})},max:2,connectionTimeoutMillis:8000,idleTimeoutMillis:30000,statement_timeout:8000,query_timeout:10000,application_name:'pipaklub'});
 pool.on('error',()=>console.error('Game database connection interrupted.'));
 return {
  async verify(){
   const {rows}=await pool.query(`SELECT current_user AS role,
    NOT (rolsuper OR rolcreaterole OR rolcreatedb OR rolbypassrls OR rolreplication) AS restricted,
    NOT has_schema_privilege(current_user,'public','CREATE') AS safe_schema,
    NOT has_table_privilege(current_user,'public.player_profiles','UPDATE') AND
    NOT has_table_privilege(current_user,'public.player_kites','UPDATE') AND
    NOT has_table_privilege(current_user,'public.cut_events','INSERT') AS protected_tables,
    has_function_privilege(current_user,'public.reserve_player_match(uuid,uuid,text,text)','EXECUTE') AND
    has_function_privilege(current_user,'public.release_player_match(uuid,uuid)','EXECUTE') AND
    has_function_privilege(current_user,'public.settle_player_cut(text,uuid,uuid,uuid,uuid)','EXECUTE') AND
    has_function_privilege(current_user,'public.finish_player_match(uuid)','EXECUTE') AND
    has_function_privilege(current_user,'public.register_trail_run(uuid,uuid,text)','EXECUTE') AND
    has_function_privilege(current_user,'public.settle_trail_run(uuid,uuid,text,boolean,integer)','EXECUTE') AND
    has_function_privilege(current_user,'public.settle_daily_challenge(uuid,uuid,date)','EXECUTE') AND
    has_function_privilege(current_user,'public.server_kite_wear(uuid,uuid,uuid,integer,integer)','EXECUTE') AS game_functions
    FROM pg_roles WHERE rolname=current_user`);
   const r=rows[0];
   if(r?.role!=='pipa_server'||!r.restricted||!r.safe_schema||!r.protected_tables||!r.game_functions)throw Object.assign(Error('Restricted database permissions must be configured.'),{code:'PIPA_DB_PERMISSIONS'});
  },
  async rpc(name,body){
   const args=Object.hasOwn(operations,name)&&operations[name];
   if(!args)throw Error('Database operation is not allowed.');
   const result=await pool.query('SELECT public.'+name+'('+args.map((_,i)=>'$'+(i+1)).join(',')+') AS result',args.map(key=>body[key]??null));
   return result.rows[0]?.result;
  },
  close:()=>pool.end()
 };
}
