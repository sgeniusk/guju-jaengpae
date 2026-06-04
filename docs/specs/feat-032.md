# feat-032 — 계략·보패 카드 계약

## 목표
Phase 2의 계략(計略)·보패(寶貝)를 구현하기 전에 카드 스키마 소유권을 고정한다. 기존 `CardData.card_type`의 `scheme`/`treasure` 값을 유지하고, 새 enum이나 임시 문자열을 늘리지 않는다.

## G034 세부 기준
스키마 owner는 `CardData.card_type`이다. `CardVocab.CARD_TYPES`의 `scheme`/`treasure`는 이미 정본 값이므로 유지한다. 계략·보패는 `CardData`를 직접 쓰는 임시 `.tres`가 아니라 아래 Resource subclass로 정의한다.

### SchemeCardData 계약
- 파일 — `scripts/resources/scheme_card_data.gd`.
- 상속 — `extends CardData`.
- `_init()`에서 `card_type = "scheme"`으로 고정한다.
- 필드:
  - `@export var effect_id: StringName = &""`
  - `@export_enum("none", "enemy", "ally", "board_slot") var target_policy: String = "none"`
  - `@export var value: int = 0`
  - `@export var secondary_value: int = 0`
  - `@export var duration_sec: float = 0.0`

### TreasureCardData 계약
- 파일 — `scripts/resources/treasure_card_data.gd`.
- 상속 — `extends CardData`.
- `_init()`에서 `card_type = "treasure"`로 고정한다.
- 필드:
  - `@export var effect_id: StringName = &""`
  - `@export var value: int = 0`
  - `@export var secondary_value: int = 0`
  - `@export var stack_limit: int = 1`

## G035 세부 기준
계략 runtime owner는 `RunState.hand`와 전투/배치 UI다. 손패에는 유닛·건물·계략이 함께 들어갈 수 있다.

- `RunState.consume_from_hand(index)`는 카드 id를 반환하며 손패에서 제거한다. Resource 조회는 하지 않는다.
- `RunManager.place_from_hand(index, block_key)`는 장수·병종·건물만 보드에 배치한다. 계략·보패·unknown 카드는 배치하지 않는다.
- `RunManager.cast_scheme_from_hand(index)`는 `card_type == "scheme"`인 카드만 발동 후 소비한다.
- 전투 UI는 손패 카드에 타입 라벨을 붙이고, 계략 선택 시 타일 배치 대신 `계략 발동` 버튼으로 소비한다.
- 효과 해석은 G036의 `SchemeCatalog`가 맡고, 실제 적용은 G041에서 `RunManager`/`BattleSim`/전투 UI 연결로 닫는다. G035의 발동은 런타임 경계와 소비 흐름만 잠근다.

## G036 세부 기준
계략 effect owner는 `scripts/run/scheme_catalog.gd`의 `SchemeCatalog`다. `SchemeCatalog.resolve(card, context)`는 RNG, ResourceLoader, scene 접근, 저장 I/O 없이 결정적 Dictionary를 반환한다.

- 반환 shape는 `{ ok, effect_id, battle, run }`이다.
- `battle`은 `BattleSim` 또는 전투 UI가 적용할 입력만 담는다. 현재 key는 `damage_enemy`, `castle_hp_delta`다.
- `run`은 `RunState` 경계에서 적용할 변경만 담는다. 현재 key는 `gold_delta`다.
- `RunManager.cast_scheme_from_hand()`는 `SchemeCatalog.resolve()`가 성공한 계략만 소비하고, `last_scheme_result`에 결과 복사본을 남긴다.
- 실제 battle/run 변경 적용은 G041에서 연결됐다. G036은 effect_id 해석 owner와 결정성 계약을 잠근다.

## G037 세부 기준
보패 runtime owner는 `RunState.treasures`다. 보패는 획득 즉시 손패가 아니라 런 지속 id 배열에 들어간다.

- `RunState.treasures`는 `Array[StringName]`이며 `start_run()`에서 초기화한다.
- `RunState.owned_card_ids()`는 board + hand + treasures를 반환한다.
- `RunManager.acquire_card(id)`는 `TreasureCardData`를 `add_treasure(id)`로, 나머지 카드는 손패로 보낸다.
- `RunManager.shop_purchase(id)`는 보패 구매 시 비용을 지불한 뒤 손패가 아니라 `RunState.treasures`에 장착한다. stack limit 또는 미등록 effect 실패는 상태와 골드를 바꾸지 않는다.
- `TreasureCatalog.resolve(card)`는 `{ ok, effect_id, battle, economy, reward }` shape를 반환한다.
- `TreasureCatalog.modifiers(treasure_ids, catalog)`는 유효한 보패 id만 채널별 숫자 보정으로 합산한다.
- 실제 전투 공격력, 골드 생산, 보상 후보 수 적용은 G041에서 연결됐다. G037은 보패 소유권과 effect_id 해석 owner를 잠근다.

## G038 세부 기준
`RewardPool`은 유닛 전용 필터가 아니라 카드 타입별 pool 정책을 가진다.

