# feat-016 — 건물 경제 (건물 카드 + 골드 생산 + 오라)

## 목표
보드 타일에 짓는 **정적 건물 카드**를 도입한다. 둔전(屯田)은 전투 중 골드를 생산하고(누적 숫자 플로팅, 종료 시 적립), 망루(望樓)는 인접 아군에 공격력 오라를 준다. 첨부 화면의 좌측 기지 건물(자원 숫자)을 실제 동작으로 만든다.

## 전제 / 불변식
- **`BattleSim` 불변.** 경제·오라는 순수 헬퍼로 분리해 헤드리스 테스트 가능하게 한다.
- 건물은 진군하지 않는다 — 보드 타일에 잔류(아이소 기지). 유닛 군세와 별개.
- 카드 데이터는 합의된 스키마만(아래 `BuildingCardData`가 정본 스키마).

## 범위 (파일)
- `scripts/resources/building_card_data.gd` (신규) — `extends CardData`. 정본 필드
  - `card_type = "building"`
  - `@export var gold_per_sec: int = 0`
  - `@export var aura_attack_pct: float = 0.0`  # 0.10 = +10%
  - `@export var aura_radius: int = 1`           # 보드 타일 거리(체비셰프)
- `resources/cards/building_dunjeon.tres` (신규) — 둔전. `gold_per_sec=5`, 오라 없음. cost 적당.
- `resources/cards/building_mangru.tres` (신규) — 망루. `aura_attack_pct=0.12`, `aura_radius=1`, 골드 없음.
- `scripts/run/board_economy.gd` (신규, 순수 RefCounted) — 테스트 가능한 경제·오라 로직.
  - `static func buildings_on_board(board, catalog) -> Array` # [{key,col,row,card}]
  - `static func gold_per_sec(board, catalog) -> int`         # 둔전 합
  - `static func apply_auras(army: Array[BattleUnit], board, catalog) -> void`  # 망루 인접(시작 타일 기준) 아군 effective attack +%. 결정적.
- `scripts/battle/battle.gd` — 건물 렌더(아이소 타일 위 정적 스프라이트, 매니페스트 `buildings/*.png`, 폴백 색), 전투 중 골드 누적·플로팅 숫자, 종료 시 `RunState.add_gold`. `_spawn_board_army` 직후 `apply_auras` 호출.
- (이미 OK) `card_catalog.build_board_army`는 `build_player_unit`이 비유닛에 null 반환 → 건물은 자동으로 군세에서 제외됨. 별도 처리 불필요, **확인만**.

## 구현 노트
- **오라 모델** — 전투 시작 시 1회, 망루 시작 타일의 `aura_radius` 내 아군 유닛 스탯에 `+aura_attack_pct` 적용(베이크). 유닛이 진군해도 유지. 시작 타일 인접 기준이라 결정적·테스트 용이.
- **골드 생산** — BATTLE 동안 `accum += gold_per_sec * delta`. 건물 위에 누적 정수 플로팅(첨부의 5182처럼). 종료 시 `floor(accum)`을 `RunState.add_gold`. (전역 칙령 배율 feat-021은 후속.)
- **HUD 연동** — 자원 카운터(feat-023)가 골드 변동 반영.

## 검증
- `test_building_economy` 신설 — `gold_per_sec` 합산, `apply_auras`가 반경 내 아군만 버프(반경 밖 불변), `build_board_army`가 건물 제외(군세 수 불변). `BattleSim` 결과 회귀 0.
- `./init.sh` green(단언 증가). 헤드리스 부팅 무에러.

## 스코프 밖
- 소환 건물·복합 오라(회복·사거리 등)·건물 칙령 상호작용(feat-021) = 후속. 둔전·망루 2종으로 바운드.
