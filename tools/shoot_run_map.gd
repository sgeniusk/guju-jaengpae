# 런 맵 화면 스크린샷 하네스 — 군주와 스테이지별 UI 상태를 재현해 캡처한다.
# 실행 — LORD=lord_caocao RUN_STAGE=5 SHOT_DIR=/tmp/guju-flow-qa godot --path . res://tools/shoot_run_map.tscn
extends Node

const _VisualQaConfig := preload("res://tools/visual_qa_config.gd")
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

var _catalog: CardCatalog

func _ready() -> void:
	_catalog = CardCatalog.new()
	_catalog.load_all()
	var target_stage := _VisualQaConfig.env_int("RUN_STAGE", 1)
	var lord := _VisualQaConfig.env_lord()
	var output_dir := _VisualQaConfig.env_output_dir()
	DirAccess.make_dir_recursive_absolute(output_dir)
	_prepare_run(lord, target_stage)
	var screen: Node = load("res://scenes/screens/run_map.tscn").instantiate()
	add_child(screen)
	await _frames(30)
	await _shoot(_VisualQaConfig.shot_path("run_map", lord, target_stage, output_dir))
	get_tree().quit()

func _prepare_run(lord: StringName, target_stage: int) -> void:
	RunManager.reset_run()
	RunManager.ensure_started(lord)
	_place_all_hand_front_first()
	while RunManager.stage_index() < target_stage:
		if RunManager.is_edict_stage():
			RunManager.add_edict(&"edict_might")
		elif RunManager.is_shop_stage():
			RunManager.add_gold(60)
			var purchase_id := _pick_combat_card(RunManager.shop_card_ids())
			if purchase_id != &"":
				RunManager.shop_purchase(purchase_id)
		else:
			_take_combat_reward()
		RunManager.advance_stage()
		_place_all_hand_front_first()
	if RunManager.is_shop_stage():
		RunManager.add_gold(60)

func _place_all_hand_front_first() -> void:
	if not RunManager.has_castle():
		RunManager.set_castle_key("1:1")
	for key in RunState.block_keys_for(RunManager.get_board_rows()):
		if RunManager.get_hand().is_empty():
			return
		if key == RunManager.get_castle_key():
			continue
		RunManager.state.place_from_hand(0, key)

func _take_combat_reward() -> void:
	var eligible := RewardPool.eligible(_catalog, RunManager.state.owned_card_ids())
	var picked := _pick_combat_card(eligible)
	if picked != &"":
		RunManager.hand_add(picked)

func _pick_combat_card(ids: Array[StringName]) -> StringName:
	for wanted in COMBAT_PICK_PRIORITY:
		if ids.has(wanted):
			return wanted
	return ids[0] if not ids.is_empty() else &""

func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame

func _shoot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(path)
		print("SHOT ", path, " ", img.get_size())
	else:
		print("SHOT FAIL ", path)
