# 진행 로그

이 파일은 재시작 상태용이다. 전체 이력은 `CHANGELOG.md`, `docs/specs/`, `session-handoff.md`를 본다. 120줄 이하로 유지한다.

## 현재 상태
**마지막 갱신** — 2026-06-06
**활성 피처** — feat-053 충돌 중 타격감 VFX 반복 완료
**현재 목표** — 완성판까지 Codex goal을 유지한다. 이번 단위는 전투 중 데미지 이벤트가 실제 타격처럼 반복해서 보이도록 피격 VFX를 추가한 작업이다.

## 완료
- [x] **feat-053 충돌 중 타격감 VFX 반복** — `docs/specs/feat-053-hit-impact-feedback.md`와 `scripts/battle/battle_hit_feedback.gd`를 추가했다. 데미지 이벤트가 positive amount일 때 spark를 만들고, 치명타는 crit ring, 스킬/계략은 burst를 추가한다. `battle.gd`는 `hit_impact_vfx` meta가 있는 Polygon2D를 VFX layer에 띄우며, UI smoke가 첫 수동 전투에서 spark/crit/burst 생성을 검증한다. `./init.sh` 카드 22개 / 2769 단언 green.
- [x] **feat-052 병력 밀도/함성 체감 패스** — `docs/specs/feat-052-force-density-and-rally.md`를 추가했다. 병종 분대 렌더/visible cap을 18명, 장수 호위 cap을 10명으로 올리고, `rally` SFX cue를 기존 전투 시작 wav에 연결했다. battle.gd가 시작 순간 rally banner, charge line, clash pulse를 meta 태그로 표시하고 UI smoke가 첫 수동 플레이에서 검증한다. `./init.sh` 카드 22개 / 2746 단언 green.
- [x] **feat-051 저장/이어하기 UX 스모크** — `docs/specs/feat-051-resume-ux-smoke.md`와 `tools/resume_ux_smoke.gd`를 추가했다. 저장 파일이 없으면 군주 선택 화면에 이어하기 버튼이 없고, autosave 런이 있으면 `저장된 런 이어하기` 버튼/tooltip이 보인다. 버튼 실행 후 run_map route와 stage, 성 위치, 보드, 손패, 골드 복원을 검증한다. `./init.sh` 카드 22개 / 2740 단언 green.
- [x] **feat-050 카드 선택 추천순 정렬** — `docs/specs/feat-050-card-choice-priority.md`를 추가했다. `CardChoiceAdvisor.ranked_ids()`가 추천 점수순 stable sort를 제공하고, run_map 상점과 battle 전리품 버튼이 이 순서로 렌더된다. 상점에서는 살 수 없는 카드는 뒤로 밀리며, UI smoke가 보병 증원 후보가 첫 추천 카드로 올라오는지 검증한다. `./init.sh` 카드 22개 / 2740 단언 green.
- [x] **feat-049 전투 템포 예산** — `docs/specs/feat-049-battle-tempo-budget.md`를 추가했다. battle 화면 기본 속도를 x3으로 올리고, UI smoke가 x3 버튼 기본 선택을 확인한다. `PlaytestMetrics.first_five_ok()`는 첫 5스테이지 전투를 개별 24초, 평균 20초 이하로 검증하며 `test_fun_contract.gd`가 느린 전투 회귀를 잡는다. `./init.sh` 카드 22개 / 2734 단언 green.
- [x] **feat-048 수동 플레이 QA 자동화** — `docs/specs/feat-048-manual-playthrough-smoke.md`를 추가했다. `tools/ui_feedback_smoke.gd`가 첫 손패를 계략/보병/건물로 고정하고 성 선택, 계략 타일 배치 거부, 보병 배치, 즉시 교전 시작을 검증한다. 교전 시작 후 성/아군/적 생성, 손패 감소, 교전당 1장 제한, 전군 돌격 hint를 확인한다. `./init.sh` 카드 22개 / 2731 단언 green.
- [x] **feat-047 현세 3군주 장기런 스모크** — `docs/specs/feat-047-three-lord-long-run-smoke.md`를 추가했다. `tools/long_run_smoke.gd`가 유비·조조·손권을 각각 새 런으로 시작해 stage 15 최종 보스까지 통과한다. 스모크 선택기는 건물 배치, 망루 오라, 계략 battle/run 효과, 병법서 보패를 반영한다. 조조 첫 정예에서 막히던 원거리 스파이크를 `WaveFactory` 정예 명궁 수치로 좁게 보정했고, 손권은 주유 우선 루트로 오나라 화공 축을 검증한다. `./init.sh` 카드 22개 / 2731 단언 green.
- [x] **feat-046 카드 선택 전략 안내** — `docs/specs/feat-046-card-choice-advisor.md`와 `scripts/run/card_choice_advisor.gd`를 추가했다. run_map 상점 카드와 battle 전리품 버튼이 `추천 — 증원 후보`, `추천 — 경제 확장`, `추천 — 자금 부족` 같은 visible text와 tooltip을 표시한다. `test_card_choice_advisor.gd`와 `tools/ui_feedback_smoke.gd`가 전략 추천 렌더를 검증한다. `./init.sh` 카드 22개 / 2726 단언 green.
- [x] **feat-045 집중표적 체감 피드백** — 전투 중 집중표적 버튼 tooltip, 성공/실패 힌트, 표적 위 `집중` 라벨, 장수→표적 지휘선, 사망/빈 곳 자동 복귀 문구를 추가했다. `./init.sh` 카드 22개 / 2701 단언 green.
- [x] **feat-044 장기런 자동 스모크** — `tools/long_run_smoke.gd`가 stage 1~15 전투·보스·칙령·상점·사건·확장을 결정적으로 통과한다. stage 15 result=1, wins=8, board=4, rows=6.
- [x] **feat-040~043 MVP 재미 루프 보강** — 성 위치 선택, 3장 손패 중 1장 플레이, 분대/증원 성장, 첫 전투 군세 체감, 진형 전술 시너지, 배치 전술 미리보기를 완료했다.
- [x] **feat-038~039 루프 hotfix** — 방어전식 다중 파도 느낌을 성 선점→단일 교전으로 바꾸고, 장수/병종을 분대와 레벨 성장 단위로 바꿨다.
- [x] **v0.7 릴리스 준비 기준선** — 밸런스 수치 계약, macOS export preset, full app export smoke, fresh clone green, 릴리스 리스크 문서를 완료했다.

