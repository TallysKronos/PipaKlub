from pathlib import Path
from PIL import Image, ImageDraw
D=Path(__file__).parent
atlas=Image.new('RGB',(1536,1280),'#ffe3b9')
atlas.paste(Image.open(D/'Rabbito-vistas.png').convert('RGB'))
p=ImageDraw.Draw(atlas)
def panel(points,color):p.polygon([(x+300,h+790) for x,h in points],fill=color)
# Face wraps in a dedicated painted island, clear of contour lines from the turnaround.
p.rectangle((489,982,706,1132),fill='#ffe5bf')
panel([(193,284),(206,282),(242,305),(289,318),(315,318),(359,303),(403,277),(410,345),(189,345)],'#f0ca9c')
panel([(201,232),(249,214),(299,205),(353,215),(389,230),(335,226),(299,216),(249,229)],'#fff0d0')
for sign in (-1,1):
 def face(poly,color):panel([(299+sign*x,h) for x,h in poly],color)
 face([(25,264),(38,261),(48,261),(44,265),(42,283),(34,292),(27,288)],'#241921')
 face([(29,266),(36,264),(39,264),(33,268)],'#533635')
 face([(26,260),(30,253),(40,250),(42,253),(33,259)],'#c78d55')
 face([(65,255),(85,244),(97,245),(103,272),(82,284),(72,287),(77,276)],'#108c94')
face([(-10,295),(10,295),(0,304)],'#452921')
face([(-6,296),(6,296),(0,300)],'#d5934c')
for sg in [-1,1]:p.line([(599,1092),(599,1097),(599+sg*6,1101),(599+sg*13,1098)],fill='#422922',width=2)
# Paws, silk sidewalls and thick sleeves sample uninterrupted pigment islands.
p.rectangle((750,1024,1000,1160),fill='#ffdfb3')
for c,poly in [('#fff1d1',[(750,1024),(957,1024),(928,1054),(845,1066),(770,1051)]),('#f1ca9f',[(750,1110),(828,1128),(897,1116),(962,1096),(1000,1103),(1000,1160),(750,1160)])]:
 p.polygon(poly,fill=c)
p.rectangle((1001,1024,1220,1170),fill='#138a92')
p.polygon([(1010,1082),(1090,1034),(1140,1031),(1120,1055),(1065,1074)],fill='#22a9a8')
p.polygon([(1002,1127),(1071,1110),(1132,1122),(1194,1095),(1220,1099),(1220,1170),(1002,1170)],fill='#08737f')
# Feet and haunches share a continuous outer marking with a cream interruption at the ankle.
for left,foot in [(1226,False),(1380,True)]:
 p.rectangle((left,1028,left+142,1254),fill='#ffdfb4')
 def island(col,pts):
  p.polygon([(left+x,1028+y) for x,y in pts],fill=col)
 island('#fff0d2',[(0,0),(90,0),(72,32),(49,50),(12,64),(0,55)])
 island('#ebc299',[(0,148),(36,171),(70,162),(95,125),(131,108),(142,126),(142,225),(0,225)])
 if not foot:
  island('#116775',[(79,0),(142,0),(142,221),(114,213),(94,181),(111,149),(118,115),(105,94),(110,67),(86,39)])
  island('#179ba2',[(84,0),(142,0),(142,126),(126,151),(117,161),(121,116),(110,92),(115,64),(96,48)])
  island('#35b6b6',[(111,5),(141,3),(141,52),(131,77),(124,65),(128,45)])
 else:
  island('#096372',[(64,0),(142,0),(142,224),(70,224),(73,195),(88,150),(99,100),(88,55)])
  island('#169da1',[(80,0),(142,0),(142,161),(125,184),(85,205),(98,151),(111,100),(96,51)])
  island('#36b7b7',[(119,0),(142,0),(142,95),(129,127),(126,87)])
atlas.resize((768,640),Image.Resampling.BOX).save(D/'Rabbito-atlas.png')
