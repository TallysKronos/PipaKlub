from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parent/'color-rig-v2'
im=Image.open(root/'dreamcatcher-source.png').convert('RGBA')
a=im.getchannel('A').point(lambda v:255 if v>20 else 0);bbox=a.getbbox();assert min(bbox[:2])>0 and bbox[2]<im.width and bbox[3]<im.height
im.crop(bbox).save(root/'body-dreamcatcher.png')
