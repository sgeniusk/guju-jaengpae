# feat-071 전장 필드 접지/깊이 보정

## 목표
- 배치 필드 9칸이 배경 위에 떠 있는 UI처럼 보이지 않고, 전장 바닥 위에 놓인 표식처럼 보인다.
- 유닛, 성, 건물은 필드 타일 뒤가 아니라 필드 위에 서 있는 것으로 렌더링된다.
- 전투 시작 후 필드 타일은 입력을 막고 빠르게 사라져 교전 시야를 가리지 않는다.

## 구현
- 배치 필드 아래에 반투명 지면 plate와 shadow를 렌더링한다.
- 필드 타일/라벨/입력 영역 레이어와 유닛/건물/VFX 레이어의 z-order 계약을 명시한다.
- 유닛 visual root의 z-index는 전장 좌표가 아니라 실제 screen y 기준으로 계산한다.
- 자동 UI smoke가 지면 plate 존재와 필드 < 유닛 레이어 순서를 검증한다.

## 검증
- `godot --headless --path . --log-file .godot/feat-071-ui.log --script res://tools/ui_feedback_smoke.gd`
- `godot --headless --path . --log-file .godot/feat-071-unit.log --script res://test/runner.gd`
- `./init.sh`
