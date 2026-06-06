# feat-085 — 전장 보드 stencil/depth 재정리

사용자 플레이 피드백에서 배치 필드 9칸이 여전히 공중에 뜬 판처럼 보이고, 유닛이 필드 뒤에서 나타나는 느낌이 남았다. 기존 보정은 보드 위치와 alpha를 낮췄지만, 모든 칸이 닫힌 다이아몬드 fill/outline과 점유 라벨을 동시에 유지해 화면에서는 유닛보다 보드 UI가 먼저 읽힌다.

## 목표
- 9칸 보드는 클릭 가능한 영역으로 유지하되, 시각적으로는 바닥에 새겨진 낮은 stencil처럼 보이게 한다.
- 성/점유 유닛 칸의 텍스트 라벨은 지면 위에 직접 표시하지 않는다. 정보는 왼쪽 패널과 유닛 이름표가 담당한다.
- 전술 preview(`엄호 +15%` 등)는 전략 판단에 필요하므로 계속 표시한다.
- 유닛/성/건물 footline을 보드 다이아몬드보다 앞쪽으로 더 밀어, “필드 뒤에서 솟는” 착시를 줄인다.

## 구현
- `battle.gd`
  - `FIELD_FOOT_OFFSET_Y`를 소폭 늘려 유닛 root가 타일 중심보다 더 앞쪽 지면에 선다.
  - 기본 타일 fill/contact/outline alpha를 더 낮춘다.
  - 성/점유 타일은 state/tooltip은 유지하되 visible field label은 숨긴다.
  - 빈 타일/성 후보/배치 가능 highlight는 더 낮은 alpha로 조정하고, 전술 preview만 상대적으로 읽히게 둔다.
- `test/test_unit_walk_visuals.gd`
  - 점유 타일 라벨이 숨겨지고 state/tooltip만 남는 계약을 검증한다.
  - footline과 alpha 상한을 새 기준으로 강화한다.
- `tools/ui_feedback_smoke.gd`
  - UI smoke가 새 alpha 상한과 점유 타일 label hidden 계약을 확인한다.

## 완료 기준
- 첫 배치 화면에서 성/점유/빈 타일의 반복 라벨이 보드판처럼 유닛 앞에 남지 않는다.
- 선택 카드 전술 preview는 계속 표시된다.
- `./init.sh`가 통과한다.
