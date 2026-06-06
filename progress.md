# 진행 로그

이 파일은 재시작 상태용이다. 전체 이력은 `CHANGELOG.md`, `docs/specs/`, `session-handoff.md`를 본다. 120줄 이하로 유지한다.

## 현재 상태
**마지막 갱신** — 2026-06-06
**활성 피처** — feat-075 전장 보드 지면화와 교전 가시성 보정 완료
**현재 목표** — 완성판까지 Codex goal을 유지한다. 이번 단위는 배치 보드가 공중 9칸처럼 보이고 교전 유닛이 필드 뒤에 나타나는 시각 결함을 줄이는 작업이다.

## 완료
- [x] **feat-075 전장 보드 지면화와 교전 가시성 보정** — `docs/specs/feat-075-battlefield-ground-plane-readability.md`를 추가했다. `battle.gd` 전투 투영을 지면 밴드로 내리고 tile diamond 클릭/시각 크기를 맞췄으며, 타일 접지 shadow와 더 진한 ground plate를 추가했다. 교전 phase 진입 후 `IsoBaseLayer`를 즉시 숨겨 유닛이 필드 뒤에서 나타나는 장면을 줄인다. UI smoke가 지면 밴드, 타일 접지 shadow, 교전 중 격자 숨김을 검증한다.
- [x] **feat-074 초반 군세 밀도 계약 강화** — `docs/specs/feat-074-early-force-density-contract.md`를 추가했다. `SquadProfile`이 병종 Lv.1 기본 분대를 12명 이상, 장수 Lv.1 호위를 7명으로 올리고, `PlaytestMetrics.first_five_ok()`가 매 교전 아군 12명/전체 30명/피크 아군 30명과 22초 max/19초 avg 예산을 검증한다. playtest loop smoke stage 1/2/5가 아군 12/20/32명으로 통과한다. `./init.sh` 카드 22개 / 3012 단언 green.
- [x] **feat-073 전투 진군 접지/충돌선 polish** — `docs/specs/feat-073-battle-advance-grounding-polish.md`를 추가했다. `BattleFeel`이 진군 먼지/지면 충돌 마커를 순수 계산하고, battle start VFX가 양 진영 3레인 먼지 18개와 중앙 충돌선 3개를 렌더한다. UI smoke가 `advance_dust`/`ground_clash` meta를 검증한다. `./init.sh` 카드 22개 / 3010 단언 green.
- [x] **feat-072 스크린샷 하네스 실행 안정화** — `docs/specs/feat-072-screenshot-harness-stability.md`를 추가했다. screenshot bundle 셸 스크립트가 모든 shoot scene을 `--scene`으로 실행하고, `VisualQaConfig.capture_viewport_png()`가 GUI에서는 `frame_post_draw`를 기다리되 headless에서는 `SHOT FAIL ... headless_display`로 즉시 종료한다. 전투/첫 보드/범용 scene quick headless 하네스가 멈추지 않고 종료하며, `./init.sh`는 카드 22개 / 단위 테스트 2994/2994 green.
- [x] **feat-071 전장 필드 접지/깊이 보정** — `docs/specs/feat-071-battlefield-ground-depth.md`를 추가했다. battle view origin을 아래로 내려 필드와 유닛을 바닥 영역에 맞추고, 필드 아래 `battlefield_ground_plate` meta 지면 plate/shadow를 추가했다. field/building/unit 레이어 z-order와 유닛 screen-y depth를 고정해 유닛이 필드 타일 뒤에 렌더되지 않게 했다. UI smoke가 지면 plate와 field < unit depth를 검증한다. `./init.sh` 카드 22개 / 2992 단언 green.
- [x] **feat-070 결과 화면 시각 polish** — `docs/specs/feat-070-result-screen-polish.md`를 추가했다. `BattleOutcomeGuide`가 결과 배너 제목/상세/다음 행동을 순수 계산하고, battle 결과 오버레이 최상단이 `결과 — 성 함락`, `결과 — 구주 정복`, `결과 — 전투 승리`와 다음 행동을 표시한다. battle result smoke와 UI smoke가 패배/최종승리/일반승리 보상 화면 배너를 검증한다. `./init.sh` 카드 22개 / 2992 단언 green.
- [x] **feat-069 스크린샷 validator 속도 최적화** — `docs/specs/feat-069-screenshot-validator-speed.md`를 추가했다. `tools/validate_screenshot_bundle.py` 기본 경로가 fast PNG mode로 바뀌어 PNG 구조, 해상도, 압축 스트림 샘플 다양성을 빠르게 검사한다. 기존 행 unfilter 픽셀 복원은 `--png-mode deep`으로 유지했다. `/tmp/guju-feat-068-ui` 11장 기준 fast 0.18초, deep 32.67초 통과. `./init.sh` 카드 22개 / 2983 단언 green.
- [x] **feat-068 첫 보드 스크린샷 QA 갱신** — `docs/specs/feat-068-first-board-screenshot-qa.md`를 추가했다. `tools/shoot_first_board_states.gd`가 `성 후보`, `손패 선택`, `계략 버튼`, `배치 가능` 4상태 PNG를 생성하고, `shoot_ui_bundle.sh`와 `validate_screenshot_bundle.py`가 이를 요구한다. validator는 PIL 의존성을 제거하고 표준 라이브러리 PNG 검사로 바뀌었다. `/tmp/guju-feat-068-ui` 최소 bundle 11장 검증과 `./init.sh` 카드 22개 / 2983 단언 green.
- [x] **feat-067 첫 전투 보드 가독성 polish** — `docs/specs/feat-067-first-board-readability.md`를 추가했다. 첫 배치 보드 빈 타일이 성 선택 전 `성 후보`, 성 선택 후 `손패 선택`, 계략 선택 시 `계략 버튼`, 유닛/건물 선택 시 `배치 가능` label과 tooltip을 표시한다. UI smoke가 4상태를 검증한다. `./init.sh` 카드 22개 / 2982 단언 green.
- [x] **feat-066 전투 유닛 접지감 보강** — `docs/specs/feat-066-unit-grounding.md`를 추가했다. battle visual이 root shadow에 `ground_shadow` meta를 붙이고, 분대/호위 병사와 장수 본체 발밑에 작은 shadow를 생성한다. 장수 본체 오프셋은 -18px에서 -10px로 낮춰 공중에 뜬 느낌을 줄였다. UI smoke가 첫 수동 전투의 ground shadow meta 생성을 검증한다. `./init.sh` 카드 22개 / 2982 단언 green.
- [x] **feat-065 전투 화면 정보 밀도 정리** — `docs/specs/feat-065-battle-status-ribbon.md`와 `BattleHudState.combat_summary`를 추가했다. battle top-center HUD가 `전황 — 배치 준비/교전`, stage, 파도, 아군/적 visible soldiers, 속도/정지/auto 상태와 병력 기준 tooltip을 표시한다. `tools/ui_feedback_smoke.gd`가 배치와 첫 교전 전황 요약을 검증한다. `./init.sh` 카드 22개 / 2982 단언 green.
- [x] **feat-064 장기런 결과 요약 UX** — `docs/specs/feat-064-run-result-summary.md`와 `RunResultSummary`를 추가했다. battle 결과 오버레이가 run_complete일 때 `런 결산 — 승리/패배`, 스테이지, 점수, 군세, 최고 Lv, 골드, 칙령/보패/손패/드로우 요약을 표시한다. `tools/battle_result_smoke.gd`가 패배/최종승리 결과 화면의 결산 문구와 tooltip을 검증한다. `./init.sh` 카드 22개 / 2972 단언 green.
- [x] **feat-063 상점 구매 피드백** — `docs/specs/feat-063-shop-purchase-feedback.md`와 `ShopPurchaseFeedback`을 추가했다. run_map 상점 카드가 `구매 가능 — N금, 구매 후 M금` 또는 `자금 부족 — N금 필요, 현재 M금`을 표시하고, 구매 성공 뒤 `구매 완료`, 남은 자금, 다음 전투 후보 3장 정리 안내를 남긴다. UI smoke가 고자금/저자금 상점과 구매 완료 문구를 검증한다. `./init.sh` 카드 22개 / 2946 단언 green.
- [x] **feat-062 런맵 진행 리듬 안내** — `docs/specs/feat-062-run-flow-rhythm-guide.md`와 `RunFlowSummary`를 추가했다. run_map 전투/칙령/상점/사건 화면이 `진행 리듬 — 현재 ...`, `현재 행동`, `다음 흐름: 2 전투 -> 3 칙령 -> 4 상점` 같은 안내를 표시한다. UI smoke가 첫 전투와 상점의 다음 흐름/tooltip을 검증한다. `./init.sh` 카드 22개 / 2920 단언 green.
- [x] **feat-061 전투 결과 복귀 안내** — `BattleOutcomeGuide`로 패배/최종승리/일반승리 결과 안내와 버튼 tooltip을 분리했다. battle 결과 오버레이가 `런 종료`/`런 계속` 안내를 표시하고, 다음 스테이지 버튼은 현재 런 유지, 새 런 버튼은 현재 런 포기 또는 완료 기록 보존을 말한다. `./init.sh` 카드 22개 / 2890 단언 green.
- [x] **feat-060 상점 손패 정리 안내** — `ShopHandSummary`가 상점 손패와 다음 전투 후보 3장의 차이를 계산한다. run_map 상점 패널이 `다음 전투 손패 — 후보 3장 중 1장`, 구매 후 `상점 손패 4장 → 전투 후보 3장`, 드로우 더미 tooltip을 표시한다.
- [x] **feat-059 자동저장 슬롯 삭제 UX** — 군주 선택 화면에서 유효 저장/손상 저장 모두 `저장된 런 삭제` 버튼을 표시하고 autosave 슬롯 삭제 후 새 런 시작 상태로 복구한다.
- [x] **feat-058 다음 배치 손패 미리보기** — `RunState.deploy_hand_preview()`와 RunManager preview API가 다음 전투 후보 3장을 비파괴 계산하고 run_map/battle 결과 안내가 드로우 더미 정리를 표시한다.
- [x] **feat-057 런맵 전투 준비 패널 강화** — `RunPrepSummary`가 성 위치, 손패 3장 중 1장 규칙, 군세, 증원/배치/계략 후보 수를 표시한다.
- [x] **feat-056 보상 후 다음 스테이지 준비 안내** — `StageCadence.stage_prep_label/tooltip`이 결과 오버레이와 다음 스테이지 버튼의 다음 행동 문구를 제공한다.
- [x] **feat-055 보상 선택 비교 UX** — `CardChoiceAdvisor`가 전리품 후보의 선택 전후 변화를 `비교 — ...` 문구와 tooltip으로 설명한다.
- [x] **feat-038~054 MVP 이후 루프 보강** — 성 선점→3장 손패→1장 플레이, 분대/증원 성장, 군세 체감, 진형 전술, 수동 QA, 전투 템포, 카드 추천순, 저장/이어하기 UX, 병력 밀도/함성 VFX, 피격 VFX, 손상 저장 보호를 완료했다.
- [x] **v0.7 릴리스 준비 기준선** — 밸런스 수치 계약, macOS export preset, full app export smoke, fresh clone green, 릴리스 리스크 문서를 완료했다.

