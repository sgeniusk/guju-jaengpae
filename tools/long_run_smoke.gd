# 최종 보스까지 결정적 선택으로 굴려 장기런이 끊기지 않는지 검증한다.
extends SceneTree

const _EdictCatalog := preload("res://scripts/run/edict_catalog.gd")
const _PlaytestMetrics := preload("res://scripts/run/playtest_metrics.gd")
const _StageCadence := preload("res://scripts/run/stage_cadence.gd")
const _TerrainPerkCatalog := preload("res://scripts/run/terrain_perk_catalog.gd")
const _TreasureCatalog := preload("res://scripts/run/treasure_catalog.gd")

const LORD_ID := &"lord_liubei"
const FINAL_STAGE := _StageCadence.FINAL_BOSS_STAGE
const COMBAT_PICK_PRIORITY := [
	&"troop_archer",
	&"troop_cavalry",
	&"troop_infantry",
	&"general_guanyu",
	&"general_zhangfei",
	&"general_zhaoyun",
	&"general_huangzhong",
]
const SHOP_PICK_PRIORITY := [
	&"troop_archer",
	&"troop_cavalry",
	&"troop_infantry",
	&"general_guanyu",
]
const TREASURE_ATTACK := &"treasure_bingfashu"

func _initialize() -> void:
	var cat := CardCatalog.new()
	cat.load_all()
	var lord := cat.get_lord(LORD_ID)
	if lord == null:
		_fail("군주 로드 실패")
		return
	var run := RunState.new()
	run.start_run(lord, cat)
	if not run.set_castle_key("1:1"):
		_fail("성 위치 선택 실패")
		return
	var combat_wins := 0
	while run.stage_index <= FINAL_STAGE:
		var stage := run.stage_index
		var kind := _StageCadence.node_kind(stage)
		match kind:
			"edict":
				_take_edict(run)
				print("  stage %d node=edict picked=%s edicts=%d" % [stage, String(run.edicts.back()), run.edicts.size()])
				run.advance_stage()
			"shop":
				_take_shop_pick(run, cat)
				print("  stage %d node=shop hand=%d draw=%d gold=%d" % [stage, run.hand.size(), run.draw_pile.size(), run.gold])
				run.advance_stage()
			"event":
				run.add_gold(20)
				print("  stage %d node=event gold=%d" % [stage, run.gold])
				run.advance_stage()
			_:
				if stage > 1:
					run.prepare_deploy_hand()
				_play_best_card(run, cat)
				var sim := _sim_for_run(run, cat, lord, stage)
				var metrics := _PlaytestMetrics.summarize(stage, sim, run.board, run.board_levels_copy(), run.hand.size(), run.draw_pile.size())
				sim.run_to_completion(0.1, 120.0)
				metrics["result"] = sim.result
				metrics["elapsed"] = sim.elapsed
				print("  ", _PlaytestMetrics.compact_line(metrics))
				if sim.result != BattleSim.Result.PLAYER_WIN:
					_fail("stage %d %s 승리 실패" % [stage, kind])
					return
				combat_wins += 1
				if _StageCadence.is_expand(stage):
					run.expand_board()
				if _StageCadence.is_final_boss(stage):
					_pass(combat_wins, run)
					return
				_take_reward_pick(run, cat)
				run.advance_stage()
	_fail("최종 보스 stage %d에 도달하지 못함" % FINAL_STAGE)

func _take_edict(run: RunState) -> void:
	run.add_edict(_EdictCatalog.MIGHT)

