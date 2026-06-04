#!/usr/bin/env python3
# Generate lightweight realm background variants from existing field art.

from pathlib import Path

from PIL import Image, ImageEnhance


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/sprites/bg/plain/field.png"
HEAVEN = ROOT / "assets/sprites/bg/heaven/field.png"


def _tint_heaven(src: Image.Image) -> Image.Image:
    base = src.convert("RGB")
    base = ImageEnhance.Brightness(base).enhance(1.08)
    base = ImageEnhance.Color(base).enhance(0.86)

    blue = Image.new("RGB", base.size, (178, 214, 255))
    gold = Image.new("RGB", base.size, (255, 226, 156))
    width, height = base.size
    mask = Image.new("L", base.size)
    pixels = mask.load()
    for y in range(height):
        value = int(88 * (1.0 - min(1.0, y / max(1, height - 1))))
        for x in range(width):
            pixels[x, y] = value

    out = Image.blend(base, blue, 0.24)
    out = Image.composite(gold, out, mask)
    return out


def main() -> int:
    if not SOURCE.exists():
        raise FileNotFoundError(SOURCE)
    HEAVEN.parent.mkdir(parents=True, exist_ok=True)
    _tint_heaven(Image.open(SOURCE)).save(HEAVEN)
    print(f"realm background: {SOURCE.relative_to(ROOT)} -> {HEAVEN.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
