'use strict';
const {app,BrowserWindow,Menu,session,shell,dialog,screen}=require('electron');
const fs=require('node:fs');
const path=require('node:path');
const {serverOrigin,navigationAllowed,externalAllowed,createBundleHandler}=require('./policy.cjs');
const config=require('./config.json'),origin=serverOrigin(config.serverOrigin),smoke=process.argv.includes('--smoke-test'),offline=smoke&&process.argv.includes('--offline');
let window,loaded=false,failed=false,localRequests=0;
app.setName('PipaKlub');
if(smoke){const profile=path.join(app.getPath('temp'),'pipaklub-desktop-smoke');fs.mkdirSync(profile,{recursive:true});app.setPath('userData',profile);}
if(!smoke&&!app.requestSingleInstanceLock()){app.quit();}else{
 app.on('second-instance',()=>{if(window){if(window.isMinimized())window.restore();window.show();window.focus();}});
 app.whenReady().then(start).catch(error=>{console.error('Desktop startup failed:',error.message);app.exit(1);});
}
async function start(){
 const client=path.join(__dirname,'build','client'),profile=path.join(app.getPath('userData'),'window.json'),ses=session.fromPartition(smoke?'desktop-smoke':'persist:pipaklub');
 ses.setPermissionRequestHandler((contents,permission,callback,details)=>callback(contents===window?.webContents&&details.requestingUrl?.startsWith(origin+'/')&&['clipboard-sanitized-write','fullscreen'].includes(permission)));
 ses.setPermissionCheckHandler((contents,permission,requestingOrigin)=>contents===window?.webContents&&requestingOrigin===origin&&['clipboard-sanitized-write','fullscreen'].includes(permission));
 ses.on('will-download',(event)=>event.preventDefault());
 await ses.protocol.handle('https',await createBundleHandler({root:client,origin,offline,onLocal:()=>localRequests++,delegate:request=>ses.fetch(request,{bypassCustomProtocolHandlers:true,credentials:'include'})}));
 let saved={};try{saved=JSON.parse(fs.readFileSync(profile,'utf8'));}catch{}
 const area=screen.getPrimaryDisplay().workAreaSize,width=Math.min(area.width,Math.max(960,Number(saved.width)||1280)),height=Math.min(area.height,Math.max(600,Number(saved.height)||800));
 window=new BrowserWindow({title:'PipaKlub',width,height,minWidth:960,minHeight:600,show:false,backgroundColor:'#112c36',autoHideMenuBar:true,webPreferences:{session:ses,nodeIntegration:false,contextIsolation:true,sandbox:true,webSecurity:true,webviewTag:false,allowRunningInsecureContent:false,devTools:!app.isPackaged}});
 Menu.setApplicationMenu(Menu.buildFromTemplate([
  {label:'PipaKlub',submenu:[{label:'Sobre esta prévia',click:()=>dialog.showMessageBox(window,{type:'info',title:'PipaKlub',message:'PipaKlub · prévia desktop '+app.getVersion(),detail:'Jogo instalado localmente. Contas e multiplayer usam o servidor online. A integração Steamworks ainda será adicionada.'})},{role:'quit',label:'Sair'}]},
  {label:'Exibir',submenu:[{label:'Tela cheia',accelerator:'F11',click:()=>window.setFullScreen(!window.isFullScreen())},{role:'resetZoom',label:'Restaurar escala'},{role:'zoomIn',label:'Aumentar interface'},{role:'zoomOut',label:'Diminuir interface'}]},
  {label:'Ajuda',submenu:[{label:'Abrir site oficial',click:()=>shell.openExternal(origin)}]}
 ]));
 const guard=event=>{if(!navigationAllowed(event.url,origin))event.preventDefault();};
 window.webContents.on('will-frame-navigate',guard);window.webContents.on('will-redirect',guard);
 window.webContents.on('will-attach-webview',event=>event.preventDefault());
 window.webContents.setWindowOpenHandler(details=>{if(externalAllowed(details.url,origin))void shell.openExternal(details.url);return {action:'deny'};});
 window.webContents.on('before-input-event',(event,input)=>{if(input.type==='keyDown'&&input.alt&&input.key==='Enter'){event.preventDefault();window.setFullScreen(!window.isFullScreen());}});
 window.webContents.on('console-message',details=>{if(details.level==='error'&&/Uncaught|Refused to execute|Content Security Policy/i.test(details.message)){failed=true;console.error('Renderer error:',details.message);}});
 window.webContents.on('render-process-gone',()=>{failed=true;});
 window.webContents.on('did-fail-load',(_event,code,_description,_url,isMainFrame)=>{if(isMainFrame&&code!==-3){failed=true;console.error('Desktop page failed:',code);}});
 window.webContents.on('did-finish-load',()=>{loaded=true;if(!smoke)window.show();});
 window.on('close',()=>{if(smoke)return;const bounds=window.getNormalBounds();try{fs.mkdirSync(path.dirname(profile),{recursive:true});fs.writeFileSync(profile,JSON.stringify({width:bounds.width,height:bounds.height,fullscreen:window.isFullScreen()}));}catch{}});
 if(saved.fullscreen&&!smoke)window.setFullScreen(true);
 await window.loadURL(origin+'/');
 if(smoke){
  setTimeout(async()=>{
   let accounts=null;if(!offline){try{const r=await ses.fetch(origin+'/account/config',{bypassCustomProtocolHandlers:true});accounts=r.ok;}catch{accounts=false;}}
   const ok=loaded&&!failed&&localRequests>=10&&(offline||accounts);
   console.log(JSON.stringify({desktopSmoke:ok,offline,loaded,localRequests,accounts,version:app.getVersion()}));app.exit(ok?0:1);
  },5000);
 }
}
app.on('window-all-closed',()=>app.quit());
