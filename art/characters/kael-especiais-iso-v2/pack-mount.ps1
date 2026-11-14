$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$kit=Resolve-Path godot/assets/mounts/doberman-c-v1
$settings=Get-Content (Join-Path $kit 'mount.json') -Raw | ConvertFrom-Json
$src=[Drawing.Bitmap]::new((Join-Path $kit 'kael-rider-refined.png'))
$dst=[Drawing.Bitmap]::new($src.Width,$src.Height,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
foreach($direction in $settings.directions.PSObject.Properties){
 $ox,$oy,$w,$h=$direction.Value.riderRect
 $step=[int][Math]::Round(1.0/$settings.riderScale)
 for($y=0;$y -lt $h;$y+=$step){for($x=0;$x -lt $w;$x+=$step){
  $right=[Math]::Min($x+$step,$w);$bottom=[Math]::Min($y+$step,$h)
  $color=$src.GetPixel($ox+[int][Math]::Floor(($x+$right-1)/2),$oy+[int][Math]::Floor(($y+$bottom-1)/2))
  if($color.A -lt 154){continue}
  $r=($color.R -band 248);$g=($color.G -band 248);$b=($color.B -band 248)
  $flat=[Drawing.Color]::FromArgb(255,$r,$g,$b)
  for($py=$y;$py -lt $bottom;$py++){for($px=$x;$px -lt $right;$px++){$dst.SetPixel($ox+$px,$oy+$py,$flat)}}
 }}
}
$dst.Save((Join-Path $kit 'kael-rider-iso.png'),[Drawing.Imaging.ImageFormat]::Png)
$dst.Dispose();$src.Dispose()
