"""Read-only research inventory; no game or source-site writes."""
import html
import json
import re
import time
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
BASE = 'https://archives.bulbagarden.net'
START = BASE + '/wiki/Category:Game_concept_art'

def fetch(url):
    request = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (Soulmonsters concept reference research)'})
    with urllib.request.urlopen(request, timeout=45) as response:
        return response.read().decode('utf-8')

def links(markup):
    for match in re.finditer(r'<a\b([^>]*)>(.*?)</a>', markup, re.S):
        attrs = dict(re.findall(r'([\w-]+)="([^"]*)"', match[1]))
        yield attrs, html.unescape(re.sub('<[^>]+>', '', match[2])).strip()

def main():
    files, categories, pages = {}, {}, []
    url = START
    while url and url not in pages:
        markup = fetch(url)
        pages.append(url)
        for attrs, label in links(markup):
            href = html.unescape(attrs.get('href', ''))
            title = html.unescape(attrs.get('title', ''))
            if title.startswith('File:') and '/wiki/File' in href:
                files[title] = {'title': title, 'name': title[5:], 'url': urllib.parse.urljoin(BASE, href)}
            if (title.startswith('Category:Concept art from ') or title == 'Category:Capsule Monsters') and '/wiki/Category' in href:
                categories[title] = {'title': title, 'url': urllib.parse.urljoin(BASE, href)}
        next_links = [html.unescape(a.get('href', '')) for a, label in links(markup) if label == 'next page']
        url = urllib.parse.urljoin(BASE, next_links[0]) if next_links else None
        time.sleep(.2)
    # Category listings are metadata inspection, not a claim of viewing every image.
    for category in categories.values():
        markup = fetch(category['url'])
        category['announced_count'] = re.findall(r'out of ([\d,]+) total', re.sub('<[^>]+>', ' ', markup))
        category['indexed_files'] = sorted({html.unescape(a.get('title', '')) for a, _ in links(markup) if a.get('title', '').startswith('File:')})
        time.sleep(.2)
    result = {'date': '2026-10-30', 'source': START, 'scope': 'Paginated parent catalogue and linked subcategory metadata; individual visual analysis logged separately.', 'pages': pages, 'files': sorted(files.values(), key=lambda f:f['name'].lower()), 'subcategories': list(categories.values())}
    (ROOT/'catalogue.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps({'parent_pages':len(pages),'parent_files':len(files),'subcategories':len(categories)}, ensure_ascii=False))
    print('\n'.join(f['name'] for f in result['files'] if any(s in f['name'].lower() for s in ['guzma','plumeria','mela','opal','piers','raihan','kabu','milo','nessa','gordie','olivia','hala','kukui','lusamine','mallow','kiawe','grimsley','team skull','skull grunt','maxie','wulfric','lysandre','siebold','ramos','valerie','sophocles','kahili','rotom','bike'])))

if __name__ == '__main__':
    main()
