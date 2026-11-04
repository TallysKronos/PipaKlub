// Original, editable Soulmonsters UI artwork. No raster mockup or baked text.
import { mkdir, writeFile } from 'node:fs/promises';
import {recorteTokens,syncRecorteManifest} from './sync-recorte-tokens.mjs';
const out = new URL('../godot/assets/campaign/ui-recorte/', import.meta.url);
await mkdir(out, { recursive: true });
const tokens = recorteTokens();
// Dark rival panels retain readable paper text; danger signals use coral.
const colors = { ink:tokens.nanquim, dark:tokens['tinta-2'], danger:tokens['tinta-3'], paper:tokens.papel, muted:tokens['papel-2'], cyan:tokens.ceu, coral:tokens.rabiola, gold:tokens.sol };
const svg = (w,h,body) => `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${body}</svg>`;
const save = (name,w,h,body) => writeFile(new URL(name+'.svg',out),svg(w,h,body));
// Source corners = 24px. Straight edge middles and blank center stretch independently.
for (const role of ['dark','danger','paper']) {
 const fill=colors[role];
 await save('frame-'+role,256,128,`
 <path d="M12 8L242 8 251 19 249 119 238 126 11 124 4 113 5 20Z" fill="${colors.ink}"/>
 <path d="M11 3L239 4 246 15 244 113 232 119 10 117 3 107 5 16Z" fill="${fill}" stroke="${colors.ink}" stroke-width="4"/>
 <path d="M7 26L8 15 19 7 29 8M217 115L232 115 240 107M8 96L7 106 15 112" fill="none" stroke="${role==='paper'?colors.muted:colors.ink}" stroke-width="2"/>
 ${role==='danger'?`<path d="M8 17L18 7 27 8 12 29Z" fill="${colors.coral}"/>`:''}
 `);
}
// Every state has identical slicing and content metrics; the brush ends never widen.
for (const state of ['normal','hover','pressed','disabled','focus']) {
 const fill=state==='hover'||state==='focus'?colors.paper:state==='disabled'?colors.muted:colors.coral;
 await save('button-'+state,160,64,`
 <path d="M17 7L157 7 145 62 3 61Z" fill="${colors.ink}"/>
 <path d="M15 3L154 3 141 57 2 56Z" fill="${fill}" stroke="${state==='focus'?colors.cyan:colors.ink}" stroke-width="3"/>
 <path d="M15 6L27 6 24 9 12 14M131 53L139 50 143 36" fill="none" stroke="${colors.ink}" stroke-width="1.5"/>
 ${state==='focus'||state==='hover'?`<path d="M14 5L20 5 8 54 3 54Z" fill="${colors.coral}"/>`:''}
 <path d="M26 7L34 7M119 53L127 53" stroke="${colors.ink}" stroke-width="1"/>
 `);
}
for (const state of ['on','off']) await save('toggle-'+state,84,40,`
 <path d="M11 3L81 3 73 37 3 37Z" fill="${colors.ink}" stroke="${colors.muted}" stroke-width="2"/>
 <path d="M${state==='on'?58:23} 8l12 12-12 12-12-12Z" fill="${state==='on'?colors.coral:colors.paper}"/>
 <path d="M15 20h17" stroke="${state==='on'?colors.cyan:tokens['tinta-3']}" stroke-width="3"/>`);
