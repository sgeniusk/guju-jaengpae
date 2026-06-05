# 최종 보스까지 결정적 선택으로 굴려 장기런이 끊기지 않는지 검증한다.
extends SceneTree

const _EdictCatalog := preload("res://scripts/run/edict_catalog.gd")
const _BoardEconomy := preload("res://scripts/run/board_economy.gd")
const _PlaytestMetrics := preload("res://scripts/run/playtest_metrics.gd")
const _SchemeCatalog := preload("res://scripts/run/scheme_catalog.gd")
const _StageCadence := preload("res://scripts/run/stage_cadence.gd")
const _TerrainPerkCatalog := preload("res://scripts/run/terrain_perk_catalog.gd")
const _TreasureCatalog := preload("res://scripts/run/treasure_catalog.gd")

const FINAL_STAGE := _StageCadence.FINAL_BOSS_STAGE
const LORD_IDS := [&"lord_liubei", &"lord_caocao", &"lord_sunquan"]
const COMBAT_PICK_PRIORITY_BY_LORD := {
	&"lord_liubei": [
		&"troop_archer",
		&"troop_cavalry",
		&"troop_infantry",
		&"general_guanyu",
		&"general_zhangfei",
		&"general_zhaoyun",
		&"general_huangzhong",
	],
	&"lord_caocao": [
		&"general_caocao",
		&"general_xiahoudun",
		&"troop_crossbow",
		&"troop_cavalry",
		&"troop_infantry",
		&"building_mangru",
		&"scheme_raid",
		&"scheme_fortify",
		&"building_dunjeon",
	],
	&"lord_sunquan": [
		&"general_sunquan",
		&"general_zhouyu",
		&"troop_navy",
		&"troop_archer",
		&"troop_crossbow",
		&"building_mangru",
		&"scheme_fortify",
	],
}
const SHOP_PICK_PRIORITY_BY_LORD := {
	&"lord_liubei": [
		&"troop_archer",
		&"troop_cavalry",
		&"troop_infantry",
		&"general_guanyu",
	],
	&"lord_caocao": [
		&"general_caocao",
		&"general_xiahoudun",
		&"troop_crossbow",
		&"troop_cavalry",
		&"troop_infantry",
		&"building_mangru",
	],
	&"lord_sunquan": [
		&"general_sunquan",
		&"general_zhouyu",
		&"troop_navy",
		&"troop_archer",
		&"troop_crossbow",
		&"building_mangru",
	],
}
const TREASURE_ATTACK := &"treasure_bingfashu"

func _initialize() -> void:
	var cat := CardCatalog.new()
	cat.load_all()
	var summaries: Array[String] = []
	for lord_id in LORD_IDS:
		var summary := _run_lord(cat, lord_id)
		if summary.is_empty():
			return
		summaries.append(summary)
	print("✅ 3군주 장기런 스모크 통과 — %s" % " / ".join(summaries))
	quit(0)

func _run_lord(cat: CardCatalog, lord_id: StringName) -> String:
	var lord := cat.get_lord(lord_id)
	if lord == null:
		_fail("%s 군주 로드 실패" % lord_id)
		return ""
	var run := RunState.new()
	run.start_run(lord, cat)
	if not run.set_castle_key("1:1"):
		_fail("%s 성 위치 선택 실패" % lord_id)
		return ""
	var combat_wins := 0
	print("  %s 장기런 시작" % _lord_label(lord))
	while run.stage_index <= FINAL_STAGE:
		var stage := run.stage_index
		var kind := _StageCadence.node_kind(stage)
		match kind:
			"edict":
				_take_edict(run)
				print("    stage %d node=edict picked=%s edicts=%d" % [stage, String(run.edicts.back()), run.edicts.size()])
				run.advance_stage()
			"shop":
				_take_shop_pick(run, cat, lord_id)
				print("    stage %d node=shop hand=%d draw=%d gold=%d" % [stage, run.hand.size(), run.draw_pile.size(), run.gold])
				run.advance_stage()
			"event":
				run.add_gold(20)
				print("    stage %d node=event gold=%d" % [stage, run.gold])
				run.advance_stage()
			_:
				if stage > 1:
					run.prepare_deploy_hand()
				var play := _play_best_card(run, cat, lord_id)
				var sim := _sim_for_run(run, cat, lord, stage, play.get("battle_effects", []))
				var metrics := _PlaytestMetrics.summarize(stage, sim, run.board, run.board_levels_copy(), run.hand.size(), run.draw_pile.size())
				sim.run_to_completion(0.1, 120.0)
				metrics["result"] = sim.result
				metrics["elapsed"] = sim.elapsed
				print("    %s play=%s board=[%s]" % [
					_PlaytestMetrics.compact_line(metrics),
					_play_label(play, cat),
					_board_summary(run, cat),
				])
				if sim.result != BattleSim.Result.PLAYER_WIN:
					_fail("%s stage %d %s 승리 실패 — %s" % [_lord_label(lord), stage, kind, _sim_summary(sim)])
					return ""
				combat_wins += 1
				if _StageCadence.is_expand(stage):
					run.expand_board()
				if _StageCadence.is_final_boss(stage):
					return "%s wins=%d board=%d rows=%d hand=%d draw=%d" % [
						_lord_label(lord),
						combat_wins,
						run.board.size(),
						run.board_rows,
						run.hand.size(),
						run.draw_pile.size(),
					]
				_take_reward_pick(run, cat, lord_id)
				run.advance_stage()
	_fail("%s 최종 보스 stage %d에 도달하지 못함" % [_lord_label(lord), FINAL_STAGE])
	return ""

