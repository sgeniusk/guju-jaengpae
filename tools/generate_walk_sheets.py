#!/usr/bin/env python3
# 기존 정적 유닛 PNG에서 4프레임 walk strip을 만드는 보조 도구.

import argparse
from pathlib import Path
from typing import Iterable

from PIL import Image


DEFAULT_TARGETS = [
    "assets/sprites/units/shu/archer.png",
    "assets/sprites/units/shu/cavalry.png",
    "assets/sprites/units/shu/crossbow.png",
    "assets/sprites/units/shu/navy.png",
    "assets/sprites/units/shu/general_guanyu.png",
    "assets/sprites/units/shu/general_huangzhong.png",
    "assets/sprites/units/shu/general_zhangfei.png",
    "assets/sprites/units/shu/general_zhaoyun.png",
    "assets/sprites/units/shu/general_zhugeliang.png",
    "assets/sprites/units/wei/archer.png",
    "assets/sprites/units/wei/cavalry.png",
    "assets/sprites/units/wei/crossbow.png",
    "assets/sprites/units/wei/infantry.png",
    "assets/sprites/units/wei/general_caocao.png",
    "assets/sprites/units/wei/general_xiahoudun.png",
    "assets/sprites/units/wu/archer.png",
    "assets/sprites/units/wu/cavalry.png",
    "assets/sprites/units/wu/infantry.png",
    "assets/sprites/units/wu/navy.png",
    "assets/sprites/units/wu/general_sunquan.png",
    "assets/sprites/units/wu/general_zhouyu.png",
    "assets/sprites/units/demon/boss_dongzhuo.png",
    "assets/sprites/units/luoyang/boss_dongzhuo.png",
    "assets/sprites/units/huangtian/boss_zhangjue.png",
    "assets/sprites/units/wanyao/boss_lvbu.png",
]

FRAME_OFFSETS = [
    (0, 0),
    (-2, -3),
    (0, 0),
    (2, -3),
]


def _walk_path(src: Path) -> Path:
    return src.with_name(f"{src.stem}_walk{src.suffix}")


def generate(src: Path, force: bool = False) -> Path:
    if not src.exists():
        raise FileNotFoundError(src)
    dst = _walk_path(src)
    if dst.exists() and not force:
        return dst

    base = Image.open(src).convert("RGBA")
    frame_w = base.width + 8
    frame_h = base.height + 6
    sheet = Image.new("RGBA", (frame_w * len(FRAME_OFFSETS), frame_h), (0, 0, 0, 0))

    for index, (dx, dy) in enumerate(FRAME_OFFSETS):
        frame = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
        x = 4 + dx
        y = frame_h - base.height + dy
        frame.alpha_composite(base, (x, y))
        sheet.alpha_composite(frame, (frame_w * index, 0))

    sheet.save(dst)
    return dst


def _iter_targets(args) -> Iterable[Path]:
    targets = args.sources if args.sources else DEFAULT_TARGETS
    for target in targets:
        yield Path(target)


def main() -> int:
    parser = argparse.ArgumentParser(description="정적 유닛 PNG에서 4프레임 walk strip 생성")
    parser.add_argument("sources", nargs="*", help="생성할 PNG. 생략하면 기본 주요 유닛 목록 사용")
    parser.add_argument("--force", action="store_true", help="이미 존재하는 _walk.png도 다시 생성")
    args = parser.parse_args()

    generated = []
    for src in _iter_targets(args):
        dst = generate(src, args.force)
        generated.append(dst)
        print(f"walk: {src} -> {dst}")
    print(f"walk sheets ready: {len(generated)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
