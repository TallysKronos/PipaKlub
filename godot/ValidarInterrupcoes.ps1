param([string]$GodotPath = $env:GODOT_PATH, [string]$OutputDirectory = '', [switch]$ProfileOnly)
$ErrorActionPreference = 'Stop'
if (-not $GodotPath -or -not (Test-Path -LiteralPath $GodotPath)) { throw 'Informe o executável Godot.' }
if (-not $OutputDirectory) { $OutputDirectory = Join-Path ([IO.Path]::GetTempPath()) ('soulmonsters-process-' + [guid]::NewGuid().ToString('N')) }
$output = [IO.Path]::GetFullPath($OutputDirectory)
if (Test-Path -LiteralPath $output) { throw 'Use uma pasta de resultados nova para não reutilizar fixtures.' }
New-Item -ItemType Directory -Path $output | Out-Null
$results = [Collections.Generic.List[object]]::new()
function Invoke-Worker([string]$Mode, [string]$Scenario, [string]$Phase, [string]$Folder) {
 $info = [Diagnostics.ProcessStartInfo]::new()
 $info.FileName = [IO.Path]::GetFullPath($GodotPath)
 $info.UseShellExecute = $false; $info.CreateNoWindow = $true
 $info.RedirectStandardOutput = $true; $info.RedirectStandardError = $true
 $arguments = @('--headless','--path',$PSScriptRoot)
 if ($Mode -ne 'contender') { $arguments += @('--script','res://tests/process_save_worker.gd','--',$Mode,$Scenario,$Phase,$Folder) }
 foreach ($arg in $arguments) { $info.ArgumentList.Add($arg) }
 $info.Environment['APPDATA'] = Join-Path $Folder 'profile'
 $process = [Diagnostics.Process]::new(); $process.StartInfo = $info
 $killed = $false
 $started = $false
 try {
  $null = $process.Start()
  $started = $true
  $stdout = $process.StandardOutput.ReadToEndAsync(); $stderr = $process.StandardError.ReadToEndAsync()
  $deadline = [DateTime]::UtcNow.AddSeconds(20)
  if ($Mode -eq 'write') {
   $marker = Join-Path $Folder 'ready'
   while (-not $process.HasExited -and -not (Test-Path -LiteralPath $marker) -and [DateTime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 20 }
   if (-not $process.HasExited -and (Test-Path -LiteralPath $marker)) {
    if ([IO.File]::ReadAllText($marker) -ne $Phase) { throw 'Barreira incorreta.' }
    if ($Scenario -eq 'profile') {
     Invoke-Worker 'contender' $Scenario $Phase $Folder
     if ($process.HasExited) { throw 'O dono do perfil encerrou antes de testar a disputa.' }
    }
    $process.Kill($true); $killed = $true
   }
  }
  if (-not $process.WaitForExit(20000)) { $process.Kill($true); $process.WaitForExit(); throw "Timeout $Mode" }
  $log = $stdout.GetAwaiter().GetResult() + "`n" + $stderr.GetAwaiter().GetResult()
  [IO.File]::WriteAllText((Join-Path $Folder "$Mode.log"),$log)
  if ($log -match 'SCRIPT ERROR:|Parse Error:|Compile Error:|FAIL process recovery|ObjectDB instances.*leaked|resources still in use') { throw "Erros no worker $Mode. $log" }
  if ($Mode -eq 'write') { if (-not $killed) { throw "Não atingiu a barreira $Phase. $log" } }
  elseif ($Mode -eq 'contender') {
   if ($process.ExitCode -ne 1 -or $log -notmatch 'Não foi possível abrir o perfil local') { throw "A segunda instância não foi bloqueada. $log" }
  }
  elseif ($process.ExitCode -ne 0) { throw "Worker $Mode falhou. $log" }
 } finally {
  if ($started -and -not $process.HasExited) { $process.Kill($true); $process.WaitForExit() }
  $process.Dispose()
 }
}
$cases = @(
 @('save','before-temp'), @('save','after-temp'), @('save','after-backup'),
 @('save','before-primary'), @('save','after-primary'), @('save','windows-gap'),
 @('bank','bank-intent'), @('bank','after-primary'), @('bank','bank-complete'),
 @('reward','bank-intent'), @('reward','after-primary'), @('reward','bank-complete'),
 @('delete','delete-intent'), @('delete','delete-first'),
 @('restore','restore-copy'), @('restore','restore-published'), @('profile','owner-held')
)
if ($ProfileOnly) { $cases = ,@('profile','owner-held') }
try {
 foreach ($case in $cases) {
  $scenario,$phase = $case
  $folder = Join-Path $output "$scenario-$phase"
  New-Item -ItemType Directory -Path (Join-Path $folder 'profile') | Out-Null
  [IO.File]::WriteAllText((Join-Path $folder 'fixture-only'),'disposable test data')
  try {
   foreach ($mode in @('prepare','write','verify')) { Invoke-Worker $mode $scenario $phase $folder }
   # A second fresh reader proves recovery is stable, rather than replayed twice.
   Move-Item -LiteralPath (Join-Path $folder 'verify.log') -Destination (Join-Path $folder 'verify-first.log')
   Invoke-Worker 'verify' $scenario $phase $folder
   $results.Add(@{scenario=$scenario;phase=$phase;passed=$true;termination='owned child Process.Kill'})
   Write-Host "PASS process interruption: $scenario/$phase"
  } catch {
   $results.Add(@{scenario=$scenario;phase=$phase;passed=$false;error="$($_.Exception.Message)"})
   Write-Warning "$scenario/$phase : $_"
  }
 }
} finally {
 @{results=@($results.ToArray());scope='isolated process termination; not power-loss or Steam isolation'} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $output 'results.json') -Encoding utf8
}
if (@($results | Where-Object { -not $_.passed }).Count -or $results.Count -ne $cases.Count) { throw 'Interrupções: consulte results.json e logs.' }
