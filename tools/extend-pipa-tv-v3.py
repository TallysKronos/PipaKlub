"""Append the TV-to-bedroom H3 shot to the preserved V2 film."""
import argparse
import importlib.util
import json
from pathlib import Path
import subprocess

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('pipa_tv_edit',ROOT/'tools/assemble-pipa-tv-v2.py')
edit=importlib.util.module_from_spec(spec)
spec.loader.exec_module(edit)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('bedroom_clip',type=Path)
    parser.add_argument('--version',choices=['v3','v4'],default='v3')
    args=parser.parse_args()
    sources=[ROOT/'art/pipa-tv-cinematic-v2/video-original/pipa-tv-v2-montagem-nativa.mp4',args.bedroom_clip.resolve(strict=True)]
    ff=edit.imageio_ffmpeg.get_ffmpeg_exe()
    metadata=[edit.probe(ff,p) for p in sources]
    if not all(m['audio'] for m in metadata):
        raise RuntimeError('Expected generated audio in both sources.')
    raster=(metadata[1].get('dimensions') or [864,480]) if args.version=='v4' else [864,480]
    width,height=raster
    out=ROOT/f'documentation/pipa-tv-cinematic-{args.version}'
    out.mkdir(parents=True,exist_ok=True)
    master=ROOT/f'art/pipa-tv-cinematic-{args.version}/video-original/pipa-tv-{args.version}-montagem-nativa.mp4'
    master.parent.mkdir(parents=True,exist_ok=True)
    common=[ff,'-nostdin','-hide_banner','-loglevel','error','-y','-filter_threads','1','-filter_complex_threads','1']
    filters=[]
    for i,m in enumerate(metadata):
        filters.append(f'[{i}:v]scale={width}:{height}:force_original_aspect_ratio=decrease,'
                       f'pad={width}:{height}:(ow-iw)/2:(oh-ih)/2,setsar=1,format=yuv420p,setpts=PTS-STARTPTS,fps=24,settb=AVTB[v{i}]')
        filters.append(f'[{i}:a]aresample=48000,aformat=channel_layouts=stereo,apad,atrim=duration={m["seconds"]},asetpts=PTS-STARTPTS[a{i}]')
    filters.extend([f'[v0][v1]xfade=transition=fade:duration=0.16:offset={metadata[0]["seconds"]-.16},fps=24[video]',
                    '[a0][a1]acrossfade=d=0.16:c1=tri:c2=tri[audio]'])
    subprocess.run(common+['-i',str(sources[0]),'-i',str(sources[1]),'-filter_complex',';'.join(filters),
                           '-map','[video]','-map','[audio]','-c:v','libx264','-threads','2','-preset','medium',
                           '-crf','18','-pix_fmt','yuv420p','-c:a','aac','-b:a','160k','-movflags','+faststart',str(master)],check=True)
    scale='scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2'
    preview=out/f'pipa-tv-abertura-completa-{args.version}.mp4'
    runtime=ROOT/f'godot/assets/campaign/cinematics/pipa-tv-abertura-{args.version}.ogv'
    subprocess.run(common+['-i',str(master),'-vf',scale,'-c:v','libx264','-threads','2','-crf','18','-c:a','copy',
                           '-movflags','+faststart',str(preview)],check=True)
    subprocess.run(common+['-i',str(master),'-vf',scale,'-c:v','libtheora','-q:v','7','-c:a','libvorbis','-q:a','4',str(runtime)],check=True)
    subprocess.run(common+['-i',str(sources[1]),'-vf','fps=1,scale=400:-1,tile=4x2','-frames:v','1',str(out/'kael-planos.png')],check=True)
    subprocess.run(common+['-i',str(master),'-vf','fps=0.55,scale=320:-1,tile=4x4','-frames:v','1',str(out/'planos.png')],check=True)
    for name,seconds in [('poster',metadata[0]['seconds']+3),('quarto-final',sum(m['seconds'] for m in metadata)-.5)]:
        subprocess.run(common+['-ss',str(seconds),'-i',str(master),'-frames:v','1',str(out/f'{name}.png')],check=True)
    report={'sources':[{'path':str(p.relative_to(ROOT)),**m} for p,m in zip(sources,metadata)],
            'transition_seconds':.16,'film':str(preview.relative_to(ROOT)),
            'master_metadata':edit.probe(ff,master),'runtime':str(runtime.relative_to(ROOT)),
            'edit_raster':raster,
            'resolution_note':'V2 base is 864x480/24fps. V4 edit uses the bedroom clip native raster; older V3 uses 864x480. 1280x720 exports are resized, not native HD.'}
    (out/'montagem.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(report,ensure_ascii=False,indent=2))


if __name__=='__main__':
    main()
