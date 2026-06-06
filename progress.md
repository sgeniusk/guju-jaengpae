# 진행 로그

이 파일은 재시작 상태용이다. 전체 이력은 `CHANGELOG.md`, `docs/specs/`, `session-handoff.md`를 본다. 120줄 이하로 유지한다.

## 현재 상태
**마지막 갱신** — 2026-06-06
**활성 피처** — feat-069 스크린샷 validator 속도 최적화 완료
**현재 목표** — 완성판까지 Codex goal을 유지한다. 이번 단위는 screenshot bundle validator의 기본 경로를 빠르게 만들어 QA 반복 비용을 줄이는 작업이다.

## 완료
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
- [ ] 완성판 안전 개선 계속 — 다음 후보는 결과 화면 시각 polish, 수동 플레이 시각 검증 갱신, 전투 화면 체감 polish다.
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

## 이번 세션 수정 파일
- `docs/specs/feat-069-screenshot-validator-speed.md`
- `tools/validate_screenshot_bundle.py`
- `feature_list.json`
- `progress.md`
- `session-handoff.md`
- `CHANGELOG.md`

## 직전 피처 수정 파일
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

## 이전 피처 수정 파일
- `docs/specs/feat-067-first-board-readability.md`
- `scripts/battle/battle.gd`
- `tools/ui_feedback_smoke.gd`
- `feature_list.json`
- `progress.md`
- `session-handoff.md`
- `CHANGELOG.md`

## 더 이전 피처 수정 파일
- `docs/specs/feat-066-unit-grounding.md`
- `scripts/battle/battle.gd`
- `tools/ui_feedback_smoke.gd`
- `feature_list.json`
- `progress.md`
- `session-handoff.md`
- `CHANGELOG.md`