func _take_edict(run: RunState) -> void:
	run.add_edict(_EdictCatalog.MIGHT)

func _play_best_card(run: RunState, cat: CardCatalog, lord_id: StringName) -> Dictionary:
	if run.hand.is_empty():
		run.draw_to_hand(RunState.HAND_DRAW_COUNT)
	for wanted in _combat_priority(lord_id):
		for idx in run.hand.size():
			if run.hand[idx] != wanted:
				continue
			if _can_upgrade_unit_from_hand(run, cat, idx) and _board_unit_count(run, cat) >= 4:
				run.upgrade_from_hand(idx)
				run.mark_deploy_card_played()
				return _play_result(wanted, "upgrade")
			var card := cat.get_card(run.hand[idx])
			if card is SchemeCardData:
				return _cast_scheme_from_hand(run, card, idx, lord_id)
			if _place_hand_index(run, idx, cat, lord_id):
				return _play_result(wanted, "place")
	for idx in run.hand.size():
		if _can_upgrade_unit_from_hand(run, cat, idx):
			var card_id := run.hand[idx]
			run.upgrade_from_hand(idx)
			run.mark_deploy_card_played()
			return _play_result(card_id, "upgrade")
	for idx in run.hand.size():
		var card_id := run.hand[idx]
		if _place_hand_index(run, idx, cat, lord_id):
			return _play_result(card_id, "place")
	for idx in run.hand.size():
		var card := cat.get_card(run.hand[idx])
		if card is SchemeCardData:
			return _cast_scheme_from_hand(run, card, idx, lord_id)
	if not run.hand.is_empty():
		var discarded := run.hand[0]
		run.consume_from_hand(0)
		run.mark_deploy_card_played()
		return _play_result(discarded, "discard")
	return _play_result(&"", "none")

func _place_hand_index(run: RunState, idx: int, cat: CardCatalog, lord_id: StringName) -> bool:
	if idx < 0 or idx >= run.hand.size():
		return false
	var card := cat.get_card(run.hand[idx])
	if card == null:
		return false
	var card_type := String(card.get("card_type"))
	if not (card is UnitCardData or card_type == "building"):
		return false
	if card is UnitCardData and run.find_board_key_for_card(run.hand[idx]) != "":
		return false
	var key = _preferred_free_block(run, card, lord_id)
	if key == null:
		return false
	if not run.place_from_hand(idx, String(key)):
		return false
	run.mark_deploy_card_played()
	return true

func _take_reward_pick(run: RunState, cat: CardCatalog, lord_id: StringName) -> void:
	var eligible := RewardPool.eligible(cat, run.owned_card_ids())
	var picked := TREASURE_ATTACK if _should_take_attack_treasure(run, cat, eligible, lord_id) else _pick_combat_card(eligible, _combat_priority(lord_id))
	if picked != &"":
		_acquire_pick(run, cat, picked)

func _take_shop_pick(run: RunState, cat: CardCatalog, lord_id: StringName) -> void:
	run.add_gold(70)
	var picked := _pick_combat_card(cat.purchasable_ids(), _shop_priority(lord_id))
	if picked != &"":
		run.hand_add(picked)

func _can_upgrade_unit_from_hand(run: RunState, cat: CardCatalog, hand_index: int) -> bool:
	if not run.can_upgrade_from_hand(hand_index):
		return false
	return cat.get_card(run.hand[hand_index]) is UnitCardData

