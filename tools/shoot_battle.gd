# 전투 화면 스크린샷 하네스 — 런을 세팅하고 battle.tscn을 띄워 배치·교전 장면을 캡처한다. 시각 QA 전용(게임 로직 아님).
# 실행 — LORD=lord_caocao SHOOT_STAGE=5 SHOT_DIR=/tmp/guju-visual-qa godot --path . --scene res://tools/shoot_battle.tscn
extends Node

const _VisualQaConfig := preload("res://tools/visual_qa_config.gd")
const BATTLE_PHASE_BATTLE := 1

func _ready() -> void:
	var target_stage := _VisualQaConfig.env_int("SHOOT_STAGE", _VisualQaConfig.DEFAULT_BATTLE_STAGE)
	var fight_frames := _VisualQaConfig.env_int("SHOOT_FIGHT_FRAMES", 560)
	var forced_result := OS.get_environment("SHOOT_FORCE_RESULT").strip_edges().to_lower()
	var lord := _VisualQaConfig.env_lord()
	var output_dir := _VisualQaConfig.env_output_dir()
	DirAccess.make_dir_recursive_absolute(output_dir)
	_prepare_target_stage(lord, target_stage)
	_prepare_demo_board(target_stage)
	var battle = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle)
	await _frames(25)
	await _shoot(_VisualQaConfig.shot_path("battle_deploy", lord, target_stage, output_dir))
	if forced_result == "win" or forced_result == "loss":
		battle._sim.result = BattleSim.Result.PLAYER_WIN if forced_result == "win" else BattleSim.Result.PLAYER_LOSE
		battle._end_battle()
		await _frames(10)
		await _shoot(_VisualQaConfig.shot_path("battle_result_%s" % forced_result, lord, target_stage, output_dir))
		get_tree().quit()
		return
	if battle.has_method("_on_start_pressed"):
		battle._on_start_pressed()
	await _frames(4)
	if _strict_shots() and int(battle._phase) != BATTLE_PHASE_BATTLE:
		print("SHOT FAIL battle_fight_not_started phase=", int(battle._phase), " deploy_cards_played=", RunManager.state.deploy_cards_played, " board_units=", _board_unit_count())
		get_tree().quit(1)
		return
	print("SHOT META battle_phase=", int(battle._phase), " deploy_cards_played=", RunManager.state.deploy_cards_played, " board_units=", _board_unit_count())
	await _frames(fight_frames)
	await _shoot(_VisualQaConfig.shot_path("battle_fight", lord, target_stage, output_dir))
	get_tree().quit()

func _prepare_target_stage(lord: StringName, target_stage: int) -> void:
	RunManager.ensure_started(lord)
	var guard := 0
	while RunManager.stage_index() < target_stage and guard < 50:
		RunManager.advance_stage()
		guard += 1

func _prepare_demo_board(target_stage: int) -> void:
	# QA 시연용 — 건물 카드(둔전·망루)를 손패에 추가해 기지에 보이게 한다.
	RunManager.hand_add(&"building_dunjeon")
	RunManager.hand_add(&"building_mangru")
	if not RunManager.has_castle():
		RunManager.set_castle_key("1:1")
	var blocks := ["0:0", "1:0", "2:0", "0:1", "1:1", "2:1", "0:2", "1:2", "2:2"]
	for key in blocks:
		if RunManager.get_hand().is_empty():
			break
		if key == RunManager.get_castle_key():
			continue
		var hand_index := _first_placeable_demo_hand_index()
		if hand_index < 0:
			break
		RunManager.state.place_from_hand(hand_index, key)
	_ensure_demo_unit()
	RunManager.state.deploy_cards_played = 1
	RunManager.state.deploy_stage_index = target_stage

func _first_placeable_demo_hand_index() -> int:
	var hand := RunManager.get_hand()
	for index in hand.size():
		if _is_placeable_demo_card(hand[index]):
			return index
	return -1

func _is_placeable_demo_card(card_id: StringName) -> bool:
	var card := CardLibrary.get_card(card_id)
	if card == null:
		return false
	return card is UnitCardData or String(card.get("card_type")) == "building"

func _ensure_demo_unit() -> void:
	if _board_unit_count() > 0:
		return
	var free_block = RunManager.state.first_free_block()
	if free_block == null:
		return
	RunManager.hand_add(&"troop_infantry")
	RunManager.state.place_from_hand(RunManager.state.hand.size() - 1, String(free_block))

func _board_unit_count() -> int:
	var count := 0
	for card_id in RunManager.get_board().values():
		var card := CardLibrary.get_card(StringName(card_id))
		if card is UnitCardData:
			count += 1
	return count

func _strict_shots() -> bool:
	if not OS.has_environment("SHOT_STRICT"):
		return false
	var value := OS.get_environment("SHOT_STRICT").strip_edges().to_lower()
	return value in ["1", "true", "yes", "y", "on"]

func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame

func _shoot(path: String) -> void:
	await _VisualQaConfig.capture_viewport_png(get_viewport(), get_tree(), path)