## 검증 증거
- [x] `PYTHONPYCACHEPREFIX=/tmp/guju-pycache python3 -m py_compile tools/validate_screenshot_bundle.py` (2026-06-06, feat-069) — Python 문법 검사 통과.
- [x] `/usr/bin/time -p python3 tools/validate_screenshot_bundle.py /tmp/guju-feat-068-ui --lords lord_liubei --flow-stages 1 --battle-stage 1 --shop-stage 4 --result-lord lord_liubei --result-loss-stage 3 --result-win-stage 15 --first-board-lord lord_liubei --first-board-stage 1` (2026-06-06, feat-069) — fast PNG mode 11장 검증 통과, real 0.18s.
- [x] `/usr/bin/time -p python3 tools/validate_screenshot_bundle.py /tmp/guju-feat-068-ui --lords lord_liubei --flow-stages 1 --battle-stage 1 --shop-stage 4 --result-lord lord_liubei --result-loss-stage 3 --result-win-stage 15 --first-board-lord lord_liubei --first-board-stage 1 --png-mode deep` (2026-06-06, feat-069) — deep PNG mode 11장 검증 통과, real 32.67s.
- [x] `./init.sh` (2026-06-06, feat-069) — 카드 22개 검증 OK, 단위 테스트 2983/2983 green.
- [x] `HOME=$PWD/.godot/home SHOT_DIR=/tmp/guju-feat-068-first-board LORD=lord_liubei SHOOT_STAGE=1 godot --path . res://tools/shoot_first_board_states.tscn` (2026-06-06, feat-068) — 첫 보드 `성 후보`/`손패 선택`/`계략 버튼`/`배치 가능` 4 PNG 생성.
- [x] `python3 tools/validate_screenshot_bundle.py /tmp/guju-feat-068-ui --lords lord_liubei --flow-stages 1 --battle-stage 1 --shop-stage 4 --result-lord lord_liubei --result-loss-stage 3 --result-win-stage 15 --first-board-lord lord_liubei --first-board-stage 1` (2026-06-06, feat-068) — 최소 bundle 11장 stdlib PNG 검증 통과.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-068-unit.log --script res://test/runner.gd` (2026-06-06, feat-068) — 단위 테스트 2983/2983 green.
- [x] `./init.sh` (2026-06-06, feat-068) — 카드 22개 검증 OK, 단위 테스트 2983/2983 green.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-067-ui.log --script res://tools/ui_feedback_smoke.gd` (2026-06-06, feat-067) — 첫 보드 `성 후보`, `손패 선택`, `계략 버튼`, `배치 가능` label/tooltip 포함 UI smoke green.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-067-unit.log --script res://test/runner.gd` (2026-06-06, feat-067) — 단위 테스트 2982/2982 green.
- [x] `./init.sh` (2026-06-06, feat-067) — 카드 22개 검증 OK, 첫 보드 가독성 UI smoke 포함, 단위 테스트 2982/2982 green.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-066-ui.log --script res://tools/ui_feedback_smoke.gd` (2026-06-06, feat-066) — 첫 수동 전투 ground shadow meta 노드 생성 포함 UI smoke green.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-066-unit.log --script res://test/runner.gd` (2026-06-06, feat-066) — 단위 테스트 2982/2982 green.
- [x] `./init.sh` (2026-06-06, feat-066) — 카드 22개 검증 OK, ground shadow UI smoke 포함, 단위 테스트 2982/2982 green.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-065-unit-3.log --script res://test/runner.gd` (2026-06-06, feat-065) — BattleHudState combat summary helper 포함 단위 테스트 2982/2982 green.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-065-ui-3.log --script res://tools/ui_feedback_smoke.gd` (2026-06-06, feat-065) — 배치 전 `전황 — 배치 준비`, 첫 교전 `전황 — 교전`, `아군 10`, `적 25`, 병력 기준 tooltip 렌더 확인.
- [x] `./init.sh` (2026-06-06, feat-065) — 카드 22개 검증 OK, 전투 전황 요약 UI smoke 포함, 단위 테스트 2982/2982 green.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-064-unit-2.log --script res://test/runner.gd` (2026-06-06, feat-064) — RunResultSummary helper 포함 단위 테스트 2972/2972 green.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-064-result-2.log --script res://tools/battle_result_smoke.gd` (2026-06-06, feat-064) — 패배/최종승리 결과 화면 `런 결산` 문구와 tooltip 렌더 확인.
- [x] `./init.sh` (2026-06-06, feat-064) — 카드 22개 검증 OK, battle result smoke 결산 확인 포함, 단위 테스트 2972/2972 green.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-063-unit.log --script res://test/runner.gd` (2026-06-06, feat-063) — ShopPurchaseFeedback helper 포함 단위 테스트 2946/2946 green.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-063-ui.log --script res://tools/ui_feedback_smoke.gd` (2026-06-06, feat-063) — 상점 `구매 가능`, 저자금 `자금 부족`, 구매 후 `구매 완료`와 `남은 자금` 렌더 확인.
- [x] `./init.sh` (2026-06-06, feat-063) — 카드 22개 검증 OK, 저자금 상점 smoke 포함, 단위 테스트 2946/2946 green.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-062-unit.log --script res://test/runner.gd` (2026-06-06, feat-062) — RunFlowSummary helper 포함 단위 테스트 2920/2920 green.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-062-ui.log --script res://tools/ui_feedback_smoke.gd` (2026-06-06, feat-062) — 런맵 첫 전투 `진행 리듬 — 현재 1 전투`, 상점 `다음 흐름: 5 보스 -> 6 칙령 -> 7 정예` 렌더 확인.
- [x] `./init.sh` (2026-06-06, feat-062) — 카드 22개 검증 OK, run_map/lord_select/battle/보스/결과/UI/저장/플레이테스트/장기런 스모크 포함, 단위 테스트 2920/2920 green.

## 다음 세션 메모
feat-069 done. 다음 안전 피처는 결과 화면 시각 polish, 수동 플레이 시각 검증 갱신, 전투 화면 체감 polish가 좋다. 천계·마계 확장은 정본 승인 전 시작하지 않는다. push와 tag는 사용자 확인 후에만 실행한다.
