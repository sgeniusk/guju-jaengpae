#!/usr/bin/env python3
# Generate fallback-safe stage ladder node icons for new StageCadence kinds.

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets/sprites/ui"
SIZE = 112


def _canvas() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    image = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((10, 10, 102, 102), radius=22, fill=(55, 34, 18, 236), outline=(222, 170, 78, 255), width=5)
    draw.rounded_rectangle((18, 18, 94, 94), radius=16, fill=(116, 75, 34, 210), outline=(248, 214, 128, 230), width=2)
    return image, draw


def _edict() -> Image.Image:
    image, draw = _canvas()
    parchment = (230, 202, 138, 255)
    shadow = (84, 47, 23, 255)
    ink = (72, 34, 18, 255)
    draw.rounded_rectangle((28, 31, 82, 76), radius=8, fill=shadow)
    draw.rounded_rectangle((24, 26, 78, 71), radius=8, fill=parchment, outline=(103, 60, 28, 255), width=3)
    draw.ellipse((18, 23, 34, 39), fill=(198, 163, 95, 255), outline=(103, 60, 28, 255), width=2)
    draw.ellipse((68, 58, 88, 78), fill=(198, 163, 95, 255), outline=(103, 60, 28, 255), width=2)
    for y in (40, 50, 60):
        draw.line((36, y, 66, y), fill=ink, width=4)
    draw.ellipse((63, 65, 86, 88), fill=(162, 34, 32, 255), outline=(255, 222, 142, 255), width=3)
    return image


def _elite() -> Image.Image:
    image, draw = _canvas()
    steel = (194, 214, 222, 255)
    edge = (48, 40, 38, 255)
    gold = (248, 198, 82, 255)
    draw.line((31, 82, 77, 34), fill=edge, width=15)
    draw.line((35, 82, 81, 34), fill=steel, width=7)
    draw.line((81, 82, 35, 34), fill=edge, width=15)
    draw.line((77, 82, 31, 34), fill=steel, width=7)
    draw.polygon([(56, 21), (64, 44), (88, 44), (68, 58), (76, 82), (56, 67), (36, 82), (44, 58), (24, 44), (48, 44)], fill=gold, outline=edge)
    draw.polygon([(56, 32), (61, 48), (78, 48), (64, 58), (69, 75), (56, 64), (43, 75), (48, 58), (34, 48), (51, 48)], fill=(255, 232, 128, 255))
    return image


def _event() -> Image.Image:
    image, draw = _canvas()
    road = (86, 61, 35, 255)
    road_edge = (237, 193, 96, 255)
    sign = (224, 174, 82, 255)
    ink = (56, 31, 18, 255)
    draw.line((56, 88, 56, 46), fill=road_edge, width=15)
    draw.line((56, 88, 56, 46), fill=road, width=8)
    draw.line((55, 55, 30, 35), fill=road_edge, width=14)
    draw.line((55, 55, 30, 35), fill=road, width=7)
    draw.line((57, 55, 84, 36), fill=road_edge, width=14)
    draw.line((57, 55, 84, 36), fill=road, width=7)
    draw.rounded_rectangle((34, 22, 78, 52), radius=7, fill=sign, outline=ink, width=3)
    draw.polygon([(78, 22), (96, 37), (78, 52)], fill=sign, outline=ink)
    draw.rectangle((53, 31, 59, 42), fill=ink)
    draw.rectangle((53, 45, 59, 49), fill=ink)
    return image


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    icons = {
        "node_edict.png": _edict(),
        "node_elite.png": _elite(),
        "node_event.png": _event(),
    }
    for name, image in icons.items():
        path = OUT_DIR / name
        image.save(path)
        print(f"ui node icon: {path.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
