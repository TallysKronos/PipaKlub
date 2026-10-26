param([string]$Area='morro-praca-da-chegada',[switch]$Rascunho,[string]$GodotPath=$env:GODOT_PATH)
$project=Split-Path -Parent $MyInvocation.MyCommand.Path
if(-not $GodotPath){
 $command=Get-Command godot -ErrorAction SilentlyContinue
 if($command){$GodotPath=$command.Source}
 else{$GodotPath=(Get-ChildItem -LiteralPath "$env:USERPROFILE\Documents\Codex\tools\godot" -Filter '*console.exe' -ErrorAction SilentlyContinue | Select-Object -First 1).FullName}
}
if(-not $GodotPath -or -not (Test-Path -LiteralPath $GodotPath)){throw 'Informe o executável Godot em -GodotPath.'}
$arguments=@('--path',('"'+$project+'"'),'res://scenes/overworld_preview.tscn','--',("--area="+$Area))
if(-not $Rascunho){$arguments+='--art-preview'}
Start-Process -FilePath $GodotPath -ArgumentList $arguments -WindowStyle Hidden
