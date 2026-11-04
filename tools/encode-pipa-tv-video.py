"""Package a reviewed local H3 output for the native Godot prologue."""
import argparse
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tmp/video-encoder'))
import imageio_ffmpeg

parser=argparse.ArgumentParser()
parser.add_argument('source',type=Path)
args=parser.parse_args()
source=args.source.resolve(strict=True)
ffmpeg=imageio_ffmpeg.get_ffmpeg_exe()
destination=ROOT/'godot/assets/campaign/cinematics'
destination.mkdir(parents=True,exist_ok=True)
preview=ROOT/'documentation/pipa-tv-cinematic-v1'
preview.mkdir(parents=True,exist_ok=True)
scale='scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2'
commands=[
 ['-i',str(source),'-vf',scale,'-r','24','-c:v','libtheora','-q:v','7','-c:a','libvorbis','-q:a','4',str(destination/'pipa-tv-duelo-h3.ogv')],
 ['-i',str(source),'-vf',scale,'-r','24','-c:v','libx264','-crf','18','-preset','medium','-pix_fmt','yuv420p','-c:a','aac','-b:a','160k','-movflags','+faststart',str(preview/'pipa-tv-duelo-h3.mp4')],
 ['-ss','1','-i',str(source),'-frames:v','1',str(preview/'poster.png')],
 ['-i',str(source),'-vf','fps=1.2,scale=320:-1,tile=4x2','-frames:v','1',str(preview/'planos.png')],
]
for command in commands:
 subprocess.run([ffmpeg,'-hide_banner','-loglevel','error','-y',*command],check=True)
print('Godot OGV, review MP4, poster and shot sheet written.')
