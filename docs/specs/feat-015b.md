# 스펙 — feat-015b 보드 기반 전투 (battle from board)

Claude(편집장)가 작성한 구현 스펙. Codex(구현자)가 이 문서·`AGENTS.md`·`CLAUDE.md`·`docs/design-loop.md`·`docs/specs/feat-015.md`를 읽고 구현한다. 완료 후 `./init.sh` 전체 green.

## 목표
전투를 **영속 보드 배치에서 스폰**한다. 지금의 per-battle 배치 단계(카드 선택 + 타일 클릭 + 지휘력)를 제거한다. **보드가 곧 군세** — 매 전투 보드의 카드들이 그 블록 위치에 스폰돼 싸운다. (손패→블록 수동 배치·드래프트·우물·상점은 feat-015c.)

## 동작
- battle.gd `_ready` — `RunManager.get_board()`의 각 (블록키 "col:row" → 카드 id)마다 `position_for_tile(col,row)` 위치에 아군 유닛 스폰(`CardCatalog.build_player_unit` 사용, `unit.row=row`, `set_position`). 성은 기존 `_ensure_castle`로 자동.
- **배치 단계 제거** — 카드 선택 행·타일 클릭 배치·지휘력 패널 제거. 대신 보드 군세 요약(현재 보드 카드 목록)과 "전투 시작" 버튼.
- 3×3 타일은 이제 **보드 배치 표시(읽기 전용)** — 클릭 배치 안 함.
- 유지 — 영웅 조작(전투 중 클릭), 보상 오버레이(승리 3중1 → `RunManager.add_card` 브리지 → 보드), 패배 재시도, 지도 복귀, 파도 라벨, 스킬 플래시.

## 테스트 가능 헬퍼
- `CardCatalog.build_board_army(board: Dictionary, lord: LordData) -> Array[BattleUnit]` 추가(순수) — 블록키 파싱 → 위치 매핑 → build_player_unit. battle.gd가 이걸 호출.
- `RunManager.get_board() -> Dictionary`(보드 복사) 추가.

## 스코프 (이 파일들)
- `scripts/battle/battle.gd` — 보드 스폰 + 배치 단계 제거 + 보드 요약 UI.
- `scripts/resources/card_catalog.gd` — `build_board_army`.
- `scripts/autoloads/run_manager.gd` — `get_board`.
- `test/test_board_army.gd` 신설(또는 test_run_board 확장).
- **유지(수정 금지)** — `scripts/battle/battle_sim.gd`·`battle_unit.gd`·기타 전투 로직, `scripts/run/run_state.gd`·`reward_pool.gd`, `scenes/screens/*`, `resources/.tres`, RunMap, TypeChart/SkillSystem/TargetRules.

## 불변식
- BattleSim·CardCatalog 순수·결정적. build_board_army 결정적.
- `./init.sh` run_map·battle 부팅 스모크 유지(런 시작 시 보드에 시작 카드가 차 있어 battle.tscn이 군세를 스폰). battle.tscn standalone 부팅 안전(RunManager.ensure_started → 보드 채움).
- 오픈필드·성·영웅·타겟AI 그대로.

## 테스트 지침 (test/test_board_army.gd, 순수)
- `build_board_army({"0:0": &"general_guanyu", "1:2": &"troop_archer"}, 유비)` — 2유닛, 각 `position_for_tile(col,row)` 위치·`row` 정확, controllable/target_rule 운반(build_player_unit 경유).
- 빈 보드 → 빈 배열. 잘못된 블록키는 무시(또는 스킵).
- start_run 보드(6장) → build_board_army 6유닛.

## 범위 밖 (feat-015c)
- 손패→블록 **수동 배치** UI, 보상 3중1 **드래프트→손패**, 우물 버리기 UI, 상점 노드(4스테이지). 현재 보상은 브리지(add_card→보드 자동)로 유지.

## 제약 (AGENTS.md)
- 비-자명한 새 파일 한 줄 한국어 헤더. 한국어 문장 `:` 종결 금지. GDScript 탭.
- `git commit`·`push` 금지. 회귀 금지. 네트워크 불필요.
- 끝나면 `./init.sh` 전체 green 증거로 "무엇이/왜/검증결과/남은모호함" 보고.

## 완료 기준 (Definition of Done)
- [ ] battle.gd 보드 스폰 + 배치 단계 제거 + 보드 요약.
- [ ] CardCatalog.build_board_army + RunManager.get_board.
- [ ] test_board_army.gd 신설, 전체 단위 테스트 통과.
- [ ] `./init.sh` 전체 green(부팅 스모크 — 보드 군세 스폰), 종료 0, 스코프 외 미수정.
