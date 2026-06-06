# feat-078 - 배치 필드 접지감 재수정

## 문제
직전 보정 뒤에도 배치 보드 9칸 뒤의 큰 어두운 직선 plate가 공중 플랫폼처럼 읽힌다. 유닛은 실제 z-order상 필드보다 앞에 있지만, 발밑을 덮는 진한 plate 때문에 필드 뒤에서 나타나는 것처럼 보인다.

## 목표
- 배치판이 하늘/중경에 뜬 UI가 아니라 전경 지면에 붙은 작전 표식처럼 보인다.
- 배경 floor band와 ground plate는 지면 얼룩/그림자 역할만 하고, 별도 플랫폼으로 보일 만큼 진하지 않다.
- 빈 타일은 선택 가능한 칸으로 읽히되 초록 판처럼 과하게 떠 보이지 않는다.
- 전투 수치, 카드, 배치 규칙, 보상 흐름은 변경하지 않는다.

## 구현
- `battle.gd`의 전장 투영 y origin/scale을 지면 쪽으로 내린다.
- `battlefield_floor_band`와 `battlefield_ground_plate`의 직선성, 범위, alpha를 줄이고 ground plate를 불규칙한 다각형으로 바꾼다.
- 빈 타일 sprite modulate alpha와 채도를 낮춰 배경 바닥과 더 잘 섞이게 한다.
- `test_unit_walk_visuals.gd`와 `tools/ui_feedback_smoke.gd`가 보드 y 범위, 세로 간격, floor/plate alpha 상한을 검증한다.

## 완료 기준
- 첫 배치 보드 중심 y 범위가 560~820 안에 있다.
- floor band alpha는 0.06 이하, ground plate alpha는 0.08 이하로 유지된다.
- 타일 접지 shadow와 지면 plate는 남아 있지만 큰 어두운 플랫폼처럼 보이지 않는다.
- `./init.sh`가 green이다.
