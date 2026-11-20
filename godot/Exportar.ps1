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
$executable=Join-Path $destination 'Soulmonsters.exe'
$exportLog=& $GodotPath --headless --path $project --export-release 'Windows Desktop' $executable 2>&1 | Tee-Object -FilePath (Join-Path $destination 'export.log')
if($LASTEXITCODE -ne 0 -or ($exportLog -join "`n") -match '(?m)^ERROR:|SCRIPT ERROR:|Parse Error:|Compile Error:'){throw 'A exportação falhou. Consulte export.log.'}
# Probe the actual executable/PCK outside the source tree, with a disposable profile.
$probeInfo=[Diagnostics.ProcessStartInfo]::new()
$probeInfo.FileName=$executable
$probeInfo.WorkingDirectory=$destination
$probeInfo.UseShellExecute=$false
$probeInfo.CreateNoWindow=$true
$probeInfo.RedirectStandardOutput=$true
$probeInfo.RedirectStandardError=$true
$probeProfile=Join-Path ([IO.Path]::GetTempPath()) ('soulmonsters-export-probe-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $probeProfile | Out-Null
$probeInfo.Environment['APPDATA']=$probeProfile
$probeInfo.Environment['SOULMONSTERS_PACKAGE_PROBE']='1'
foreach($argument in @('--headless','--log-file',(Join-Path $destination 'resource-check.log'),'--','--package-probe','resources')){$probeInfo.ArgumentList.Add($argument)}
$probe=[Diagnostics.Process]::new();$probe.StartInfo=$probeInfo
$null=$probe.Start()
$probeOut=$probe.StandardOutput.ReadToEndAsync();$probeErr=$probe.StandardError.ReadToEndAsync()
$probeTimeout=-not $probe.WaitForExit(120000)
if($probeTimeout){$probe.Kill($true);$probe.WaitForExit()}
$probeLog=$probeOut.GetAwaiter().GetResult()+"`n"+$probeErr.GetAwaiter().GetResult()
if(Test-Path -LiteralPath (Join-Path $destination 'resource-check.log')){$probeLog+="`n"+(Get-Content -LiteralPath (Join-Path $destination 'resource-check.log') -Raw)}
[IO.File]::WriteAllText((Join-Path $destination 'resource-check.log'),$probeLog)
$probeFailed=$probeTimeout -or $probe.ExitCode -ne 0 -or $probeLog -match '(?m)SCRIPT ERROR:|Parse Error:|Compile Error:|^ERROR:' -or $probeLog -notmatch 'EXPORT RESOURCES \d+ checks; 0 failures'
$probe.Dispose()
if($probeFailed){throw 'Recursos inválidos no executável exportado. Consulte resource-check.log.'}
$licenseDirectory=Join-Path $destination 'licenses'
New-Item -ItemType Directory -Path $licenseDirectory -Force | Out-Null
Get-ChildItem -LiteralPath (Join-Path $project 'licenses') -File | Copy-Item -Destination $licenseDirectory
$repository=Split-Path -Parent $project
$commit=git -C $repository rev-parse HEAD
$dirty=[bool](git -C $repository status --porcelain)
$files=@('Soulmonsters.exe','Soulmonsters.pck') | ForEach-Object {
 $file=Get-Item -LiteralPath (Join-Path $destination $_)
 @{name=$file.Name;bytes=$file.Length;sha256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()}
}
@{createdUtc=[DateTime]::UtcNow.ToString('o');engine=(& $GodotPath --version);sourceCommit=$commit;uncommittedChanges=$dirty;files=$files} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $destination 'build-info.json') -Encoding utf8
'Soulmonsters: Elo das Ruínas. Mantenha Soulmonsters.exe e Soulmonsters.pck juntos. Esta build local não foi publicada na Steam. Licenças do motor em licenses/. O progresso fica em %APPDATA%/PipaKlub/campaign.' | Set-Content -LiteralPath (Join-Path $destination 'LEIA-ME.txt') -Encoding utf8
Write-Output "Build Windows disponível em $destination"
