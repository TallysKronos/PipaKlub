// Browsers share cookies across ports. Separate local servers must not share auth.
export function localSessionCookies(port){
 const prefix='local'+port+'_',names=new Set(['pipa_access','pipa_refresh']);
 return {
  incoming(value=''){return value.split(';').map(p=>p.trim()).filter(Boolean).flatMap(pair=>{const at=pair.indexOf('='),name=pair.slice(0,at);if(names.has(name))return [];if(name.startsWith(prefix)&&names.has(name.slice(prefix.length)))return [pair.slice(prefix.length)];return [pair];}).join('; ');},
  outgoing(value){return value.replace(/^(pipa_access|pipa_refresh)=/,name=>prefix+name);}
 };
}
