# feat-015d — 상점(商店) 이벤트

## 목적
StageCadence가 shop으로 분류하는 스테이지(4·8·12…)에서 모은 골드로 카드를 사 손패에 넣는다. **건물 카드(둔전·망루)의 실제 획득 경로**가 된다(보상풀은 유닛 전용이라 건물이 안 나옴). 루프 — 전투 골드 → 상점 카드 → 강한 보드 → 다음 전투.

## 정본 결정
- **상점은 독립 스테이지** — `StageCadence.node_kind`가 "shop"인 스테이지엔 전투가 없다. run_map이 상점 UI를 보여주고, 떠나면 다음 스테이지로 advance.
- **판매 목록 = 전체 구매 가능 카드**(유닛 + 건물). v0.1은 카드가 12종뿐이라 롤링 없이 전부 노출, 비용 오름차순. **owned 제외 안 함**(중복 구매 허용 — 둔전 2채 등 보드빌더상 유효). 롤링 상점은 후속.
- **구매** = `spend_gold(cost)` 성공 시 `hand_add(id)`. 골드 부족이면 구매 불가(버튼 비활성/실패).
- **손패 초과 허용** — 보상 드래프트와 동일하게 hand가 HAND_MAX(3)를 넘어도 구매 가능. 초과분은 **다음 전투 배치 단계에서 보드 배치로 해소**(기존 deploy 경로). 상점은 초과 시 안내만.
- **순수 로직 분리** — 구매·판매목록 로직은 헤드리스 테스트 가능하게 RunManager/CardCatalog에 둔다. UI(run_map)는 얇게.

## 구현
1. `scripts/resources/card_catalog.gd` — `purchasable_ids() -> Array[StringName]` 추가. `cards` + `building_cards` 키 합집합, 비용 오름차순(동률 id순) 정렬. 순수.
2. `scripts/autoloads/run_manager.gd` —
   - `is_shop_stage() -> bool` = `StageCadence.is_shop(stage_index())` (기존 `is_boss_stage` 미러).
   - `shop_purchase(id: StringName) -> bool` — 카드 존재 + `get_gold() >= card.cost` 확인 후 `RunState.spend_gold(cost)` 성공 시 `RunState.hand_add(id)`, true 반환. 실패 시 false(상태 불변).
   - `shop_card_ids() -> Array[StringName]` = `CardLibrary.purchasable_ids()` 브리지(선택).
3. `scripts/screens/run_map.gd` — `is_shop_stage()`면 **상점 모드** 렌더(기존 "전투 시작" 대신).
   - 판매 목록 — 각 카드 `display_name (cost) — 간략설명` 버튼, 골드 부족이면 비활성. 클릭 시 `shop_purchase(id)` → 골드·손패 패널 갱신·재렌더.
   - 현재 골드·손패(N/HAND_MAX) 표시. hand > HAND_MAX면 "다음 전투 배치에서 보드로 정리" 힌트.
   - **"상점 떠나기"** 버튼 — `RunManager.advance_stage()` 후 재렌더(다음 스테이지로). 별도 씬 없이 run_map 내 모드 분기로 구현(씬 플러밍 최소화).
   - 보드/손패 요약 등 기존 패널은 유지.

## 불변식 (HARD)
- `battle_sim.gd`·`battle_unit.gd`·`skill_system.gd`·`target_rules.gd`·`type_chart.gd`·기존 `test/`(신규 추가 허용) **수정 금지**. 전투 로직 회귀 0.
- `RewardPool`(유닛 전용 보상) 규칙 변경 금지 — 상점은 별개 경로.
- 기존 런 흐름(전투→보상→advance→run_map) 보존. shop 스테이지만 분기 추가.
- `./init.sh` 단언 수(684) 이상 green + 부팅 무에러.

## 검증
- `test/test_shop.gd` 신설 — ① `purchasable_ids`에 building_dunjeon·building_mangru 포함 ② `shop_purchase` 골드 충분 시 골드 차감+손패 추가·true ③ 골드 부족 시 false·상태 불변 ④ `is_shop_stage` 4·8·12 true, 1·5 false.
- `./init.sh` green. run_map 부팅(상점 스테이지 강제 시 에러 없음).
- `feature_list.json`·`progress.md`는 편집장(Claude) 반영.
