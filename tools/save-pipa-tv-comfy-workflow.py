"""Save this project's new workflow in the local ComfyUI workflow library."""
from pathlib import Path
from urllib.request import Request,urlopen
from urllib.error import HTTPError
from urllib.parse import quote
root=Path(__file__).resolve().parents[1]
workflow=root/'art/pipa-tv-cinematic-v1/pipa-tv-h3-local.json'
name=quote('workflows/PipaTV - Duelo H3 local.json',safe='')
request=Request('http://127.0.0.1:8188/userdata/'+name+'?overwrite=false',data=workflow.read_bytes(),headers={'Content-Type':'application/json'},method='POST')
try:
 with urlopen(request,timeout=20) as response:print(response.read().decode())
except HTTPError as error:
 if error.code==409:print('Existing workflow preserved; project copy remains available.')
 else:raise
