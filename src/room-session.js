// The existing seat credential stays in this tab, never in invitation URLs or public state.
export function createRoomSessions(storage){
 const key=code=>'pipaRoomV1:'+String(code).toUpperCase();
 function read(code,owner=null){try{const s=JSON.parse(storage?.getItem(key(code))||'null');return s&&typeof s.token==='string'&&s.token.length<=100&&s.owner===owner?s:null;}catch{return null;}}
 function save(code,token,owner=null){if(!/^[A-F0-9]{6}$/.test(code||'')||!token)return;try{storage?.setItem(key(code),JSON.stringify({token,owner}));}catch{}}
 function remove(code){try{storage?.removeItem(key(code));}catch{}}
 return {read,save,remove};
}
