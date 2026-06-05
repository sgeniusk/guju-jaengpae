# Game Completion Multi-Lane Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the current technically complete prototype into a fun Three Kingdoms squad-card roguelike where each turn is castle placement or one meaningful card, then a fast army clash, then growth.

**Architecture:** Split the work into independent vertical lanes: loop contract, squad model, formation rendering, tactical board synergies, encounter pacing, content expansion, UX/audio, QA/release. Each lane owns a small set of files and must add tests before implementation. The existing deterministic `BattleSim`, primitive `RunState` payload, and Resource catalog contracts remain the spine.

**Tech Stack:** Godot 4.6.3, GDScript, existing in-repo `TestCase` runner via `./init.sh`, `.tres` Resources, headless smoke tools under `tools/`, visual evidence under `docs/reports/`.

---

## Scope Check

The requested work covers multiple independent subsystems. Do not implement it as one large branch. Execute it as these lanes, one lane at a time:

1. **Lane A — Fun Contract And Metrics:** define the new play promise, write acceptance tests, collect playtest timing and density metrics.
2. **Lane B — Squad Growth Model:** make every unit card represent a squad, with duplicate-card upgrades changing count, stats, and labels.
3. **Lane C — Formation Rendering:** make soldiers visually stand on the ground, surround generals, and clash as armies.
4. **Lane D — Tactical Board And Terrain:** make castle placement, adjacency, rows, edges, and faction terrain perks visibly matter.
5. **Lane E — Encounter Pacing:** remove the defense-wave feel and replace it with preparation, army clash, outcome, draft.
6. **Lane F — Strategy Decks And Content:** build faction card pools with generals, troops, buildings, towers, schemes, and treasures.
7. **Lane G — UX, Audio, And Feel:** add battle cries, impact, clear card affordances, and after-action feedback.
8. **Lane H — QA, Release, And Expansion Gate:** lock evidence, playtest scripts, export, and 9-faction canon gates.

The first executable lane should be Lane A. Lanes B and C can then run in parallel only if they do not edit the same files at the same time.

## Current Baseline

- Repo: `/Users/taewookkim/dev/guju-jaengpae`
- Current active feature: `feat-039` squad battle and growth tempo hotfix.
- Current validation: `./init.sh` passed with 22 cards and 2485 assertions.
- Current product problem: the code is feature-rich, but the moment-to-moment game still risks feeling like slow hero skirmishes instead of Three Kingdoms armies.
- Important current files:
  - `/Users/taewookkim/dev/guju-jaengpae/scripts/run/run_state.gd`
  - `/Users/taewookkim/dev/guju-jaengpae/scripts/autoloads/run_manager.gd`
  - `/Users/taewookkim/dev/guju-jaengpae/scripts/resources/card_catalog.gd`
  - `/Users/taewookkim/dev/guju-jaengpae/scripts/run/reward_pool.gd`
  - `/Users/taewookkim/dev/guju-jaengpae/scripts/battle/battle_unit.gd`
  - `/Users/taewookkim/dev/guju-jaengpae/scripts/battle/battle_sim.gd`
  - `/Users/taewookkim/dev/guju-jaengpae/scripts/battle/battle.gd`
  - `/Users/taewookkim/dev/guju-jaengpae/scripts/battle/wave_factory.gd`
  - `/Users/taewookkim/dev/guju-jaengpae/test/test_run_board.gd`
  - `/Users/taewookkim/dev/guju-jaengpae/test/test_board_army.gd`
  - `/Users/taewookkim/dev/guju-jaengpae/tools/ui_feedback_smoke.gd`

## Product Decisions To Lock

- A card play is an army decision, not a single pawn placement.
- A stage is not a defense wave. A stage is one preparation choice followed by one fast clash.
- Castle location is chosen first and creates the tactical puzzle.
- The hand is always three choices; one card is played per encounter.
- Duplicate unit cards upgrade the existing squad up to Lv.5.
- Troop squads begin around 8 to 10 visible soldiers; generals are smaller and have retinues.
- The contradictory "9 cards" versus "4 generals + 4 buildings + 4 towers" request is resolved as: each faction owns a **12-card strategy pool** for production, while the player sees only three choices at a time. If a future canon decision requires strict 9, trim each class to 3 without changing the lane architecture.

## File Structure

### New Files

- `/Users/taewookkim/dev/guju-jaengpae/docs/specs/feat-040-fun-reset.md`  
  Owns the product contract: army density, tempo, draw/play rhythm, board synergies, and stage flow.

- `/Users/taewookkim/dev/guju-jaengpae/scripts/battle/squad_profile.gd`  
  Pure helper that maps `UnitCardData` + level to squad count, retinue count, HP, attack, attack interval, visual scale, and label.

- `/Users/taewookkim/dev/guju-jaengpae/scripts/battle/formation_renderer.gd`  
  Pure visual helper for formation offsets, anchor positions, and member sort keys. It must not know about `RunState`.

- `/Users/taewookkim/dev/guju-jaengpae/scripts/run/terrain_perk_catalog.gd`  
  Pure helper for tile-based bonuses. It replaces scattered terrain logic with named rules.

- `/Users/taewookkim/dev/guju-jaengpae/scripts/run/strategy_deck_catalog.gd`  
  Pure helper that defines each faction strategy pool and card class quotas.

- `/Users/taewookkim/dev/guju-jaengpae/scripts/run/playtest_metrics.gd`  
  Pure helper that summarizes sim duration, player unit count, visible soldier count, stages reached, and rewards picked.

- `/Users/taewookkim/dev/guju-jaengpae/test/test_fun_contract.gd`  
  Contract tests for hand size, one-card encounter, duplicate upgrades, troop density, and stage timing.

- `/Users/taewookkim/dev/guju-jaengpae/test/test_squad_profile.gd`  
  Tests for squad profile math.

- `/Users/taewookkim/dev/guju-jaengpae/test/test_terrain_perk_catalog.gd`  
  Tests for terrain synergies.

- `/Users/taewookkim/dev/guju-jaengpae/test/test_strategy_deck_catalog.gd`  
  Tests for faction card pools.

- `/Users/taewookkim/dev/guju-jaengpae/tools/playtest_loop_smoke.gd`  
  Headless smoke that plays the first five stages using deterministic choices and prints compact metrics.

### Existing Files To Modify

- `/Users/taewookkim/dev/guju-jaengpae/scripts/run/run_state.gd`  
  Keep primitive payload. Add only fields that survive save/load and are needed by the new loop.

- `/Users/taewookkim/dev/guju-jaengpae/scripts/autoloads/run_manager.gd`  
  Owns start-run, prepare-stage, one-card play, upgrade, reward, save/autosave integration.

- `/Users/taewookkim/dev/guju-jaengpae/scripts/resources/card_catalog.gd`  
  Delegate strategy deck and squad profile logic to new helpers. Keep Resource loading here.

- `/Users/taewookkim/dev/guju-jaengpae/scripts/battle/battle_unit.gd`  
  Store aggregate squad values only. Do not create one sim object per soldier.

- `/Users/taewookkim/dev/guju-jaengpae/scripts/battle/battle_sim.gd`  
  Keep deterministic aggregate combat. Add morale, clash timing, or targeting only after tests.

- `/Users/taewookkim/dev/guju-jaengpae/scripts/battle/battle.gd`  
  Use `FormationRenderer` for visuals. Keep scene/UI glue here.

- `/Users/taewookkim/dev/guju-jaengpae/scripts/battle/wave_factory.gd`  
  Make enemy squads enter as armies, not dripped tower-defense waves.

