# 첫 5스테이지를 결정적 선택으로 굴려 MVP 템포와 밀도를 요약한다.
extends SceneTree

const _PlaytestMetrics := preload("res://scripts/run/playtest_metrics.gd")
const _TerrainPerkCatalog := preload("res://scripts/run/terrain_perk_catalog.gd")
const _StageCadence := preload("res://scripts/run/stage_cadence.gd")
const COMBAT_PICK_PRIORITY := [
	&"troop_archer",
	&"troop_infantry",
	&"general_zhangfei",
	&"general_zhaoyun",
	&"general_huangzhong",
	&"building_mangru",
]

func _initialize() -> void:
	var cat := CardCatalog.new()
	cat.load_all()
	var lord := cat.get_lord(&"lord_liubei")
	var run := RunState.new()
	run.start_run(lord, cat)
	if not run.set_castle_key("1:1"):
		_fail("성 위치 선택 실패")
		return
	var metrics_list: Array = []
	while run.stage_index <= 5:
		var stage := run.stage_index
		if _StageCadence.is_edict(stage):
			run.add_edict(&"edict_might")
			print("  stage %d node=edict picked=edict_might hand=%d draw=%d" % [stage, run.hand.size(), run.draw_pile.size()])
			run.advance_stage()
			continue
		if _StageCadence.is_shop(stage):
			_take_shop_pick(run)
			print("  stage %d node=shop hand=%d draw=%d gold=%d" % [stage, run.hand.size(), run.draw_pile.size(), run.gold])
			run.advance_stage()
			continue
		if stage > 1:
			run.prepare_deploy_hand()
		_play_best_card(run, cat)
		var sim := _sim_for_run(run, cat, lord, stage)
		var metrics := _PlaytestMetrics.summarize(stage, sim, run.board, run.board_levels_copy(), run.hand.size(), run.draw_pile.size())
		sim.run_to_completion(0.1, 35.0)
		metrics["result"] = sim.result
		metrics["elapsed"] = sim.elapsed
		metrics_list.append(metrics)
		print("  ", _PlaytestMetrics.compact_line(metrics))
		if sim.result != BattleSim.Result.PLAYER_WIN:
			_fail("stage %d 승리 실패" % stage)
			return
		_take_reward_pick(run, cat)
		run.advance_stage()
	if not _PlaytestMetrics.first_five_ok(metrics_list):
		_fail("첫 5스테이지 메트릭 계약 실패")
		return
	print("✅ 플레이테스트 루프 스모크 통과")
	quit(0)

func _play_best_card(run: RunState, cat: CardCatalog) -> void:
	if run.hand.is_empty():
		run.draw_to_hand(RunState.HAND_DRAW_COUNT)
	for idx in run.hand.size():
		var card := cat.get_card(run.hand[idx])
		if card is UnitCardData and String(card.get("card_type")) == "troop" and run.find_board_key_for_card(run.hand[idx]) == "":
			var key = _preferred_free_block(run)
			if key != null and run.place_from_hand(idx, String(key)):
				run.mark_deploy_card_played()
				return
	for idx in run.hand.size():
		if run.can_upgrade_from_hand(idx):
			run.upgrade_from_hand(idx)
			run.mark_deploy_card_played()
			return
	for idx in run.hand.size():
		var card := cat.get_card(run.hand[idx])
		if card is UnitCardData:
			var key = _preferred_free_block(run)
			if key != null and run.place_from_hand(idx, String(key)):
				run.mark_deploy_card_played()
				return
	for idx in run.hand.size():
		var card := cat.get_card(run.hand[idx])
		if card != null and String(card.get("card_type")) == "building":
			var key = _preferred_free_block(run)
			if key != null and run.place_from_hand(idx, String(key)):
				run.mark_deploy_card_played()
				return
	if not run.hand.is_empty():
		run.consume_from_hand(0)
		run.mark_deploy_card_played()

func _take_reward_pick(run: RunState, cat: CardCatalog) -> void:
	var eligible := RewardPool.eligible(cat, run.owned_card_ids())
	var picked := _pick_combat_card(eligible)
	if picked != &"":
		run.hand_add(picked)

func _take_shop_pick(run: RunState) -> void:
	run.add_gold(60)
	for picked in COMBAT_PICK_PRIORITY:
		run.hand_add(picked)
		return

func _pick_combat_card(ids: Array[StringName]) -> StringName:
	for wanted in COMBAT_PICK_PRIORITY:
		if ids.has(wanted):
			return wanted
	return ids[0] if not ids.is_empty() else &""

func _preferred_free_block(run: RunState):
	for key in ["1:0", "0:0", "2:0", "1:2", "0:1", "2:1"]:
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
	sim.set_waves(WaveFactory.stage_encounter_waves(stage))
	return sim

func _fail(message: String) -> void:
	printerr("❌ 플레이테스트 루프 스모크 실패: %s" % message)
	quit(1)
