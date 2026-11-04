param(
 [ValidateSet('Selvagem','Morro','Chefe','Treino')][string]$Tipo='Selvagem',
 [ValidateRange(1,5)][int]$Licao=1,
 [switch]$ReduzirMovimento,
 [string]$GodotPath=$env:GODOT_PATH
)
$project=Split-Path -Parent $MyInvocation.MyCommand.Path
if(-not $GodotPath){
 $command=Get-Command godot -ErrorAction SilentlyContinue
 if($command){$GodotPath=$command.Source}
 else{$GodotPath=(Get-ChildItem -LiteralPath "$env:USERPROFILE\Documents\Codex\tools\godot" -Filter '*console.exe' -ErrorAction SilentlyContinue | Select-Object -First 1).FullName}
}
if(-not $GodotPath -or -not (Test-Path -LiteralPath $GodotPath)){throw 'Informe o executável Godot em -GodotPath.'}
$fixture=@{Selvagem='battle';Morro='morro-battle';Chefe='boss-intro';Treino=('lesson-'+($Licao-1))}[$Tipo]
$arguments=@('--path',('"'+$project+'"'),'--script','res://tools/battle_review.gd','--',('--fixture='+$fixture))
if($ReduzirMovimento){$arguments+='--reduced-motion'}
Start-Process -FilePath $GodotPath -ArgumentList $arguments -WindowStyle Hidden
