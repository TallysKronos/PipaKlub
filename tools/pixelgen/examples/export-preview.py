"""Export native PNG and nearest-neighbor GIF from a Pixelgen project. Requires Pillow."""
import argparse
import json
from pathlib import Path
from PIL import Image


def export(path, scale):
    project = json.loads(path.read_text(encoding="utf-8"))
    width, height = project["width"], project["height"]
    colors = project["palette"]
    palette = [component for color in colors for component in color[:3]]
    palette += [0] * (768 - len(palette))
    sheet = Image.new("RGBA", (width * project["cols"], height * project["rows"]))
    images = []
    for index, frame in enumerate(project["frames"]):
        image = Image.new("P", (width, height))
        image.putpalette(palette)
        image.putdata(frame["indices"])
        rgba = image.convert("RGBA")
        rgba.putalpha(Image.frombytes("L", (width, height), bytes(255 if n else 0 for n in frame["indices"])))
        sheet.paste(rgba, (index % project["cols"] * width, index // project["cols"] * height))
        enlarged = image.resize((width * scale, height * scale), Image.Resampling.NEAREST)
        enlarged.putpalette(palette)
        images.append(enlarged)
    name = path.name.removesuffix(".pixelgen.json")
    sheet.save(path.with_name(name + "-sheet.png"))
    sheet.resize((sheet.width * scale, sheet.height * scale), Image.Resampling.NEAREST).save(path.with_name(name + f"-preview-{scale}x.png"))
    sequences = project.get("sequences") or [{"name": "all", "start": 0, "end": len(images) - 1, "loop": True}]
    for sequence in sequences:
        start, end = sequence["start"], sequence["end"]
        frames = images[start:end + 1]
        durations = [max(20, min(2000, frame.get("duration", 150))) for frame in project["frames"][start:end + 1]]
        suffix = "" if len(sequences) == 1 else "-" + str(start + 1) + "-" + str(end + 1)
        options = {"loop": 0} if sequence.get("loop", True) else {}
        frames[0].save(path.with_name(name + suffix + ".gif"), save_all=True, append_images=frames[1:], duration=durations, disposal=2, transparency=0, optimize=False, **options)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("project", type=Path)
    parser.add_argument("--scale", type=int, choices=range(1, 13), default=6)
    arguments = parser.parse_args()
    export(arguments.project, arguments.scale)
