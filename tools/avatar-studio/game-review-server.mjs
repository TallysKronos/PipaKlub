// Local visual review: the production avatar, navigation and room renderer, no account or database.
import http from 'node:http';
import fs from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {artConfig} from '../../scripts/art-build.mjs';
import {createAssetHandler} from '../../src/static-assets.js';
const root=new URL('../../',import.meta.url),config=artConfig(),asset=createAssetHandler();
const modules=new Set(['src/avatar-player.js','src/avatar-activity.js','src/bedroom-isometric.js','src/bedroom-layout.js','src/home-layout.js','src/world-navigation.js','src/world-map.js','tools/iso-studio/model.mjs','tools/avatar-studio/model.mjs','tools/avatar-studio/game-review.mjs','src/switch-ui.css']);
const server=http.createServer(async(req,res)=>{try{const path=new URL(req.url,'http://localhost').pathname.slice(1);let data,type;
 if(!path){data=await fs.readFile(new URL('tools/avatar-studio/game-review.html',root));type='text/html';}
 else if(path==='config.json'){data=JSON.stringify({avatar:config.avatar,world:config.courtyard.world});type='application/json';}
 else if(modules.has(path)){data=await fs.readFile(new URL(path,root));type=path.endsWith('.css')?'text/css':'text/javascript';}
 else {const response=await asset(new Request('http://localhost'+req.url));if(!response){res.writeHead(404);res.end();return;}res.writeHead(response.status,Object.fromEntries(response.headers));res.end(Buffer.from(await response.arrayBuffer()));return;}
 res.writeHead(200,{'Content-Type':type,'Cache-Control':'no-store','X-Content-Type-Options':'nosniff'});res.end(data);
 }catch(error){console.error(error);res.writeHead(500);res.end('Falha na prévia.');}});
if(process.argv[1]===fileURLToPath(import.meta.url))server.listen(Number(process.env.AVATAR_REVIEW_PORT||5247),'127.0.0.1',()=>console.log('Avatar no cenário: http://127.0.0.1:'+server.address().port));
