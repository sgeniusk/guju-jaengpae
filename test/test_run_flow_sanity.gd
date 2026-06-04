# 위·촉·오 군주가 첫 보스까지 런 흐름을 막힘 없이 통과하는지 검증한다.
extends TestCase

const COMBAT_PICK_PRIORITY := [
	&"general_guanyu",
	&"general_sunquan",
	&"general_zhangfei",
	&"general_caocao",
	&"general_zhouyu",
	&"general_zhaoyun",
	&"general_huangzhong",
	&"troop_crossbow",
	&"troop_navy",
	&"troop_cavalry",
	&"troop_archer",
	&"troop_infantry",
]

var cat: CardCatalog

func before_each() -> void:
	cat = CardCatalog.new()
	cat.load_all()
	RunManager.reset_run()

func test_three_lords_reach_and_clear_first_boss_flow() -> void:
	for lord_id in [&"lord_liubei", &"lord_caocao", &"lord_sunquan"]:
		RunManager.reset_run()
		RunManager.ensure_started(lord_id)
		eq(RunManager.stage_index(), 1, "%s stage 1 시작" % lord_id)
		_place_all_hand()
		var battle := _battle_current_stage(lord_id)
		truthy(battle["won"], "%s stage 1 전투 승리 — %s" % [lord_id, battle["summary"]])
		_take_first_reward_and_advance(lord_id, "stage 1")

		eq(RunManager.stage_index(), 2, "%s stage 2 도달" % lord_id)
		_place_all_hand()
		battle = _battle_current_stage(lord_id)
		truthy(battle["won"], "%s stage 2 전투 승리 — %s" % [lord_id, battle["summary"]])
		_take_first_reward_and_advance(lord_id, "stage 2")

		eq(RunManager.stage_index(), 3, "%s stage 3 도달" % lord_id)
		truthy(RunManager.is_edict_stage(), "%s stage 3 왕의 칙령" % lord_id)
		truthy(RunManager.add_edict(&"edict_might"), "%s 칙령 선택" % lord_id)
		eq(RunManager.get_edicts(), [&"edict_might"], "%s 칙령 누적" % lord_id)
		RunManager.advance_stage()

		eq(RunManager.stage_index(), 4, "%s stage 4 도달" % lord_id)
		truthy(RunManager.is_shop_stage(), "%s stage 4 상점" % lord_id)
		RunManager.add_gold(60)
		var purchase_id := _pick_combat_card(RunManager.shop_card_ids())
		truthy(RunManager.shop_purchase(purchase_id), "%s 상점 구매" % lord_id)
		RunManager.advance_stage()

		eq(RunManager.stage_index(), 5, "%s stage 5 도달" % lord_id)
		truthy(RunManager.is_boss_stage(), "%s stage 5 보스" % lord_id)
		_place_all_hand()
		battle = _battle_current_stage(lord_id)
		truthy(battle["won"], "%s stage 5 보스 승리 — %s" % [lord_id, battle["summary"]])
		truthy(RunManager.expand_board(), "%s 보스 보상으로 보드 확장" % lord_id)
		_take_first_reward_and_advance(lord_id, "stage 5")

		eq(RunManager.stage_index(), 6, "%s 첫 보스 이후 stage 6" % lord_id)
		truthy(RunManager.get_board_rows() >= 4, "%s 보드 4행 이상" % lord_id)

func _place_all_hand() -> void:
	for key in _preferred_block_keys():
		if RunManager.get_hand().is_empty():
			return
		RunManager.place_from_hand(0, key)

func _preferred_block_keys() -> Array[String]:
	var keys: Array[String] = []
	var rows := RunManager.get_board_rows()
	for row in [0, 1, 2]:
		if row < rows:
			for col in RunState.BOARD_COLS:
				keys.append("%d:%d" % [col, row])
	for row in range(3, rows):
		for col in RunState.BOARD_COLS:
			keys.append("%d:%d" % [col, row])
	return keys

func _battle_current_stage(lord_id: StringName) -> Dictionary:
	var lord := cat.get_lord(lord_id)
	var army := cat.build_board_army(RunManager.get_board(), lord, RunManager.get_board_rows(), RunManager.get_edicts())
	if army.is_empty():
		return {"won": false, "summary": "army empty"}
	var sim := BattleSim.new()
	var castle := sim.add_castle()
	for unit in army:
		sim.add_unit(unit)
	sim.set_waves(RunManager.current_waves())
	var result := sim.run_to_completion(0.1, 180.0)
	var won := result == BattleSim.Result.PLAYER_WIN and castle.is_alive()
	return {
		"won": won,
		"summary": "result=%d elapsed=%.1f castle_hp=%d players=%d enemies=%d wave=%d/%d player_hp=[%s] enemy_hp=[%s]" % [
			result,
			sim.elapsed,
			castle.hp,
			sim.player_units.size(),
			sim.enemy_units.size(),
			sim.wave_index,
			sim.wave_total,
			_unit_hp_summary(sim.player_units),
			_unit_hp_summary(sim.enemy_units),
		],
	}

func _unit_hp_summary(units: Array) -> String:
	var parts: Array[String] = []
	for unit: BattleUnit in units:
		if unit == null or not unit.is_alive() or unit.is_castle:
			continue
		parts.append("%s:%d" % [unit.display_name, unit.hp])
	return ",".join(parts)

func _take_first_reward_and_advance(lord_id: StringName, label: String) -> void:
	var candidates := RunManager.reward_candidates(3)
	truthy(not candidates.is_empty(), "%s %s 보상 후보" % [lord_id, label])
	var eligible := RewardPool.eligible_for_profile(cat, RunManager.state.owned_card_ids(), RunManager.get_profile())
	var picked := _pick_combat_card(eligible)
	if picked == &"" and not candidates.is_empty():
		picked = candidates[0]
	if picked != &"":
		RunManager.hand_add(picked)
	RunManager.advance_stage()

func _pick_combat_card(ids: Array[StringName]) -> StringName:
	for wanted in COMBAT_PICK_PRIORITY:
		if ids.has(wanted):
			return wanted
	return ids[0] if not ids.is_empty() else &""
