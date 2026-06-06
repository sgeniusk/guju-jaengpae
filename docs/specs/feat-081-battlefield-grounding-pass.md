# feat-081 — 전장 접지/depth 재보정

## 문제
첫 배치 화면에서 9칸 필드가 배경의 하늘/중경 위에 얹힌 UI판처럼 보이고, 배치된 유닛이 타일 뒤쪽에서 솟는 것처럼 읽힌다. 기존 feat-071~080은 라벨과 큰 plate 착시를 줄였지만, 실제 플레이 감각상 보드와 유닛 발 위치가 아직 같은 지면에 붙어 보이지 않는다.

## 목표
- 첫 보드 9칸의 중심을 더 아래 지면 영역으로 옮겨 하늘/중경 위 floating grid 착시를 줄인다.
- 유닛, 성, 건물 visual root를 타일 중심이 아니라 타일의 앞쪽 발 위치에 세워 필드 뒤에서 나타나는 느낌을 줄인다.
- 성 후보 단계에서 모든 빈 칸이 강하게 빛나지 않도록 기본 fill/outline alpha를 더 낮춘다.
- 배치/전투 규칙, 카드 데이터, 전투 수치, 난이도는 바꾸지 않는다.

## 범위
- `scripts/battle/battle.gd`
  - view origin y와 유닛/건물 footprint helper 조정.
  - 빈 타일 fill/outline alpha 보정.
- `tools/ui_feedback_smoke.gd`
  - 보드 y 범위와 유닛 foot 위치 검증 강화.
  - 기본 격자 alpha 상한 강화.

## 완료 기준
- 첫 배치 보드의 `min_y`가 실제 지면 영역으로 내려오고 하단 HUD와 겹치지 않는다.
- 배치된 유닛 root y가 해당 타일 center보다 앞쪽/아래쪽에 있다.
- 성 후보 상태의 전체 9칸 outline/fill이 너무 밝지 않다.
- `./init.sh`가 green이다.
