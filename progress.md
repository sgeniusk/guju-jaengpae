# 진행 로그

이 파일은 재시작 상태용이다. 전체 이력은 `CHANGELOG.md`, `docs/specs/`, `session-handoff.md`를 본다. 120줄 이하로 유지한다.

## 현재 상태
**마지막 갱신** — 2026-06-06
**활성 피처** — feat-080 첫 보드 지면 라벨 절제 완료
**현재 목표** — 완성판까지 Codex goal을 유지한다. 이번 단위는 사용자가 지적한 “필드 9칸이 하늘에 떠 있고 유닛이 필드 뒤에 나타나는 느낌”을 줄이기 위해 빈 타일 반복 라벨을 숨기고, 격자 fill/outline을 더 낮은 알파로 눌러 첫 보드가 UI판처럼 읽히지 않게 한 작업이다.

## 완료
- [x] **feat-080 첫 보드 지면 라벨 절제** — `battle.gd`가 빈 타일 generic state(`성 후보`, `손패 선택`, `계략 버튼`, `배치 가능`)를 격자 위 visible label로 그리지 않고 `state_label`/`tooltip`/Area2D meta/hover hint로 유지한다. 성, 배치된 카드, `엄호 +15%` 같은 전술 preview 라벨은 계속 보인다. idle fill/outline alpha를 낮춰 흰 9칸 격자와 유닛 앞쪽 UI선 착시를 줄였다. UI smoke가 hidden generic label, hover hint, deploy unit depth, outline alpha <=0.50을 검증하고 GUI 캡처(`/tmp/guju-feat-080-label-discipline-v2`)로 확인했다. `./init.sh` 카드 22개 / 3065 단언 green.
- [x] **feat-079 전장 지면 격자/타격 리듬 polish** — 배치 타일 fill을 낮추고 `TileGroundOutline`/납작한 contact shadow로 보드를 지면 격자화했다. `BattleHitFeedback` 발밑 impact와 강타 camera shake를 추가했다. `./init.sh` 카드 22개 / 3065 단언 green.
- [x] **feat-078 배치 필드 접지감 재수정** — 전장 투영을 낮추고 floor/plate/contact alpha를 줄여 큰 공중 platform 착시를 완화했다. `./init.sh` 카드 22개 / 3043 단언 green.
- [x] **feat-077 전투 첫 화면 지면/깊이 재보정** — 배경 지면 밴드와 3레인 진군 바닥선을 추가해 보드, 성, 유닛의 지면 축을 연결했다. `./init.sh` 카드 22개 / 3043 단언 green.
- [x] **feat-038~076 MVP 이후 루프 보강** — 성 선점→3장 손패→1장 플레이, 분대/증원 성장, 군세 체감, 진형 전술, 수동 QA, 전투 템포, 카드 추천순, 저장/이어하기 UX, 병력 밀도/함성 VFX, 피격 VFX, 손상 저장 보호, 보상/상점/결과 UX, 스크린샷 QA, 필드 접지/깊이 보정, 장기런 템포 계약을 완료했다.

## 진행 중
- [ ] 수동 플레이 감각 확인 — 첫 손패 장수+병종, 성 위치 선택, 1장 배치/증원, 전군 돌격 피드백, stage 3 칙령, stage 4 상점, 전리품 추천 문구를 사용자 플레이로 확인한다.
- [ ] 완성판 안전 개선 계속 — 다음 후보는 실제 첫 보드 screenshot bundle 갱신, 배치 카드 UI 정리, 전투 phase에서 군세 충돌 밀도/속도 추가 polish다.
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

## 이번 세션 수정 파일
- `docs/specs/feat-080-first-board-label-discipline.md`
- `scripts/battle/battle.gd`
- `tools/ui_feedback_smoke.gd`
- `feature_list.json`
- `progress.md`
- `session-handoff.md`
- `CHANGELOG.md`

## 검증 증거
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-080-unit.log --script res://test/runner.gd` (2026-06-06, feat-080) — 단위 테스트 3065/3065 green.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-080-ui.log --script res://tools/ui_feedback_smoke.gd` (2026-06-06, feat-080) — hidden generic label, hover hint, deploy unit depth, outline alpha 포함 UI smoke green.
- [x] `HOME=$PWD/.godot/home SHOT_DIR=/tmp/guju-feat-080-label-discipline-v2 LORD=lord_liubei SHOOT_STAGE=1 SHOOT_FIGHT_FRAMES=120 godot --path . --scene res://tools/shoot_battle.tscn` (2026-06-06, feat-080) — 배치 GUI PNG 생성 및 확인.
- [x] `./init.sh` (2026-06-06, feat-080) — 카드 22개 검증 OK, UI smoke, 저장/이어하기 smoke, playtest loop, 장기런 tempo gate, 단위 테스트 3065/3065 포함 전체 green.

## 다음 세션 메모
feat-080 done. 다음 안전 피처는 실제 첫 보드 screenshot bundle 갱신 또는 배치 카드 UI 정리가 좋다. 천계·마계 확장은 정본 승인 전 시작하지 않는다. push와 tag는 사용자 확인 후에만 실행한다.
