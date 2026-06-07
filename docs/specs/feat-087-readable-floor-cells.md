# feat-087 — 읽히는 바닥 칸 seam

사용자가 지적한 “바닥 칸이 안 보이는” 문제를 좁게 고친다. 직전 접지감 패스에서 fill과 outline을 너무 낮춰 공중판 착시는 줄었지만, 배치 가능한 칸 자체가 묻히는 부작용이 생겼다.

## 목표
- 배치 단계에서 바닥 칸 경계가 즉시 읽힌다.
- 타일 fill을 다시 진하게 올려 판처럼 보이게 만들지는 않는다.
- 칸 경계는 밝은 격자보다 바닥에 새겨진 홈처럼 보인다.

## 구현
- `scripts/battle/battle.gd`
  - 각 타일에 `TileFloorSeam` 두 줄을 추가한다.
  - 어두운 홈 line과 얇은 밝은 lip line을 겹쳐 바닥에 새겨진 경계처럼 보이게 한다.
  - 기존 `battlefield_tile_outline`은 낮은 alpha 계약을 유지해 공중 격자 느낌을 막는다.

## 검증
- 단위 테스트가 타일마다 floor seam 2개가 있는지 확인한다.
- 단위 테스트와 UI smoke가 seam alpha 최소/최대 범위를 검증한다.
- 기존 fill/outline 최대 alpha 계약은 유지한다.
- `./init.sh` green으로 닫는다.

## 비범위
- 타일 배치 좌표, 클릭 영역, 유닛 footline은 바꾸지 않는다.
- 전투 중 숨김 동작은 기존 `_fade_iso_tiles_out()`을 유지한다.
