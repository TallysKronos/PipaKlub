"""Add the new film workflows to this machine's local ComfyUI library."""
from pathlib import Path
from urllib.error import HTTPError
from urllib.parse import quote
from urllib.request import Request, urlopen

root = Path(__file__).resolve().parents[1]
folder = root / 'art/pipa-tv-cinematic-v2/workflows'
for stem, label in [('01-locutor', '01 Locutor'), ('02-pipeiros', '02 Pipeiros'), ('03-batalha', '03 Batalha')]:
    filename = quote(f'workflows/PipaTV V2 - {label} H3 local.json', safe='')
    request = Request('http://127.0.0.1:8188/userdata/' + filename + '?overwrite=false',
                      data=(folder/f'{stem}-h3-local.json').read_bytes(),
                      headers={'Content-Type':'application/json'}, method='POST')
    try:
        with urlopen(request, timeout=20) as response:
            print(label, response.status)
    except HTTPError as error:
        if error.code == 409:
            print(label, 'existing library entry preserved')
        else:
            raise
