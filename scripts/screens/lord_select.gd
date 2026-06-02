# 군주 선택 화면 — 촉·위·오 군주 중 하나를 골라 런을 시작한다.
extends Control

const RUN_MAP_SCENE := "res://scenes/screens/run_map.tscn"
const LORD_IDS: Array[StringName] = [&"lord_liubei", &"lord_caocao", &"lord_sunquan"]

# 진영 식별자 → 한국어 표기.
const NATION_LABELS := {
	&"shu": "촉(蜀)",
	&"wei": "위(魏)",
	&"wu": "오(吳)",
}

var _root: VBoxContainer

func _ready() -> void:
	_render()

func _render() -> void:
	for child in get_children():
		child.queue_free()
	_build_background()
	_build_root()
	_build_lord_panels()

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
	title.text = "군주를 선택하라"
	title.add_theme_font_size_override("font_size", 54)
	_root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "三界의 九州 — 패권을 다툴 진영을 고른다."
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.modulate = Color(0.78, 0.82, 0.78)
	_root.add_child(subtitle)

func _build_lord_panels() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	_root.add_child(row)

	for lord_id in LORD_IDS:
		var lord := CardLibrary.get_lord(lord_id)
		if lord == null:
			continue
		row.add_child(_build_lord_button(lord))

func _build_lord_button(lord: LordData) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(360.0, 320.0)
	btn.pressed.connect(_on_lord_pressed.bind(lord.id))

	var info_box := VBoxContainer.new()
	info_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	info_box.add_theme_constant_override("separation", 12)
	info_box.alignment = BoxContainer.ALIGNMENT_CENTER
	info_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(info_box)

	var name_label := Label.new()
	name_label.text = lord.display_name
	name_label.add_theme_font_size_override("font_size", 40)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.modulate = Color(0.96, 0.92, 0.78)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_box.add_child(name_label)

	var nation_label := Label.new()
	nation_label.text = NATION_LABELS.get(lord.nation, String(lord.nation))
	nation_label.add_theme_font_size_override("font_size", 28)
	nation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nation_label.modulate = Color(0.82, 0.86, 0.92)
	nation_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_box.add_child(nation_label)

	var trait_label := Label.new()
	trait_label.text = "특성 — %s" % lord.trait_name
	trait_label.add_theme_font_size_override("font_size", 22)
	trait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trait_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	trait_label.modulate = Color(0.80, 0.80, 0.78)
	trait_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_box.add_child(trait_label)

	return btn

func _on_lord_pressed(lord_id: StringName) -> void:
	RunManager.ensure_started(lord_id)
	GameManager.change_scene(RUN_MAP_SCENE)
