param([switch]$Editor,[switch]$Test,[switch]$Prototype,[string]$GodotPath=$env:GODOT_PATH)
$project=Split-Path -Parent $MyInvocation.MyCommand.Path
if(-not $GodotPath){
 $command=Get-Command godot -ErrorAction SilentlyContinue
 if($command){$GodotPath=$command.Source}
 else{
  $candidates=Get-ChildItem -LiteralPath "$env:USERPROFILE\Documents\Codex\tools\godot" -Filter '*console.exe' -ErrorAction SilentlyContinue
  if($candidates){$GodotPath=$candidates[0].FullName}
 }
}
if(-not $GodotPath -or -not (Test-Path -LiteralPath $GodotPath)){throw 'Godot 4.7 necessário. Defina GODOT_PATH ou passe -GodotPath com o caminho do executável.'}
if($Test){ & $GodotPath --headless --path $project res://scenes/illustrated_veredas.tscn -- --smoke; exit $LASTEXITCODE }
$arguments=@('--path',('"'+$project+'"'))
if($Editor){$arguments+='--editor'}
if($Prototype){$arguments+='res://scenes/illustrated_veredas.tscn'}
Start-Process -FilePath $GodotPath -ArgumentList $arguments -WindowStyle Hidden