## 진행 중
- [ ] 수동 플레이 감각 확인 — 첫 손패 장수+병종, 성 위치 선택, 1장 배치/증원, 전군 돌격 피드백, stage 3 칙령, stage 4 상점, 전리품 추천 문구를 사용자 플레이로 확인한다.
- [ ] 완성판 안전 개선 계속 — 다음 후보는 GUI screenshot bundle 실촬영, 수동 플레이 시각 검증 갱신, 전투 템포/중후반 보스 시간 추가 개선이다.
- [ ] Codex goal은 완성판까지 계속 활성이다. MVP 이후 핵심 루프 재미와 안정성을 단계적으로 개선한다.

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
- `docs/specs/feat-075-battlefield-ground-plane-readability.md`
- `scripts/battle/battle.gd`
- `test/test_unit_walk_visuals.gd`
- `tools/ui_feedback_smoke.gd`
- `feature_list.json`
- `progress.md`
- `session-handoff.md`
- `CHANGELOG.md`

## 직전 피처 수정 파일
- `docs/specs/feat-070-result-screen-polish.md`
- `scripts/battle/battle_outcome_guide.gd`
- `scripts/battle/battle.gd`
- `test/test_battle_outcome_guide.gd`
- `tools/battle_result_smoke.gd`, `tools/ui_feedback_smoke.gd`
- `feature_list.json`
- `progress.md`
- `session-handoff.md`
- `CHANGELOG.md`

