$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies ([Drawing.Bitmap].Assembly.Location),([Drawing.Color].Assembly.Location),([Collections.Generic.List[int]].Assembly.Location) -TypeDefinition @"
using System;
using System.Drawing;
public static class DoberPixels {
    static readonly Color Ink = Color.FromArgb(255, 20, 20, 30);
    static readonly Color LightEdge = Color.FromArgb(255, 47, 40, 52);
    static readonly int[] Palette = {
        0x14141e, 0x252431, 0x353544, 0x4b4856, 0x69616a, 0x928188,
        0x4d3740, 0x7b5150, 0xa16a54, 0xc98e69, 0xe4ad83, 0xf4c49a, 0xffdfb6,
        0xb29b82, 0xd2bca2, 0xe8d3b6, 0xffebca, 0xfff7df,
        0x65342e, 0x933e2c, 0xbf562f, 0xe67435, 0xf09b50, 0xffc668,
        0x202940, 0x2d3b5c, 0x384d78, 0x49679a, 0x6389b6,
        0x254451, 0x387d88, 0x55b8bd, 0x95e1d9
    };
    static Color Shade(Color c) {
        int best = 0, distance = int.MaxValue;
        foreach (int rgb in Palette) {
            int r = c.R - ((rgb >> 16) & 255), g = c.G - ((rgb >> 8) & 255), b = c.B - (rgb & 255);
            int cost = 3*r*r + 4*g*g + 2*b*b;
            if (cost < distance) { best = rgb; distance = cost; }
        }
        return Color.FromArgb(unchecked((int)0xff000000) | best);
    }
    static bool Cord(Color c) {
        return c.A > 0 && c.R > c.G + 25 && c.G > c.B + 6 && c.R < 200;
    }
    public static void Frame(Bitmap input, Bitmap output, int left, int top, int width, int height, double scale, bool outline) {
        int columns = (int)Math.Ceiling(width * scale), rows = (int)Math.Ceiling(height * scale);
        var samples = new Color[columns, rows];
        var visited = new bool[columns, rows];
        var queue = new int[columns * rows];
        for (int y=0; y<rows; y++) for (int x=0; x<columns; x++) {
            int sx = Math.Min(width-1, (int)((x+.5)/scale)), sy = Math.Min(height-1, (int)((y+.5)/scale));
            Color c = input.GetPixel(left+sx, top+sy);
            if (c.A >= 175 || (c.A >= 100 && Cord(c))) samples[x,y] = Shade(c);
        }
        var sourceSamples = (Color[,])samples.Clone();
        for (int y=1; y<rows-1; y++) for (int x=1; x<columns-1; x++) {
            if (sourceSamples[x,y].A > 0) continue;
            for (int axis=-1; axis<=2; axis++) {
                int dx=axis==2?0:1, dy=axis==2?1:axis;
                Color near=sourceSamples[x-dx,y-dy], far=sourceSamples[x+dx,y+dy];
                if (Cord(near) && Cord(far)) { samples[x,y]=near; break; }
            }
        }
        for (int y=0; y<rows; y++) for (int x=0; x<columns; x++) {
            if (samples[x,y].A == 0 || visited[x,y]) continue;
            int end=1; queue[0]=y*columns+x; visited[x,y]=true;
            for (int index=0; index<end; index++) {
                int cx=queue[index]%columns, cy=queue[index]/columns;
                for (int ny=cy-1; ny<=cy+1; ny++) for (int nx=cx-1; nx<=cx+1; nx++) {
                    if (nx<0 || ny<0 || nx>=columns || ny>=rows || visited[nx,ny] || samples[nx,ny].A==0) continue;
                    visited[nx,ny]=true; queue[end++]=ny*columns+nx;
                }
            }
            if (end<5) for (int index=0; index<end; index++) samples[queue[index]%columns,queue[index]/columns]=Color.Empty;
        }
        for (int y=0; y<height; y++) for (int x=0; x<width; x++) {
            int px=(int)(x*scale), py=(int)(y*scale);
            Color color=samples[px,py];
            if (color.A==0) continue;
            if (outline) {
                bool above=py>0 && samples[px,py-1].A>0, below=py+1<rows && samples[px,py+1].A>0;
                bool west=px>0 && samples[px-1,py].A>0, east=px+1<columns && samples[px+1,py].A>0;
                int neighbors=(above?1:0)+(below?1:0)+(west?1:0)+(east?1:0);
                if (neighbors==3) color=(!below || !east)?Ink:LightEdge;
            }
            output.SetPixel(left+x,top+y,color);
        }
    }
}
"@
$root = (Resolve-Path 'godot').Path
$kit = Join-Path $root 'assets/mounts/doberman-c-v1'
$motion = Join-Path $root 'assets/mounts/doberman-animated-v1'
$out = (New-Item -ItemType Directory -Force (Join-Path $root 'assets/mounts/doberman-overworld-iso')).FullName
$settings = Get-Content (Join-Path $kit 'mount.json') -Raw | ConvertFrom-Json
$manifest = Get-Content (Join-Path $motion 'animations.json') -Raw | ConvertFrom-Json
$calibration = Get-Content (Join-Path $PSScriptRoot 'calibration.json') -Raw | ConvertFrom-Json
function Export-Atlas($source, $name, $regions, $scale, $outline) {
    $original = [Drawing.Bitmap]::new($source)
    $result = [Drawing.Bitmap]::new($original.Width, $original.Height, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        foreach ($rect in $regions) {
            [DoberPixels]::Frame($original,$result,$rect[0],$rect[1],$rect[2],$rect[3],$scale,$outline)
        }
        $result.Save((Join-Path $out $name),[Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $result.Dispose()
        $original.Dispose()
    }
}
$regions = $settings.directions.PSObject.Properties
Export-Atlas (Join-Path $kit 'idle-eight.png') 'idle-eight.png' ($regions | ForEach-Object {,$_.Value.rect}) $settings.scale $true
Export-Atlas (Join-Path $kit 'kael-rider-refined.png') 'kael-rider.png' ($regions | ForEach-Object {,$_.Value.riderRect}) $settings.riderScale $false
foreach ($entry in $manifest.animations.PSObject.Properties) {
    $clip = $entry.Value
    $name = "$($entry.Name).png"
    $w,$h = $clip.cell
    $rects = for ($i=0; $i -lt $clip.frames; $i++) {
        ,@((($i % $clip.columns)*$w), ([Math]::Floor($i / $clip.columns)*$h), $w, $h)
    }
    Export-Atlas (Join-Path $motion $name) $name $rects $clip.scale $true
    $alignment = $calibration.($entry.Name)
    $clip.scale *= $alignment.ratio
    $clip.pivot[1] += ($alignment.originalBottomOffset * $alignment.ratio - $alignment.bottomOffset) / $clip.scale
    $clip.texture = "res://assets/mounts/doberman-overworld-iso/$name"
}
$manifest | ConvertTo-Json -Depth 20 | Set-Content (Join-Path $out 'animations.json')
