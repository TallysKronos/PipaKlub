"""Package the selected comic pages without raster editing."""
from pathlib import Path
import hashlib
import json
import zipfile
from PIL import Image
from reportlab.pdfgen import canvas
from reportlab.lib.utils import ImageReader
from pypdf import PdfReader

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
PDF=ROOT/'output/pdf/PipaKlub-Fios-do-Principio-Paginas-01-08-v1.pdf'
ZIP=ROOT/'output/PipaKlub-Fios-do-Principio-Paginas-01-08-v1.zip'
PDF.parent.mkdir(parents=True,exist_ok=True)
images=[HERE/f'pagina-{n:02d}.png' for n in range(1,9)]
assert all(p.is_file() for p in images)
records=[]
book=canvas.Canvas(str(PDF),pageCompression=1)
book.setTitle('PipaKlub: Fios do Princípio — páginas 01 a 08')
book.setAuthor('PipaKlub')
book.setSubject('Primeira edição ilustrada; arte gerada com image_gen e diálogos em português.')
for n,path in enumerate(images,1):
    with Image.open(path) as image:
        width,height=image.size
        image.verify()
    pw=512
    ph=pw*height/width
    book.setPageSize((pw,ph))
    key=f'page-{n:02d}'
    book.bookmarkPage(key)
    book.addOutlineEntry(f'Página {n:02d}',key,0,False)
    book.drawImage(ImageReader(str(path)),0,0,width=pw,height=ph,mask='auto')
    book.showPage()
    records.append({'page':n,'file':path.name,'width':width,'height':height,
                    'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
book.save()
assert len(PdfReader(PDF).pages)==8
manifest={'edition':'v1','pages':records,'tool':'image_gen integrada','reading_order':'left-to-right, top-to-bottom',
          'pdf':str(PDF.relative_to(ROOT)).replace('\\','/'),'status':'primeira edição ilustrada para revisão autoral'}
(HERE/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
with zipfile.ZipFile(ZIP,'w',compression=zipfile.ZIP_DEFLATED) as archive:
    for path in images:
        archive.write(path,path.name)
    for filename in ['README.md','prompts.json','refinamentos.json','manifest.json','build_leitura.py']:
        archive.write(HERE/filename,filename)
    archive.write(PDF,PDF.name)
    assert archive.testzip() is None
print(json.dumps({'pdf':str(PDF),'zip':str(ZIP),'pages':records},ensure_ascii=False))
