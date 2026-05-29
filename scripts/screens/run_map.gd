# 로그라이크 런 맵 화면 — 막별 전투 노드를 선택해 전투로 진입한다.
extends Control

const LORD_ID := &"lord_liubei"
const BATTLE_SCENE := "res://scenes/battle/battle.tscn"

var _root: VBoxContainer

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
	summary.text = "현재 막 %d / %d · 덱 %d장" % [
		min(RunManager.state.map.layer_idx + 1, RunManager.state.map.total_layers()),
		RunManager.state.map.total_layers(),
		RunManager.get_deck().size(),
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
	GameManager.change_scene(BATTLE_SCENE)

func _on_new_run_pressed() -> void:
	RunManager.reset_run()
	RunManager.ensure_started(LORD_ID)
	_render()

func _node_label(node_type: int) -> String:
	match node_type:
		RunMap.NodeType.BATTLE:
			return "전투"
		RunMap.NodeType.ELITE:
			return "정예"
		RunMap.NodeType.BOSS:
			return "보스"
		_:
			return "전투"
