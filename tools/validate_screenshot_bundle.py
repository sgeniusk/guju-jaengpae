#!/usr/bin/env python3
"""Validate the durable UI screenshot bundle produced by shoot_ui_bundle.sh."""

from __future__ import annotations

import argparse
import struct
import zlib
from pathlib import Path
from typing import Iterable


DEFAULT_LORDS = ["lord_liubei", "lord_caocao", "lord_sunquan"]
DEFAULT_FLOW_STAGES = [1, 3, 4, 5]
FIRST_BOARD_KINDS = [
    "battle_first_castle",
    "battle_first_hand",
    "battle_first_scheme",
    "battle_first_place",
]
MIN_SIZE = (1280, 720)
MIN_COLOR_COUNT = 8
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


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
    for kind in FIRST_BOARD_KINDS:
        names.append(_shot_name(kind, args.first_board_lord, args.first_board_stage))
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
        png = _decode_png(path)
        if png["width"] < MIN_SIZE[0] or png["height"] < MIN_SIZE[1]:
            return f"{path.name}: 해상도 {png['width']}x{png['height']}, 최소 {MIN_SIZE[0]}x{MIN_SIZE[1]} 미만"
        if png["alpha_all_zero"]:
            return f"{path.name}: 완전 투명/빈 이미지"
        if len(png["sample_colors"]) < MIN_COLOR_COUNT:
            return f"{path.name}: 색상 수 {len(png['sample_colors'])}, 빈 화면 의심"
    except Exception as exc:  # noqa: BLE001 - CLI validator should surface the path and raw decoder issue.
        return f"{path.name}: 열기 실패: {exc}"
    return None


def _decode_png(path: Path) -> dict:
    data = path.read_bytes()
    if not data.startswith(PNG_SIGNATURE):
        raise ValueError("PNG signature mismatch")
    offset = len(PNG_SIGNATURE)
    width = 0
    height = 0
    bit_depth = 0
    color_type = 0
    idat = bytearray()
    while offset + 8 <= len(data):
        length = struct.unpack(">I", data[offset : offset + 4])[0]
        chunk_type = data[offset + 4 : offset + 8]
        chunk_data = data[offset + 8 : offset + 8 + length]
        offset += 12 + length
        if chunk_type == b"IHDR":
            width, height, bit_depth, color_type = struct.unpack(">IIBB", chunk_data[:10])
        elif chunk_type == b"IDAT":
            idat.extend(chunk_data)
        elif chunk_type == b"IEND":
            break
    if width <= 0 or height <= 0 or not idat:
        raise ValueError("PNG chunks incomplete")
    if bit_depth != 8 or color_type not in (0, 2, 6):
        return {
            "width": width,
            "height": height,
            "sample_colors": {("opaque", path.stat().st_size)},
            "alpha_all_zero": False,
        }
    channels = {0: 1, 2: 3, 6: 4}[color_type]
    rows = _unfilter_rows(zlib.decompress(bytes(idat)), width, height, channels)
    sample_colors = set()
    alpha_seen = color_type != 6
    sample_w = min(64, width)
    sample_h = min(36, height)
    for sy in range(sample_h):
        y = int(sy * height / sample_h)
        row = rows[y]
        for sx in range(sample_w):
            x = int(sx * width / sample_w)
            start = x * channels
            px = tuple(row[start : start + channels])
            sample_colors.add(px)
            if color_type == 6 and px[3] > 0:
                alpha_seen = True
    return {
        "width": width,
        "height": height,
        "sample_colors": sample_colors,
        "alpha_all_zero": not alpha_seen,
    }


def _unfilter_rows(raw: bytes, width: int, height: int, channels: int) -> list[bytearray]:
    stride = width * channels
    rows: list[bytearray] = []
    offset = 0
    previous = bytearray(stride)
    for _row_index in range(height):
        filter_type = raw[offset]
        offset += 1
        current = bytearray(raw[offset : offset + stride])
        offset += stride
        for i in range(stride):
            left = current[i - channels] if i >= channels else 0
            up = previous[i]
            up_left = previous[i - channels] if i >= channels else 0
            if filter_type == 1:
                current[i] = (current[i] + left) & 0xFF
            elif filter_type == 2:
                current[i] = (current[i] + up) & 0xFF
            elif filter_type == 3:
                current[i] = (current[i] + ((left + up) // 2)) & 0xFF
            elif filter_type == 4:
                current[i] = (current[i] + _paeth(left, up, up_left)) & 0xFF
            elif filter_type != 0:
                raise ValueError(f"unsupported PNG filter {filter_type}")
        rows.append(current)
        previous = current
    return rows


def _paeth(left: int, up: int, up_left: int) -> int:
    p = left + up - up_left
    pa = abs(p - left)
    pb = abs(p - up)
    pc = abs(p - up_left)
    if pa <= pb and pa <= pc:
        return left
    if pb <= pc:
        return up
    return up_left


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
    parser.add_argument("--first-board-lord", default="lord_liubei")
    parser.add_argument("--first-board-stage", type=int, default=1)
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