func _cast_scheme_from_hand(run: RunState, card: SchemeCardData, hand_index: int, lord_id: StringName) -> Dictionary:
	var resolved := _SchemeCatalog.resolve(card, {
		"lord_id": String(lord_id),
		"stage": run.stage_index,
	})
	if not bool(resolved.get("ok", false)):
		return _play_result(card.id, "scheme_failed")
	var consumed := run.consume_from_hand(hand_index)
	if consumed == &"":
		return _play_result(card.id, "scheme_failed")
	run.mark_deploy_card_played()
	_apply_scheme_run_result(run, resolved.get("run", {}))
	var effects: Array[Dictionary] = []
	var battle: Dictionary = resolved.get("battle", {})
	if not battle.is_empty():
		effects.append(battle.duplicate(true))
	return _play_result(consumed, "scheme", effects)

func _apply_scheme_run_result(run: RunState, run_result: Dictionary) -> void:
	if run_result.is_empty():
		return
	var gold_delta := maxi(0, int(run_result.get("gold_delta", 0)))
	if gold_delta > 0:
		run.add_gold(gold_delta)

func _should_take_attack_treasure(run: RunState, cat: CardCatalog, eligible: Array[StringName], lord_id: StringName) -> bool:
	if not eligible.has(TREASURE_ATTACK):
		return false
	var board_units := _board_unit_count(run, cat)
	if lord_id == &"lord_liubei":
		return board_units >= 2
	var attack_treasures := _treasure_count(run, TREASURE_ATTACK)
	return board_units >= 2 if attack_treasures <= 0 else board_units >= 3

func _acquire_pick(run: RunState, cat: CardCatalog, picked: StringName) -> void:
	var card := cat.get_card(picked)
	if card is TreasureCardData:
		run.add_treasure(picked)
	else:
		run.hand_add(picked)

func _pick_combat_card(ids: Array[StringName], priority: Array) -> StringName:
	for wanted in priority:
		if ids.has(wanted):
			return wanted
	return ids[0] if not ids.is_empty() else &""

func _combat_priority(lord_id: StringName) -> Array:
	return (COMBAT_PICK_PRIORITY_BY_LORD.get(lord_id, []) as Array).duplicate()

func _shop_priority(lord_id: StringName) -> Array:
	return (SHOP_PICK_PRIORITY_BY_LORD.get(lord_id, []) as Array).duplicate()

func _preferred_free_block(run: RunState, card: CardData, lord_id: StringName):
	if String(card.get("card_type")) == "building":
		return _preferred_building_block(run, card)
	var troop_type := String(card.get("troop_type")) if card is UnitCardData else ""
	var keys := []
	if lord_id == &"lord_caocao":
		keys = ["0:1", "2:1", "1:0", "0:0", "2:0", "0:2", "2:2", "1:2", "0:3", "2:3"]
	elif lord_id == &"lord_sunquan":
		keys = ["0:0", "2:0", "0:1", "2:1", "0:2", "2:2", "0:3", "2:3", "1:0", "1:2"]
	elif troop_type == "archer":
		keys = ["1:1", "0:1", "2:1", "1:2", "0:2", "2:2", "1:3", "0:3", "2:3"]
	elif troop_type == "cavalry":
		keys = ["0:0", "2:0", "0:3", "2:3", "0:4", "2:4"]
	else:
		keys = ["1:0", "0:0", "2:0", "1:1", "0:1", "2:1", "1:2", "0:2", "2:2"]
	for key in keys:
		if run.is_block_free(key):
			return key
	return run.first_free_block()

func _preferred_building_block(run: RunState, card: CardData):
	if float(card.get("aura_attack_pct")) > 0.0:
		var best_key = null
		var best_score := -1
		var radius := maxi(0, int(card.get("aura_radius")))
		for key in run.block_keys():
			if not run.is_block_free(key):
				continue
			var col := _TerrainPerkCatalog.col_from_key(key)
			var row := _TerrainPerkCatalog.row_from_key(key)
			var score := _aura_score_for_block(run, col, row, radius)
			if score > best_score:
				best_score = score
				best_key = key
		if best_key != null and best_score > 0:
			return best_key
	for key in ["1:2", "0:2", "2:2", "0:0", "2:0", "1:0", "0:3", "2:3"]:
		if run.is_block_free(key):
			return key
	return run.first_free_block()

