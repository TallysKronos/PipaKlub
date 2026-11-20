"""Read-only PNG validation and nearest-neighbour presentation of the pilot."""
from pathlib import Path
from PIL import Image
import json

folder = Path(__file__).resolve().parents[2] / 'art/creatures/soulmonsters-overworld-v2/azulfazo/animacoes-v1'
report = {}
for state in ['idle', 'walk']:
    sheet = Image.open(folder / f'{state}.png').convert('RGBA')
    assert sheet.size == (896, 224)
    stats, frames = [], []
    for row in range(2):
        for f in range(8):
            cell = sheet.crop((f*112, row*112, (f+1)*112, (row+1)*112))
            mask = {(x, y) for y in range(112) for x in range(112) if cell.getpixel((x, y))[3]}
            left, small = set(mask), []
            while left:
                todo, group = [left.pop()], []
                while todo:
                    x, y = todo.pop()
                    group.append((x, y))
                    for dx in [-1, 0, 1]:
                        for dy in [-1, 0, 1]:
                            q = x+dx, y+dy
                            if q in left:
                                left.remove(q)
                                todo.append(q)
                if len(group) < 5:
                    small.append(group)
            stats.append(dict(view=row, frame=f, bbox=cell.getbbox(), volume=len(mask), small=small))
    for f in range(8):
        canvas = Image.new('RGB', (672, 336), '#33454a')
        for row in range(2):
            cell = sheet.crop((f*112, row*112, (f+1)*112, (row+1)*112)).resize((336, 336), Image.Resampling.NEAREST)
            canvas.paste(cell, (row*336, 0), cell)
        frames.append(canvas)
    durations = [320,140,220,320,140,220,200,240] if state == 'idle' else [110,90,90,100,110,90,90,100]
    frames[0].save(folder / f'{state}.gif', save_all=True, append_images=frames[1:], duration=durations, loop=0, disposal=2)
    report[state] = stats
(folder / 'validacao.json').write_text(json.dumps(report, indent=2))
for state, stats in report.items():
    print(state, 'small components:', [(s['view'], s['frame'], s['small']) for s in stats if s['small']])
