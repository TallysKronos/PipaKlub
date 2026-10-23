import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import {artConfig} from './art-build.mjs';
import {createParkIsometricScene} from '../src/park-isometric-layout.js';
const root=path.resolve(import.meta.dirname,'..'),base='/art/soulgen/keys/park-wind-v2/',review='/art/ui-reviews/park-isometric-v1/';
const c=artConfig().courtyard,config={scene:createParkIsometricScene(JSON.parse(fs.readFileSync('assets/world/park-v1/park-trail.tmj','utf8')),c.world.scenes['park-trail'].art),actor:c.plaza.actor,actorImage:'/assets/'+c.images['plaza-kael'].image,npc:c.world.actors.characters['sr-assis'],companion:c.world.companions.species.rabbito};
const allowed=new Set([review+'index.html',review+'preview.js','/src/world-isometric.js','/src/world-tall-grass.js','/src/world-tall-grass-renderer.js','/src/park-isometric-layout.js','/src/park-exploration.js','/src/world-map.js','/src/world-art.js','/src/world-navigation.js','/tools/soulgen-studio/model.mjs',config.actorImage,'/assets/'+config.npc.image,'/assets/'+config.companion.image,...fs.readdirSync(path.join(root,base)).filter(f=>/\.(png|json)$/.test(f)).map(f=>base+f)]);
http.createServer((req,res)=>{
 if(!['GET','HEAD'].includes(req.method)){res.writeHead(405);res.end();return;}
 const u=new URL(req.url,'http://localhost'),file=u.pathname==='/'?review+'index.html':u.pathname;
 res.setHeader('Cache-Control','no-store');
 if(file==='/config'){res.setHeader('Content-Type','application/json');res.end(req.method==='HEAD'?'':JSON.stringify(config));return;}
 if(!allowed.has(file)){res.writeHead(404);res.end();return;}
 res.setHeader('Content-Type',({'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.mjs':'text/javascript; charset=utf-8','.json':'application/json','.png':'image/png'})[path.extname(file)]);
 if(req.method==='HEAD'){res.end();return;}fs.createReadStream(path.join(root,file)).pipe(res);
}).listen(5241,'127.0.0.1',()=>console.log('Parque isométrico: http://127.0.0.1:5241/'));