func _aura_score_for_block(run: RunState, col: int, row: int, radius: int) -> int:
	var score := 0
	for key in run.board.keys():
		var other_col := _TerrainPerkCatalog.col_from_key(String(key))
		var other_row := _TerrainPerkCatalog.row_from_key(String(key))
		if maxi(absi(other_col - col), absi(other_row - row)) > radius:
			continue
		var id := String(run.board[key])
		if id.begins_with("general_"):
			score += 3
		elif id == "troop_archer" or id == "troop_crossbow" or id == "troop_navy":
			score += 3
		elif id.begins_with("troop_"):
			score += 2
	return score

func _sim_for_run(run: RunState, cat: CardCatalog, lord: LordData, stage: int, battle_effects: Array = []) -> BattleSim:
	var sim := BattleSim.new()
	var castle_col := _TerrainPerkCatalog.col_from_key(run.castle_key)
	var castle_row := _TerrainPerkCatalog.row_from_key(run.castle_key)
	var castle_pos := BattleSim.position_for_tile(castle_col, castle_row)
	sim.add_castle_at(castle_pos.x, castle_pos.y)
	for unit in cat.build_board_army(run.board, lord, run.board_rows, run.edicts, run.castle_key, run.terrain_perk_id, run.board_levels_copy()):
		sim.add_unit(unit)
	sim.set_waves(WaveFactory.stage_encounter_waves(stage))
	for effect in battle_effects:
		sim.apply_battle_effect(effect)
	_BoardEconomy.apply_auras(sim.player_units, run.board, cat)
	_apply_treasures(sim.player_units, run, cat)
	return sim

func _apply_treasures(units: Array, run: RunState, cat: CardCatalog) -> void:
	var modifiers := _TreasureCatalog.modifiers(run.treasure_ids(), cat)
	var battle: Dictionary = modifiers.get("battle", {})
	var attack_pct := float(battle.get("attack_pct", 0.0))
	if attack_pct <= 0.0:
		return
	for unit in units:
		if unit == null or not (unit is BattleUnit) or unit.is_castle:
			continue
		unit.attack = maxi(0, int(round(unit.attack * (1.0 + attack_pct))))

func _board_unit_count(run: RunState, cat: CardCatalog) -> int:
	var count := 0
	for key in run.block_keys():
		if not run.board.has(key):
			continue
		var card := cat.get_card(StringName(run.board[key]))
		if card is UnitCardData:
			count += 1
	return count

func _board_summary(run: RunState, cat: CardCatalog) -> String:
	var parts: Array[String] = []
	for key in run.block_keys():
		if not run.board.has(key):
			continue
		var card := cat.get_card(StringName(run.board[key]))
		var name := card.display_name if card != null else String(run.board[key])
		parts.append("%s=%s Lv.%d" % [key, name, run.board_level(key)])
	return ", ".join(parts)

func _treasure_count(run: RunState, treasure_id: StringName) -> int:
	var count := 0
	for id in run.treasure_ids():
		if id == treasure_id:
			count += 1
	return count

func _play_result(card_id: StringName, action: String, battle_effects: Array[Dictionary] = []) -> Dictionary:
	return {
		"card_id": card_id,
		"action": action,
		"battle_effects": battle_effects,
	}

func _play_label(play: Dictionary, cat: CardCatalog) -> String:
	var card_id := StringName(play.get("card_id", &""))
	var action := String(play.get("action", "none"))
	if card_id == &"":
		return action
	var card := cat.get_card(card_id)
	var name := card.display_name if card != null else String(card_id)
	return "%s:%s" % [action, name]

func _sim_summary(sim: BattleSim) -> String:
	var castle_hp := 0
	var alive_players: Array[String] = []
	var alive_enemies: Array[String] = []
	for unit in sim.player_units:
		if unit == null:
			continue
		if unit.is_castle:
			castle_hp = unit.hp
		elif unit.is_alive():
			alive_players.append("%s:%d" % [unit.display_name, unit.hp])
	for unit in sim.enemy_units:
		if unit != null and unit.is_alive():
			alive_enemies.append("%s:%d" % [unit.display_name, unit.hp])
	return "castle=%d players=[%s] enemies=[%s]" % [
		castle_hp,
		",".join(alive_players),
		",".join(alive_enemies),
	]

func _lord_label(lord: LordData) -> String:
	return lord.display_name if lord != null else "?"

func _fail(message: String) -> void:
	printerr("❌ 장기런 스모크 실패: %s" % message)
	quit(1)
