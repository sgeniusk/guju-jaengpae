# feat-072 — 스크린샷 하네스 실행 안정화

## 문제
전투 화면 깊이 보정 이후 시각 QA용 전투 스크린샷을 직접 재현하려 했지만 `godot --headless --path . res://tools/shoot_battle.tscn`가 `SHOT`을 출력하지 않고 멈췄다.

원인은 두 갈래다.

- Godot 4.6 CLI에서 씬 실행은 위치 인자가 아니라 `--scene <path>` 계약을 써야 한다.
- `--headless` 표시 드라이버에서는 `RenderingServer.frame_post_draw`가 GUI처럼 보장되지 않아 캡처 하네스가 무한 대기할 수 있다.

## 목표
- 모든 screenshot bundle 셸 스크립트가 Godot 씬을 `--scene`으로 실행한다.
- headless 환경에서는 캡처 대기 지점이 멈추지 않고 빠르게 실패/종료하거나 최소 PNG를 저장한다.
- 전투 하네스는 짧은 fight frame 설정으로도 `SHOT` 또는 `SHOT FAIL`을 출력하고 종료한다.
- 기존 GUI screenshot bundle 계약은 유지한다.

## 범위
- `tools/visual_qa_config.gd`에 캡처 대기/저장 공용 함수를 추가한다.
- `tools/shoot_*.gd`의 중복 `_shoot()`를 공용 함수로 전환한다.
- `tools/shoot_ui_bundle.sh`, `tools/shoot_visual_qa.sh`, `tools/shoot_run_flow.sh`를 `--scene` 실행으로 바꾼다.
- 테스트는 공용 설정/경로/quick headless 종료를 검증한다.

## 비목표
- 스크린샷 이미지의 미술 품질 개선.
- headless PNG를 사람이 보는 GUI 캡처와 동일한 품질로 보장.
- 게임 루프나 카드/전투 규칙 변경.

## 검증
- `./init.sh`
- 전투 하네스 quick headless 실행이 제한 프레임에서 종료한다.
- screenshot bundle validator unit/smoke가 기존 expected 파일명을 유지한다.