- 기본 전리 보상 타입은 `general`, `troop`, `scheme`, `treasure`다. 이는 `docs/worldview.md`의 전리 정의(장수·병종·계략·보패)를 따른다.
- `building`은 현재 상점 경로가 기본 owner이므로 기본 전리 pool에서 제외한다. 다만 테스트와 후속 노드 정책을 위해 `allowed_types`를 명시하면 building pool도 조회할 수 있다.
- `RewardPool.eligible(catalog, owned, allowed_types = [])`는 board·hand·treasures가 합쳐진 `owned_card_ids()`를 입력으로 받는다.
- 일반 카드(`general`, `troop`, `scheme`, `building`)는 같은 id가 owned에 있으면 후보에서 제외한다.
- 보패는 `TreasureCardData.stack_limit`이 남아 있으면 같은 id가 owned에 있어도 후보로 유지한다.
- `RewardPool.by_type()`은 같은 정책으로 타입별 후보 bucket을 반환한다.
- `RewardPool.roll()`과 `RunManager.reward_candidates()`는 같은 타입 정책을 공유한다.

## G039 세부 기준
`tools/validate_cards.gd`는 scheme/treasure 리소스 계약을 헤드리스 검증에 포함한다.

- `card_errors(res)`는 단위 테스트에서 직접 호출 가능한 순수 검증 결과를 반환한다.
- `scheme` 카드는 `SchemeCardData`여야 하며, `effect_id`가 비어 있지 않고 `SchemeCatalog`에 등록되어야 한다.
- `treasure` 카드는 `TreasureCardData`여야 하며, `effect_id`가 비어 있지 않고 `TreasureCatalog`에 등록되어야 한다.
- scheme/treasure의 `cost`는 음수일 수 없다.
- treasure의 `stack_limit`은 1 이상이어야 한다.
- 누락 필드는 validator crash가 아니라 검증 오류로 보고한다.

## G040 세부 기준
초기 계략 3종과 보패 3종만 실제 Resource로 추가한다. 새 effect code는 늘리지 않고 G036/G037의 registry id를 그대로 사용한다.

- 계략:
  - `scheme_raid` — `scheme_damage_enemy`, target `enemy`, value 80.
  - `scheme_levy` — `scheme_gain_gold`, target `none`, value 8.
  - `scheme_fortify` — `scheme_fortify_castle`, target `none`, value 160.
- 보패:
  - `treasure_bingfashu` — `treasure_attack_pct`, value 10, stack_limit 2.
  - `treasure_jinyin` — `treasure_gold_pct`, value 20, stack_limit 1.
  - `treasure_qianliyan` — `treasure_reward_bonus`, value 1, stack_limit 1.
- 카드는 모두 `resources/cards/*.tres`에 들어가고 `CardCatalog`/`tools/validate_cards.gd`가 실제 로드한다.
- 실제 수치 적용은 G041에서 연결됐으므로 G040은 데이터 존재, schema, registry 연결, 보상 pool 노출만 검증한다.

## G041 세부 기준
계략·보패는 해석 딕셔너리에 머물지 않고 실제 런/전투/보상 결과를 바꾼다.

- `RunManager.cast_scheme_from_hand()`는 `run.gold_delta`를 런 골드에 즉시 적용한다.
- `BattleSim.apply_battle_effect(effect)`는 `castle_hp_delta`와 `damage_enemy`를 결정적으로 적용한다. Resource 로딩, RNG, 저장 I/O는 넣지 않는다.
- 전투 UI는 배치 단계에서 발동한 계략의 전투 효과를 적용한다. 적 파도 이전의 `damage_enemy`는 보류했다가 전투 시작 직후 첫 생존 적에게 적용한다.
- 보패 `treasure_attack_pct`는 전투 시작 시 아군 비성 유닛 공격력에 적용한다.
- 보패 `treasure_gold_pct`는 전투 중 건물 생산 골드의 종료 정산에 칙령 보정과 함께 적용한다.
- 보패 `treasure_reward_bonus`는 승리 보상 후보 수를 늘린다.

## G042 세부 기준
저장 구현 전이라도 런 상태는 저장 가능한 id/primitive 중심 계약을 깨면 안 된다.

- `RunState.lord_id`, `hand`, `edicts`, `treasures`, `owned_card_ids()`는 Resource가 아니라 `StringName` id를 담는다.
- `RunState.board`는 block key `String`에서 card id `StringName`으로 매핑한다.
- `gold`, `board_rows`, `stage_index`, `wave_index`, `command_points`, `started`는 primitive 값으로 남는다.
- G042는 full persistence API를 만들지 않는다. `RunState.to_dict()`/`from_dict()`와 save version은 Phase 3에서 구현한다.

## G043 세부 기준
계략·보패가 추가되어도 기존 장수·병종·건물 경로가 깨지면 안 된다.