// Icon language: bamboo spars + folded paper, 64px box and common ink weight.
const iconPaths={
 attack:'<path d="M12 48L50 10 55 15 18 53Z" fill="#F4E9D2"/><path d="M14 38l12 12M33 15l16 17M13 10l6 7M45 48l8 6"/>',
 energy:'<path d="M33 5L53 27 31 58 10 30Z" fill="#2EC8E3"/><path d="M33 5L31 58M10 30L53 27M20 15L44 43"/>',
 dodge:'<path d="M27 11L51 28 30 52 16 30Z" fill="#F4E9D2"/><path d="M27 11L30 52M16 30L51 28M5 20h12M3 30h10M6 41h12"/>',
 puxao:'<path d="M19 10L39 16 29 48 9 42Z" fill="#FF5A36"/><path d="M16 19L36 25M12 36L32 42M38 21c26-9 22 32 6 22l-6-5M16 7l26 8M6 44l25 8"/>',
 line:'<path d="M32 7L51 17 47 39 32 57 16 39 12 17Z" fill="#2EC8E3"/><path d="M32 11v39M19 25l13-7 13 7M20 34l12 10 12-10"/>',
 bag:'<path d="M20 12L43 12 39 22Q58 34 51 53L12 53Q7 34 25 22Z" fill="#F4E9D2"/><path d="M23 21h17M22 14l5 7M38 14l-4 7M19 37l13-9 13 9-13 13Z"/><path d="M32 29v19" stroke="#FF5A36"/>',
 team:'<path d="M23 7L42 22 24 46 7 24Z" fill="#2EC8E3"/><path d="M23 7L24 46M7 24L42 22M41 30l16 11-14 18-14-17Z" fill="none"/><path d="M24 46q-4 13 11 11"/>',
 map:'<path d="M5 14L22 7 42 14 58 7 56 50 41 57 22 49 7 56Z" fill="#F4E9D2"/><path d="M22 7v42M42 14l-1 43"/><path d="M32 21l9 11-10 13-9-12Z" fill="#FF5A36"/>',
 settings:'<path d="M12 16h40M12 32h40M12 48h40"/><path d="M22 9l7 7-7 7-7-7ZM43 25l7 7-7 7-7-7ZM25 41l7 7-7 7-7-7Z" fill="#2EC8E3"/>',
 back:'<path d="M29 11L8 31 29 51 29 39 54 39 54 23 29 23Z" fill="#F4E9D2"/><path d="M31 27h17" stroke="#FF5A36"/>',
 save:'<path d="M11 7L46 7 55 16 55 56 9 56Z" fill="#F4E9D2"/><path d="M20 7v18h23V7M19 56V36h26v20"/><path d="M31 13v6" stroke="#FF5A36"/>',
 tail:'<path d="M32 6q-20 17 0 27t0 25" fill="none"/><path d="M14 15L31 21 49 10 47 31 31 25 14 34ZM14 39L31 44 48 34 47 55 32 49 16 59Z" fill="#FF5A36"/>',
};
for(const [id,body] of Object.entries(iconPaths)) await save('icon-'+id,64,64,`<g fill="none" stroke="${colors.ink}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round">${body}</g>`);
for(const role of ['victory','defeat']) await save('ribbon-'+role,720,160,`
 <path d="M15 44L112 37 101 135 4 148 30 95ZM609 25L713 10 692 75 715 121 613 129Z" fill="${role==='victory'?colors.cyan:colors.coral}" stroke="${colors.ink}" stroke-width="5"/>
 <path d="M83 26L638 4 650 123 92 154Z" fill="${colors.ink}"/>
 <path d="M77 18L631 2 643 115 85 144Z" fill="${colors.paper}" stroke="${colors.ink}" stroke-width="5"/>
 <path d="M94 30L618 14M100 130L628 105" stroke="${colors.muted}" stroke-width="2"/>
 <path d="M78 19L96 25 104 128 86 143Z" fill="${role==='victory'?colors.cyan:colors.coral}"/>
 <path d="M625 2L632 2 643 115 628 115Z" fill="${role==='victory'?colors.cyan:colors.coral}"/>
 `);
await save('splat',256,192,`<path fill="white" d="M89 21L112 38 142 9 150 42 198 31 186 65 235 84 202 104 223 140 179 139 172 179 141 155 104 182 92 148 44 162 54 128 11 113 48 94 21 57 64 61 67 24Z"/><circle cx="225" cy="27" r="7" fill="white"/><circle cx="23" cy="170" r="5" fill="white"/>`);
await save('thread-mark',320,100,`<g fill="none" stroke="${colors.cyan}" stroke-width="2"><path d="M3 75C71 9 153 96 225 22"/><path d="M3 81C71 15 153 102 225 28" opacity=".35"/></g><g stroke="${colors.ink}" stroke-width="3"><path d="M250 4L283 30 249 77 218 32Z" fill="${colors.coral}"/><path d="M250 4L249 77M218 32L283 30" fill="none"/></g>`);
console.log('Soulmonsters Recorte: original SVG family generated.');
syncRecorteManifest();

// Item identities share ink weight, with distinct paper profiles, not color alone.
for (const [id, color, shape] of [
 ['basica','#FF8C48','M13 16L30 24 50 12 46 34 30 28 13 40Z'],
 ['mata','#6FD08C','M13 26Q13 8 31 21Q52 5 49 25L32 37Z'],
 ['azulao','#2EC8E3','M10 24L31 9 53 25 32 43Z'],
 ['raio','#FFC23D','M18 7L42 7 34 25 50 25 21 54 28 32 12 32Z'],
 ['lacertubo','#D5A17B','M11 13L28 20 43 8 53 26 38 40 17 33Z'],
 ['quest-nina-tail','#FF8C48','M13 16L30 24 50 12 46 34 30 28 13 40Z']
]) await save('item-'+id,64,64,`<g stroke="#0B1017" stroke-width="3" stroke-linejoin="round"><path d="M31 8Q19 33 33 43T30 61" fill="none"/><path d="${shape}" fill="${color}"/>${id==='quest-nina-tail'?'<path d="M46 39l6 7-6 7-6-7Z" fill="#FFC23D"/><path d="M47 12l-7 9" stroke="#F4E9D2"/>':''}</g>`);
