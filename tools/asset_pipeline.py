#!/usr/bin/env python3
# agy 생성 이미지(1024² JPEG, 무알파)를 게임 애셋으로 후처리하는 파이프라인.
# 스프라이트 — 단색 크로마(기본 마젠타) 배경 키 아웃 → 알파 → 오토크롭 → 다운스케일 → 투명 PNG.
# 배경 — 키잉 없이 리사이즈/크롭만.
# 의존 — Pillow(PIL)만. ImageMagick 불필요.
#
# 사용법
#   python3 tools/asset_pipeline.py chroma <in> <out.png> <W> <H> [--key R,G,B] [--tol N] [--filter nearest|lanczos]
#   python3 tools/asset_pipeline.py bg     <in> <out.png> <W> <H> [--fit cover|contain]
#   python3 tools/asset_pipeline.py info   <in>

import argparse
import sys
from PIL import Image


def _parse_color(s: str):
    parts = [int(x) for x in s.split(",")]
    if len(parts) != 3:
        raise ValueError("색은 R,G,B 형식이어야 한다")
    return tuple(parts)


def chroma_key(src: str, dst: str, w: int, h: int, key=(255, 0, 255), tol: int = 60, resample="nearest"):
    """단색 배경을 투명으로 키 아웃하고 콘텐츠로 크롭한 뒤 목표 크기로 다운스케일."""
    img = Image.open(src).convert("RGBA")
    px = img.load()
    kr, kg, kb = key
    tol2 = tol * tol
    W, H = img.size
    for y in range(H):
        for x in range(W):
            r, g, b, a = px[x, y]
            dr, dg, db = r - kr, g - kg, b - kb
            dist2 = dr * dr + dg * dg + db * db
            if dist2 <= tol2:
                px[x, y] = (r, g, b, 0)            # 키색 → 완전 투명
            elif dist2 <= (tol * 2) ** 2:
                # 경계 페더 — 키색에 가까울수록 반투명(디스필)
                frac = (dist2 ** 0.5 - tol) / float(tol)
                px[x, y] = (r, g, b, int(255 * max(0.0, min(1.0, frac))))

    bbox = img.getbbox()                            # 불투명 콘텐츠 경계
    if bbox:
        img = img.crop(bbox)
    flt = Image.LANCZOS if resample == "lanczos" else Image.NEAREST
    # 종횡비 유지하며 (w,h) 안에 맞춤
    img.thumbnail((w, h), flt)
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.paste(img, ((w - img.width) // 2, h - img.height))   # 가로 중앙·세로 하단 정렬(발밑 앵커)
    out.save(dst)
    print(f"chroma: {src} -> {dst} ({w}x{h}, key={key}, tol={tol})")


def resize_bg(src: str, dst: str, w: int, h: int, fit="cover"):
    """배경 — 키잉 없이 cover/contain으로 리사이즈·크롭."""
    img = Image.open(src).convert("RGB")
    sw, sh = img.size
    scale = max(w / sw, h / sh) if fit == "cover" else min(w / sw, h / sh)
    nw, nh = max(1, int(sw * scale)), max(1, int(sh * scale))
    img = img.resize((nw, nh), Image.LANCZOS)
    if fit == "cover":
        left, top = (nw - w) // 2, (nh - h) // 2
        img = img.crop((left, top, left + w, top + h))
    img.save(dst)
    print(f"bg: {src} -> {dst} ({w}x{h}, fit={fit})")


def info(src: str):
    img = Image.open(src)
    print(f"{src}: {img.format} {img.mode} {img.size}")


def main():
    ap = argparse.ArgumentParser(description="구주쟁패 애셋 후처리")
    sub = ap.add_subparsers(dest="cmd", required=True)

    c = sub.add_parser("chroma")
    c.add_argument("src"); c.add_argument("dst")
    c.add_argument("w", type=int); c.add_argument("h", type=int)
    c.add_argument("--key", default="255,0,255"); c.add_argument("--tol", type=int, default=60)
    c.add_argument("--filter", default="nearest", choices=["nearest", "lanczos"])

    b = sub.add_parser("bg")
    b.add_argument("src"); b.add_argument("dst")
    b.add_argument("w", type=int); b.add_argument("h", type=int)
    b.add_argument("--fit", default="cover", choices=["cover", "contain"])

    i = sub.add_parser("info")
    i.add_argument("src")

    a = ap.parse_args()
    if a.cmd == "chroma":
        chroma_key(a.src, a.dst, a.w, a.h, _parse_color(a.key), a.tol, a.filter)
    elif a.cmd == "bg":
        resize_bg(a.src, a.dst, a.w, a.h, a.fit)
    elif a.cmd == "info":
        info(a.src)


if __name__ == "__main__":
    main()
