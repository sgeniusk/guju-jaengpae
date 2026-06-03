# feat-021 — 왕의 칙령 (King's Edict / 전역 perk)

3스테이지마다 칙령 드래프트 — 전역 perk 3중1을 골라 런 전체에 누적 적용한다. feat-019 StageCadence·feat-029 trait 수정자 패턴의 확장이다. (explore 코드 파악 기반, 함수명·라인은 Codex가 최신 코드 확인 후 맞춘다.)

## 분업
Claude(이 스펙·정본·검증) → Codex(GDScript 구현) → Claude(독립 검증) → architect.

## 설계 결정 (편집장)
- **EDICT_INTERVAL = 3** — `is_edict(stage) = stage % 3 == 0`.
- **캐이던스 충돌 — node_kind 우선순위 `boss > edict > shop > expand > combat`** (단일 반환). stage 12(상점·칙령 충돌)=칙령 우선(상점은 4·8·16·20 등 많아 스킵 손실 작음), stage 15(보스·칙령)=보스 우선(칙령 스킵). 보스·상점·확장의 기존 동작은 불변.
- **EdictCatalog = 코드 딕셔너리**(Resource .tres 대신, skill_system COOLDOWNS 패턴). perk 3종:
  - **군세(軍勢)** `edict_might` — 전 아군 공격력 +12%
  - **재정(財政)** `edict_economy` — 골드 획득 +25%
  - **축성(築城)** `edict_fortify` — 성 HP +20%
- **누적 합산** — 같은 칙령 N회 = pct×N (예 군세 2회 = +24%).

## 1. EdictCatalog (신규 — `scripts/run/edict_catalog.gd`)
skill_system.gd 패턴의 코드 레지스트리.
```gdscript
const EDICTS := {
    &"edict_might":    {"name": "군세(軍勢)", "desc": "전 아군 공격력 +12%", "attack_pct": 0.12},
    &"edict_economy":  {"name": "재정(財政)", "desc": "골드 획득 +25%",     "gold_pct": 0.25},
    &"edict_fortify":  {"name": "축성(築城)", "desc": "성 HP +20%",          "castle_hp_pct": 0.20},
}
static func attack_pct(edicts: Array) -> float    # 합산
static func gold_pct(edicts: Array) -> float
static func castle_hp_pct(edicts: Array) -> float
static func all_ids() -> Array[StringName]        # 드래프트 후보(3종)
static func info(id) -> Dictionary
```

## 2. StageCadence (`scripts/run/stage_cadence.gd`)
- `const EDICT_INTERVAL := 3`, `static func is_edict(stage) -> bool` (is_expand 아래).
- `node_kind` 우선순위에 edict 삽입 — `boss > edict > shop > expand > combat`.

## 3. RunState (`scripts/run/run_state.gd`)
- `var edicts: Array[StringName] = []` (command_points 아래). `start_run()`에 `edicts.clear()` 명시(인스턴스 교체 reset과 일관). 직렬화 미구현이라 추가 불필요.

## 4. RunManager (`scripts/autoloads/run_manager.gd`)
- `is_edict_stage()`(StageCadence 위임), `add_edict(id)`, `get_edicts() -> Array[StringName]` (is_expand_stage 아래, 동일 패턴).

## 5. 전역 수정자 적용 (3곳)
- **군세** — `card_catalog.build_player_unit`에 `edicts: Array = []` 파라미터 추가. trait 분기(hopae/suseon/rende, feat-029) **이후** `var pct := EdictCatalog.attack_pct(edicts); if pct > 0: unit.attack = int(round(unit.attack * (1.0 + pct)))`. `build_board_army`도 edicts 받아 전달. 호출부에서 `RunManager.get_edicts()` 주입. trait과는 **곱셈 체인**(trait 적용된 attack에 edict 곱).
- **재정** — `battle.gd._end_battle`의 `add_gold(produced_gold)` 지점(explore: battle.gd:~1337)에서 `int(round(produced_gold * (1.0 + EdictCatalog.gold_pct(get_edicts()))))`.
- **축성** — 성 생성 `_sim.add_castle(hp)`(explore: battle.gd:~1164)에서 `int(round(CASTLE_HP * (1.0 + EdictCatalog.castle_hp_pct(get_edicts()))))`.

## 6. run_map 드래프트 UI (`scripts/screens/run_map.gd`)
- `_build_stage_panel()`에 `elif RunManager.is_edict_stage(): _build_edict_panel(); return` (보스보다 뒤, 상점 앞 — node_kind 우선순위와 정합). `_build_edict_panel()`은 `_build_shop_panel()` 패턴 — perk 3종 버튼(EdictCatalog.all_ids), 골드 없이 1택 → `RunManager.add_edict(id)` + `advance_stage()` + `_render()`.

## 7. 테스트
- `test_stage_cadence` — `is_edict(3·6·9)`, `falsy(is_edict(4·5))`, `node_kind(12)=="edict"`, `node_kind(15)=="boss"`, `node_kind(3)=="edict"`.
- `test_run_board`(또는 신규 test_edicts) — edicts 초기 빈 배열·누적, RunManager is_edict_stage/add_edict/get_edicts, `build_player_unit`에 edict_might 주입 시 공격력 합산(스택 2회 +24%), feat-029 trait과 함께 적용 시 곱셈 정확.
- EdictCatalog attack_pct/gold_pct/castle_hp_pct 합산 단위 테스트.

## 금지 / 보존
- BattleSim 결정성, feat-029 trait/스킬, feat-020 board 확장, 촉/위/오 빌드 회귀 없음.
- 전역 수정자는 결정적(런 edicts 기반, 무작위 발동 없음). 단 드래프트 후보가 무작위면 시드 고정 또는 고정 3종.

## 검증 (Definition of Done)
- 3마다 칙령 드래프트, perk가 런 전체 전투(공격력·성HP)·경제(골드)에 누적 적용.
- `./init.sh` 전체 green, 단언 876 초과(칙령 캐이던스·수정자 테스트 추가분).
