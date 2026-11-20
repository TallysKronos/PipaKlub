param([string]$Godot)
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
if(-not $Godot){
    $bundled=Join-Path ([IO.Directory]::GetParent($repo).FullName) 'pipa-club-pip88/godot/Godot_v4.7.2-stable_win64.exe'
    if(Test-Path -LiteralPath $bundled){$Godot=$bundled}
    else{
        $command=Get-Command godot -ErrorAction SilentlyContinue
        if($command){$Godot=$command.Source}
    }
}
if(-not $Godot -or -not(Test-Path -LiteralPath $Godot)){
    throw 'Informe o executável com -Godot C:/caminho/Godot.exe'
}
Start-Process -FilePath $Godot -ArgumentList @('--path',"`"$repo/godot`"",'res://scenes/overworld_pixel_compare.tscn') -WindowStyle Hidden
