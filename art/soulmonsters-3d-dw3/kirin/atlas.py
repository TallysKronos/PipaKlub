from pathlib import Path
from PIL import Image
import numpy as np
d=Path(__file__).resolve().parent
s=d/'referencias'
a=Image.new('RGBA',(1024,1024))
a.paste(Image.open(s/'perfil-esquerda.png'),(0,0))
a.paste(Image.open(s/'vista-01.png').resize((222,222),Image.Resampling.LANCZOS),(0,796))
a.paste(Image.open(s/'vista-01.png').crop((154,187,286,300)).resize((198,170)),(525,802))
from PIL import ImageDraw
brush=ImageDraw.Draw(a)
brush.rectangle((260,800,510,1014),fill='#992c38')
for c,poly in [('#65223b',[(260,802),(510,802),(510,849),(472,840),(431,853),(381,840),(330,853),(260,829)]),('#bc3940',[(260,865),(309,853),(359,862),(378,880),(356,912),(318,928),(279,909)]),('#a93239',[(365,878),(422,860),(461,866),(484,880),(463,914),(409,931),(366,915)]),('#73243a',[(260,918),(306,939),(346,933),(379,916),(366,938),(333,951),(295,952),(260,939)]),('#70223a',[(378,927),(435,935),(487,912),(510,898),(504,925),(461,950),(405,953)]),('#55243b',[(260,965),(314,976),(362,967),(401,976),(460,968),(510,947),(510,1014),(260,1014)])]:
 brush.polygon(poly,fill=c)
arr=np.array(a);valid=arr[:,:,3]>192
for i in range(9):
 old=valid.copy()
 for axis,step in [(0,1),(0,-1),(1,1),(1,-1)]:
  mask=np.roll(old,step,axis)&~valid
  arr[mask]=np.roll(arr,step,axis)[mask];valid|=mask
arr[~valid,:3]=[74,34,54]
Image.fromarray(arr[:,:,:3]).resize((512,512),Image.Resampling.BOX).save(d/'Kirin-atlas.png')