## 이전 피처 수정 파일
- `docs/specs/feat-068-first-board-screenshot-qa.md`
- `tools/shoot_first_board_states.gd`
- `tools/shoot_first_board_states.tscn`
- `tools/shoot_ui_bundle.sh`
- `tools/validate_screenshot_bundle.py`
- `test/test_visual_qa_config.gd`
- `feature_list.json`
- `progress.md`
- `session-handoff.md`
- `CHANGELOG.md`

## 검증 증거
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-075-unit.log --script res://test/runner.gd` (2026-06-06, feat-075) — 단위 테스트 3018/3018 green.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-075-ui.log --script res://tools/ui_feedback_smoke.gd` (2026-06-06, feat-075) — 전장 보드 지면 밴드, tile contact shadow, 교전 중 `IsoBaseLayer` 숨김 포함 UI smoke green.
- [x] `./init.sh` (2026-06-06, feat-075) — 카드 22개 검증 OK, UI smoke와 장기런 스모크 포함, 단위 테스트 3018/3018 green.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-074-unit.log --script res://test/runner.gd` (2026-06-06, feat-074) — 단위 테스트 3012/3012 green.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-074-playtest.log --script res://tools/playtest_loop_smoke.gd` (2026-06-06, feat-074) — stage 1/2/5 아군 12/20/32명, 전체 37/36/42명, 시간 21.1/18.3/14.6초로 강화 metric 통과.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-074-ui.log --script res://tools/ui_feedback_smoke.gd` (2026-06-06, feat-074) — 전투 손패 `12명 분대` tooltip과 첫 교전 `아군 12` 요약 포함 UI smoke green.
- [x] `./init.sh` (2026-06-06, feat-074) — 카드 22개 검증 OK, 강화된 playtest loop와 UI smoke 포함, 단위 테스트 3012/3012 green.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-073-unit.log --script res://test/runner.gd` (2026-06-06, feat-073) — 단위 테스트 3010/3010 green.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-073-ui.log --script res://tools/ui_feedback_smoke.gd` (2026-06-06, feat-073) — 첫 수동 전투 `advance_dust` 18개와 `ground_clash` 3개 포함 UI smoke green.
- [x] `./init.sh` (2026-06-06, feat-073) — 카드 22개 검증 OK, UI smoke와 장기런 스모크 포함, 단위 테스트 3010/3010 green.
- [x] `HOME=$PWD/.godot/home LORD=lord_liubei SHOOT_STAGE=1 SHOOT_FIGHT_FRAMES=1 SHOT_DIR=/tmp/guju-shot-scene-fixed godot --headless --path . --scene res://tools/shoot_battle.tscn` (2026-06-06, feat-072) — 전투 deploy/fight가 `SHOT FAIL ... headless_display`로 종료, hang 없음.
- [x] `HOME=$PWD/.godot/home LORD=lord_liubei SHOOT_STAGE=1 SHOT_DIR=/tmp/guju-first-board-fixed godot --headless --path . --scene res://tools/shoot_first_board_states.tscn` (2026-06-06, feat-072) — 첫 보드 4상태가 headless_display fail로 종료, hang 없음.
- [x] `HOME=$PWD/.godot/home SCENE=res://scenes/screens/lord_select.tscn SHOT_KIND=lord_select SHOT_DIR=/tmp/guju-scene-fixed godot --headless --path . --scene res://tools/shoot_scene.tscn` (2026-06-06, feat-072) — 범용 scene 하네스 headless 종료, hang 없음.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --script res://test/runner.gd` (2026-06-06, feat-072) — 단위 테스트 2994/2994 green.
- [x] `./init.sh` (2026-06-06, feat-072) — 카드 22개 검증 OK, screenshot 하네스 계약 변경 포함, 단위 테스트 2994/2994 green.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-071-ui.log --script res://tools/ui_feedback_smoke.gd` (2026-06-06, feat-071) — `battlefield_ground_plate`와 field < unit depth 포함 UI smoke green.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-071-unit.log --script res://test/runner.gd` (2026-06-06, feat-071) — 단위 테스트 2992/2992 green.
- [x] `./init.sh` (2026-06-06, feat-071) — 카드 22개 검증 OK, UI 피드백 smoke와 단위 테스트 2992/2992 포함 전체 green.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-070-unit.log --script res://test/runner.gd` (2026-06-06, feat-070) — 단위 테스트 2992/2992 green.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-070-result.log --script res://tools/battle_result_smoke.gd` (2026-06-06, feat-070) — 패배 `결과 — 성 함락`, 최종승리 `결과 — 구주 정복`, 새 런 행동 배너 확인.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-070-ui.log --script res://tools/ui_feedback_smoke.gd` (2026-06-06, feat-070) — 일반승리 보상 화면 `결과 — 전투 승리`, `다음 행동 — 전리품 선택 후 런맵 복귀` 확인.
- [x] `./init.sh` (2026-06-06, feat-070) — 카드 22개 검증 OK, 결과 배너 smoke 포함, 단위 테스트 2992/2992 green.
- [x] `PYTHONPYCACHEPREFIX=/tmp/guju-pycache python3 -m py_compile tools/validate_screenshot_bundle.py` 및 fast/deep screenshot validator (2026-06-06, feat-069) — `/tmp/guju-feat-068-ui` 11장 fast 0.18s, deep 32.67s 통과.
- [x] feat-068~feat-062의 자세한 검증 로그는 `CHANGELOG.md`와 각 `docs/specs/`에 보관했다.

## 다음 세션 메모
feat-075 done. 다음 안전 피처는 GUI screenshot bundle 실촬영, 수동 플레이 시각 검증 갱신, 전투 템포/중후반 보스 시간 추가 개선이 좋다. 천계·마계 확장은 정본 승인 전 시작하지 않는다. push와 tag는 사용자 확인 후에만 실행한다.
