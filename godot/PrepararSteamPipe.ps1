param(
 [Parameter(Mandatory)][uint32]$AppId,
 [Parameter(Mandatory)][uint32]$DepotId,
 [Parameter(Mandatory)][string]$PackageDirectory,
 [Parameter(Mandatory)][string]$OutputDirectory
)
$ErrorActionPreference = 'Stop'
if ($AppId -eq 0 -or $DepotId -eq 0) { throw 'Informe os IDs do aplicativo e do depot Windows.' }
$package = (Resolve-Path -LiteralPath $PackageDirectory).Path
$output = [IO.Path]::GetFullPath($OutputDirectory)
if (Test-Path -LiteralPath $output) { throw 'Use uma pasta de saída nova.' }
$manifest = Get-Content -LiteralPath (Join-Path $package 'build-info.json') -Raw | ConvertFrom-Json
foreach ($name in @('Soulmonsters.exe','Soulmonsters.pck')) {
 $entry = @($manifest.files | Where-Object name -eq $name)
 if ($entry.Count -ne 1 -or (Get-FileHash -LiteralPath (Join-Path $package $name)).Hash -ne $entry[0].sha256) {
  throw "Pacote divergente do manifesto: $name"
 }
}
$licenses = @(Get-ChildItem -LiteralPath (Join-Path $package 'licenses') -File | Where-Object Extension -in @('.txt','.md'))
if ($licenses.Count -eq 0) { throw 'O pacote não contém arquivos de licença.' }
$content = Join-Path $output 'content'
New-Item -ItemType Directory -Path (Join-Path $content 'licenses'),(Join-Path $output 'scripts'),(Join-Path $output 'build-output') | Out-Null
foreach ($name in @('Soulmonsters.exe','Soulmonsters.pck','build-info.json','LEIA-ME.txt')) {
 Copy-Item -LiteralPath (Join-Path $package $name) -Destination $content
}
foreach ($license in $licenses) {
 Copy-Item -LiteralPath $license.FullName -Destination (Join-Path $content 'licenses')
}
@"
"AppBuild"
{
    "AppID" "$AppId"
    "Desc" "Soulmonsters Godot Windows - preview"
    "Preview" "1"
    "ContentRoot" "../content"
    "BuildOutput" "../build-output"
    "Depots"
    {
        "$DepotId"
        {
            "FileMapping"
            {
                "LocalPath" "*"
                "DepotPath" "."
                "Recursive" "1"
            }
        }
    }
}
"@ | Set-Content -LiteralPath (Join-Path $output "scripts/app_build_$AppId.vdf") -Encoding utf8NoBOM
Write-Host "Preview SteamPipe preparado em $output"
