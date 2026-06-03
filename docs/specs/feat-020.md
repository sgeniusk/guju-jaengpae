# feat-020 — 땅 확장 (board expansion)

보스 격파 보상으로 보드를 3행→최대 6행(18칸)까지 확장한다. 전장 깊이·타일·스폰이 `board_rows`에 연동된다.

## 분업
Claude(이 스펙·정본·검증) → Codex(GDScript 구현) → Claude(독립 검증) → architect.

## 설계 결정 (편집장)
- **보스 = 확장** — `BOSS_INTERVAL == EXPAND_INTERVAL == 5`. 별도 확장 스테이지를 만들지 않는다(`node_kind`는 보스 우선 유지, expand 분기는 dead code로 둔다). 대신 **보스 격파 보상 화면에 "보드 +1행 확장"을 함께 제공**한다(보스마다 1행, 상한 6행).
- **BattleSim은 static 유지** — `ROW_COUNT`를 인스턴스 변수로 바꾸지 않는다(회귀 위험 큼). 대신 `ROW_X`를 6행 고정 배열로 확장하고, **실제 사용 행 수는 `RunState.board_rows`로 제어**한다. BattleSim은 6행 좌표를 알지만, 스폰·타일·보드는 board_rows만큼만 쓴다.

## 1. RunState (`scripts/run/run_state.gd`)
- `var board_rows: int = 3` 추가 (시작 3, 상한 6). `const BOARD_ROWS_MAX := 6`, `const BOARD_COLS := 3`.
- `BOARD_BLOCKS` 상수 사용처를 `board_rows * BOARD_COLS` 동적 계산으로 교체.
- `block_keys()` — 현재 static `for row in 3`. **인스턴스 메서드로 전환**(`self.board_rows` 사용) 또는 `block_keys(rows: int)` 인자형. 호출부 일괄 갱신.
- `board_full()` → `board.size() >= board_rows * BOARD_COLS`.
- `expand_board() -> bool` 추가 — `board_rows < BOARD_ROWS_MAX`면 `board_rows += 1` 후 true, 아니면 false(불변).
- 런 초기화(reset/start) 시 `board_rows = 3`.

## 2. BattleSim (`scripts/battle/battle_sim.gd`)
- `ROW_X` 배열을 3개→**6개 고정**으로 확장. 기존 `[360, 240, 120]`(성 쪽→전방) 패턴을 6행으로 균등 연장 — 전장 깊이(FIELD 범위) 안에서 6행이 겹치지 않게 분포(예 `[400, 330, 260, 190, 120, 50]`, 실제 값은 FIELD_W/타일 간격 보고 Codex가 조정).
- `ROW_COUNT` 상한 6으로(또는 `ROW_X.size()` 참조). `position_for_tile(col, row)`가 row 0~5 지원.
- static 함수 형태·시그니처는 유지 — 동작 변경 최소.

## 3. CardCatalog.build_board_army (`scripts/resources/card_catalog.gd`)
- `for row in BattleSim.ROW_COUNT`(고정 3) → **`for row in run_board_rows`** 로 변경. board_rows를 인자로 받거나 RunManager에서 조회. board에 없는 키는 기존대로 skip.

## 4. RunManager (`scripts/autoloads/run_manager.gd`)
- `expand_board() -> bool` — `state.expand_board()` 위임.
- `get_board_rows() -> int` — `state.board_rows`.

## 5. battle.gd (`scripts/battle/battle.gd`)
- `_build_iso_base()` 타일 그리드를 `RunManager.get_board_rows()`만큼 렌더(현재 BattleSim.ROW_COUNT 고정).
- 보스 승리 보상 화면(`_build_outcome_ui` 또는 보상 흐름)에서 `if RunManager.is_expand_stage() and RunManager.get_board_rows() < 6`이면 "보드 +1행 확장" 보상(자동 또는 버튼) → `RunManager.expand_board()`. 상한 도달 시 생략.

## 6. 테스트 (`test/test_run_board.gd`)
- `expand_board()` — 3→4→5→6 증가, 6에서 false·불변(상한).
- `board_full()` — board_rows에 따라 9/12/15/18칸 기준 동적.
- `block_keys()` — board_rows에 따라 키 개수(9~18).
- 회귀 — 기본 3행(9칸) 동작·기존 보드 테스트 보존.

## 금지 / 보존
- BattleSim 결정성·기존 전투 로직 보존, static 함수 유지.
- 촉/위/오 빌드·trait·스킬(feat-029) 회귀 없음.
- 카드 .tres·스킬·trait 로직 미수정.

## 검증 (Definition of Done)
- 보드가 보스 보상으로 3→6행 확장, 전장 타일·스폰이 board_rows를 따른다.
- `./init.sh` 전체 green, 단언 수 795 초과(확장 테스트 추가분).
