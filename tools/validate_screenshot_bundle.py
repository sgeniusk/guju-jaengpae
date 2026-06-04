#!/usr/bin/env python3
"""Validate the durable UI screenshot bundle produced by shoot_ui_bundle.sh."""

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Iterable

from PIL import Image


DEFAULT_LORDS = ["lord_liubei", "lord_caocao", "lord_sunquan"]
DEFAULT_FLOW_STAGES = [1, 3, 4, 5]
MIN_SIZE = (1280, 720)
MIN_COLOR_COUNT = 8


def _safe_token(value: str) -> str:
    safe = value.strip().lower()
    for ch in ("/", "\\", " ", ":", ";"):
        safe = safe.replace(ch, "_")
    return safe


def _shot_name(kind: str, lord: str, stage: int = 0) -> str:
    suffix = f"_stage_{stage}" if stage > 0 else ""
    return f"{_safe_token(kind)}_{_safe_token(lord)}{suffix}.png"


def _required_names(args: argparse.Namespace) -> list[str]:
    names = [_shot_name("lord_select", "all")]
    for lord in args.lords:
        for stage in args.flow_stages:
            names.append(_shot_name("run_map", lord, stage))
        names.append(_shot_name("battle_deploy", lord, args.battle_stage))
        names.append(_shot_name("battle_fight", lord, args.battle_stage))
        names.append(_shot_name("shop", lord, args.shop_stage))
    names.append(_shot_name("battle_result_loss", args.result_lord, args.result_loss_stage))
    names.append(_shot_name("battle_result_win", args.result_lord, args.result_win_stage))
    return names


def _parse_ints(values: Iterable[str]) -> list[int]:
    out: list[int] = []
    for value in values:
        out.append(int(value))
    return out


def _validate_png(path: Path) -> str | None:
    try:
        with Image.open(path) as image:
            image.load()
            if image.format != "PNG":
                return f"{path.name}: PNG 파일이 아님"
            width, height = image.size
            if width < MIN_SIZE[0] or height < MIN_SIZE[1]:
                return f"{path.name}: 해상도 {width}x{height}, 최소 {MIN_SIZE[0]}x{MIN_SIZE[1]} 미만"
            rgba = image.convert("RGBA")
            if rgba.getbbox() is None:
                return f"{path.name}: 완전 투명/빈 이미지"
            sample = rgba.resize((64, 36))
            colors = sample.getcolors(maxcolors=4096)
            if colors is not None and len(colors) < MIN_COLOR_COUNT:
                return f"{path.name}: 색상 수 {len(colors)}, 빈 화면 의심"
    except Exception as exc:  # noqa: BLE001 - CLI validator should surface the path and raw decoder issue.
        return f"{path.name}: 열기 실패: {exc}"
    return None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("shot_dir", type=Path)
    parser.add_argument("--lords", nargs="+", default=DEFAULT_LORDS)
    parser.add_argument("--flow-stages", nargs="+", type=int, default=DEFAULT_FLOW_STAGES)
    parser.add_argument("--battle-stage", type=int, default=5)
    parser.add_argument("--shop-stage", type=int, default=4)
    parser.add_argument("--result-lord", default="lord_liubei")
    parser.add_argument("--result-loss-stage", type=int, default=3)
    parser.add_argument("--result-win-stage", type=int, default=15)
    args = parser.parse_args()
    args.flow_stages = _parse_ints(args.flow_stages)

    errors: list[str] = []
    for name in _required_names(args):
        path = args.shot_dir / name
        if not path.is_file():
            errors.append(f"{name}: 파일 없음")
            continue
        error = _validate_png(path)
        if error:
            errors.append(error)

    if errors:
        for error in errors:
            print(f"SCREENSHOT BUNDLE FAIL {error}")
        return 1

    print(f"validated {len(_required_names(args))} UI screenshots in {args.shot_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
