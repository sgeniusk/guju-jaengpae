# 로그라이크 런 맵 화면 — 막별 전투 노드를 선택해 전투로 진입한다.
extends Control

const LORD_ID := &"lord_liubei"
const BATTLE_SCENE := "res://scenes/battle/battle.tscn"

var _root: VBoxContainer
var _overlay: Control

func _ready() -> void:
	RunManager.ensure_started(LORD_ID)
	_render()

func _render() -> void:
	for child in get_children():
		child.queue_free()
	_build_background()
	_build_root()
	if RunManager.map_finished():
		_build_conquest()
	else:
		_build_map()

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

func _build_root() -> void:
	_root = VBoxContainer.new()
	_root.position = Vector2(80.0, 56.0)
	_root.size = Vector2(1760.0, 960.0)
	_root.add_theme_constant_override("separation", 24)
	add_child(_root)

	var title := Label.new()
	title.text = "구주쟁패"
	title.add_theme_font_size_override("font_size", 54)
	_root.add_child(title)

	var summary := Label.new()
	summary.text = "현재 막 %d / %d · 덱 %d장 · 지휘력 %d" % [
		min(RunManager.state.map.layer_idx + 1, RunManager.state.map.total_layers()),
		RunManager.state.map.total_layers(),
		RunManager.get_deck().size(),
		RunManager.get_command_points(),
	]
	summary.add_theme_font_size_override("font_size", 24)
	_root.add_child(summary)

func _build_map() -> void:
	var columns := HBoxContainer.new()
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 28)
	_root.add_child(columns)

	for layer_idx in RunManager.state.map.layers.size():
		columns.add_child(_make_layer_column(layer_idx))

func _make_layer_column(layer_idx: int) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(300.0, 0.0)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 14)

	var layer_title := Label.new()
	layer_title.text = "제%d막" % (layer_idx + 1)
	layer_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer_title.add_theme_font_size_override("font_size", 24)
	column.add_child(layer_title)

	var spacer_top := Control.new()
	spacer_top.custom_minimum_size = Vector2(0.0, 80.0 if RunManager.state.map.layers[layer_idx].size() == 1 else 20.0)
	column.add_child(spacer_top)

	var nodes: Array = RunManager.state.map.layers[layer_idx]
	for node_idx in nodes.size():
		column.add_child(_make_node_button(nodes[node_idx], layer_idx, node_idx))

	return column

func _make_node_button(node: Dictionary, layer_idx: int, node_idx: int) -> Button:
	var button := Button.new()
	button.text = "%s\n%s" % [_node_label(int(node["type"])), String(node["id"])]
	button.custom_minimum_size = Vector2(0.0, 92.0)
	button.add_theme_font_size_override("font_size", 22)
	if layer_idx < RunManager.state.map.layer_idx:
		button.text = "%s\n완료" % _node_label(int(node["type"]))
		button.disabled = true
		button.modulate = Color(0.65, 0.75, 0.7)
	elif layer_idx == RunManager.state.map.layer_idx:
		button.disabled = false
		button.pressed.connect(_on_node_pressed.bind(node_idx))
	else:
		button.disabled = true
		button.modulate = Color(0.45, 0.45, 0.5)
	return button

func _build_conquest() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	_root.add_child(box)

	var done := Label.new()
	done.text = "구주 정복!"
	done.add_theme_font_size_override("font_size", 44)
	box.add_child(done)

	var fresh := Button.new()
	fresh.text = "새 런"
	fresh.custom_minimum_size = Vector2(300.0, 56.0)
	fresh.pressed.connect(_on_new_run_pressed)
	box.add_child(fresh)

func _on_node_pressed(node_idx: int) -> void:
	RunManager.choose_node(node_idx)
	var node_type := RunManager.active_node_type()
	if RunMap.is_battle(node_type):
		GameManager.change_scene(BATTLE_SCENE)
	elif node_type == RunMap.NodeType.REWARD:
		_show_reward_overlay()
	elif node_type == RunMap.NodeType.SUPPLY:
		_show_supply_overlay()
	else:
		GameManager.change_scene(BATTLE_SCENE)

func _on_new_run_pressed() -> void:
	RunManager.reset_run()
	RunManager.ensure_started(LORD_ID)
	_render()

func _node_label(node_type: int) -> String:
	return RunManager.node_label(node_type)

func _show_reward_overlay() -> void:
	var box := _new_overlay_box()
	var head := Label.new()
	head.text = "보상 — 한 장을 골라 덱에 넣으세요"
	head.add_theme_font_size_override("font_size", 30)
	box.add_child(head)

	var candidates := RunManager.reward_candidates(3)
	if candidates.is_empty():
		var none := Label.new()
		none.text = "획득 가능한 보상이 없습니다."
		box.add_child(none)
		box.add_child(_make_overlay_button("계속", _complete_non_battle_and_render))
		return
	for id in candidates:
		var card := CardLibrary.get_card(id)
		var label := String(id)
		if card != null:
			label = "%s (%d) — %s" % [card.display_name, card.cost, _card_brief(card)]
		box.add_child(_make_overlay_button(label, _pick_reward.bind(id)))

func _show_supply_overlay() -> void:
	var box := _new_overlay_box()
	var head := Label.new()
	head.text = "보급 — 이 런의 지휘력 +3"
	head.add_theme_font_size_override("font_size", 30)
	box.add_child(head)

	var now := Label.new()
	now.text = "현재 지휘력 %d → %d" % [RunManager.get_command_points(), RunManager.get_command_points() + 3]
	now.add_theme_font_size_override("font_size", 22)
	box.add_child(now)
	box.add_child(_make_overlay_button("보급 받기", _take_supply))

func _pick_reward(id: StringName) -> void:
	RunManager.add_card(id)
	EventBus.card_rewarded.emit(id)
	_complete_non_battle_and_render()

func _take_supply() -> void:
	RunManager.add_command_points(3)
	_complete_non_battle_and_render()

func _complete_non_battle_and_render() -> void:
	RunManager.complete_node()
	_render()

func _new_overlay_box() -> VBoxContainer:
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.queue_free()
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.72)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	_overlay = shade

	var box := VBoxContainer.new()
	box.position = Vector2(520.0, 220.0)
	box.custom_minimum_size = Vector2(880.0, 0.0)
	box.add_theme_constant_override("separation", 14)
	shade.add_child(box)
	return box

func _make_overlay_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0.0, 52.0)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(cb)
	return b

func _card_brief(card: CardData) -> String:
	if card is UnitCardData:
		return "%s/%s" % [card.troop_type, card.attack_range]
	return card.card_type