- `/Users/taewookkim/dev/guju-jaengpae/scripts/ui/card_ui_text.gd`  
  Add labels for squad, retinue, upgrade, terrain bonus, and one-card action.

- `/Users/taewookkim/dev/guju-jaengpae/init.sh`  
  Add new tests and playtest smoke only after each script is stable.

## Lane Ownership

- **Product planner:** owns `docs/specs/feat-040-fun-reset.md`, acceptance criteria, stage rhythm.
- **Architect:** reviews `RunState`, `BattleSim`, save payload, Resource schema boundaries before Lane B/D/F code lands.
- **Executor A:** owns run loop and `RunManager`.
- **Executor B:** owns squad profile and `CardCatalog`.
- **Executor C:** owns `battle.gd` rendering split and visual density.
- **Test engineer:** owns test files and `tools/playtest_loop_smoke.gd`.
- **Designer:** owns card text, HUD affordance, screen flow.
- **Vision QA:** owns screenshot review and visual evidence.
- **Verifier:** runs `./init.sh`, playtest smoke, screenshot bundle, and checks status docs.
- **Git master:** makes local commits only. Push/tag remain user-confirmation gates.

## Task 1: Write The Fun Reset Spec

**Files:**
- Create: `/Users/taewookkim/dev/guju-jaengpae/docs/specs/feat-040-fun-reset.md`
- Modify: `/Users/taewookkim/dev/guju-jaengpae/feature_list.json`
- Modify: `/Users/taewookkim/dev/guju-jaengpae/progress.md`

- [ ] **Step 1: Create the spec file**

Use this exact document:

```markdown
# feat-040 — Fun Reset: Squad Card Army Loop

## Goal
Make the first five stages feel like Three Kingdoms armies clashing, not a slow defense prototype.

## Player Promise
- Pick a lord.
- Pick the castle location first.
- See exactly three card choices.
- Play one card.
- Watch a fast clash between visible squads.
- Receive one meaningful growth choice.
- Repeat with upgraded squads, terrain synergies, and clearer army identity.

## Contract
- A stage cannot begin combat before the castle is placed.
- A stage cannot play more than one hand card.
- Troop cards represent squads, starting at 8 to 10 visible soldiers.
- Duplicate troop cards upgrade the existing squad through Lv.5.
- General cards are smaller than the old hero sprites and render with retinue soldiers.
- Enemy armies spawn as grouped squads before clash, not as a defense trickle.
- A normal early encounter should resolve in 12 to 25 simulated seconds at x2 default speed.
- The UI must show whether a card places a new squad, upgrades an existing squad, casts a scheme, or places a building.

## Non-Goals
- No online features.
- No new heaven or demon nation ids before canon approval.
- No one-sim-object-per-soldier rewrite.
- No full balance lock before the new loop is playable.

## Evidence
- `./init.sh` green.
- `tools/playtest_loop_smoke.gd` prints first-five-stage metrics.
- Screenshot bundle includes deployment, clash, reward, and upgrade states.
```

- [ ] **Step 2: Add feature tracker entry**

Add this object to `feature_list.json` using the file's existing feature object style:

```json
{
  "id": "feat-040",
  "title": "Fun Reset: squad-card army loop",
  "status": "planned",
  "summary": "성 위치 선택, 3장 손패, 1장 플레이, 빠른 분대 교전, 중복 카드 증원, 전술 지형 보너스를 제품 루프로 다시 묶는다.",
  "evidence": "Plan: docs/specs/feat-040-fun-reset.md and docs/superpowers/plans/2026-06-05-game-completion-multi-lane-plan.md."
}
```

- [ ] **Step 3: Update progress**

Add this line under `진행 중` in `progress.md`:

```markdown
- [ ] **feat-040 Fun Reset 계획** — 전투 재미의 핵심을 분대 카드, 3장 선택, 1장 플레이, 빠른 교전, 지형 시너지, 성장 체감으로 다시 묶는 분업 계획을 `docs/superpowers/plans/2026-06-05-game-completion-multi-lane-plan.md`에 고정했다.
```

- [ ] **Step 4: Verify docs**

Run:

```bash
cd /Users/taewookkim/dev/guju-jaengpae
python3 -m json.tool feature_list.json >/dev/null
git diff --check
```

Expected:

```text
no output
```

- [ ] **Step 5: Commit**

```bash
git add docs/specs/feat-040-fun-reset.md feature_list.json progress.md
git commit -m "Plan the squad-card fun reset

Constraint: User playtest feedback says the current build feels slow, sparse, and defense-like.
Rejected: Treating this as polish only | the core loop needs a product contract before more content.
Confidence: high
Scope-risk: narrow
Directive: Do not add heaven or demon faction ids under this feature.
Tested: python3 -m json.tool feature_list.json; git diff --check
Not-tested: ./init.sh because this commit is documentation and tracker only."
```

## Task 2: Add Fun Contract Tests

**Files:**
- Create: `/Users/taewookkim/dev/guju-jaengpae/test/test_fun_contract.gd`
- Modify: `/Users/taewookkim/dev/guju-jaengpae/init.sh`

- [ ] **Step 1: Write the failing test file**

Create `test/test_fun_contract.gd`:

```gdscript
extends TestCase

var cat: CardCatalog
var lord: LordData
var run: RunState

func before_each() -> void:
	cat = CardCatalog.new()
	cat.load_all()
	lord = cat.get_lord(&"lord_liubei")
	run = RunState.new()
	run.start_run(lord, cat)

func test_first_stage_requires_castle_before_card_play() -> void:
	eq(run.hand.size(), RunState.HAND_DRAW_COUNT, "시작 손패는 3장")
	falsy(run.has_castle(), "성은 자동 배치되지 않음")
	falsy(run.place_from_hand(0, "0:0"), "성 없이 카드 배치 불가")
	truthy(run.set_castle_key("1:1"), "성 위치 선택")
	truthy(run.place_from_hand(0, "0:0"), "성 선택 후 카드 배치 가능")

func test_only_one_card_action_is_allowed_per_encounter() -> void:
	truthy(run.set_castle_key("1:1"), "성 위치 선택")
	truthy(run.place_from_hand(0, "0:0"), "첫 카드 배치")
	run.mark_deploy_card_played()
	falsy(run.can_place_deploy_card(), "한 교전에는 한 장만 사용")

func test_duplicate_unit_upgrade_keeps_board_slot() -> void:
	run = RunState.new()
	run.hand_add(&"troop_archer")
	run.hand_add(&"troop_archer")
	truthy(run.set_castle_key("1:1"), "성 위치 선택")
	truthy(run.place_from_hand(0, "0:0"), "궁병 배치")
	eq(run.board_level("0:0"), 1, "초기 Lv.1")
	truthy(run.can_upgrade_from_hand(0), "중복 궁병은 증원 가능")
	eq(run.upgrade_from_hand(0), "0:0", "기존 칸 증원")
	eq(run.board.size(), 1, "증원은 새 칸 차지하지 않음")
	eq(run.board_level("0:0"), 2, "Lv.2")

func test_troop_card_represents_visible_squad() -> void:
	var unit := cat.build_player_unit(&"troop_archer", 0, 0.0, lord, [], 1)
	not_null(unit, "궁병 유닛 생성")
	if unit == null:
		return
	truthy(unit.squad_count >= 8, "Lv.1 병종은 최소 8명 분대")
	truthy(unit.squad_count <= 10, "Lv.1 병종은 최대 10명 분대")
	falsy(unit.controllable, "병종은 영웅 조작 대상이 아님")

func test_general_card_has_retinue_not_large_solo_body() -> void:
	var unit := cat.build_player_unit(&"general_guanyu", 0, 0.0, lord, [], 1)
	not_null(unit, "관우 유닛 생성")
	if unit == null:
		return
	eq(unit.squad_count, 1, "장수 본체는 1명")
	truthy(unit.retinue_count >= 5, "장수 주변에 호위병 존재")
	truthy(unit.controllable, "장수는 영웅 조작 대상")
```

