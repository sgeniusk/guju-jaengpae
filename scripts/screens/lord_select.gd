# 군주 선택 화면 — 카탈로그의 해금 가능한 군주 중 하나를 골라 런을 시작한다.
extends Control

const RUN_MAP_SCENE := "res://scenes/screens/run_map.tscn"
const _ExportSmoke := preload("res://scripts/run/export_smoke.gd")

# 진영 식별자 → 한국어 표기.
const NATION_LABELS := {
	&"shu": "촉(蜀)",
	&"wei": "위(魏)",
	&"wu": "오(吳)",
}

var _root: VBoxContainer

func _ready() -> void:
	RunManager.ensure_profile_loaded()
	AudioManager.play_music(&"battle")
	_render()
	if _ExportSmoke.is_first_battle_requested():
		call_deferred("_run_export_first_battle_smoke")

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
	var save_status: Dictionary = RunManager.run_save_status()
	if bool(save_status.get("can_continue", false)):
		var continue_btn := Button.new()
		continue_btn.text = "저장된 런 이어하기"
		continue_btn.tooltip_text = _continue_tooltip(save_status)
		continue_btn.custom_minimum_size = Vector2(420.0, 64.0)
		continue_btn.add_theme_font_size_override("font_size", 28)
		continue_btn.pressed.connect(_on_continue_pressed)
		_root.add_child(continue_btn)
	elif bool(save_status.get("exists", false)):
		_root.add_child(_build_resume_unavailable_notice(save_status))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	_root.add_child(row)

	for lord in _catalog_lords():
		row.add_child(_build_lord_button(lord))

func _build_resume_unavailable_notice(save_status: Dictionary) -> Button:
	var notice := Button.new()
	notice.text = "저장된 런을 불러올 수 없음"
	notice.tooltip_text = "%s\n새 군주를 선택하면 새 런으로 다시 시작합니다." % _resume_error_text(save_status)
	notice.custom_minimum_size = Vector2(520.0, 58.0)
	notice.add_theme_font_size_override("font_size", 24)
	notice.disabled = true
	return notice

func _continue_tooltip(save_status: Dictionary) -> String:
	var stage := int(save_status.get("stage", 1))
	return "저장된 런을 불러와 현재 스테이지 %d년에서 이어갑니다." % stage

func _resume_error_text(save_status: Dictionary) -> String:
	var reason := String(save_status.get("reason", ""))
	if reason == "load_error":
		return "저장 파일을 읽을 수 없습니다."
	if reason == "invalid_payload":
		return "저장 파일 버전이 맞지 않거나 내용이 손상되었습니다."
	if reason == "not_started":
		return "저장된 런이 시작 상태가 아닙니다."
	return "저장 파일을 이어하기에 사용할 수 없습니다."

func _catalog_lords() -> Array[LordData]:
	return CardLibrary.lord_list()

func _build_lord_button(lord: LordData) -> Button:
	var unlocked := RunManager.is_lord_unlocked(lord.id)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(360.0, 320.0)
	btn.tooltip_text = _lord_tooltip(lord, unlocked)
	btn.disabled = not unlocked
	if unlocked:
		btn.pressed.connect(_on_lord_pressed.bind(lord.id))
	else:
		btn.modulate = Color(0.46, 0.46, 0.46, 0.86)

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

	var status_label := Label.new()
	status_label.text = "해금됨" if unlocked else "잠김"
	status_label.add_theme_font_size_override("font_size", 22)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.modulate = Color(0.72, 1.0, 0.72) if unlocked else Color(1.0, 0.72, 0.54)
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_box.add_child(status_label)

	var trait_label := Label.new()
	trait_label.text = "특성 — %s" % lord.trait_name
	trait_label.add_theme_font_size_override("font_size", 22)
	trait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trait_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	trait_label.modulate = Color(0.80, 0.80, 0.78)
	trait_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_box.add_child(trait_label)

	return btn

func _lord_tooltip(lord: LordData, unlocked: bool) -> String:
	if lord == null:
		return "군주 정보를 불러오지 못했습니다."
	var nation: String = String(NATION_LABELS.get(lord.nation, String(lord.nation)))
	var trait_description: String = lord.trait_text if lord.trait_text != "" else lord.trait_name
	if unlocked:
		return "%s — %s\n특성: %s\n선택하면 새 런을 시작합니다." % [lord.display_name, nation, trait_description]
	return "%s — %s\n잠김. 보스 승리로 해금됩니다." % [lord.display_name, nation]

func _on_lord_pressed(lord_id: StringName) -> void:
	AudioManager.play_sfx(&"start")
	RunManager.reset_run()
	RunManager.ensure_started(lord_id)
	GameManager.change_scene(RUN_MAP_SCENE)

func _on_continue_pressed() -> void:
	if RunManager.load_run():
		AudioManager.play_sfx(&"ui")
		GameManager.change_scene(RUN_MAP_SCENE)
	else:
		AudioManager.play_sfx(&"defeat")
		_render()

func _run_export_first_battle_smoke() -> void:
	if not _ExportSmoke.is_first_battle_requested():
		return
	var lord_id := _ExportSmoke.lord_id()
	_ExportSmoke.log_marker("lord_select_ready", { "lord_id": String(lord_id) })
	RunManager.reset_run()
	RunManager.ensure_started(lord_id)
	GameManager.change_scene(RUN_MAP_SCENE)