- 장수·병종·건물은 손패에서 기존처럼 보드에 배치된다.
- 계략은 보드에 배치되지 않고 발동 경로를 유지한다.
- 보드에서 전투 군세를 만들 때 장수·병종만 `BattleUnit`으로 변환되고 건물은 제외된다.
- 건물은 기존 `BoardEconomy` 경로로 골드 생산과 오라 계산 대상이 된다.

## G044 세부 기준
계략 발동, 보패 획득, 유닛/건물 배치가 UI 문구에서 서로 혼동되지 않아야 한다.

- 손패와 전리 보상 UI는 카드 타입 라벨을 `장수`/`병종`/`건물`/`계략`/`보패`로 노출한다.
- 전리 보상과 상점은 내부 `effect_id`가 아니라 플레이어 행동 경로와 효과 요약을 보여준다.
- 계략은 `계략 발동`, 보패는 `보패 장착`, 장수·병종은 `보드 배치`, 건물은 `건물 배치` 어휘를 사용한다.
- 상점 구매 후 피드백은 계략·유닛·건물이 손패로 들어가는지, 보패가 즉시 장착되는지 구분한다.
- 상점 카드 수가 늘어나도 목록은 스크롤 가능하고 첫 화면의 카드 텍스트가 잘리지 않는다.

## 런타임 경계
- 계략 효과 owner는 `SchemeCatalog` 또는 동등한 순수 코드 레지스트리다. `effect_id`는 그 레지스트리의 key와 일치해야 한다.
- 보패 효과 owner는 `TreasureCatalog` 또는 동등한 순수 코드 레지스트리다. 런 상태에는 보패 Resource가 아니라 카드 id만 저장한다.
- `RunState`의 저장 가능성을 위해 손패·보드·보패 상태는 `StringName` id 배열 중심으로 둔다.
- 전투 계산 owner인 `BattleSim`에는 Resource 로딩이나 저장 I/O를 넣지 않는다.

## 보상·상점·검증 계약
- `RewardPool`은 유닛 전용 필터가 아니라 카드 타입별 정책을 사용한다.
- 상점은 계략을 손패 구매로, 보패를 즉시 런 지속 패시브 획득으로 취급한다.
- `tools/validate_cards.gd`는 scheme/treasure 리소스가 올바른 subclass인지, `effect_id`가 비어 있지 않은지, 레지스트리와 연결되는지 검사한다.
- 기존 장수·병종·건물 `.tres`와 `CardCatalog.get_card()` 호출자는 깨지면 안 된다.

## 스코프 밖
- 계략·보패 보정치의 실제 battle/run/economy/reward 적용은 G041에서 닫혔다.
- 저장·해금 직렬화는 Phase 3.

## 검증
- 이 스펙이 `docs/roadmap.md`, `feature_list.json`, `progress.md`, `session-handoff.md`의 Phase 2 다음 작업과 같은 계약을 말해야 한다.
- `test_run_board.gd`는 손패 소비, 계략 배치 거부, 계략 발동 후 소비, 유닛 배치 유지 흐름을 검증한다.
- `test_scheme_catalog.gd`는 effect_id 목록, battle/run 채널 분리, context 복사, unknown effect 실패를 검증한다.
- `test_treasure_catalog.gd`는 effect_id 목록, battle/economy/reward 채널 분리, 보패 보정 합산, unknown effect 실패를 검증한다.
- `test_run_board.gd`는 보패가 손패가 아니라 `RunState.treasures`에 들어가고 상점 구매도 같은 경계를 따르는지 검증한다.
- `test_run_board.gd`는 계략 골드 즉시 적용, 보패 공격/골드/보상 선택 수 helper, 성 제외 공격 보정을 검증한다.
- `test_run_board.gd`는 `RunState`의 저장 대상 필드가 id/primitive 값만 담는지 검증한다.
- `test_run_board.gd`는 장수·병종·건물·계략이 섞인 손패에서 기존 배치/군세/건물경제 흐름이 유지되는지 검증한다.
- `test_battle_sim.gd`는 계략 성 보강과 적 피해가 HP, 피해 이벤트, 승패 판정에 반영되는지 검증한다.
- `test_run_reward.gd`는 RewardPool 기본 타입 정책, 명시적 building pool, 보패 stack_limit, 타입 제한 roll을 검증한다.
- `test_shop.gd`는 상점 판매 목록에 계략·보패가 포함되고, `CardUiText`가 구매/사용 경로와 내부 effect_id 비노출을 검증한다.
- `test_validate_cards.gd`는 existing cards 통과, scheme/treasure subclass·effect registry·cost·stack policy를 검증한다.
- `test_card_catalog.gd`는 초기 계략/보패 3+3 리소스가 실제 로드되고 registry effect와 연결되는지 검증한다.
- `SHOT_DIR=/tmp/guju-g044-ui LORD=lord_liubei SHOP_STAGE=4 godot --path . res://tools/shoot_shop.tscn`은 G044 상점 UI 캡처를 생성한다.
- `./init.sh` green과 `tools/validate_cards.gd`가 scheme/treasure를 검사하는 단언으로 닫는다.
