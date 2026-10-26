param([string]$GodotPath=$env:GODOT_PATH,[string]$OutputDirectory='')
$ErrorActionPreference='Stop'
$project=$PSScriptRoot
if(-not $GodotPath){
 $command=Get-Command godot -ErrorAction SilentlyContinue
 if($command){$GodotPath=$command.Source}
 else{
  $candidates=Get-ChildItem -LiteralPath "$env:USERPROFILE\Documents\Codex\tools\godot" -Filter '*console.exe' -ErrorAction SilentlyContinue
  if($candidates){$GodotPath=$candidates[0].FullName}
 }
}
if(-not $GodotPath -or -not(Test-Path -LiteralPath $GodotPath)){throw 'Informe o Godot 4.7.2 e instale seus templates oficiais de exportação Windows.'}
$destination=if($OutputDirectory){[System.IO.Path]::GetFullPath($OutputDirectory)}else{Join-Path $project 'exports/windows'}
New-Item -ItemType Directory -Path $destination -Force | Out-Null
$executable=Join-Path $destination 'PipaKlub.exe'
& $GodotPath --headless --path $project --export-release 'Windows Desktop' $executable
if($LASTEXITCODE -ne 0){throw 'A exportação falhou. Consulte as mensagens do Godot.'}
$licenseDirectory=Join-Path $destination 'licenses'
New-Item -ItemType Directory -Path $licenseDirectory -Force | Out-Null
Get-ChildItem -LiteralPath (Join-Path $project 'licenses') -File | Copy-Item -Destination $licenseDirectory
$repository=Split-Path -Parent $project
$commit=git -C $repository rev-parse HEAD
$dirty=[bool](git -C $repository status --porcelain)
$files=@('PipaKlub.exe','PipaKlub.pck') | ForEach-Object {
 $file=Get-Item -LiteralPath (Join-Path $destination $_)
 @{name=$file.Name;bytes=$file.Length;sha256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()}
}
@{createdUtc=[DateTime]::UtcNow.ToString('o');engine=(& $GodotPath --version);sourceCommit=$commit;uncommittedChanges=$dirty;files=$files} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $destination 'build-info.json') -Encoding utf8
'Mantenha PipaKlub.exe e PipaKlub.pck juntos. Esta build local não foi publicada na Steam. Licenças do motor em licenses/. O progresso fica em %APPDATA%/PipaKlub/campaign.' | Set-Content -LiteralPath (Join-Path $destination 'LEIA-ME.txt') -Encoding utf8
Write-Output "Build Windows disponível em $destination"
