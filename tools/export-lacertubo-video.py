"""Preserve the native H3 result, make playback exports and a frame-review sheet."""
import argparse,importlib.util,json,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('video_edit',ROOT/'tools/assemble-pipa-tv-v2.py')
edit=importlib.util.module_from_spec(spec);spec.loader.exec_module(edit)
parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('source',type=Path)
args=parser.parse_args();source=args.source.resolve(strict=True)
ff=edit.imageio_ffmpeg.get_ffmpeg_exe()
folder=ROOT/'documentation/qa/lacertubo-video-v1';folder.mkdir(parents=True,exist_ok=True)
common=[ff,'-nostdin','-hide_banner','-loglevel','error','-y','-filter_threads','1']
preview=folder/'lacertubo-cinematic.mp4'
subprocess.run(common+['-i',str(source),'-vf','scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2',
 '-c:v','libx264','-threads','2','-crf','18','-c:a','aac','-b:a','160k','-movflags','+faststart',str(preview)],check=True)
subprocess.run(common+['-i',str(source),'-vf','fps=1.5,scale=400:-1,tile=4x3','-frames:v','1',str(folder/'planos.png')],check=True)
for name,second in [('abertura',0),('passos',3.5),('rugido',6),('final',7.8)]:
 subprocess.run(common+['-ss',str(second),'-i',str(source),'-frames:v','1',str(folder/(name+'.png'))],check=True)
movie=ROOT/'godot/assets/campaign/cinematics/lacertubo-patio-h3-v1.ogv'
subprocess.run(common+['-i',str(source),'-c:v','libtheora','-q:v','9','-pix_fmt','yuv420p','-c:a','libvorbis','-q:a','5',str(movie)],check=True)
report={'source':str(source.relative_to(ROOT)),'native':edit.probe(ff,source),
 'preview':str(preview.relative_to(ROOT)),'preview_metadata':edit.probe(ff,preview),
 'game_movie':str(movie.relative_to(ROOT)),'game_metadata':edit.probe(ff,movie),
 'single_generation':True,'native_hd':False,'editing':'Proportional upscale and encoding only; no cuts, holds or dissolves.'}
(folder/'metadados.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False,indent=2))