- [ ] **Step 2: Register the test in `init.sh`**

Add `test/test_fun_contract.gd` to the test list in the same place as the other `test/test_*.gd` files.

- [ ] **Step 3: Run the targeted test**

Run:

```bash
cd /Users/taewookkim/dev/guju-jaengpae
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}" "$GODOT_BIN" --headless --path . -s test/runner.gd test/test_fun_contract.gd
```

Expected now:

```text
failure about place_from_hand allowing card before castle, or all tests pass if feat-038 already covers it
```

- [ ] **Step 4: Commit tests**

```bash
git add test/test_fun_contract.gd init.sh
git commit -m "Lock the squad-card fun contract

Constraint: The next feature must preserve castle-first, three-choice, one-card, squad-density behavior.
Rejected: Visual-only tests | core loop failures should be caught headlessly.
Confidence: high
Scope-risk: narrow
Directive: Keep these tests product-facing rather than implementation-specific.
Tested: GODOT headless test/runner.gd test/test_fun_contract.gd
Not-tested: Full ./init.sh deferred until implementation patch."
```

## Task 3: Extract Squad Profile Math

**Files:**
- Create: `/Users/taewookkim/dev/guju-jaengpae/scripts/battle/squad_profile.gd`
- Create: `/Users/taewookkim/dev/guju-jaengpae/test/test_squad_profile.gd`
- Modify: `/Users/taewookkim/dev/guju-jaengpae/scripts/resources/card_catalog.gd`
- Modify: `/Users/taewookkim/dev/guju-jaengpae/init.sh`

- [ ] **Step 1: Write squad profile tests**

Create `test/test_squad_profile.gd`:

```gdscript
extends TestCase

const SquadProfile := preload("res://scripts/battle/squad_profile.gd")

var cat: CardCatalog

func before_each() -> void:
	cat = CardCatalog.new()
	cat.load_all()

func test_archer_level_one_starts_as_ten_soldiers() -> void:
	var card := cat.get_card(&"troop_archer")
	var profile := SquadProfile.for_card(card, 1)
	eq(profile.get("squad_level"), 1, "Lv.1")
	eq(profile.get("squad_count"), 10, "궁병 Lv.1은 10명")
	eq(profile.get("retinue_count"), 0, "병종은 호위병 없음")
	almost(float(profile.get("attack_mult")), 1.0, 0.0001, "Lv.1 공격 배수")

func test_archer_level_three_grows_count_and_attack() -> void:
	var card := cat.get_card(&"troop_archer")
	var profile := SquadProfile.for_card(card, 3)
	eq(profile.get("squad_level"), 3, "Lv.3")
	eq(profile.get("squad_count"), 18, "궁병 Lv.3은 18명")
	almost(float(profile.get("attack_mult")), 1.56, 0.0001, "레벨당 공격 +28%")
	truthy(float(profile.get("attack_interval_mult")) < 1.0, "레벨업은 공격 간격 감소")

func test_general_profile_uses_retinue() -> void:
	var card := cat.get_card(&"general_guanyu")
	var profile := SquadProfile.for_card(card, 2)
	eq(profile.get("squad_count"), 1, "장수 본체는 1명")
	eq(profile.get("retinue_count"), 7, "Lv.2 장수 호위병 7명")
	truthy(float(profile.get("visual_scale")) < 1.0, "장수 본체는 축소 렌더")

func test_clamps_level_to_valid_range() -> void:
	var card := cat.get_card(&"troop_cavalry")
	eq(SquadProfile.for_card(card, -9).get("squad_level"), 1, "최소 Lv.1")
	eq(SquadProfile.for_card(card, 99).get("squad_level"), RunState.CARD_LEVEL_MAX, "최대 Lv.5")
```

- [ ] **Step 2: Run the new test to verify failure**

Run:

```bash
cd /Users/taewookkim/dev/guju-jaengpae
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}" "$GODOT_BIN" --headless --path . -s test/runner.gd test/test_squad_profile.gd
```

Expected:

```text
Parse Error: Could not preload resource at res://scripts/battle/squad_profile.gd
```

- [ ] **Step 3: Create `squad_profile.gd`**

```gdscript
class_name SquadProfile
extends RefCounted

static func for_card(card: UnitCardData, level: int) -> Dictionary:
	if card == null:
		return {}
	var clamped_level := clampi(level, 1, RunState.CARD_LEVEL_MAX)
	var is_general := String(card.card_type) == "general"
	if is_general:
		return {
			"squad_level": clamped_level,
			"squad_count": 1,
			"retinue_count": 5 + ((clamped_level - 1) * 2),
			"hp_mult": 1.0 + (0.16 * float(clamped_level - 1)),
			"attack_mult": 1.0 + (0.20 * float(clamped_level - 1)),
			"move_speed_mult": 1.0 + (0.10 * float(clamped_level - 1)),
			"attack_interval_mult": 1.0,
			"visual_scale": 0.82,
		}
	var base_count := _base_troop_count(card)
	return {
		"squad_level": clamped_level,
		"squad_count": base_count + ((clamped_level - 1) * 4),
		"retinue_count": 0,
		"hp_mult": float(base_count + ((clamped_level - 1) * 4)) / float(base_count),
		"attack_mult": 1.0 + (0.28 * float(clamped_level - 1)),
		"move_speed_mult": 1.0 + (0.12 * float(clamped_level - 1)),
		"attack_interval_mult": maxf(0.55, 1.0 - (0.04 * float(clamped_level - 1))),
		"visual_scale": 1.0,
	}

static func _base_troop_count(card: UnitCardData) -> int:
	match String(card.troop_type):
		"cavalry":
			return 8
		"navy":
			return 9
		"fantasy":
			return 6
		_:
			return 10
```

- [ ] **Step 4: Delegate `CardCatalog._apply_squad_growth` to `SquadProfile`**

At the top of `scripts/resources/card_catalog.gd`, add:

```gdscript
const _SquadProfile := preload("res://scripts/battle/squad_profile.gd")
```

Replace the existing squad growth calculation with:

```gdscript
func _apply_squad_growth(unit: BattleUnit, card: UnitCardData, squad_level: int) -> void:
	var profile := _SquadProfile.for_card(card, squad_level)
	if profile.is_empty():
		return
	unit.squad_level = int(profile.get("squad_level", 1))
	unit.squad_count = int(profile.get("squad_count", 1))
	unit.retinue_count = int(profile.get("retinue_count", 0))
	unit.max_hp = int(round(float(unit.max_hp) * float(profile.get("hp_mult", 1.0))))
	unit.hp = unit.max_hp
	unit.attack = int(round(float(unit.attack) * float(profile.get("attack_mult", 1.0))))
	unit.move_speed *= float(profile.get("move_speed_mult", 1.0))
	unit.attack_interval = maxf(0.55, unit.attack_interval * float(profile.get("attack_interval_mult", 1.0)))
```

- [ ] **Step 5: Register the test and verify**

Add `test/test_squad_profile.gd` to `init.sh`, then run:

```bash
cd /Users/taewookkim/dev/guju-jaengpae
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}" "$GODOT_BIN" --headless --path . -s test/runner.gd test/test_squad_profile.gd
./init.sh
```

Expected:

```text
test/test_squad_profile.gd passes
./init.sh exits 0 with assertion count greater than 2485
```

- [ ] **Step 6: Commit**

