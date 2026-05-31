# 스펙 — feat-015c 수동 보드 배치 + 보상 드래프트 + 우물

Claude(편집장)가 작성한 구현 스펙. Codex(구현자)가 이 문서·`AGENTS.md`·`CLAUDE.md`·`docs/design-loop.md`·`docs/specs/feat-015.md`·`docs/specs/feat-015b.md`를 읽고 구현한다. 완료 후 `./init.sh` 전체 green.

## 배경 — 배치 agency 복원
feat-015b가 보드 군세를 자동 배치(start_run이 보드 채움, 보상 add_card 자동)해서, **플레이어가 배치를 고르는 핵심 agency가 빠졌다.** 이 피처가 **수동 배치**를 복원한다 — 손패에서 카드를 골라 보드의 원하는 블록에 배치한다. 보드는 영속(015b의 build_board_army 스폰 그대로). 상점은 feat-015d.

## 모델
- **start_run → 손패** — 군주 시작 카드를 **손패**에 넣는다(보드는 빈 채). 플레이어가 첫 전투 배치 단계에서 보드에 깐다. (자동 보드 채움 제거.)
- **배치 = 플레이어 행동** — 전투 씬 배치 단계에서 손패 카드 선택 → 빈 블록 클릭 → `place_from_hand`로 보드에 영속 배치.
- **우물 버리기** — 손패 카드 선택 → 우물 버튼 → `discard_from_hand`(+10 골드).
- **전투 시작** — 보드에 1장 이상 있으면 가능. 015b의 보드 군세 스폰으로 싸운다.
- **보상 → 손패** — 승리 시 후보 3장 중 1장 선택 → `hand_add`(보드 자동 배치 아님). 다음 전투 배치 단계에서 배치/우물.
- 손패 한도 — `HAND_MAX=3`는 v1에서 소프트(초과 시 경고만, 하드 차단 없음). 엄격 강제(드래프트 후 3장 해소)는 후속 튜닝. 시작 손패는 시작 카드 수만큼 허용.

## 스코프 (이 파일들)
- `scripts/battle/battle.gd` — 배치 단계 복원(손패 표시·카드 선택→블록 배치·우물 버튼·보드 갱신) + 전투 시작. 015b의 보드 스폰·읽기전용 타일을 **배치 가능 타일 + 손패 UI**로 교체.
- `scripts/run/run_state.gd` — `start_run`이 시작 카드를 **board 대신 hand**에 넣는다.
- `scripts/autoloads/run_manager.gd` — 보상이 `add_card`(→보드) 대신 `hand_add`(→손패)로 가도록. `get_hand`/`place_from_hand`/`discard_from_hand`/`get_gold` 위임(일부 015에 있음).
- 테스트 — `test/test_run_board.gd`·`test/test_board_army.gd`의 start_run 기대(보드→손패)·보상 기대(보드→손패) 갱신. 배치/우물 흐름 단위 테스트 보강.
- **유지(수정 금지)** — `scripts/battle/battle_sim.gd`·`battle_unit.gd`·`card_catalog.gd`(build_board_army 그대로)·`target_rules`·`skill_system`·`wave_factory`, `scenes/screens/*`, `resources/.tres`, RunMap, TypeChart.

## 불변식
- RunState 순수·결정적. place_from_hand/discard_from_hand는 015 모델 그대로 사용.
- `./init.sh` run_map·battle 부팅 스모크 유지 — battle.tscn standalone은 시작 손패가 차 있고 배치 단계에서 대기(입력 없으면 전투 미시작, 크래시 없음).
- 보드 스폰(build_board_army)·오픈필드·성·영웅·타겟AI 그대로.

## 테스트 지침
- `start_run` 후 `hand`에 시작 카드(6), `board` 빈, `gold` 0.
- 보상(RunManager 보상 경로) → hand_add(손패 +1), 보드 자동 배치 아님.
- place_from_hand로 손패→보드 이동(손패 -1, 보드 +1, owned 불변), 우물 버리기 손패 -1·gold +10.
- build_board_army는 플레이어가 깐 board로 군세 생성(015b 그대로).
- 기존 테스트 회귀 없이 통과(start_run·보상 기대 갱신분 포함).

## 범위 밖 (후속)
- feat-015d — 상점 노드(4스테이지마다, 골드로 구매→손패).
- 손패 3 엄격 강제(드래프트 후 해소), 보드 재배치/회수, "상대 진영 카드" 보상(6국).

## 제약 (AGENTS.md)
- 비-자명한 새 파일 한 줄 한국어 헤더. 한국어 문장 `:` 종결 금지. GDScript 탭.
- `git commit`·`push` 금지. 회귀 금지. 네트워크 불필요.
- 끝나면 `./init.sh` 전체 green 증거로 "무엇이/왜/검증결과/남은모호함" 보고.

## 완료 기준 (Definition of Done)
- [ ] start_run → 손패, 보상 → 손패(자동 보드 배치 제거).
- [ ] battle.gd 배치 단계 복원 — 손패 카드 선택 → 블록 배치, 우물 버리기, 전투 시작.
- [ ] 보드 스폰(build_board_army)으로 전투 진행(015b 유지).
- [ ] 테스트 갱신·보강, 전체 단위 테스트 통과.
- [ ] `./init.sh` 전체 green(부팅 스모크), 종료 0, 스코프 외 미수정.