## 진행 중
- [ ] 수동 플레이 감각 확인 — 첫 손패 장수+병종, 성 위치 선택, 1장 배치/증원, 전군 돌격 피드백, stage 3 칙령, stage 4 상점, 전리품 추천 문구를 사용자 플레이로 확인한다.
- [ ] 완성판 안전 개선 계속 — 다음 피처 후보는 저장/재시작 실패/손상 파일 UX 보강, 보상 화면 선택 비교 UX, 전투 결과/보상 화면의 플레이어 선택 설명 강화다.
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
- `docs/specs/feat-053-hit-impact-feedback.md`
- `scripts/battle/battle_hit_feedback.gd`
- `scripts/battle/battle.gd`
- `tools/ui_feedback_smoke.gd`
- `test/test_battle_hit_feedback.gd`
- `feature_list.json`
- `progress.md`
- `session-handoff.md`
- `CHANGELOG.md`

## 검증 증거
- [x] `godot --headless --path . --script res://test/runner.gd` (2026-06-06, feat-053) — `test_battle_hit_feedback.gd` 포함 단위 테스트 2769/2769 green.
- [x] `godot --headless --path . --script res://tools/ui_feedback_smoke.gd` (2026-06-06, feat-053) — 첫 수동 플레이에서 시작 함성 VFX와 hit impact spark/crit/burst VFX 생성 확인.
- [x] `./init.sh` (2026-06-06, feat-053) — 카드 22개 검증 OK, 저장/이어하기 UX 스모크와 병력 밀도/함성/피격 VFX UI smoke 포함, 단위 테스트 2769/2769 green.
- [x] `godot --headless --path . --script res://tools/ui_feedback_smoke.gd` (2026-06-06, feat-052) — 첫 수동 플레이에서 시작 함성 힌트, rally banner, charge line, clash pulse VFX 확인.
- [x] `godot --headless --path . --script res://test/runner.gd` (2026-06-06, feat-052) — BattleFeel cap/rally cue, FormationRenderer cap, AudioManager rally cue 포함 단위 테스트 2746/2746 green.
- [x] `./init.sh` (2026-06-06, feat-052) — 카드 22개 검증 OK, 저장/이어하기 UX 스모크와 병력 밀도/함성 UI smoke 포함, 단위 테스트 2746/2746 green.
- [x] `godot --headless --path . --script res://tools/resume_ux_smoke.gd` (2026-06-06, feat-051) — no-save 이어하기 미노출, autosave 런 이어하기 버튼/tooltip, run_map route, stage/성/보드/손패/골드 복원 확인.
- [x] `./init.sh` (2026-06-06, feat-051) — 카드 22개 검증 OK, 저장/이어하기 UX 스모크 포함, 단위 테스트 2740/2740 green.
- [x] `godot --headless --path . --script res://tools/ui_feedback_smoke.gd` (2026-06-06, feat-050) — 상점 추천순 첫 카드가 `추천 — 증원 후보`로 렌더됨을 포함해 UI 스모크 통과.
- [x] `./init.sh` (2026-06-06, feat-050) — 카드 22개 검증 OK, CardChoiceAdvisor ranked_ids 테스트와 상점/보상 추천순 렌더 포함, 단위 테스트 2740/2740 green.
- [x] `godot --headless --path . --script res://tools/playtest_loop_smoke.gd` (2026-06-06, feat-049) — stage 1/2/5 전투 21.1s/18.3s/14.6s로 개별 24초와 평균 20초 예산 통과.
- [x] `./init.sh` (2026-06-06, feat-049) — 카드 22개 검증 OK, UI 스모크 기본 x3 검증 포함, PlaytestMetrics tempo budget 테스트 포함, 단위 테스트 2734/2734 green.
- [x] `godot --headless --path . --script res://tools/ui_feedback_smoke.gd` (2026-06-06, feat-048) — 첫 수동 플레이 smoke 통과. 성 선택, 계략 타일 배치 거부, 보병 배치 후 전투 phase, 성/아군/적 생성, 전군 돌격 hint 확인.
- [x] `./init.sh` (2026-06-06, feat-048) — 카드 22개 검증 OK, UI 스모크에 전투 수동 첫 플레이 OK 추가, 단위 테스트 2731/2731 green.
- [x] `godot --headless --path . --script res://tools/long_run_smoke.gd` (2026-06-06, feat-047) — 유비·조조·손권 각각 wins=8, board=5, rows=6, stage 15 final boss 통과. Godot 종료 resource leak 경고는 기존 headless 경고이며 종료 코드는 0.
- [x] `./init.sh` (2026-06-06, feat-047) — 카드 22개 검증 OK, 3군주 장기런 스모크 통과, test_wave_factory stage 7 정예 수치 검증 포함, 단위 테스트 2731/2731 green.
- [x] `./init.sh` (2026-06-06, feat-046) — 카드 22개 검증 OK, CardChoiceAdvisor 전역 클래스 등록, run_map/battle/보스/result/UI 스모크 통과, UI 스모크에 상점·보상 추천 문구 검증 포함, 플레이테스트 루프 stage 1/2/5 전투 21.1s/18.3s/14.6s, 장기런 stage 15 result=1·wins=8·board=4·rows=6, 단위 테스트 2726/2726 green.
- [x] `./init.sh` (2026-06-06, feat-045) — 카드 22개 검증 OK, 전투 집중표적 피드백 OK, 단위 테스트 2701/2701 green.

## 다음 세션 메모
`./init.sh` 2769 단언 green. feat-053 done. 다음 안전 피처는 저장/재시작 실패/손상 파일 UX 보강, 보상 화면 선택 비교 UX, 전투 결과/보상 화면의 선택 설명 강화가 좋다. 천계·마계 확장은 정본 승인 전 시작하지 않는다. push와 tag는 사용자 확인 후에만 실행한다.
