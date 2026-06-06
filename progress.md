# 진행 로그

이 파일은 재시작 상태용이다. 전체 이력은 `CHANGELOG.md`, `docs/specs/`, `session-handoff.md`를 본다. 120줄 이하로 유지한다.

## 현재 상태
**마지막 갱신** — 2026-06-06
**활성 피처** — feat-062 런맵 진행 리듬 안내 완료
**현재 목표** — 완성판까지 Codex goal을 유지한다. 이번 단위는 런맵에서 현재 스테이지 행동과 앞으로 이어질 전투·칙령·상점·보스 흐름을 읽히게 하는 작업이다.

## 완료
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
- [ ] 완성판 안전 개선 계속 — 다음 후보는 상점 구매 제한/선택 피드백 보강, 장기런 결과 요약 UX, 전투 화면 정보 밀도 정리다.
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
- `docs/specs/feat-062-run-flow-rhythm-guide.md`
- `scripts/run/run_flow_summary.gd`
- `test/test_run_flow_summary.gd`
- `scripts/screens/run_map.gd`
- `tools/ui_feedback_smoke.gd`
- `feature_list.json`
- `progress.md`
- `session-handoff.md`
- `CHANGELOG.md`

## 검증 증거
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-062-unit.log --script res://test/runner.gd` (2026-06-06, feat-062) — RunFlowSummary helper 포함 단위 테스트 2920/2920 green.
- [x] `HOME=$PWD/.godot/home godot --headless --path . --log-file .godot/feat-062-ui.log --script res://tools/ui_feedback_smoke.gd` (2026-06-06, feat-062) — 런맵 첫 전투 `진행 리듬 — 현재 1 전투`, 상점 `다음 흐름: 5 보스 -> 6 칙령 -> 7 정예` 렌더 확인.
- [x] `./init.sh` (2026-06-06, feat-062) — 카드 22개 검증 OK, run_map/lord_select/battle/보스/결과/UI/저장/플레이테스트/장기런 스모크 포함, 단위 테스트 2920/2920 green.

## 다음 세션 메모
feat-062 done. 다음 안전 피처는 상점 구매 제한/선택 피드백 보강 또는 장기런 결과 요약 UX가 좋다. 천계·마계 확장은 정본 승인 전 시작하지 않는다. push와 tag는 사용자 확인 후에만 실행한다.
