param([string]$Output='godot/assets/kael-video/iso-v2',[string]$Source='art/characters/kael-especiais-iso-v2/fontes')
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$format=[Drawing.Imaging.PixelFormat]::Format32bppArgb
$reference=[Drawing.Bitmap]::new((Resolve-Path "$Output/idle.png").Path)
function Open-Strip($name) { [Drawing.Bitmap]::new((Resolve-Path "$Source/$name.png").Path) }
function Measure-Frame($bitmap,$x0,$y0,$x1,$y1) {
 $left=$x1; $right=-1; $top=$y1; $bottom=-1
 for($y=$y0;$y -lt $y1;$y++){for($x=$x0;$x -lt $x1;$x++){
  if($bitmap.GetPixel($x,$y).A -ge 160){$left=[Math]::Min($x,$left);$right=[Math]::Max($x,$right);$top=[Math]::Min($y,$top);$bottom=[Math]::Max($y,$bottom)}
 }}
 if($right -lt $left){throw 'Empty animation frame'}
 if($left -eq $x0 -or $right -eq $x1-1 -or $top -eq $y0 -or $bottom -eq $y1-1){throw "Art touches frame boundary ($x0,$y0)"}
 [Drawing.Rectangle]::new($left,$top,$right-$left+1,$bottom-$top+1)
}
function Write-Frame($atlas,$bitmap,$bounds,$column,$row,$cellHeight,$height,$mirror) {
 $width=[Math]::Max(1,[int][Math]::Round($bounds.Width*$height/$bounds.Height))
 if($width -gt 92 -or $height -gt ($cellHeight-2)){throw "Oversized pose ${width}x${height}"}
 $offsetX=96*$column+[int][Math]::Floor((96-$width)/2)
 $offsetY=$cellHeight*($row+1)-2-$height
 for($y=0;$y -lt $height;$y++){for($x=0;$x -lt $width;$x++){
  $sx=$width-1-$x;if(!$mirror){$sx=$x}
  $color=$bitmap.GetPixel($bounds.X+[int][Math]::Floor(($sx+.5)*$bounds.Width/$width),$bounds.Y+[int][Math]::Floor(($y+.5)*$bounds.Height/$height))
  if($color.A -ge 145){$atlas.SetPixel($offsetX+$x,$offsetY+$y,[Drawing.Color]::FromArgb(255,$color.R,$color.G,$color.B))}
 }}
}
function Write-Idle($atlas,$column,$row,$cellHeight) {
 for($y=0;$y -lt 96;$y++){for($x=0;$x -lt 64;$x++){
  $atlas.SetPixel($column*96+$x+16,($row+1)*$cellHeight-96+$y,$reference.GetPixel($x,$row*96+$y))
 }}
}
function Write-Strip($atlas,$sheet,$row,$cellHeight,$heights,$mirror,$item) {
 $idleTop=96; $idleBottom=-1
 for($iy=0;$iy -lt 96;$iy++){for($ix=0;$ix -lt 64;$ix++){if($reference.GetPixel($ix,$row*96+$iy).A -ge 160){$idleTop=[Math]::Min($idleTop,$iy);$idleBottom=$iy}}}
 $referenceHeight=$idleBottom-$idleTop+1
 for($i=0;$i -lt 6;$i++){
  if($i -eq 5 -or ($item -and $i -eq 0)){Write-Idle $atlas $i $row $cellHeight; continue}
  $col=$i%3;$line=[Math]::Floor($i/3)
  $bounds=Measure-Frame $sheet ([Math]::Floor($col*$sheet.Width/3)) ([Math]::Floor($line*$sheet.Height/2)) ([Math]::Floor(($col+1)*$sheet.Width/3)) ([Math]::Floor(($line+1)*$sheet.Height/2))
  Write-Frame $atlas $sheet $bounds $i $row $cellHeight ([int][Math]::Round($heights[$i]*$referenceHeight/86.0)) $mirror
 }
}
$jump=[Drawing.Bitmap]::new(576,896,$format)
$item=[Drawing.Bitmap]::new(576,144,$format)
$directions='s','se','e','ne','n','ne','e','se'
for($row=0;$row -lt 8;$row++){
 $sheet=Open-Strip "jump-$($directions[$row])"
 try {Write-Strip $jump $sheet $row 112 @(72,88,71,86,73,86) ($row -in 1,2,3) $false} finally {$sheet.Dispose()}
}
$sheet=Open-Strip 'item'
try {Write-Strip $item $sheet 0 144 @(86,86,87,89,86,86) $false $true} finally {$sheet.Dispose()}
foreach($entry in @(@($jump,'jump'),@($item,'item'))){
 $ms=[IO.MemoryStream]::new()
 try {$entry[0].Save($ms,[Drawing.Imaging.ImageFormat]::Png);[IO.File]::WriteAllBytes((Join-Path (Resolve-Path $Output).Path "$($entry[1]).png"),$ms.ToArray())} finally {$ms.Dispose();$entry[0].Dispose()}
}
$reference.Dispose()
