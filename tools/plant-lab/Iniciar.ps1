param([string]$NodePath=$env:NODE_BINARY)
$labFolder=Split-Path -Parent $MyInvocation.MyCommand.Path
$labPort=if($env:PLANT_LAB_PORT){[int]$env:PLANT_LAB_PORT}else{5256}
$labUrl="http://127.0.0.1:$labPort"
if(-not $NodePath){
 $nodeCommand=Get-Command node -ErrorAction SilentlyContinue
 if($nodeCommand){$NodePath=$nodeCommand.Source}
 else{$NodePath=Join-Path $env:USERPROFILE '.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe'}
}
if(-not (Test-Path -LiteralPath $NodePath)){throw 'Node.js necessário. Informe -NodePath com o executável.'}
$labRunning=$false
try{$labResponse=Invoke-WebRequest -Uri $labUrl -TimeoutSec 2 -UseBasicParsing;$labRunning=$labResponse.Content -match 'Jardim de Kronasta'}catch{}
if(-not $labRunning){
 Start-Process -FilePath $NodePath -ArgumentList ('"'+(Join-Path $labFolder 'server.mjs')+'"') -WorkingDirectory $labFolder -WindowStyle Hidden -RedirectStandardOutput (Join-Path $labFolder 'server.log') -RedirectStandardError (Join-Path $labFolder 'server-error.log')
}
Write-Host "Bancada: $labUrl"
# A interface visível é a própria ferramenta que o usuário está abrindo.
Start-Process -FilePath $labUrl
