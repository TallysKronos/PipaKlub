from pathlib import Path
import subprocess,json
from PIL import Image,ImageDraw
ROOT=Path(r'C:/Users/user/produto/pipa-club-integracao-atualizada')
out=Path(__file__).parent
video=out.parent/'battle-attack-h3-v1/video-original/alvacordo-attack.mp4'
ffmpeg=Path(r'C:/Users/user/produto/pipa-club-pip88/tmp/video-encoder/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe')
times=[1.30,1.43,1.53,1.65,3.10,3.25,3.45,3.70,3.95,4.20]
sheet=Image.new('RGB',(5*256,2*282),'#d3d9d9');d=ImageDraw.Draw(sheet)
for i,t in enumerate(times):
 path=out/'references'/f'pose-{i:02d}.png'
 subprocess.run([str(ffmpeg),'-hide_banner','-loglevel','error','-y','-ss',str(t),'-i',str(video),'-frames:v','1',str(path)],check=True)
 im=Image.open(path).convert('RGB');im.thumbnail((256,256),Image.Resampling.NEAREST)
 x=(i%5)*256;y=(i//5)*282;sheet.paste(im,(x,y));d.text((x+5,y+259),str(i)+' / '+str(t)+'s',fill='#112930')
sheet.save(out/'review/poses-selecionadas.png')
(out/'references/tempos.json').write_text(json.dumps(times))
print('10 raw video poses extracted at a fixed512x512 canvas')