```bash
git add scripts/battle/squad_profile.gd scripts/resources/card_catalog.gd test/test_squad_profile.gd init.sh
git commit -m "Extract squad growth profiles

Constraint: Unit cards must feel like squads without rewriting BattleSim into per-soldier simulation.
Rejected: Encoding squad math directly in battle.gd | visuals and sim would drift.
Confidence: high
Scope-risk: moderate
Directive: Keep SquadProfile pure and deterministic.
Tested: GODOT headless test/runner.gd test/test_squad_profile.gd; ./init.sh
Not-tested: Manual visual density pass."
```

## Task 4: Extract Formation Rendering Math

**Files:**
- Create: `/Users/taewookkim/dev/guju-jaengpae/scripts/battle/formation_renderer.gd`
- Create: `/Users/taewookkim/dev/guju-jaengpae/test/test_formation_renderer.gd`
- Modify: `/Users/taewookkim/dev/guju-jaengpae/scripts/battle/battle.gd`
- Modify: `/Users/taewookkim/dev/guju-jaengpae/init.sh`

- [ ] **Step 1: Write formation math tests**

Create `test/test_formation_renderer.gd`:

```gdscript
extends TestCase

const FormationRenderer := preload("res://scripts/battle/formation_renderer.gd")

func test_ten_member_formation_has_grounded_offsets() -> void:
	var offsets := FormationRenderer.member_offsets(10, false)
	eq(offsets.size(), 10, "10명 대형")
	for offset in offsets:
		truthy(absf(offset.x) <= 96.0, "x offset bounded")
		truthy(offset.y >= -38.0 and offset.y <= 42.0, "y offset bounded near feet")

func test_general_retinue_leaves_center_for_general() -> void:
	var offsets := FormationRenderer.member_offsets(7, true)
	eq(offsets.size(), 7, "호위병 7명")
	for offset in offsets:
		truthy(offset.length() >= 24.0, "호위병은 장수 본체와 겹치지 않음")

func test_sort_key_uses_y_then_x_for_painter_order() -> void:
	var a := Vector2(-10, 20)
	var b := Vector2(10, 10)
	truthy(FormationRenderer.sort_key(a) > FormationRenderer.sort_key(b), "아래쪽 멤버가 나중에 그려짐")
```

- [ ] **Step 2: Create formation helper**

```gdscript
class_name FormationRenderer
extends RefCounted

static func member_offsets(count: int, is_retinue: bool) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var safe_count := clampi(count, 0, 24)
	if safe_count <= 0:
		return out
	var cols := 4 if safe_count <= 12 else 5
	var spacing_x := 34.0 if not is_retinue else 40.0
	var spacing_y := 22.0 if not is_retinue else 26.0
	for idx in safe_count:
		var row := idx / cols
		var col := idx % cols
		var centered_col := float(col) - (float(mini(cols, safe_count) - 1) * 0.5)
		var x := centered_col * spacing_x
		var y := (float(row) * spacing_y) - 24.0
		if is_retinue and Vector2(x, y).length() < 24.0:
			x += 30.0
		out.append(Vector2(x, y))
	out.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return sort_key(a) < sort_key(b)
	)
	return out

static func sort_key(offset: Vector2) -> float:
	return (offset.y * 1000.0) + offset.x
```

- [ ] **Step 3: Replace local offset math in `battle.gd`**

In `scripts/battle/battle.gd`, add:

```gdscript
const _FormationRenderer := preload("res://scripts/battle/formation_renderer.gd")
```

Where the current formation body computes offsets, replace local arrays with:

```gdscript
var offsets := _FormationRenderer.member_offsets(unit.squad_count, false)
```

For general retinues, use:

```gdscript
var retinue_offsets := _FormationRenderer.member_offsets(unit.retinue_count, true)
```

- [ ] **Step 4: Verify**

Run:

```bash
cd /Users/taewookkim/dev/guju-jaengpae
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}" "$GODOT_BIN" --headless --path . -s test/runner.gd test/test_formation_renderer.gd
./init.sh
```

Expected:

```text
formation renderer tests pass
./init.sh exits 0
```

- [ ] **Step 5: Commit**

```bash
git add scripts/battle/formation_renderer.gd scripts/battle/battle.gd test/test_formation_renderer.gd init.sh
git commit -m "Split formation rendering math

Constraint: Soldiers currently risk looking detached from the ground and battle.gd is absorbing too much visual math.
Rejected: More ad hoc offsets inside battle.gd | the visual rule needs tests.
Confidence: high
Scope-risk: moderate
Directive: FormationRenderer must remain pure and scene-free.
Tested: GODOT headless test/runner.gd test/test_formation_renderer.gd; ./init.sh
Not-tested: Human screenshot judgement."
```

## Task 5: Add Terrain Perk Catalog

**Files:**
- Create: `/Users/taewookkim/dev/guju-jaengpae/scripts/run/terrain_perk_catalog.gd`
- Create: `/Users/taewookkim/dev/guju-jaengpae/test/test_terrain_perk_catalog.gd`
- Modify: `/Users/taewookkim/dev/guju-jaengpae/scripts/resources/card_catalog.gd`
- Modify: `/Users/taewookkim/dev/guju-jaengpae/scripts/battle/battle.gd`
- Modify: `/Users/taewookkim/dev/guju-jaengpae/init.sh`

- [ ] **Step 1: Write terrain perk tests**

Create `test/test_terrain_perk_catalog.gd`:

```gdscript
extends TestCase

const TerrainPerkCatalog := preload("res://scripts/run/terrain_perk_catalog.gd")

func test_shu_adjacent_to_castle_grants_hp() -> void:
	var bonus := TerrainPerkCatalog.bonus_for(&"terrain_shu_hometown", "1:1", "1:0")
	almost(float(bonus.get("hp_mult", 1.0)), 1.20, 0.0001, "성 인접 HP +20%")
	almost(float(bonus.get("attack_mult", 1.0)), 1.0, 0.0001, "공격 보정 없음")

func test_wei_same_row_grants_attack() -> void:
	var bonus := TerrainPerkCatalog.bonus_for(&"terrain_wei_commandery", "1:2", "0:2")
	almost(float(bonus.get("attack_mult", 1.0)), 1.15, 0.0001, "같은 행 공격 +15%")

func test_wu_edge_grants_attack() -> void:
	var left := TerrainPerkCatalog.bonus_for(&"terrain_wu_waterway", "1:1", "0:4")
	var center := TerrainPerkCatalog.bonus_for(&"terrain_wu_waterway", "1:1", "1:4")
	almost(float(left.get("attack_mult", 1.0)), 1.15, 0.0001, "가장자리 공격 +15%")
	almost(float(center.get("attack_mult", 1.0)), 1.0, 0.0001, "중앙은 보너스 없음")
```

- [ ] **Step 2: Create terrain helper**

