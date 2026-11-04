// Original SVG family for PIP-65. No generated text inside game icons.
import fs from 'node:fs/promises';
import {recorteTokens} from './sync-recorte-tokens.mjs';
const t=recorteTokens(), root=new URL('../godot/assets/ui/recorte-v1/icons/',import.meta.url);
const p=d=>`<path d="${d}"/>`, c=(x,y,r)=>`<circle cx="${x}" cy="${y}" r="${r}"/>`;
const line=d=>`<path d="${d}" fill="none"/>`;
const kite=p('M24 6L39 24 24 40 9 24Z')+line('M24 6V40M9 24H39');
const leaf=p('M8 34C8 13 23 7 40 8 40 27 30 40 12 39Z')+line('M10 38L32 17M20 28L19 18M26 23L35 24');
const shield=p('M24 6L40 12 38 29Q34 38 24 42 14 38 10 29L8 12Z');
const wind=line('M7 18H29Q40 18 36 10T26 12M8 25H38M10 32H28Q40 32 35 39T25 37');
const bolt=p('M26 6L10 27H23L19 42 39 20H26Z');
const spool=p('M15 10H33V38H15Z')+line('M11 8H37M11 40H37M16 18H32M16 25H32M16 32H32M33 16C46 16 44 36 36 30');
const star=p('M24 6L29 18 42 19 32 28 35 41 24 34 13 41 16 28 6 19 19 18Z');
const shapes={
 localizacao:p('M24 5L42 41 24 32 6 41Z'),
 'seta-direita':p('M25 8L42 24 25 40V31H6V17H25Z'),
 'seta-esquerda':p('M23 8L6 24 23 40V31H42V17H23Z'),
 pipa:kite+line('M24 40Q32 40 28 44'),
 mochila:p('M16 13V10Q24 3 32 10V13M10 16Q24 10 38 16V40H10Z')+p('M16 27H32V36H16Z')+line('M17 19H31'),
 'pipa-dex':p('M7 9H22L24 12 26 9H41V39H26L24 42 22 39H7Z')+line('M24 13V38')+p('M33 17L39 24 33 30 27 24Z'),
 parceiros:p('M15 8L26 21 15 34 4 21ZM34 15L44 27 34 39 24 27Z')+line('M15 34Q22 36 16 42M34 39L38 43'),
 missoes:p('M11 10H37V41H11Z')+p('M18 7H30V16H18Z')+line('M17 25H31M17 33H28'),
 oficina:p('M8 34H40V41H8ZM9 13L19 5 29 15 19 25Z')+line('M24 20L36 32'), salvar:p('M8 7H35L41 13V41H8Z')+p('M16 7H31V21H16ZM16 29H33V41H16Z'),
 carregar:p('M7 15H20L25 20H41L38 40H7Z')+line('M24 7V30M18 24L24 30 30 24'),
 configuracoes:p('M20 6H28L30 13 37 12 42 20 37 25 39 33 32 38 26 35 20 42 12 37 12 29 6 24 10 16 18 15Z')+c(24,24,6),
 sair:p('M9 7H26V41H9Z')+line('M23 24H42M34 16L42 24 34 32'),
 mapa:p('M6 12L18 7 31 13 42 8V37L31 42 18 36 6 41Z')+line('M18 7V36M31 13V42'),
 voltar:p('M24 9L7 24 24 39V30H41V18H24Z'), confirmar:line('M8 25L19 36 40 12'), fechar:line('M12 12L36 36M36 12L12 36'),
 info:c(24,24,18)+line('M24 22V34')+c(24,15,1), alerta:p('M24 6L44 40H4Z')+line('M24 17V27')+c(24,34,1),
 moeda:c(24,24,18)+p('M24 12L34 24 24 36 14 24Z'), linha:spool,
 rabiola:line('M24 6C8 15 40 28 23 42')+p('M8 12L23 18 38 12V25L23 18 8 25Z')+p('M13 32L23 36 34 31V42L23 36 13 42Z'),
 vida:p('M24 41C17 34 5 26 6 16 6 5 20 4 24 14 28 4 42 5 42 16 43 26 31 34 24 41Z'), energia:bolt,xp:star,
 nivel:p('M8 26L24 10 40 26 34 32 24 22 14 32Z')+line('M12 40H36'),
 tempo:c(24,26,16)+line('M18 5H30M24 5V10M24 16V27L32 31'),
 bau:p('M7 23Q7 8 24 8T41 23V40H7Z')+line('M7 24H41')+p('M20 20H28V32H20Z'),
 chave:c(16,17,10)+line('M23 24L40 41M29 30L35 24M35 36L41 30'),
 presente:p('M8 21H40V41H8ZM5 15H43V23H5Z')+line('M24 15V41')+p('M24 15C7 18 8 2 18 7ZM24 15C41 18 40 2 30 7Z'),
 troca:line('M7 16H39L32 8M41 32H9L16 40'),
 amigos:c(17,16,7)+c(34,19,6)+p('M5 40V34Q5 25 17 25T29 34V40ZM29 29Q43 26 43 39H33'),
 ranqueada:p('M13 7H35V24Q33 33 24 34 15 33 13 24Z')+line('M13 12H6V19Q6 26 15 26M35 12H42V19Q42 26 33 26M24 34V41M15 42H33'),
 treino:p('M8 7H16V41H8ZM32 7H40V41H32Z')+line('M16 23H32M4 15V33M44 15V33'),
 'ceu-do-dia':c(31,15,8)+p('M9 39Q1 25 14 23 18 9 29 24 43 20 43 32 43 39 36 39Z'),
 cadeado:p('M10 22H38V41H10Z')+line('M16 22V14Q16 5 24 5T32 14V22M24 30V35'),
 check:line('M8 25L19 36 40 12'), mais:line('M24 9V39M9 24H39'), menos:line('M9 24H39'),
 filtro:p('M6 8H42L28 25V39L20 42V25Z'), ordenar:line('M12 7V41M6 35L12 41 18 35M25 12H42M25 24H37M25 36H31'),
 buscar:c(21,20,13)+line('M31 30L42 42'),
 som:p('M7 18H16L27 8V40L16 30H7Z')+line('M33 16Q44 24 33 32'),
 musica:line('M17 35V11L38 6V31M17 17L38 12')+p('M17 31C3 27 3 44 13 41L17 39ZM38 27C24 23 24 40 34 37L38 35Z'),
 vibracao:p('M16 9H32V39H16Z')+line('M9 12L5 19 9 26 5 34M39 12L43 19 39 26 43 34'),
 idioma:c(24,24,18)+line('M6 24H42M24 6Q8 24 24 42 40 24 24 6M10 14H38M10 34H38'),
 controle:p('M14 13H34Q41 14 43 34 42 45 31 32H17Q6 45 5 34 7 14 14 13Z')+line('M15 19V29M10 24H20')+c(31,22,1)+c(37,27,1),
 teclado:p('M5 12H43V38H5Z')+line('M12 20H14M21 20H23M30 20H32M37 20H38M12 27H14M21 27H23M30 27H32M15 33H34'),
 acessibilidade:c(24,10,4)+line('M7 19L24 23 41 19M24 23V30M24 30L14 42M24 30L34 42'),
 cortar:p('M8 37L34 8 39 12 13 42Z')+line('M25 14L34 23M10 9L19 18M7 24L13 24'),
 esquiva:p('M29 8C10 7 10 30 28 33L28 24 42 33 28 43V37C3 35 2 5 29 8Z'),
 puxao:spool+line('M7 24H17M7 24L12 19M7 24L12 29'),
 chicote:line('M9 40L15 28C39 45 47 17 28 9 10 1 7 24 25 22'),
 estilingue:line('M24 42V24M24 24L8 8M24 24L40 8M8 8Q24 30 40 8'),
 laco:line('M24 27C3 30 6 7 24 7 42 7 45 30 24 27L24 42'),
 'folha-solta':leaf,'duplo-toque':p('M6 34L20 10V23L30 10V34H20L13 42Z')+line('M35 11L42 6M36 22H43'),
 foco:c(24,24,13)+line('M24 4V13M24 35V44M4 24H13M35 24H44')+c(24,24,3),
 dash:p('M20 8L42 24 20 40V29H6V19H20Z')+line('M7 9H14M6 39H14'), guarda:shield+line('M16 23L22 29 33 17'),
 especial:star+c(24,24,5), fugir:p('M13 7H34V41H13Z')+line('M5 24H28M21 17L28 24 21 31'),
 pausar:p('M11 8H20V40H11ZM28 8H37V40H28Z'),
 'pulo-do-elo':p('M12 33L23 17 33 33Z')+line('M7 41Q24 22 41 41M19 13L17 5M28 13L31 5'),
 'no-de-vendaval':wind+c(24,25,5), 'ruptura-dos-canos':p('M9 9H22V22H38V40H25V33H9Z')+line('M24 10L32 18M39 8L36 16M27 5L28 13'),
 precisa:line('M8 38L37 9M27 9H37V19')+c(15,31,6), agil:bolt, guardia:shield, tecnica:wind
};
const accentFor=id=>['moeda','xp','nivel','ranqueada','especial','pulo-do-elo'].includes(id)?t.sol:['vida','parceiros','folha-solta','guardia'].includes(id)?t.folha:['cortar','puxao','alerta','sair','fugir','ruptura-dos-canos'].includes(id)?t.rabiola:t.ceu;
await fs.mkdir(root,{recursive:true}); await fs.mkdir(new URL('world/',root),{recursive:true});
const assets=[];
const lineSymbols=new Set(['confirmar','fechar','check','mais','menos','troca','estilingue','laco','chicote','no-de-vendaval','tecnica']);
for(const [id,body] of Object.entries(shapes)){
 const outlined=lineSymbols.has(id);
 const shape=`<g fill="${t.papel}" stroke="${t.nanquim}" stroke-width="${outlined?9:3}" stroke-linejoin="round" stroke-linecap="round">${body}</g>`+(outlined?`<g fill="${t.papel}" stroke="${t.papel}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round">${body}</g>`:'');
 const accent=`<circle cx="36" cy="10" r="4" fill="${accentFor(id)}" stroke="${t.nanquim}" stroke-width="2"/><path d="M34 9h2" stroke="${t.papel}" stroke-width="1.5" stroke-linecap="round"/>`;
 const shell=inner=>`<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48">${inner}</svg>\n`;
 await fs.writeFile(new URL(id+'.svg',root),shell(shape+accent));
 // Outer paper silhouette: 9px outer stroke minus 3px ink = 3px sticker rim.
 const world=`<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="-8 -8 64 64"><g fill="${t.papel}" stroke="${t.papel}" stroke-width="${outlined?15:9}" stroke-linejoin="round" stroke-linecap="round">${body}</g>${shape}${accent}</svg>\n`;
 await fs.writeFile(new URL('world/'+id+'.svg',root),world);
 assets.push({id,file:id+'.svg',world:'world/'+id+'.svg',png96:'png96/'+id+'.png',size:[48,48],worldSize:[64,64],worldPadding:8,stroke:3,accent:accentFor(id)});
}
await fs.writeFile(new URL('manifest.json',root),JSON.stringify({version:1,source:'Original project-authored vector geometry; scripts/build-recorte-icons.mjs',palette:'ui_tokens.gd via sync-recorte-tokens.mjs',status:'implemented; visual review required',assets},null,2)+'\n');
console.log(`${assets.length} Recorte icons + paper-rim variants exported.`);
