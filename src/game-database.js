import pg from 'pg';

// The DB login can execute these four functions, with no direct table access.
const operations=Object.freeze({
 reserve_player_match:['p_user','p_match','p_code','p_mode'],
 release_player_match:['p_user','p_match'],
 settle_player_cut:['p_event','p_match','p_winner','p_loser','p_kite'],
 finish_player_match:['p_match']
});
export function createGameDatabase(env,{Pool=pg.Pool}={}){
 if(!env.PIPA_DB_HOST||!env.PIPA_DB_USER||!env.PIPA_DB_PASSWORD)return null;
 if(!/^pipa_server(?:\.[a-z0-9]+)?$/.test(env.PIPA_DB_USER))throw Error('Use the restricted pipa_server database role.');
 const pool=new Pool({host:env.PIPA_DB_HOST,port:Number(env.PIPA_DB_PORT||5432),user:env.PIPA_DB_USER,password:env.PIPA_DB_PASSWORD,database:'postgres',
  ssl:{rejectUnauthorized:true,...(env.PIPA_DB_CA?{ca:env.PIPA_DB_CA.replaceAll('\\n','\n')}:{})},max:2,connectionTimeoutMillis:8000,idleTimeoutMillis:30000,statement_timeout:8000,query_timeout:10000,application_name:'pipaklub'});
 pool.on('error',()=>console.error('Game database connection interrupted.'));
 return {
  async rpc(name,body){
   const args=Object.hasOwn(operations,name)&&operations[name];
   if(!args)throw Error('Database operation is not allowed.');
   const result=await pool.query('SELECT public.'+name+'('+args.map((_,i)=>'$'+(i+1)).join(',')+') AS result',args.map(key=>body[key]??null));
   return result.rows[0]?.result;
  },
  close:()=>pool.end()
 };
}
