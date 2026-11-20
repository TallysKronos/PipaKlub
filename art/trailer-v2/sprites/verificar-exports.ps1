$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$probeBitmap = [Drawing.Bitmap]::new(1,1)
$probeBitmap.Dispose()
$drawingReferences = @([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.FullName -match '^System\.(Drawing\.Common|Drawing\.Primitives|Private\.Windows\.[^,]+),' } | ForEach-Object { $_.Location })
$drawingReferences += @('System.Runtime','System.Collections')
Add-Type -ReferencedAssemblies $drawingReferences -TypeDefinition @'
using System;
using System.Drawing;
using System.Collections.Generic;
public class TrailerFrameQa {
 public int x0=999999,y0=999999,x1=-1,y1=-1,opaque,transparent,partial;
 public int colors;
 public string fingerprint;
}
public class TrailerRasterQa {
 public static TrailerFrameQa Frame(string path,int ox,int oy,int width,int height) {
  using(var bmp = new Bitmap(path)) {
   var r = new TrailerFrameQa(); var colors = new HashSet<int>();
   ulong hash=14695981039346656037UL;
   for(int y=0;y<height;y++) for(int x=0;x<width;x++) {
    var c=bmp.GetPixel(x+ox,y+oy); colors.Add(c.ToArgb());
    unchecked { hash=(hash^(uint)c.ToArgb())*1099511628211UL; }
    if(c.A==0)r.transparent++; else {
     if(c.A<255)r.partial++; else r.opaque++;
     if(c.A>=160){r.x0=Math.Min(r.x0,x);r.y0=Math.Min(r.y0,y);r.x1=Math.Max(r.x1,x);r.y1=Math.Max(r.y1,y);}
    }
   }
   r.colors=colors.Count;r.fingerprint=hash.ToString("x16");return r;
  }
 }
}
'@
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$reports = foreach ($name in @('eremor-rugido-v1','eremor-rugido-silhueta-v1','eremor-onda-rugido-v1','rabbito-rastro-v1')) {
 $pngPath = Join-Path $repoRoot "godot/assets/campaign/$name.png"
 $atlasPath = [IO.Path]::ChangeExtension($pngPath,'.json')
 $atlas = Get-Content -Raw -LiteralPath $atlasPath | ConvertFrom-Json
 $bitmap = [Drawing.Bitmap]::new($pngPath)
 $dimensions = @($bitmap.Width,$bitmap.Height)
 $bitmap.Dispose()
 $frames = @(); $frameIndex=0
 foreach($entry in $atlas.frames) {
  $rect=$entry.frame
  if($rect.x -lt 0 -or $rect.y -lt 0 -or ($rect.x+$rect.w) -gt $dimensions[0] -or ($rect.y+$rect.h) -gt $dimensions[1]) { throw "Recorte fora do PNG: $name frame $frameIndex" }
  $metrics=[TrailerRasterQa]::Frame($pngPath,$rect.x,$rect.y,$rect.w,$rect.h)
  if($metrics.transparent -eq 0 -or $metrics.x1 -lt 0) { throw "Quadro sem alpha ou vazio: $name frame $frameIndex" }
  $frames += @{index=$frameIndex;rect=$rect;duration_ms=$entry.duration;metrics=$metrics}
  $frameIndex++
 }
 $unique = @($frames.metrics.fingerprint | Sort-Object -Unique).Count
 if($unique -ne $frames.Count) { throw "Desenho duplicado em $name" }
 @{id=$name;image="godot/assets/campaign/$name.png";size=$dimensions;sha256=(Get-FileHash -Algorithm SHA256 -LiteralPath $pngPath).Hash.ToLower();frame_count=$frames.Count;distinct_frames=$unique;duration_ms=($atlas.frames.duration | Measure-Object -Sum).Sum;frames=$frames}
}
$reports | ConvertTo-Json -Depth 12 | Set-Content -Encoding utf8 -LiteralPath (Join-Path $PSScriptRoot 'qa-exports.json')
$reports | ForEach-Object { '{0}: {1} frames distintos, {2} ms, {3}x{4}' -f $_.id,$_.frame_count,$_.duration_ms,$_.size[0],$_.size[1] }
