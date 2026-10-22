import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
export function steamBuildFiles(appId,depotId,contentRoot){
 if(!/^[1-9][0-9]*$/.test(String(appId))||! /^(?:[1-9][0-9]*)$/.test(String(depotId)))throw Error('Informe App ID e Depot ID reais, positivos, do Steamworks.');
 if(String(appId)===String(depotId))throw Error('App ID e Depot ID devem identificar recursos diferentes.');
 const safe=path.resolve(contentRoot).replaceAll('\\','/');if(/["\r\n]/.test(safe))throw Error('Caminho inválido.');
 return {
  app:`"AppBuild"\n{\n "AppID" "${appId}"\n "Desc" "PipaKlub Windows preview"\n "BuildOutput" "./output"\n "ContentRoot" "${safe}"\n "Preview" "1"\n "Depots"\n {\n  "${depotId}" "depot_${depotId}.vdf"\n }\n}\n`,
  depot:`"DepotBuildConfig"\n{\n "DepotID" "${depotId}"\n "FileMapping"\n {\n  "LocalPath" "*"\n  "DepotPath" "."\n  "recursive" "1"\n }\n "FileExclusion" "*.pdb"\n "FileExclusion" "steam_appid.txt"\n}\n`
 };
}
if(process.argv[1]===fileURLToPath(import.meta.url)){
 const [appId,depotId]=process.argv.slice(2),repo=fileURLToPath(new URL('../../',import.meta.url)),out=path.join(repo,'dist','steam','vdf');
 const files=steamBuildFiles(appId,depotId,path.join(repo,'dist','steam','PipaKlub-win32-x64'));
 await fs.mkdir(out,{recursive:true});await fs.writeFile(path.join(out,'app_'+appId+'.vdf'),files.app);await fs.writeFile(path.join(out,'depot_'+depotId+'.vdf'),files.depot);
 console.log('SteamPipe preview configuration:',out,'— Preview=1; no upload or live branch change.');
}
