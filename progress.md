# 진행 로그

이 파일은 재시작 상태용이다. 전체 이력은 `CHANGELOG.md`, `docs/specs/`, `session-handoff.md`를 본다. 120줄 이하로 유지한다.

## 현재 상태
**마지막 갱신** — 2026-06-06
**활성 피처** — feat-081 전장 접지/depth 재보정 완료
**현재 목표** — 완성판까지 Codex goal을 유지한다. 이번 단위는 사용자가 다시 지적한 “필드 9칸이 하늘에 떠 있고, 유닛이 필드 뒤에서 나타나는 느낌”을 줄이기 위해 보드 위치와 유닛/성/건물 발 위치를 재보정한 작업이다.

## 완료
- [x] **feat-081 전장 접지/depth 재보정** — `battle.gd`의 보드 origin y를 낮춰 첫 보드 9칸이 전경 바닥에 놓이도록 했고, 유닛/성/건물/root 및 지면 VFX를 타일 중심보다 앞쪽 `foot` 지점에 세웠다. 성 후보/빈 타일 fill·outline alpha도 더 낮춰 전체 9칸이 밝은 공중 격자로 읽히지 않게 했다. `test_unit_walk_visuals.gd`와 UI smoke가 보드 y>=610, outline alpha<=0.38, 유닛 foot 위치를 검증한다. GUI 캡처는 `/tmp/guju-feat-081-grounding`, `./init.sh` 카드 22개 / 3066 단언 green.
- [x] **feat-080 첫 보드 지면 라벨 절제** — 빈 타일 generic state(`성 후보`, `손패 선택`, `계략 버튼`, `배치 가능`)를 visible label로 그리지 않고 `state_label`/`tooltip`/Area2D meta/hover hint로 유지한다. 성, 배치된 카드, `엄호 +15%` 같은 전술 preview 라벨은 계속 보인다.
- [x] **feat-079 전장 지면 격자/타격 리듬 polish** — 배치 타일 fill을 낮추고 `TileGroundOutline`/납작한 contact shadow로 보드를 지면 격자화했다. `BattleHitFeedback` 발밑 impact와 강타 camera shake를 추가했다.
- [x] **feat-038~078 MVP 이후 루프 보강** — 성 선점→3장 손패→1장 플레이, 분대/증원 성장, 군세 체감, 진형 전술, 수동 QA, 전투 템포, 카드 추천순, 저장/이어하기 UX, 병력 밀도/함성 VFX, 피격 VFX, 손상 저장 보호, 보상/상점/결과 UX, 스크린샷 QA, 필드 접지/깊이 보정, 장기런 템포 계약을 완료했다.

## 진행 중
- [ ] 수동 플레이 감각 확인 — 첫 손패 장수+병종, 성 위치 선택, 1장 배치/증원, 전군 돌격 피드백, stage 3 칙령, stage 4 상점, 전리품 추천 문구를 사용자 플레이로 확인한다.
- [ ] 완성판 안전 개선 계속 — 다음 후보는 배치 카드 UI 정리, 실제 교전 시작 screenshot 하네스 정정, 교전 phase 군세 충돌 밀도/속도 polish다.
- [ ] Codex goal은 완성판까지 계속 활성이다. 현재 피처 완료가 전체 goal 완료는 아니다.

## 다음
1. `feature_list.json`에서 다음 미완 피처 하나를 추가하거나 선택한다.
2. 정본 승인이 필요 없는 안전 작업을 우선한다.
3. 구현 전 `docs/specs/feat-0XX-*.md`를 작성한다.
4. `./init.sh` green 후 상태 파일 갱신과 중요 커밋을 만든다.

## 블로커 / 리스크
- [ ] push/tag는 사용자 확인 전 실행 금지다.
- [ ] G055/G056/G058/G060/G061/G062는 천계·마계 nation id, 군주명, resource id 정본 승인 전 보류한다.
- [ ] Godot 4.6.3 macOS headless 종료 시 resource leak 경고가 남지만 종료 코드는 0이고 테스트 실패는 아니다.
- [ ] Godot headless dummy renderer는 PNG 추출을 지원하지 않아 screenshot 하네스가 `SHOT FAIL ... headless_display`로 종료한다. 실제 PNG 품질 검증은 GUI 표시 드라이버에서 `--scene` bundle로 실행한다.
- [ ] `tools/shoot_battle.gd`는 QA용 직접 배치가 `deploy_cards_played`를 갱신하지 않아 `battle_fight` 캡처가 실제 교전으로 못 넘어갈 수 있다. 후속 안전 피처로 정정하면 좋다.

## 이번 세션 수정 파일
- `docs/specs/feat-081-battlefield-grounding-pass.md`
- `scripts/battle/battle.gd`
- `test/test_unit_walk_visuals.gd`
- `tools/ui_feedback_smoke.gd`
- `feature_list.json`
- `progress.md`
- `session-handoff.md`
- `CHANGELOG.md`

## 검증 증거
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-081-unit.log --script res://test/runner.gd` (2026-06-06, feat-081) — 단위 테스트 3066/3066 green.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-081-ui.log --script res://tools/ui_feedback_smoke.gd` (2026-06-06, feat-081) — 보드 y/alpha/유닛 foot 검증 포함 UI smoke green.
- [x] `HOME=$PWD/.godot/home SHOT_DIR=/tmp/guju-feat-081-grounding LORD=lord_liubei SHOOT_STAGE=1 godot --path . --scene res://tools/shoot_first_board_states.tscn` (2026-06-06, feat-081) — 첫 보드 4상태 PNG 생성 및 확인.
- [x] `HOME=$PWD/.godot/home SHOT_DIR=/tmp/guju-feat-081-grounding LORD=lord_liubei SHOOT_STAGE=1 SHOOT_FIGHT_FRAMES=120 godot --path . --scene res://tools/shoot_battle.tscn` (2026-06-06, feat-081) — 유닛/건물 채움 배치 PNG 생성 및 확인.
- [x] `./init.sh` (2026-06-06, feat-081) — 카드 22개 검증 OK, UI smoke, 저장/이어하기 smoke, playtest loop, 장기런 tempo gate, 단위 테스트 3066/3066 포함 전체 green.

## 다음 세션 메모
feat-081 done. 다음 안전 피처는 `tools/shoot_battle.gd`의 실제 교전 캡처 정정 또는 배치 카드 UI surface 정리가 좋다. 천계·마계 확장은 정본 승인 전 시작하지 않는다. push와 tag는 사용자 확인 후에만 실행한다.
