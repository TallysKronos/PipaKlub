Add-Type -AssemblyName System.Drawing
$source=[Drawing.Bitmap]::new((Resolve-Path 'art/characters/kael/overworld-isometrico-v2/cabecas-fonte.png').Path)
$out=(Resolve-Path 'godot/assets/kael-video/iso-v2').Path
$headWidths=@(27,27,25,27,27)
$headHeight=31
$headAngles=@()
$headMap=@(0,1,2,3,4,3,2,1)
$headAnchor=@(13,15,15,13,13,13,9,11)
$targetPalette=@('10101c','171b2b','202637','28334c','303d5b','3b4b70','465a86','5974a1','758db5','15283f','1d3963','254a80','335d9a','526f9d','474553','595d72','6c748d','c7bcb3','f3dfcc','fff1d8','523137','8b5c51','b87a63','d99b7d','edb58f','ffd5a5','277287','399eab','67d3d3','84684b') | ForEach-Object {[Drawing.ColorTranslator]::FromHtml("#$_")}
$quantized=@{}
function Write-Pixel($image,[int]$x,[int]$y,$pixel){
 if($pixel.A -lt 150 -or $x -lt 0 -or $x -ge $image.Width -or $y -lt 0 -or $y -ge $image.Height){return}
 $key=$pixel.ToArgb()
 if(!$quantized.ContainsKey($key)){
  $winner=$targetPalette[0];$distance=[double]::PositiveInfinity
  foreach($color in $targetPalette){
   $dr=[int]$pixel.R-$color.R;$dg=[int]$pixel.G-$color.G;$db=[int]$pixel.B-$color.B
   $score=2*$dr*$dr+3*$dg*$dg+$db*$db
   if($score -lt $distance){$distance=$score;$winner=$color}
  }
  $quantized[$key]=$winner
 }
 $image.SetPixel($x,$y,$quantized[$key])
}
for($i=0;$i -lt 5;$i++){
 $left=[int][Math]::Floor($source.Width*$i/5)
 $right=[int][Math]::Floor($source.Width*($i+1)/5)
 $l=$right;$r=-1;$t=$source.Height;$b=-1
 for($y=0;$y -lt $source.Height;$y++){for($x=$left;$x -lt $right;$x++){
  if($source.GetPixel($x,$y).A -ge 180){$l=[Math]::Min($l,$x);$r=[Math]::Max($r,$x);$t=[Math]::Min($t,$y);$b=[Math]::Max($b,$y)}
 }}
 if($r -lt $l -or $l -le $left -or $r -ge $right-1){throw "Bad head crop $i"}
 $w=$headWidths[$i]
 $head=[Drawing.Bitmap]::new($w,$headHeight)
 for($y=0;$y -lt $headHeight;$y++){for($x=0;$x -lt $w;$x++){
  $pixel=$source.GetPixel($l+[int][Math]::Floor(($x+.5)*($r-$l+1)/$w),$t+[int][Math]::Floor(($y+.5)*($b-$t+1)/$headHeight))
  Write-Pixel $head $x $y $pixel
 }}
 $headAngles+=$head
}
$source.Dispose()

$cutOffsets=@{
 idle=@(32,32,31,30,30,30,31,32)
 walk=@(32,32,31,31,31,31,31,32)
 run=@(34,32,31,31,30,31,31,32)
}
foreach($action in 'idle','walk','run'){
 $old=[Drawing.Bitmap]::new((Resolve-Path "godot/assets/kael-video/kael-$action-eight.png").Path)
 $sheet=[Drawing.Bitmap]::new(512,768,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
 for($row=0;$row -lt 8;$row++){for($frame=0;$frame -lt 8;$frame++){
  $ax=$frame*64;$ay=$row*96
  $top=96
  for($y=0;$y -lt 50;$y++){
   for($x=0;$x -lt 64;$x++){if($old.GetPixel($ax+$x,$ay+$y).A -ge 150){$top=$y;break}}
   if($top -lt 96){break}
  }
  $cut=$top+$cutOffsets[$action][$row]
  $midpoints=@()
  foreach($y in $cut..($cut+2)){
   $xs=@()
   for($x=0;$x -lt 64;$x++){if($old.GetPixel($ax+$x,$ay+$y).A -ge 150){$xs+=$x}}
   $midpoints+=$xs[[int][Math]::Floor($xs.Count/2)]
  }
  $neck=($midpoints | Sort-Object)[1]
  $height=[int][Math]::Round((94-$cut)*.80)
  $destTop=94-$height
  for($y=$destTop;$y -lt 96;$y++){for($x=0;$x -lt 64;$x++){
   $sy=if($y -lt 94){$cut+[int][Math]::Floor(($y-$destTop+.5)*(94-$cut)/$height)}else{$y}
   $pixel=$old.GetPixel($ax+$x,$ay+$sy)
   Write-Pixel $sheet ($ax+$x) ($ay+$y) $pixel
  }}
  $head=$headAngles[$headMap[$row]]
  $headTop=$destTop-$headHeight+4
  for($y=0;$y -lt $headHeight;$y++){for($x=0;$x -lt $head.Width;$x++){
   $srcX=if($row -ge 5){$head.Width-1-$x}else{$x}
   $color=$head.GetPixel($srcX,$y)
   if($color.A){$sheet.SetPixel($ax+$neck-$headAnchor[$row]+$x,$ay+$headTop+$y,$color)}
  }}
 }}
 if($action -eq 'idle'){
  for($row=0;$row -lt 8;$row++){
   for($frame=1;$frame -lt 8;$frame++){
    for($y=$row*96+78;$y -lt ($row+1)*96;$y++){
     for($x=0;$x -lt 64;$x++){$sheet.SetPixel($frame*64+$x,$y,$sheet.GetPixel($x,$y))}
    }
   }
  }
 }
 $sheet.Save((Join-Path $out "$action.png"),[Drawing.Imaging.ImageFormat]::Png)
 $sheet.Dispose();$old.Dispose()
}
foreach($head in $headAngles){$head.Dispose()}
