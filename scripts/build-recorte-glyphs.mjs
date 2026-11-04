// Kenney Input Prompts 1.5A (CC0), adapted with the Recorte palette.
// Fetch the archive from the official URL recorded in the manifest, extract into tmp/pip65/kenney.
import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import {recorteTokens} from './sync-recorte-tokens.mjs';
const t=recorteTokens(), source=path.resolve('tmp/pip65/kenney'), out=path.resolve('godot/assets/ui/recorte-v1/glyphs');
const families={kbd:'Keyboard & Mouse',xbox:'Xbox Series',ps:'PlayStation Series',switch:'Nintendo Switch'};
const buttons={
 xbox:{south:'xbox_button_a_outline',east:'xbox_button_b_outline',west:'xbox_button_x_outline',north:'xbox_button_y_outline',lb:'xbox_lb_outline',rb:'xbox_rb_outline',lt:'xbox_lt_outline',rt:'xbox_rt_outline',ls:'xbox_stick_l',rs:'xbox_stick_r_press',back:'xbox_button_view_outline',start:'xbox_button_menu_outline'},
 ps:{south:'playstation_button_cross_outline',east:'playstation_button_circle_outline',west:'playstation_button_square_outline',north:'playstation_button_triangle_outline',lb:'playstation_trigger_l1_outline',rb:'playstation_trigger_r1_outline',lt:'playstation_trigger_l2_outline',rt:'playstation_trigger_r2_outline',ls:'playstation_stick_l',rs:'playstation_button_r3_outline',back:'playstation4_button_share_outline','back-ps3':'playstation3_button_select_outline','back-ps5':'playstation5_button_create_outline',start:'playstation4_button_options_outline'},
 switch:{south:'switch_button_b_outline',east:'switch_button_a_outline',west:'switch_button_y_outline',north:'switch_button_x_outline',lb:'switch_button_l_outline',rb:'switch_button_r_outline',lt:'switch_button_zl_outline',rt:'switch_button_zr_outline',ls:'switch_stick_l',rs:'switch_stick_r_press',back:'switch_button_minus_outline',start:'switch_button_plus_outline'}
};
buttons.ps['start-ps3']='playstation3_button_start_outline';
buttons.ps['start-ps5']='playstation5_button_options_outline';
await fs.mkdir(out,{recursive:true}); const assets=[];
for(const [family,folder] of Object.entries(families)){
 await fs.mkdir(path.join(out,family),{recursive:true});
 const input=path.join(source,folder,'Vector');
 const selected=family==='kbd'?Object.fromEntries((await fs.readdir(input)).filter(n=>n.startsWith('keyboard_')&&n.endsWith('_outline.svg')).map(n=>[n.replace(/^keyboard_/,'').replace(/_outline.svg$/,''),n.slice(0,-4)])):buttons[family];
 for(const [id,name] of Object.entries(selected)){
  const original=await fs.readFile(path.join(input,name+'.svg'),'utf8');
  const content=original.replace(/<\/?svg[^>]*>/g,'').replace(/<defs\s*\/>/g,'').replace(/#FFFFFF/gi,t.nanquim).replace(/#000000/gi,t.papel);
  // A paper keycap keeps the original CC0 symbol legible on sky and ink alike.
  const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64"><rect x="3" y="3" width="58" height="58" rx="9" fill="${t.papel}" stroke="${t.nanquim}" stroke-width="3"/>${content}</svg>\n`;
  await fs.writeFile(path.join(out,family,id+'.svg'),svg.split(/\r?\n/).map(line=>line.trimEnd()).join('\n'));
  assets.push({family,id,file:family+'/'+id+'.svg',source:folder+'/Vector/'+name+'.svg',sourceSha256:crypto.createHash('sha256').update(original).digest('hex')});
 }
}
await fs.writeFile(path.join(out,'manifest.json'),JSON.stringify({version:1,source:'https://kenney.nl/assets/input-prompts',archive:'https://kenney.nl/media/pages/assets/input-prompts/8de120163f-1783763952/kenney_input-prompts_1.5.zip',license:'CC0-1.0',upstreamVersion:'1.5A (bundled License.txt)',changes:'Recolored vector paths; added paper keycap and ink contour. Positional action mapping; no changes to gameplay bindings.',assets},null,2)+'\n');
await fs.mkdir('godot/licenses',{recursive:true});
await fs.copyFile(path.join(source,'License.txt'),'godot/licenses/kenney-input-prompts-CC0.txt');
console.log(`${assets.length} Kenney-derived Recorte glyphs exported.`);
