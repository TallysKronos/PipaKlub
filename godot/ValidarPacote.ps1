param(
 [Parameter(Mandatory)][string]$PackageDirectory,
 [string]$OutputDirectory = '',
 [string]$PreviousPackageDirectory = ''
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
function Run-Package([string]$Stage,[string]$Directory,[string]$Mode,[string]$ProfilePath=$profile){
 $info=[Diagnostics.ProcessStartInfo]::new()
 $info.FileName=Join-Path $Directory 'Soulmonsters.exe'
 $info.WorkingDirectory=$working
 $info.UseShellExecute=$false
 $info.CreateNoWindow=$true
 $info.RedirectStandardOutput=$true
 $info.RedirectStandardError=$true
 $info.Environment['APPDATA']=$ProfilePath
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
 $otherProfile=Join-Path $output 'perfil B separado'
 New-Item -ItemType Directory -Path $otherProfile | Out-Null
 $saveRelative='PipaKlub/package-probe/slot-1.json'
 $saveA=Join-Path $profile $saveRelative
 $saveB=Join-Path $otherProfile $saveRelative
 $hashA=(Get-FileHash -LiteralPath $saveA).Hash
 Run-Package 'second-profile-create' $second 'create' $otherProfile
 $hashB=(Get-FileHash -LiteralPath $saveB).Hash
 if($hashA -eq $hashB){throw 'Os perfis deveriam ter IDs de campanha distintos.'}
 $freshInstall=Join-Path $output 'Instalação C nova'
 New-Item -ItemType Directory -Path $freshInstall | Out-Null
 foreach($name in @('Soulmonsters.exe','Soulmonsters.pck')){Copy-Item -LiteralPath (Join-Path $package $name) -Destination $freshInstall}
 Run-Package 'reinstalled-profile-a' $freshInstall 'resume'
 Run-Package 'reinstalled-profile-b' $freshInstall 'resume' $otherProfile
 if((Get-FileHash -LiteralPath $saveA).Hash -ne $hashA -or (Get-FileHash -LiteralPath $saveB).Hash -ne $hashB){
  throw 'A troca de perfil ou reinstalação alterou um save existente.'
 }
 $results.Add(@{stage='profile-isolation';passed=$true})
 if($PreviousPackageDirectory){
  $previous=[IO.Path]::GetFullPath($PreviousPackageDirectory)
  $previousManifest=Get-Content -LiteralPath (Join-Path $previous 'build-info.json') -Raw | ConvertFrom-Json
  if($previousManifest.sourceCommit -eq $manifest.sourceCommit){throw 'Informe uma versão anterior distinta para validar a atualização.'}
  $updateInstall=Join-Path $output 'Instalação para atualização'
  $updateProfile=Join-Path $output 'Perfil para atualização'
  New-Item -ItemType Directory -Path $updateInstall,$updateProfile | Out-Null
  foreach($name in @('Soulmonsters.exe','Soulmonsters.pck')){
   $entry=@($previousManifest.files | Where-Object {$_.name -eq $name})
   $source=Join-Path $previous $name
   if($entry.Count -ne 1 -or (Get-FileHash -LiteralPath $source).Hash -ne $entry[0].sha256){throw "Pacote anterior divergente do manifesto: $name"}
   Copy-Item -LiteralPath $source -Destination $updateInstall
  }
  Run-Package 'previous-version-create' $updateInstall 'create' $updateProfile
  $updateSave=Join-Path $updateProfile $saveRelative
  $previousHash=(Get-FileHash -LiteralPath $updateSave).Hash
  foreach($name in @('Soulmonsters.exe','Soulmonsters.pck')){Copy-Item -LiteralPath (Join-Path $package $name) -Destination $updateInstall -Force}
  Run-Package 'updated-version-resume' $updateInstall 'resume' $updateProfile
  if((Get-FileHash -LiteralPath $updateSave).Hash -ne $previousHash){throw 'A retomada após atualização alterou o arquivo salvo.'}
  $results.Add(@{stage='update-preserves-save';passed=$true;previousCommit=$previousManifest.sourceCommit})
 }
}finally{
 @{sourceCommit=$manifest.sourceCommit;scope='Windows release headless: two disposable APPDATA profiles, restart, relocation and fresh installation';results=@($results.ToArray())} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $output 'results.json') -Encoding utf8
}
Write-Host "Package validation: $output"