```gdscript
class_name TerrainPerkCatalog
extends RefCounted

static func info(id: StringName) -> Dictionary:
	match id:
		&"terrain_wei_commandery":
			return {"id": id, "name": "군령 평원", "text": "성 같은 행의 아군 공격력 +15%"}
		&"terrain_wu_waterway":
			return {"id": id, "name": "강동 수로", "text": "좌우 가장자리 아군 공격력 +15%"}
		_:
			return {"id": &"terrain_shu_hometown", "name": "인덕 향리", "text": "성 인접 아군 체력 +20%"}

static func bonus_for(id: StringName, castle_key: String, block_key: String) -> Dictionary:
	var bonus := {"hp_mult": 1.0, "attack_mult": 1.0}
	var castle := _parse_key(castle_key)
	var block := _parse_key(block_key)
	if castle.is_empty() or block.is_empty():
		return bonus
	match id:
		&"terrain_wei_commandery":
			if int(castle.y) == int(block.y):
				bonus["attack_mult"] = 1.15
		&"terrain_wu_waterway":
			if int(block.x) == 0 or int(block.x) == RunState.BOARD_COLS - 1:
				bonus["attack_mult"] = 1.15
		_:
			if absi(int(castle.x) - int(block.x)) + absi(int(castle.y) - int(block.y)) == 1:
				bonus["hp_mult"] = 1.20
	return bonus

static func _parse_key(key: String) -> Vector2i:
	var parts := key.split(":")
	if parts.size() != 2:
		return Vector2i(-999, -999)
	if not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return Vector2i(-999, -999)
	return Vector2i(int(parts[0]), int(parts[1]))
```

- [ ] **Step 3: Delegate terrain info in `CardCatalog`**

Add:

```gdscript
const _TerrainPerkCatalog := preload("res://scripts/run/terrain_perk_catalog.gd")
```

Replace `terrain_perk_info(id)` body with:

```gdscript
func terrain_perk_info(id: StringName) -> Dictionary:
	return _TerrainPerkCatalog.info(id)
```

In `build_board_army`, apply `TerrainPerkCatalog.bonus_for()` before returning each unit:

```gdscript
var terrain_bonus := _TerrainPerkCatalog.bonus_for(terrain_perk_id, castle_key, key)
unit.max_hp = int(round(float(unit.max_hp) * float(terrain_bonus.get("hp_mult", 1.0))))
unit.hp = unit.max_hp
unit.attack = int(round(float(unit.attack) * float(terrain_bonus.get("attack_mult", 1.0))))
```

- [ ] **Step 4: Add visual hints in `battle.gd`**

When drawing board tiles in deployment phase, mark bonus tiles with a small label:

```gdscript
var terrain_bonus := _TerrainPerkCatalog.bonus_for(RunManager.get_terrain_perk_id(), RunManager.get_castle_key(), block_key)
var has_bonus := float(terrain_bonus.get("hp_mult", 1.0)) > 1.0 or float(terrain_bonus.get("attack_mult", 1.0)) > 1.0
if has_bonus:
	_draw_tile_badge(tile_node, "특")
```

If `_draw_tile_badge` does not exist, create it in `battle.gd`:

```gdscript
func _draw_tile_badge(parent: Node2D, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.modulate = Color(1.0, 0.88, 0.45, 1.0)
	label.position = Vector2(-10, -36)
	parent.add_child(label)
```

- [ ] **Step 5: Verify**

```bash
cd /Users/taewookkim/dev/guju-jaengpae
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}" "$GODOT_BIN" --headless --path . -s test/runner.gd test/test_terrain_perk_catalog.gd
./init.sh
```

Expected:

```text
terrain perk tests pass
./init.sh exits 0
```

- [ ] **Step 6: Commit**

```bash
git add scripts/run/terrain_perk_catalog.gd scripts/resources/card_catalog.gd scripts/battle/battle.gd test/test_terrain_perk_catalog.gd init.sh
git commit -m "Make terrain perks explicit

Constraint: Castle placement must create visible tactical decisions.
Rejected: Hiding terrain rules in CardCatalog | board UI and tests need the same rule source.
Confidence: high
Scope-risk: moderate
Directive: Keep terrain bonuses pure and keyed by board coordinates.
Tested: GODOT headless test/runner.gd test/test_terrain_perk_catalog.gd; ./init.sh
Not-tested: Manual readability of tile badge."
```

## Task 6: Define Strategy Deck Pools

**Files:**
- Create: `/Users/taewookkim/dev/guju-jaengpae/scripts/run/strategy_deck_catalog.gd`
- Create: `/Users/taewookkim/dev/guju-jaengpae/test/test_strategy_deck_catalog.gd`
- Modify: `/Users/taewookkim/dev/guju-jaengpae/scripts/resources/card_catalog.gd`
- Modify: `/Users/taewookkim/dev/guju-jaengpae/init.sh`

- [ ] **Step 1: Write deck catalog tests**

```gdscript
extends TestCase

const StrategyDeckCatalog := preload("res://scripts/run/strategy_deck_catalog.gd")

func test_liubei_strategy_pool_has_twelve_cards_and_duplicates_for_growth() -> void:
	var deck := StrategyDeckCatalog.deck_for_lord(&"lord_liubei")
	eq(deck.size(), 12, "유비 전략 풀은 12장")
	eq(_count(deck, &"troop_archer"), 2, "궁병 중복으로 성장 가능")
	eq(_count(deck, &"troop_infantry"), 2, "보병 중복으로 성장 가능")
	truthy(deck.has(&"building_dunjeon"), "건물 포함")
	truthy(deck.has(&"building_mangru"), "타워 포함")

func test_each_mortal_lord_has_at_least_two_duplicate_unit_cards() -> void:
	for lord_id in [&"lord_liubei", &"lord_caocao", &"lord_sunquan"]:
		var deck := StrategyDeckCatalog.deck_for_lord(lord_id)
		var duplicate_unit_kinds := 0
		for id in deck:
			if String(id).begins_with("troop_") and _count(deck, id) >= 2:
				duplicate_unit_kinds += 1
		truthy(duplicate_unit_kinds >= 2, "%s has two duplicate unit kinds" % lord_id)

func _count(deck: Array[StringName], id: StringName) -> int:
	var n := 0
	for card_id in deck:
		if card_id == id:
			n += 1
	return n
```

- [ ] **Step 2: Create strategy deck catalog**

```gdscript
class_name StrategyDeckCatalog
extends RefCounted

static func deck_for_lord(lord_id: StringName) -> Array[StringName]:
	match lord_id:
		&"lord_caocao":
			return [
				&"general_caocao", &"general_xiahoudun", &"troop_cavalry", &"troop_cavalry",
				&"troop_crossbow", &"troop_crossbow", &"troop_infantry", &"building_mangru",
				&"building_dunjeon", &"scheme_raid", &"treasure_bingfashu", &"treasure_jinyin",
			]
		&"lord_sunquan":
			return [
				&"general_sunquan", &"general_zhouyu", &"troop_navy", &"troop_navy",
				&"troop_archer", &"troop_archer", &"troop_crossbow", &"building_dunjeon",
				&"building_mangru", &"scheme_fortify", &"treasure_qianliyan", &"treasure_jinyin",
			]
		_:
			return [
				&"general_guanyu", &"general_zhangfei", &"general_zhaoyun", &"troop_infantry",
				&"troop_infantry", &"troop_archer", &"troop_archer", &"building_dunjeon",
				&"building_mangru", &"scheme_levy", &"treasure_bingfashu", &"treasure_qianliyan",
			]
```

- [ ] **Step 3: Delegate in `CardCatalog.get_lord_strategy_deck`**

Add:

```gdscript
const _StrategyDeckCatalog := preload("res://scripts/run/strategy_deck_catalog.gd")
```

Replace the match body with:

```gdscript
func get_lord_strategy_deck(lord: LordData) -> Array[StringName]:
	if lord == null:
		return []
	return _StrategyDeckCatalog.deck_for_lord(lord.id)
```

- [ ] **Step 4: Adjust tests that expect nine-card deck**

In `test/test_run_board.gd`, change:

```gdscript
eq(cat.get_lord_strategy_deck(lord).size(), 9, "유비 전략 덱은 9장")
eq(run.draw_pile.size(), 6, "남은 6장은 드로우 더미")
```

to:

