param(
 [string]$GodotPath = $env:GODOT_PATH,
 [string]$OutputDirectory = '',
 [int]$TimeoutSeconds = 180,
 [switch]$SkipImport
)
$ErrorActionPreference = 'Stop'
if (-not $GodotPath -or -not (Test-Path -LiteralPath $GodotPath)) { throw 'Informe -GodotPath com o executável Godot 4.7.2.' }
$project = $PSScriptRoot
if (-not $OutputDirectory) { $OutputDirectory = Join-Path ([IO.Path]::GetTempPath()) ('soulmonsters-validation-' + [guid]::NewGuid().ToString('N')) }
$output = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Force $output | Out-Null
$results = [Collections.Generic.List[object]]::new()
function Invoke-Check([string]$Name, [string[]]$Arguments, [int]$Limit, [bool]$Required = $true) {
 $info = [Diagnostics.ProcessStartInfo]::new()
 $info.FileName = [IO.Path]::GetFullPath($GodotPath)
 $info.UseShellExecute = $false
 $info.CreateNoWindow = $true
 $info.RedirectStandardOutput = $true
 $info.RedirectStandardError = $true
 foreach ($argument in $Arguments) { $info.ArgumentList.Add($argument) }
 # Each test gets a private profile; never touch the developer/player campaign.
 $profile = Join-Path $output "profiles/$Name"
 New-Item -ItemType Directory -Force $profile | Out-Null
 $info.Environment['APPDATA'] = $profile
 $process = [Diagnostics.Process]::new()
 $process.StartInfo = $info
 Write-Host "Running $Name"
 $null = $process.Start()
 $stdout = $process.StandardOutput.ReadToEndAsync()
 $stderr = $process.StandardError.ReadToEndAsync()
 $timedOut = -not $process.WaitForExit($Limit * 1000)
 if ($timedOut) { $process.Kill($true); $process.WaitForExit() }
 $log = $stdout.GetAwaiter().GetResult() + "`n" + $stderr.GetAwaiter().GetResult()
 [IO.File]::WriteAllText((Join-Path $output "$Name.log"), $log)
 $failed = $timedOut -or $process.ExitCode -ne 0 -or $log -match '(?m)SCRIPT ERROR:|Parse Error:|Compile Error:'
 if ($Name.StartsWith('import') -and $log -match '(?m)^ERROR:') { $failed = $true }
 if ($Name -in @('title_menu_checks','menu_lifecycle_checks','save_feedback_checks','autosave_recovery_checks','autosave_slots_checks','campaign_reset_checks','partner_bank_checks') -and $log -match 'ObjectDB instances.*leaked|resources still in use|Leaked instance:') { $failed = $true }
 $results.Add(@{name=$Name;exitCode=$process.ExitCode;timedOut=$timedOut;passed=(-not $failed);required=$Required})
 $process.Dispose()
 if ($failed) { Write-Warning "$Name reported errors (required=$Required). See $output/$Name.log"; Write-Host ($log -split "`n" | Select-Object -Last 15 | Out-String) }
 else { Write-Host "$Name passed" }
 return (-not $failed)
}
$version = & $GodotPath --version
if ($LASTEXITCODE -ne 0 -or "$version" -notmatch '^4\.7\.2\.stable') { throw "Godot inesperado: $version; use 4.7.2 stable." }
try {
 if (-not $SkipImport) {
  # The editor resolves the custom theme before its first font/image import.
  # Retain bootstrap diagnostics, then require a second, clean import to pass.
  $null = Invoke-Check 'import-bootstrap' @('--headless','--path',$project,'--editor','--import') 600 $false
  if ($results[-1].timedOut -or $results[-1].exitCode -ne 0) { throw 'A preparação inicial da importação falhou.' }
  if (-not (Invoke-Check 'import' @('--headless','--path',$project,'--editor','--import') 600)) { throw 'A importação de recursos falhou.' }
 }
 $suites = @(
  'overworld_checks', 'morro_map_checks', 'campaign_checks', 'controls_checks',
  'endgame_story_checks', 'endgame_staging_checks', 'release_travel_checks',
  'notice_after_load_checks', 'district_names_checks', 'flower_epilogue_checks',
  'city_restoration_checks', 'champions_meeting_checks',
  'trovareta_presentation_checks', 'trovareta_release_checks',
  'beira_canal_flow_checks', 'title_menu_checks', 'menu_lifecycle_checks',
  'save_resilience_checks', 'save_feedback_checks', 'autosave_recovery_checks', 'autosave_slots_checks', 'campaign_reset_checks', 'partner_bank_checks'
 )
 foreach ($suite in $suites) {
  $limit = if ($suite -eq 'overworld_checks') { [Math]::Max(600, $TimeoutSeconds) } else { $TimeoutSeconds }
  $null = Invoke-Check $suite @('--headless','--path',$project,'--script',"res://tests/$suite.gd") $limit
 }
 $null = Invoke-Check 'export_resources' @('--headless','--path',$project,'--script','res://scripts/diagnostics/export_resources.gd') $TimeoutSeconds
} finally {
 @{engine="$version";results=@($results.ToArray())} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $output 'results.json') -Encoding utf8
 Write-Host "Validation logs: $output"
}
if (@($results | Where-Object { $_.required -and -not $_.passed }).Count) { throw 'Godot validation failed. Consulte results.json e os logs.' }
