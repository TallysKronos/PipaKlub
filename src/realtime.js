import {WebSocketServer} from 'ws';
import {createEngine} from './engine.js';

export function attachRealtime(server,db){
  const engine=createEngine(),wss=new WebSocketServer({noServer:true,maxPayload:2048,perMessageDeflate:false});
  const clients=new Map();
  const visible=s=>({...s,players:s.players.map(({key,...p})=>p)});
  const read=code=>db.prepare('SELECT state FROM pipa_rooms WHERE code=?').get(code);
  const write=(code,s)=>db.prepare('UPDATE pipa_rooms SET state=?,rev=rev+1,updated=? WHERE code=?').run(JSON.stringify(s),Date.now(),code);
  const send=(ws,data)=>{if(ws.readyState===1&&ws.bufferedAmount<65536)ws.send(JSON.stringify(data));};
  server.on('upgrade',(req,socket,head)=>{
    const protocol=req.headers['x-forwarded-proto']==='https'?'https':'http';
    if(req.url!=='/realtime'||(req.headers.origin&&req.headers.origin!==protocol+'://'+req.headers.host)){socket.end('HTTP/1.1 403 Forbidden\r\n\r\n');return;}
    wss.handleUpgrade(req,socket,head,ws=>wss.emit('connection',ws));
  });
  wss.on('connection',ws=>{
    const deadline=setTimeout(()=>ws.close(1008,'Authentication required'),5000);deadline.unref();
    let windowStart=Date.now(),messages=0;
    ws.on('error',()=>{});
    ws.on('message',raw=>{try{
      const now=Date.now();if(now-windowStart>=1000){windowStart=now;messages=0;}if(++messages>100){ws.close(1008,'Too many messages');return;}
      const b=JSON.parse(String(raw));let c=clients.get(ws);
      if(!c){
        if(b.type!=='hello'||!/^[A-F0-9]{6}$/.test(String(b.code)))return ws.close(1008,'Invalid room');
        const row=read(b.code),s=row&&JSON.parse(row.state),p=s?.players.find(p=>p.key===b.token);
        if(!p)return ws.close(1008,'Invalid session');
        clearTimeout(deadline);c={code:b.code,id:p.id,input:{x:0,y:0,cut:false},seen:now};clients.set(ws,c);
        send(ws,{type:'state',state:visible(s)});return;
      }
      if(b.type==='ping'){send(ws,{type:'pong',at:b.at});return;}
      if(b.type==='input'){
        const axis=v=>Number.isFinite(v)?Math.max(-1,Math.min(1,v)):0;
        c.input={x:axis(b.input?.x),y:axis(b.input?.y),cut:!!b.input?.cut};c.seen=now;
      }
    }catch{ws.close(1008,'Invalid message');}});
    ws.on('close',()=>{clearTimeout(deadline);const c=clients.get(ws);clients.delete(ws);
      if(!c||[...clients.values()].some(q=>q.id===c.id))return;
      try{const row=read(c.code);if(!row)return;const s=JSON.parse(row.state),p=s.players.find(p=>p.id===c.id);if(p){p.input={x:0,y:0,cut:false};write(c.code,s);}}catch{}
    });
  });
  const tick=setInterval(()=>{
    const rooms=new Map();for(const [ws,c] of clients){if(!rooms.has(c.code))rooms.set(c.code,[]);rooms.get(c.code).push([ws,c]);}
    for(const [code,peers] of rooms){try{
      const row=read(code);if(!row){for(const [ws] of peers)ws.close(1008,'Room expired');continue;}
      const s=JSON.parse(row.state),now=Date.now();
      for(const [ws,c] of peers){const p=s.players.find(p=>p.id===c.id);if(!p||now-c.seen>15000){ws.close(1008,'Session expired');continue;}
        p.input=now-c.seen>500?{x:0,y:0,cut:false}:c.input;p.seen=c.seen;
      }
      engine.step(s,now);write(code,s);const packet={type:'state',state:visible(s)};for(const [ws] of peers)send(ws,packet);
    }catch(e){console.error('Realtime tick failed:',e.message);for(const [ws] of peers)ws.close(1011,'Server error');}}
  },1000/30);tick.unref();
  return ()=>{clearInterval(tick);for(const ws of wss.clients)ws.terminate();wss.close();};
}