func _play_best_card(run: RunState, cat: CardCatalog) -> void:
	if run.hand.is_empty():
		run.draw_to_hand(RunState.HAND_DRAW_COUNT)
	for wanted in COMBAT_PICK_PRIORITY:
		for idx in run.hand.size():
			if run.hand[idx] != wanted:
				continue
			if run.can_upgrade_from_hand(idx) and _board_unit_count(run, cat) >= 4:
				run.upgrade_from_hand(idx)
				run.mark_deploy_card_played()
				return
			if _place_hand_index(run, idx, cat):
				return
	for idx in run.hand.size():
		if run.can_upgrade_from_hand(idx):
			run.upgrade_from_hand(idx)
			run.mark_deploy_card_played()
			return
	for idx in run.hand.size():
		if _place_hand_index(run, idx, cat):
			return
	if not run.hand.is_empty():
		run.consume_from_hand(0)
		run.mark_deploy_card_played()

func _place_hand_index(run: RunState, idx: int, cat: CardCatalog) -> bool:
	if idx < 0 or idx >= run.hand.size():
		return false
	var card := cat.get_card(run.hand[idx])
	if card == null or not (card is UnitCardData):
		return false
	if run.find_board_key_for_card(run.hand[idx]) != "":
		return false
	var key = _preferred_free_block(run, card)
	if key == null:
		return false
	if not run.place_from_hand(idx, String(key)):
		return false
	run.mark_deploy_card_played()
	return true

func _take_reward_pick(run: RunState, cat: CardCatalog) -> void:
	var eligible := RewardPool.eligible(cat, run.owned_card_ids())
	var picked := TREASURE_ATTACK if _should_take_attack_treasure(run, cat, eligible) else _pick_combat_card(eligible, COMBAT_PICK_PRIORITY)
	if picked != &"":
		_acquire_pick(run, cat, picked)

func _take_shop_pick(run: RunState, cat: CardCatalog) -> void:
	run.add_gold(70)
	var picked := _pick_combat_card(cat.purchasable_ids(), SHOP_PICK_PRIORITY)
	if picked != &"":
		run.hand_add(picked)

func _should_take_attack_treasure(run: RunState, cat: CardCatalog, eligible: Array[StringName]) -> bool:
	if not eligible.has(TREASURE_ATTACK):
		return false
	return _board_unit_count(run, cat) >= 3

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

func _preferred_free_block(run: RunState, card: CardData):
	var troop_type := String(card.get("troop_type")) if card is UnitCardData else ""
	var keys := []
	if troop_type == "archer":
		keys = ["1:1", "0:1", "2:1", "1:2", "0:2", "2:2", "1:3", "0:3", "2:3"]
	elif troop_type == "cavalry":
		keys = ["0:0", "2:0", "0:3", "2:3", "0:4", "2:4"]
	else:
		keys = ["1:0", "0:0", "2:0", "1:1", "0:1", "2:1", "1:2", "0:2", "2:2"]
	for key in keys:
		if run.is_block_free(key):
			return key
	return run.first_free_block()

func _sim_for_run(run: RunState, cat: CardCatalog, lord: LordData, stage: int) -> BattleSim:
	var sim := BattleSim.new()
	var castle_col := _TerrainPerkCatalog.col_from_key(run.castle_key)
	var castle_row := _TerrainPerkCatalog.row_from_key(run.castle_key)
	var castle_pos := BattleSim.position_for_tile(castle_col, castle_row)
	sim.add_castle_at(castle_pos.x, castle_pos.y)
	for unit in cat.build_board_army(run.board, lord, run.board_rows, run.edicts, run.castle_key, run.terrain_perk_id, run.board_levels_copy()):
		sim.add_unit(unit)
	_apply_treasures(sim.player_units, run, cat)
	sim.set_waves(WaveFactory.stage_encounter_waves(stage))
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

func _pass(combat_wins: int, run: RunState) -> void:
	print("✅ 장기런 스모크 통과 — wins=%d stage=%d board=%d rows=%d hand=%d draw=%d" % [
		combat_wins,
		run.stage_index,
		run.board.size(),
		run.board_rows,
		run.hand.size(),
		run.draw_pile.size(),
	])
	quit(0)

func _fail(message: String) -> void:
	printerr("❌ 장기런 스모크 실패: %s" % message)
	quit(1)