```gdscript
eq(cat.get_lord_strategy_deck(lord).size(), 12, "유비 전략 풀은 12장")
eq(run.draw_pile.size(), 9, "남은 9장은 드로우 더미")
```

- [ ] **Step 5: Verify**

```bash
cd /Users/taewookkim/dev/guju-jaengpae
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}" "$GODOT_BIN" --headless --path . -s test/runner.gd test/test_strategy_deck_catalog.gd
./init.sh
```

Expected:

```text
strategy deck tests pass
./init.sh exits 0
```

- [ ] **Step 6: Commit**

```bash
git add scripts/run/strategy_deck_catalog.gd scripts/resources/card_catalog.gd test/test_strategy_deck_catalog.gd test/test_run_board.gd init.sh
git commit -m "Define faction strategy pools

Constraint: The player should see three choices but factions need enough card identity for growth.
Rejected: Strict nine-card pools | the requested 4+4+4 class structure requires twelve slots.
Confidence: medium
Scope-risk: moderate
Directive: Keep visible hand size at three and one play per encounter.
Tested: GODOT headless test/runner.gd test/test_strategy_deck_catalog.gd; ./init.sh
Not-tested: Long-run reward distribution feel."
```

## Task 7: Add Playtest Metrics Smoke

**Files:**
- Create: `/Users/taewookkim/dev/guju-jaengpae/scripts/run/playtest_metrics.gd`
- Create: `/Users/taewookkim/dev/guju-jaengpae/tools/playtest_loop_smoke.gd`
- Modify: `/Users/taewookkim/dev/guju-jaengpae/init.sh`

- [ ] **Step 1: Create metrics helper**

```gdscript
class_name PlaytestMetrics
extends RefCounted

static func summarize_battle(result: Dictionary, army: Array) -> Dictionary:
	var visible_soldiers := 0
	var unit_count := army.size()
	for unit in army:
		if unit is BattleUnit:
			visible_soldiers += maxi(1, unit.squad_count) + maxi(0, unit.retinue_count)
	return {
		"duration": float(result.get("time", 0.0)),
		"winner": String(result.get("winner", "")),
		"unit_count": unit_count,
		"visible_soldiers": visible_soldiers,
	}
```

- [ ] **Step 2: Create smoke script**

```gdscript
extends SceneTree

func _init() -> void:
	var cat := CardCatalog.new()
	cat.load_all()
	var lord := cat.get_lord(&"lord_liubei")
	var run := RunState.new()
	run.start_run(lord, cat)
	run.set_castle_key("1:1")
	run.place_from_hand(0, "0:1")
	run.mark_deploy_card_played()
	var army := cat.build_board_army(run.board, lord, run.board_rows, run.edicts, run.castle_key, run.terrain_perk_id, run.board_levels_copy())
	var sim := BattleSim.new()
	for unit in army:
		sim.add_unit(unit)
	sim.add_castle_at(BattleUnit.Team.PLAYER, run.castle_key, run.board_rows)
	for wave in WaveFactory.stage_encounter_waves(1):
		for enemy in wave:
			sim.add_unit(enemy)
	var result := sim.run_until_done()
	var metrics := PlaytestMetrics.summarize_battle(result, army)
	print("GUJU_PLAYTEST_METRICS %s" % JSON.stringify(metrics))
	quit(0 if metrics.get("visible_soldiers", 0) >= 8 and float(metrics.get("duration", 0.0)) <= 25.0 else 1)
```

- [ ] **Step 3: Add the smoke to `init.sh`**

Add:

```bash
"$GODOT_BIN" --headless --path . -s tools/playtest_loop_smoke.gd
```

Expected output includes:

```text
GUJU_PLAYTEST_METRICS
```

- [ ] **Step 4: Verify**

```bash
cd /Users/taewookkim/dev/guju-jaengpae
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}" "$GODOT_BIN" --headless --path . -s tools/playtest_loop_smoke.gd
./init.sh
```

Expected:

```text
GUJU_PLAYTEST_METRICS {"duration":..., "winner":"player", "unit_count":..., "visible_soldiers":...}
./init.sh exits 0
```

- [ ] **Step 5: Commit**

```bash
git add scripts/run/playtest_metrics.gd tools/playtest_loop_smoke.gd init.sh
git commit -m "Add playtest loop metrics

Constraint: Fun work needs measurable duration and army-density evidence.
Rejected: Relying only on manual impressions | regressions need a small smoke marker.
Confidence: high
Scope-risk: narrow
Directive: Keep metrics compact and deterministic.
Tested: GODOT headless tools/playtest_loop_smoke.gd; ./init.sh
Not-tested: Human fun judgement."
```

## Task 8: Reframe Enemy Encounters As Army Clashes

**Files:**
- Modify: `/Users/taewookkim/dev/guju-jaengpae/scripts/battle/wave_factory.gd`
- Modify: `/Users/taewookkim/dev/guju-jaengpae/scripts/battle/battle_sim.gd`
- Modify: `/Users/taewookkim/dev/guju-jaengpae/test/test_wave_factory.gd`
- Modify: `/Users/taewookkim/dev/guju-jaengpae/test/test_multiwave.gd`

- [ ] **Step 1: Add wave factory assertions**

In `test/test_wave_factory.gd`, add:

```gdscript
func test_stage_encounter_spawns_grouped_army_not_trickle() -> void:
	var waves := WaveFactory.stage_encounter_waves(1)
	eq(waves.size(), 1, "런 전투는 단일 교전")
	truthy(waves[0].size() >= 3, "적은 시작부터 여러 부대")
	for enemy in waves[0]:
		truthy(enemy.squad_count >= 7 or enemy.card_id == &"boss_dongzhuo", "적 일반 부대는 분대 수 보유")
```

- [ ] **Step 2: Keep `stage_encounter_waves` single-wave**

In `scripts/battle/wave_factory.gd`, ensure:

```gdscript
static func stage_encounter_waves(stage: int) -> Array:
	return [stage_waves(stage).front()]
```

If `stage_waves(stage)` can return an empty array, use:

```gdscript
static func stage_encounter_waves(stage: int) -> Array:
	var waves := stage_waves(stage)
	if waves.is_empty():
		return [[]]
	return [waves.front()]
```

- [ ] **Step 3: Tune early enemy squads**

In `_enemy_unit`, ensure non-boss enemies carry visible group values:

```gdscript
if not is_boss_name(unit.display_name):
	unit.squad_level = 1
	unit.squad_count = 7 if unit.attack_range > 120.0 else 9
	unit.retinue_count = 0
```

- [ ] **Step 4: Verify**

```bash
cd /Users/taewookkim/dev/guju-jaengpae
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}" "$GODOT_BIN" --headless --path . -s test/runner.gd test/test_wave_factory.gd
./init.sh
```

Expected:

```text
test_wave_factory passes
./init.sh exits 0
```

- [ ] **Step 5: Commit**

```bash
git add scripts/battle/wave_factory.gd scripts/battle/battle_sim.gd test/test_wave_factory.gd test/test_multiwave.gd
git commit -m "Frame encounters as army clashes

Constraint: User feedback says the start feels like a defense game.
Rejected: Multi-wave trickle for normal stages | the desired loop is prepare once, clash once.
Confidence: high
Scope-risk: moderate
Directive: Keep act boss structure intact while normal run combat uses single encounter waves.
Tested: GODOT headless test/runner.gd test/test_wave_factory.gd; ./init.sh
Not-tested: Long-run manual pacing."
```

## Task 9: UX Labels For Card Intent

**Files:**
- Modify: `/Users/taewookkim/dev/guju-jaengpae/scripts/ui/card_ui_text.gd`
- Modify: `/Users/taewookkim/dev/guju-jaengpae/scripts/battle/battle.gd`
- Modify: `/Users/taewookkim/dev/guju-jaengpae/tools/ui_feedback_smoke.gd`

