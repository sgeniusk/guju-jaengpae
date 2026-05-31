# 스펙 — feat-015 경제·보드 상태 모델 (1단계)

Claude(편집장)가 작성한 구현 스펙. Codex(구현자)가 이 문서·`AGENTS.md`·`CLAUDE.md`·`docs/design-loop.md`를 읽고 구현한다. 완료 후 `./init.sh` 전체 green.

## 배경 — 손패·영속 보드·경제 (design-loop 참조)
NK식 핵심 루프 — 손패 3장, 카드를 **영속 보드 블록**에 배치, 우물에 버리면 +10골드, 4스테이지마다 상점. 이 피처는 그 **상태 모델만**(순수 로직) 깐다. 전투를 보드에서 스폰하는 것·배치/상점/우물 UI는 후속(feat-015b 전투·UI, feat-015c 상점·드래프트). 빌드는 깨지지 않게 **브리지**를 둔다.

## 모델 (RunState)
- `const HAND_MAX := 3`, `const BOARD_BLOCKS := 9`(3×3), `const WELL_GOLD := 10`.
- `var board: Dictionary = {}` — 블록키(String "col:row", col·row 0..2) → 카드 id(StringName). 영속 배치.
- `var hand: Array[StringName] = []` — 손패. (HAND_MAX 초과는 일시 허용, 해소는 UI 몫.)
- `var gold: int = 0`.
- 메서드 —
    - `static block_keys() -> Array[String]`(9개), `is_block_free(key)`, `board_full()`(size ≥ 9), `first_free_block()`.
    - `place_from_hand(hand_index, block_key) -> bool` — 유효 index·빈 블록이면 board[key]=hand[idx], 손패에서 제거.
    - `discard_from_hand(hand_index) -> bool` — 제거 + `gold += WELL_GOLD`.
    - `hand_add(card_id)`, `hand_over_limit() -> bool`.
    - `board_card_ids() -> Array[StringName]`(board.values()), `owned_card_ids()`(board + hand).
    - `add_gold(n)`, `spend_gold(n) -> bool`.
- `start_run(lord, catalog)` — 군주 시작 카드를 **보드 블록에 순서대로 배치**(블록 한도까지), 손패 빈 채로, gold 0. (시작 군세 = 보드.)

## 브리지 (빌드 보호 — 기존 동작 유지)
기존 코드가 `deck`/`add_card`를 쓰므로 호환 유지.
- `RunManager.get_deck()` → `board_card_ids()` 반환(battle.gd·run_map이 보드 군세를 그대로 사용).
- `RunManager.add_card(id)` → 빈 블록 있으면 보드에 배치, 없으면 `hand_add`(임시). 기존 보상 흐름이 깨지지 않게.
- `RunManager` 신규 위임 — `get_hand()`, `get_gold()`, `place_from_hand`, `discard_from_hand`, `add_gold`, `board_full` 등.
- `RewardPool.eligible(catalog, owned)` — 후보 = 카탈로그 유닛카드 − **owned(board+hand)**. (기존 deck 인자를 owned로.) `reward_candidates`도 owned 기준.

## 스코프 (이 파일들)
- `scripts/run/run_state.gd` — 위 모델.
- `scripts/autoloads/run_manager.gd` — 위 위임·브리지.
- `scripts/run/reward_pool.gd` — owned 기준 eligible.
- `test/test_run_board.gd` 신설 + `test/test_run_reward.gd`(필요 시 owned 기준으로 갱신).
- **유지(수정 금지)** — `scripts/battle/*`(브리지로 그대로 동작), `scenes/*`, `resources/.tres`, TypeChart/SkillSystem/TargetRules 규칙. battle.gd·run_map.gd는 get_deck/add_card 브리지로 동작하므로 손대지 않는다.

## 불변식
- RunState 순수·결정적(헤드리스 테스트 가능).
- 브리지로 `./init.sh` run_map·battle 부팅 스모크와 기존 reward/sim 스모크가 계속 green.
- 보드 블록 한도(9) 넘는 배치 거부, 우물 버리기 +10골드 정확.

## 테스트 지침 (test/test_run_board.gd, 순수)
- block_keys 9개·유일. start_run 후 보드에 시작 카드 채워짐(손패 빈·gold 0).
- place_from_hand — 빈 블록 성공, 점유 블록·잘못된 index 실패, 손패 감소.
- board_full — 9 채우면 true, first_free_block null.
- discard_from_hand — 손패 감소 + gold +10.
- owned_card_ids = board + hand. add_gold/spend_gold(부족 시 false).
- 브리지 — get_deck()==board_card_ids(), add_card가 빈 블록에 배치(가득이면 hand). RewardPool.eligible가 owned 제외.

## 범위 밖 (후속)
- feat-015b — 전투를 보드 배치에서 스폰(per-battle deploy 제거), 보드·손패 관리 UI.
- feat-015c — 상점 노드(4스테이지마다)·보상 드래프트(3중1) UI·우물 UI.
- "상대 진영 카드" 보상은 6국 콘텐츠 때.

## 제약 (AGENTS.md)
- 비-자명한 새 파일 한 줄 한국어 헤더. 한국어 문장 `:` 종결 금지. GDScript 탭.
- `git commit`·`push` 금지. 회귀 금지(브리지로 빌드 green). 네트워크 불필요.
- 끝나면 `./init.sh` 전체 green 증거로 "무엇이/왜/검증결과/남은모호함" 보고.

## 완료 기준 (Definition of Done)
- [ ] RunState board/hand/gold + 메서드, start_run 보드 채움.
- [ ] RunManager 위임·브리지(get_deck→board, add_card→board/hand), RewardPool owned 기준.
- [ ] test_run_board.gd 신설 + 기존 run 테스트 갱신, 전체 통과.
- [ ] `./init.sh` 전체 green(부팅·기존 스모크 유지), 종료 0, 전투/씬/리소스 미수정.
