param(
 [Parameter(Mandatory)][string]$PackageDirectory,
 [string]$OutputDirectory = ''
)
$ErrorActionPreference='Stop'
$package=[IO.Path]::GetFullPath($PackageDirectory)
if(-not $OutputDirectory){$OutputDirectory=Join-Path ([IO.Path]::GetTempPath()) ('soulmonsters-package-'+[guid]::NewGuid().ToString('N'))}
$output=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $output){throw 'Use uma pasta de saída nova para garantir um perfil limpo.'}
New-Item -ItemType Directory -Force $output | Out-Null
$manifest=Get-Content -LiteralPath (Join-Path $package 'build-info.json') -Raw | ConvertFrom-Json
foreach($name in @('Soulmonsters.exe','Soulmonsters.pck')){
 $entry=@($manifest.files | Where-Object {$_.name -eq $name})
 if($entry.Count -ne 1 -or (Get-FileHash -LiteralPath (Join-Path $package $name) -Algorithm SHA256).Hash -ne $entry[0].sha256){throw "Pacote divergente do manifesto: $name"}
}
$profile=Join-Path $output 'perfil isolado'
$working=Join-Path $output 'diretório sem projeto'
New-Item -ItemType Directory -Force $profile,$working | Out-Null
$results=[Collections.Generic.List[object]]::new()
function Run-Package([string]$Stage,[string]$Directory,[string]$Mode){
 $info=[Diagnostics.ProcessStartInfo]::new()
 $info.FileName=Join-Path $Directory 'Soulmonsters.exe'
 $info.WorkingDirectory=$working
 $info.UseShellExecute=$false
 $info.CreateNoWindow=$true
 $info.RedirectStandardOutput=$true
 $info.RedirectStandardError=$true
 $info.Environment['APPDATA']=$profile
 $info.Environment['SOULMONSTERS_PACKAGE_PROBE']='1'
 $file=Join-Path $output "$Stage-engine.log"
 foreach($arg in @('--headless','--log-file',$file,'--','--package-probe',$Mode)){$info.ArgumentList.Add($arg)}
 $process=[Diagnostics.Process]::new();$process.StartInfo=$info
 $null=$process.Start()
 $stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync()
 $timeout=-not $process.WaitForExit(120000)
 if($timeout){$process.Kill($true);$process.WaitForExit()}
 $log=$stdout.GetAwaiter().GetResult()+"`n"+$stderr.GetAwaiter().GetResult()
 if(Test-Path -LiteralPath $file){$log+="`n"+(Get-Content -LiteralPath $file -Raw)}
 [IO.File]::WriteAllText((Join-Path $output "$Stage.log"),$log)
 $passed=-not $timeout -and $process.ExitCode -eq 0 -and $log -match "PACKAGE JOURNEY ${Mode}: \d+ checks; 0 failures" -and $log -notmatch '(?m)^ERROR:|SCRIPT ERROR:|Parse Error:|Leaked instance:|ObjectDB instances.*leaked'
 $results.Add(@{stage=$Stage;passed=$passed;exitCode=$process.ExitCode;timedOut=$timeout})
 $process.Dispose()
 if(-not $passed){throw "Falha no pacote: $Stage. Consulte $output/$Stage.log"}
 Write-Host "$Stage passed"
}
try{
 $first=Join-Path $output 'Instalação A com acentos'
 New-Item -ItemType Directory -Force $first | Out-Null
 foreach($name in @('Soulmonsters.exe','Soulmonsters.pck')){Copy-Item -LiteralPath (Join-Path $package $name) -Destination $first}
 Run-Package 'create' $first 'create'
 Run-Package 'restart' $first 'resume'
 $second=Join-Path $output 'Biblioteca B reinstalada'
 # Move only this disposable install, never the source package or player data.
 $sourceInstall=(Resolve-Path -LiteralPath $first).Path
 $destinationInstall=[IO.Path]::GetFullPath($second)
 $boundary=$output.TrimEnd([IO.Path]::DirectorySeparatorChar)+[IO.Path]::DirectorySeparatorChar
 if(-not $sourceInstall.StartsWith($boundary,[StringComparison]::OrdinalIgnoreCase) -or -not $destinationInstall.StartsWith($boundary,[StringComparison]::OrdinalIgnoreCase)){throw 'Instalação de teste fora do diretório isolado.'}
 Move-Item -LiteralPath $sourceInstall -Destination $destinationInstall
 Run-Package 'relocated' $second 'resume'
}finally{
 @{sourceCommit=$manifest.sourceCommit;profileIsolated=$true;scope='Windows release headless: main scene, save, restart, moved install; not a clean VM/Steam install';results=@($results.ToArray())} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $output 'results.json') -Encoding utf8
}
Write-Host "Package validation: $output"