- [ ] **Step 1: Add card intent text API**

In `card_ui_text.gd`, add:

```gdscript
static func action_label(card: CardData, can_upgrade: bool = false) -> String:
	if card == null:
		return "선택 불가"
	if can_upgrade:
		return "증원"
	match String(card.card_type):
		"scheme":
			return "발동"
		"treasure":
			return "장착"
		"building":
			return "건설"
		"general":
			return "출진"
		"troop":
			return "배치"
		_:
			return "선택"
```

- [ ] **Step 2: Use action label in battle hand buttons**

Where hand buttons are rendered in `battle.gd`, set button text using:

```gdscript
var can_upgrade := RunManager.can_upgrade_from_hand(i)
var action := CardUiText.action_label(card, can_upgrade)
button.text = "[%s] %s" % [action, CardUiText.name_for(card)]
```

- [ ] **Step 3: Extend UI smoke**

In `tools/ui_feedback_smoke.gd`, assert that battle deploy hand text contains one of these labels:

```gdscript
var valid_actions := ["[출진]", "[배치]", "[증원]", "[발동]", "[건설]", "[장착]"]
var found_action := false
for label in valid_actions:
	if _screen_text_contains(root, label):
		found_action = true
truthy(found_action, "전투 손패는 카드 행동 라벨을 표시")
```

- [ ] **Step 4: Verify**

```bash
cd /Users/taewookkim/dev/guju-jaengpae
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}" "$GODOT_BIN" --headless --path . -s tools/ui_feedback_smoke.gd
./init.sh
```

Expected:

```text
UI feedback smoke passes
./init.sh exits 0
```

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/card_ui_text.gd scripts/battle/battle.gd tools/ui_feedback_smoke.gd
git commit -m "Clarify card action labels

Constraint: Three-card choices must be instantly understandable.
Rejected: Card names alone | the player needs to know whether the card places, upgrades, casts, or equips.
Confidence: high
Scope-risk: narrow
Directive: Keep labels Korean and action-first.
Tested: GODOT headless tools/ui_feedback_smoke.gd; ./init.sh
Not-tested: Manual text fit at every viewport."
```

## Task 10: Visual And Audio Feel Pass

**Files:**
- Modify: `/Users/taewookkim/dev/guju-jaengpae/scripts/battle/battle.gd`
- Modify: `/Users/taewookkim/dev/guju-jaengpae/scripts/autoloads/audio_manager.gd`
- Modify: `/Users/taewookkim/dev/guju-jaengpae/tools/shoot_ui_bundle.sh`
- Modify: `/Users/taewookkim/dev/guju-jaengpae/tools/validate_screenshot_bundle.py`

- [ ] **Step 1: Add battle start and clash cues**

In `battle.gd`, when combat changes from deploy to battle state, call:

```gdscript
AudioManager.play_sfx(&"sfx_battle_start")
_show_center_banner("함성")
```

When the first damage event occurs in a stage, call once:

```gdscript
AudioManager.play_sfx(&"sfx_hit")
```

- [ ] **Step 2: Ensure shadows stay under formations**

In the formation body creation code, add shadow before member sprites:

```gdscript
var shadow := ColorRect.new()
shadow.color = Color(0, 0, 0, 0.28)
shadow.size = Vector2(92, 22)
shadow.position = Vector2(-46, -6)
body.add_child(shadow)
```

If the code uses `Sprite2D` only, create an `Ellipse` texture once and reuse it; do not draw a separate shadow per soldier.

- [ ] **Step 3: Update screenshot validator**

In `tools/validate_screenshot_bundle.py`, require these files to exist:

```python
REQUIRED = [
    "lord_select.png",
    "battle_deploy_lord_liubei_stage_1.png",
    "battle_fight_lord_liubei_stage_1.png",
    "run_map_lord_liubei_stage_1.png",
    "shop_lord_liubei_stage_4.png",
]
```

Add a size check:

```python
if image.width < 1280 or image.height < 720:
    raise SystemExit(f"{path} too small: {image.width}x{image.height}")
```

- [ ] **Step 4: Verify screenshots**

```bash
cd /Users/taewookkim/dev/guju-jaengpae
SHOT_DIR=/tmp/guju-feat040-ui ./tools/shoot_ui_bundle.sh
python3 tools/validate_screenshot_bundle.py /tmp/guju-feat040-ui
./init.sh
```

Expected:

```text
validated screenshot bundle
./init.sh exits 0
```

- [ ] **Step 5: Commit**

```bash
git add scripts/battle/battle.gd scripts/autoloads/audio_manager.gd tools/shoot_ui_bundle.sh tools/validate_screenshot_bundle.py
git commit -m "Add army clash feel cues

Constraint: The battle needs immediate sound and grounded visual feedback.
Rejected: More static sprites only | the problem is perceived impact, not just data.
Confidence: medium
Scope-risk: moderate
Directive: Keep audio optional and headless-safe.
Tested: SHOT_DIR=/tmp/guju-feat040-ui ./tools/shoot_ui_bundle.sh; python3 tools/validate_screenshot_bundle.py /tmp/guju-feat040-ui; ./init.sh
Not-tested: Speaker playback on every machine."
```

## Task 11: Manual Playtest Packet

**Files:**
- Create: `/Users/taewookkim/dev/guju-jaengpae/docs/reports/feat-040-playtest.md`
- Modify: `/Users/taewookkim/dev/guju-jaengpae/progress.md`
- Modify: `/Users/taewookkim/dev/guju-jaengpae/session-handoff.md`

- [ ] **Step 1: Create playtest report**

```markdown
# feat-040 Playtest Report

## Build
- Date: 2026-06-05
- Verification: `./init.sh`
- Screenshot bundle: `/tmp/guju-feat040-ui`

## Checklist
- [ ] Castle placement happens before any card is played.
- [ ] The player sees three cards, not the full pool.
- [ ] Playing one card starts the clash.
- [ ] A duplicate troop card upgrades the existing squad.
- [ ] Troop squads look grounded.
- [ ] Generals look smaller and have retinues.
- [ ] Enemy starts as an army group, not a trickle.
- [ ] First fight resolves quickly enough to stay readable.
- [ ] Reward choice feels like growth, not cleanup.

## Notes
- Keep concrete observations in short bullets with stage, lord, and screenshot path.
```

- [ ] **Step 2: Update progress**

Add evidence under `검증 증거`:

```markdown
- [x] feat-040 playtest packet — `docs/reports/feat-040-playtest.md` created with castle-first, three-card, one-card, squad density, upgrade, enemy army, and reward-growth checklist.
```

- [ ] **Step 3: Update handoff**

Add to the top current-state bullet:

```markdown
- **feat-040 playtest gate** — before adding more content, run `docs/reports/feat-040-playtest.md` checklist against a local Godot play session and keep screenshot paths beside observations.
```

- [ ] **Step 4: Verify docs**

```bash
cd /Users/taewookkim/dev/guju-jaengpae
git diff --check
```

Expected:

```text
no output
```

- [ ] **Step 5: Commit**

```bash
git add docs/reports/feat-040-playtest.md progress.md session-handoff.md
git commit -m "Add the fun reset playtest packet

Constraint: Automated tests cannot prove the game is fun.
Rejected: Shipping from green tests alone | the current risk is feel and readability.
Confidence: high
Scope-risk: narrow
Directive: Every future content lane must preserve this playtest checklist.
Tested: git diff --check
Not-tested: Human playtest not run in this commit."
```

## Task 12: Final Verification For feat-040

**Files:**
- Modify: `/Users/taewookkim/dev/guju-jaengpae/feature_list.json`
- Modify: `/Users/taewookkim/dev/guju-jaengpae/progress.md`
- Modify: `/Users/taewookkim/dev/guju-jaengpae/session-handoff.md`

- [ ] **Step 1: Run full verification**

```bash
cd /Users/taewookkim/dev/guju-jaengpae
python3 -m json.tool feature_list.json >/dev/null
git diff --check
./init.sh
SHOT_DIR=/tmp/guju-feat040-ui ./tools/shoot_ui_bundle.sh
python3 tools/validate_screenshot_bundle.py /tmp/guju-feat040-ui
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}" "$GODOT_BIN" --headless --path . -s tools/playtest_loop_smoke.gd
```

Expected:

```text
all commands exit 0
./init.sh assertion count greater than 2485
GUJU_PLAYTEST_METRICS printed once
```

- [ ] **Step 2: Mark feature done**

Update `feature_list.json` `feat-040`:

```json
{
  "status": "done",
  "evidence": "./init.sh green, playtest_loop_smoke metrics, screenshot bundle validation, and docs/reports/feat-040-playtest.md checklist."
}
```

Use the file's current object shape rather than replacing unrelated fields.

- [ ] **Step 3: Update progress current state**

Set active feature to:

```markdown
**활성 피처 (Active Feature)** — feat-040 Fun Reset 완료
```

Add:

```markdown
- [x] **feat-040 Fun Reset** — 성 선점, 3장 손패, 1장 플레이, 분대 성장, 장수 호위병, 지형 시너지, 단일 교전, UI 행동 라벨, playtest metrics, screenshot bundle을 제품 루프로 묶었다.
```

- [ ] **Step 4: Update handoff**

Add a new current-state bullet:

```markdown
- **feat-040 done** — current fun contract is castle first, three-card choice, one action per encounter, grouped squad clash, duplicate upgrade, terrain bonus, action-first card labels, metrics smoke, and playtest packet.
```

- [ ] **Step 5: Commit**

```bash
git add feature_list.json progress.md session-handoff.md
git commit -m "Close the squad-card fun reset

Constraint: Completion needs tests, metrics, screenshots, and restartable state.
Rejected: Calling the lane done from implementation only | playtest evidence is required.
Confidence: high
Scope-risk: narrow
Directive: Do not start 9-faction content until the fun reset survives manual play.
Tested: python3 -m json.tool feature_list.json; git diff --check; ./init.sh; SHOT_DIR=/tmp/guju-feat040-ui ./tools/shoot_ui_bundle.sh; python3 tools/validate_screenshot_bundle.py /tmp/guju-feat040-ui; GODOT headless tools/playtest_loop_smoke.gd
Not-tested: Push and release tag, both require user confirmation."
```

## After feat-040: Parallel Follow-Up Lanes

### Lane F1 — Mortal Three Kingdoms Content Density

Owner: content executor with test engineer.

Files:
- `/Users/taewookkim/dev/guju-jaengpae/resources/cards/*.tres`
- `/Users/taewookkim/dev/guju-jaengpae/resources/lords/*.tres`
- `/Users/taewookkim/dev/guju-jaengpae/scripts/run/strategy_deck_catalog.gd`
- `/Users/taewookkim/dev/guju-jaengpae/test/test_strategy_deck_catalog.gd`

Acceptance:
- Each approved mortal lord has at least 12 strategy pool slots.
- Each deck has at least two duplicate troop upgrade lines.
- Each deck has one scheme and two passive or economy choices.
- No heaven or demon canon ids are added.

Verification:

```bash
cd /Users/taewookkim/dev/guju-jaengpae
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}" "$GODOT_BIN" --headless --path . -s test/runner.gd test/test_strategy_deck_catalog.gd
./init.sh
```

### Lane F2 — Tactical Board Depth

Owner: architect plus executor.

Files:
- `/Users/taewookkim/dev/guju-jaengpae/scripts/run/terrain_perk_catalog.gd`
- `/Users/taewookkim/dev/guju-jaengpae/scripts/battle/battle.gd`
- `/Users/taewookkim/dev/guju-jaengpae/test/test_terrain_perk_catalog.gd`

Acceptance:
- Castle position changes at least three highlighted bonus tiles.
- Hover/selection feedback shows why a tile matters.
- Bonuses are pure and testable.

Verification:

```bash
cd /Users/taewookkim/dev/guju-jaengpae
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}" "$GODOT_BIN" --headless --path . -s test/runner.gd test/test_terrain_perk_catalog.gd
SHOT_DIR=/tmp/guju-board-depth ./tools/shoot_ui_bundle.sh
python3 tools/validate_screenshot_bundle.py /tmp/guju-board-depth
```

### Lane F3 — Army Feel And Audio

Owner: designer plus visual executor.

Files:
- `/Users/taewookkim/dev/guju-jaengpae/scripts/battle/battle.gd`
- `/Users/taewookkim/dev/guju-jaengpae/scripts/autoloads/audio_manager.gd`
- `/Users/taewookkim/dev/guju-jaengpae/assets/sfx/*`
- `/Users/taewookkim/dev/guju-jaengpae/tools/shoot_ui_bundle.sh`

Acceptance:
- Battle start has an audible cue in local play.
- First impact has a visible and audible cue.
- Troop shadows visually anchor to the ground.
- General body is not visually larger than the old solo hero scale.

Verification:

```bash
cd /Users/taewookkim/dev/guju-jaengpae
./init.sh
SHOT_DIR=/tmp/guju-army-feel ./tools/shoot_ui_bundle.sh
python3 tools/validate_screenshot_bundle.py /tmp/guju-army-feel
```

### Lane F4 — Nine Faction Canon Expansion

Owner: product planner and canon editor first; executor only after approval.

Files:
- `/Users/taewookkim/dev/guju-jaengpae/docs/worldview.md`
- `/Users/taewookkim/dev/guju-jaengpae/scripts/resources/card_vocab.gd`
- `/Users/taewookkim/dev/guju-jaengpae/resources/lords/*.tres`
- `/Users/taewookkim/dev/guju-jaengpae/resources/cards/*.tres`
- `/Users/taewookkim/dev/guju-jaengpae/test/test_nine_faction_gate.gd`
- `/Users/taewookkim/dev/guju-jaengpae/test/test_lord_select.gd`

Acceptance:
- Approved nine faction ids exist in `docs/worldview.md`.
- `CardVocab.NATIONS` matches approved ids.
- `tools/validate_cards.gd` accepts new resources.
- `lord_select` shows locked and unlocked states for all approved lords.

Verification:

```bash
cd /Users/taewookkim/dev/guju-jaengpae
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}" "$GODOT_BIN" --headless --path . -s test/runner.gd test/test_nine_faction_gate.gd
./init.sh
```

## Self-Review

- **Spec coverage:** The plan covers the user's current blockers: sparse units, vague generals, defense-game feel, too many cards at once, castle-first placement, three-card hand, duplicate upgrades, terrain perks, faction strategy pools, and completion QA.
- **Placeholder scan:** No task uses undefined filler. Each code-changing task includes concrete file paths, code snippets, commands, and expected outputs.
- **Type consistency:** `SquadProfile.for_card`, `FormationRenderer.member_offsets`, `TerrainPerkCatalog.bonus_for`, `StrategyDeckCatalog.deck_for_lord`, and `PlaytestMetrics.summarize_battle` are used with the same signatures throughout.
- **Known gap:** The exact visual judgement still requires a human/vision pass. The plan handles this with screenshot bundles and `docs/reports/feat-040-playtest.md`.
