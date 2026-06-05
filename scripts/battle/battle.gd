# 전투 화면 — Node2D 월드와 CanvasLayer HUD로 전투 뷰만 렌더링한다.
# 순수 전투 로직은 BattleSim에 있다. 이 스크립트는 입력·보드 표시·유닛 시각화만 담당한다.
extends Control

enum Phase { DEPLOY, BATTLE, DONE }

const LORD_ID := &"lord_liubei"
const _StageCadence := preload("res://scripts/run/stage_cadence.gd")
const _BattleHudState := preload("res://scripts/battle/hud_state.gd")
const _BattlefieldTheme := preload("res://scripts/battle/battlefield_theme.gd")
const _BoardEconomy := preload("res://scripts/run/board_economy.gd")
const _EdictCatalog := preload("res://scripts/run/edict_catalog.gd")
const _CardChoiceAdvisor := preload("res://scripts/run/card_choice_advisor.gd")
const _CardUiText := preload("res://scripts/ui/card_ui_text.gd")
const _FormationRenderer := preload("res://scripts/battle/formation_renderer.gd")
const _BattleFeel := preload("res://scripts/battle/battle_feel.gd")
const _BattleCommandFeedback := preload("res://scripts/battle/battle_command_feedback.gd")
const _FormationTactics := preload("res://scripts/run/formation_tactics.gd")
const _ExportSmoke := preload("res://scripts/run/export_smoke.gd")
const LORD_SELECT_SCENE := "res://scenes/screens/lord_select.tscn"

const VIEW_ORIGIN := Vector2(520.0, 225.0)
const VIEW_SCALE_X := 1.28
const VIEW_SCALE_Y := 0.86
const ISO_HALF_W := 48.0
const ISO_HALF_H := 24.0
const TILE_TEXTURE_SCALE := 0.75
const UNIT_W := 140.0
const UNIT_H := 130.0
const UNIT_MEMBER_W := 48.0
const UNIT_MEMBER_H := 54.0
const GENERAL_W := 130.0
const GENERAL_H := 148.0
const GENERAL_BODY_W := 96.0
const GENERAL_BODY_H := 112.0
const BOSS_W := 204.0
const BOSS_H := 244.0
const CASTLE_W := 150.0
const CASTLE_H := 188.0
const BUILDING_W := 108.0
const BUILDING_H := 104.0
const COMMAND_PICK_RADIUS := 70.0
const MAX_FLOATING_DAMAGE_LABELS := 40
const VFX_FLOATING_Z := 4095
const VFX_RALLY_Z := 4096
const WALK_FRAME_COUNT := 4
const WALK_FPS := 8.0
const WALK_MOVE_EPSILON := 0.01
const TILE_CLICK_MARGIN := 1.35
const BOSS_TEXTURE_PATHS := {
	"마왕 동탁": "res://assets/sprites/units/luoyang/boss_dongzhuo.png",
	"천공 장각": "res://assets/sprites/units/huangtian/boss_zhangjue.png",
	"귀신 여포": "res://assets/sprites/units/wanyao/boss_lvbu.png",
}

var _phase: int = Phase.DEPLOY
var _sim := BattleSim.new()
var _lord: LordData
var _vis: Dictionary = {}            # BattleUnit -> { root, body, hp, command_marker, command_label, hp_width, last_px, last_py }
var _building_vis: Dictionary = {}   # "col:row" -> { root, gold_label, gold_per_sec }
var _tile_buttons: Dictionary = {}   # "col:row" -> { area, poly, label }
var _placeholder_textures: Dictionary = {}
var _theme: Dictionary = {}
var _stage_advanced := false
var _command_toggle_active := false
var _commanded_target: BattleUnit = null
var _selected_hand_index := -1
var _speed := 3.0
var _paused := false
var _auto_enabled := false
var _enemy_force_max := 0
var _last_ladder_stage := -1
var _battle_gold_per_sec := 0
var _battle_gold_accum := 0.0
var _pending_scheme_battle_effects: Array[Dictionary] = []
var _battle_outcome: Dictionary = {}

var _world_root: Node2D
var _camera: Camera2D
var _background_layer: Node2D
var _iso_base_layer: Node2D
var _buildings_layer: Node2D
var _units_layer: Node2D
var _vfx_layer: Node2D
var _hud: CanvasLayer
var _top_left: Control
var _top_center: Control
var _top_right: Control
var _left_bar: Control
var _bottom_bars: Control
var _deploy_panel: Control
var _hud_theme: Theme
var _top_gold_label: Label
var _stage_ladder_box: HBoxContainer
var _stage_year_label: Label
var _pause_button: Button
var _auto_button: Button
var _speed_buttons: Array[Button] = []
var _ability_buttons: Array[Button] = []
var _bar_rows: Dictionary = {}
var _damage_font: Font
var _panel: VBoxContainer
var _board_head: Label
var _board_box: VBoxContainer
var _hand_box: VBoxContainer
var _gold_label: Label
var _scheme_button: Button
var _well_button: Button
var _wave_label: Label
var _hint_label: Label
var _start_button: Button
var _result_label: Label
var _overlay: Control            # 승리 보상 / 패배 재시도 패널

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lord_id := RunManager.state.lord_id if RunManager.is_run_started() and RunManager.state.lord_id != &"" else LORD_ID
	RunManager.ensure_started(lord_id)
	RunManager.prepare_deploy_hand()
	_lord = CardLibrary.get_lord(RunManager.state.lord_id)
	AudioManager.play_music(&"battle")
	_theme = _BattlefieldTheme.theme_for_stage(RunManager.stage_index(), _player_realm())
	_bind_scene_nodes()
	_build_hud_theme()
	_build_field()
	_build_hud()
	_ensure_castle()
	_spawn_board_army()
	_build_panel()
	if _lord == null:
		_hint_label.text = "오류 — 군주(%s)를 불러오지 못했습니다." % String(RunManager.state.lord_id)
	if _ExportSmoke.is_first_battle_requested():
		call_deferred("_run_export_first_battle_smoke")

func _process(delta: float) -> void:
	if _phase != Phase.BATTLE:
		_sync_hud()
		return
	var step_delta := _BattleHudState.speed_delta(delta, _speed, _paused, true)
	if step_delta > 0.0:
		_sim.step(step_delta)
		_accumulate_building_gold(step_delta)
		_play_damage_events()
	_prune_command_target()
	_sync_visuals()
	_flash_skill_casts()
	if _sim.is_over():
		_end_battle()

func _input(event: InputEvent) -> void:
	if _phase != Phase.BATTLE:
		return
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return
		if _command_toggle_active and mouse_button.pressed:
			_apply_hero_command_at(mouse_button.position)
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if _phase != Phase.DEPLOY:
		return
	if not (event is InputEventMouseButton):
		return
	var mouse_button := event as InputEventMouseButton
	if mouse_button.button_index != MOUSE_BUTTON_LEFT or not mouse_button.pressed:
		return
	var block_key := _tile_key_at_screen_position(mouse_button.position)
	if block_key == "":
		return
	_on_tile_pressed(block_key)
	get_viewport().set_input_as_handled()

# ── 화면 구성 ───────────────────────────────────────────────
func _bind_scene_nodes() -> void:
	_world_root = get_node_or_null("WorldRoot") as Node2D
	if _world_root == null:
		_world_root = Node2D.new()
		_world_root.name = "WorldRoot"
		add_child(_world_root)
	_camera = _world_root.get_node_or_null("Camera2D") as Camera2D
	if _camera == null:
		_camera = Camera2D.new()
		_camera.name = "Camera2D"
		_world_root.add_child(_camera)
	_camera.position = Vector2(960.0, 540.0)
	_camera.enabled = true
	_camera.zoom = Vector2.ONE
	_background_layer = _ensure_node2d(_world_root, "BackgroundLayer")
	_iso_base_layer = _ensure_node2d(_world_root, "IsoBaseLayer")
	_buildings_layer = _ensure_node2d(_world_root, "BuildingsLayer")
	_buildings_layer.y_sort_enabled = true
	_units_layer = _ensure_node2d(_world_root, "UnitsLayer")
	_units_layer.y_sort_enabled = true
	_vfx_layer = _ensure_node2d(_world_root, "VfxLayer")
	_hud = get_node_or_null("HUD") as CanvasLayer
	if _hud == null:
		_hud = CanvasLayer.new()
		_hud.name = "HUD"
		add_child(_hud)
	for name in ["TopLeft", "TopCenter", "TopRight", "LeftBar", "BottomBars", "DeployPanel"]:
		if _hud.get_node_or_null(name) == null:
			var c := Control.new()
			c.name = name
			_hud.add_child(c)
	_top_left = _hud.get_node("TopLeft") as Control
	_top_center = _hud.get_node("TopCenter") as Control
	_top_right = _hud.get_node("TopRight") as Control
	_left_bar = _hud.get_node("LeftBar") as Control
	_bottom_bars = _hud.get_node("BottomBars") as Control
	_deploy_panel = _hud.get_node("DeployPanel") as Control
	_deploy_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_deploy_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layout_hud_slot(_top_left, Vector2(24.0, 22.0), Vector2(250.0, 54.0))
	_layout_hud_slot(_top_center, Vector2(510.0, 18.0), Vector2(900.0, 88.0))
	_layout_hud_slot(_top_right, Vector2(1450.0, 22.0), Vector2(440.0, 54.0))
	_layout_hud_slot(_left_bar, Vector2(24.0, 180.0), Vector2(76.0, 360.0))
	_layout_hud_slot(_bottom_bars, Vector2(540.0, 900.0), Vector2(840.0, 142.0))

func _layout_hud_slot(node: Control, pos: Vector2, size: Vector2) -> void:
	if node == null:
		return
	node.set_anchors_preset(Control.PRESET_TOP_LEFT)
	node.position = pos
	node.size = size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ensure_node2d(parent: Node, node_name: String) -> Node2D:
	var node := parent.get_node_or_null(node_name) as Node2D
	if node == null:
		node = Node2D.new()
		node.name = node_name
		parent.add_child(node)
	return node

func _build_field() -> void:
	_clear_children(_background_layer)
	_clear_children(_iso_base_layer)
	_clear_children(_buildings_layer)
	_clear_children(_units_layer)
	_clear_children(_vfx_layer)
	_tile_buttons.clear()
	_building_vis.clear()
	_build_background()
	_build_iso_base()
	_result_label = Label.new()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.position = Vector2(560.0, 108.0)
	_result_label.size = Vector2(980.0, 70.0)
	_result_label.add_theme_font_size_override("font_size", 56)
	_result_label.visible = false
	_deploy_panel.add_child(_result_label)

func _build_hud_theme() -> void:
	_hud_theme = Theme.new()
	if ResourceLoader.exists("res://assets/fonts/pixel.ttf"):
		_damage_font = load("res://assets/fonts/pixel.ttf") as Font
	var panel := _stylebox(Color(0.76, 0.66, 0.47, 0.86), Color(0.19, 0.12, 0.07, 0.95), 2, 8)
	var button := _stylebox(Color(0.33, 0.22, 0.12, 0.92), Color(0.84, 0.63, 0.24, 0.95), 2, 8)
	var button_hover := _stylebox(Color(0.44, 0.29, 0.13, 0.96), Color(0.96, 0.75, 0.30, 1.0), 2, 8)
	var button_pressed := _stylebox(Color(0.70, 0.45, 0.15, 0.98), Color(1.0, 0.86, 0.38, 1.0), 2, 8)
	var button_disabled := _stylebox(Color(0.16, 0.15, 0.13, 0.70), Color(0.35, 0.31, 0.24, 0.85), 1, 8)
	for type in ["PanelContainer", "Panel"]:
		_hud_theme.set_stylebox("panel", type, panel)
	for type in ["Button"]:
		_hud_theme.set_stylebox("normal", type, button)
		_hud_theme.set_stylebox("hover", type, button_hover)
		_hud_theme.set_stylebox("pressed", type, button_pressed)
		_hud_theme.set_stylebox("disabled", type, button_disabled)
		_hud_theme.set_color("font_color", type, Color(0.96, 0.88, 0.68))
		_hud_theme.set_color("font_pressed_color", type, Color(0.13, 0.08, 0.04))
		_hud_theme.set_color("font_disabled_color", type, Color(0.55, 0.51, 0.42))
	_hud_theme.set_color("font_color", "Label", Color(0.12, 0.08, 0.04))
	_hud_theme.set_font_size("font_size", "Label", 17)
	_hud_theme.set_font_size("font_size", "Button", 17)

func _stylebox(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 10.0
	box.content_margin_right = 10.0
	box.content_margin_top = 6.0
	box.content_margin_bottom = 6.0
	return box

func _build_hud() -> void:
	_build_resource_counter()
	_build_stage_ladder()
	_build_speed_controls()
	_build_ability_bar()
	_build_bottom_bars()
	_sync_hud()

func _build_resource_counter() -> void:
	_clear_children(_top_left)
	var panel := _make_hud_panel(_top_left)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var icon := _hud_icon("res://assets/sprites/ui/icon_gold.png", "◆", Vector2(34.0, 34.0))
	row.add_child(icon)
	_top_gold_label = Label.new()
	_top_gold_label.add_theme_font_size_override("font_size", 24)
	_top_gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_top_gold_label)

func _build_stage_ladder() -> void:
	_clear_children(_top_center)
	var panel := _make_hud_panel(_top_center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	_stage_year_label = Label.new()
	_stage_year_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage_year_label.add_theme_font_size_override("font_size", 18)
	box.add_child(_stage_year_label)
	_stage_ladder_box = HBoxContainer.new()
	_stage_ladder_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_stage_ladder_box.add_theme_constant_override("separation", 8)
	box.add_child(_stage_ladder_box)

func _build_speed_controls() -> void:
	_clear_children(_top_right)
	_speed_buttons.clear()
	var panel := _make_hud_panel(_top_right)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)
	_auto_button = Button.new()
	_auto_button.toggle_mode = true
	_auto_button.text = "auto"
	_auto_button.tooltip_text = "전투 속도를 자동 진행 모드로 전환합니다."
	_auto_button.custom_minimum_size = Vector2(70.0, 38.0)
	_auto_button.pressed.connect(_on_auto_toggled)
	row.add_child(_auto_button)
	_pause_button = Button.new()
	_pause_button.toggle_mode = true
	_pause_button.text = "Ⅱ"
	_pause_button.tooltip_text = "전투를 일시정지하거나 재개합니다."
	_pause_button.custom_minimum_size = Vector2(48.0, 38.0)
	_pause_button.pressed.connect(_on_pause_toggled)
	row.add_child(_pause_button)
	for value in [1.0, 2.0, 3.0]:
		var b := Button.new()
		b.text = "×%d" % int(value)
		b.tooltip_text = "전투 속도를 ×%d로 바꿉니다." % int(value)
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(58.0, 38.0)
		b.pressed.connect(_set_speed.bind(value))
		row.add_child(b)
		_speed_buttons.append(b)

func _build_ability_bar() -> void:
	_clear_children(_left_bar)
	_ability_buttons.clear()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	_left_bar.add_child(box)
	var well := _make_ability_button("우", "우물 — 선택한 손패 카드를 버리고 +%d골드를 얻습니다." % RunState.WELL_GOLD, "res://assets/sprites/ui/ability_well.png")
	well.pressed.connect(_on_ability_well_pressed)
	box.add_child(well)
	_ability_buttons.append(well)
	var focus := _make_ability_button("표", "집중표적 — 전투 중 적을 클릭해 장수들의 표적을 지정합니다.", "res://assets/sprites/ui/ability_focus.png")
	focus.toggle_mode = true
	focus.pressed.connect(_on_focus_toggled)
	box.add_child(focus)
	_ability_buttons.append(focus)
	for data in [
		{"label": "2", "icon": "res://assets/sprites/ui/ability_demon.png"},
		{"label": "3", "icon": "res://assets/sprites/ui/ability_plague.png"},
	]:
		var disabled := _make_ability_button(String(data["label"]), "예약 — 후속 능력 슬롯입니다.", String(data["icon"]))
		disabled.disabled = true
		box.add_child(disabled)
		_ability_buttons.append(disabled)

func _build_bottom_bars() -> void:
	_clear_children(_bottom_bars)
	_bar_rows.clear()
	var panel := _make_hud_panel(_bottom_bars)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)
	_add_hud_bar(box, "castle", "성", Color(0.23, 0.72, 0.48))
	_add_hud_bar(box, "champion", "챔피언", Color(0.80, 0.20, 0.38))
	_add_hud_bar(box, "force", "군세", Color(0.86, 0.58, 0.20))

func _make_hud_panel(parent: Control) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme = _hud_theme
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel

func _hud_icon(path: String, fallback: String, size: Vector2) -> Control:
	if ResourceLoader.exists(path):
		var tex := TextureRect.new()
		tex.texture = load(path) as Texture2D
		tex.custom_minimum_size = size
		tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		return tex
	var label := Label.new()
	label.text = fallback
	label.custom_minimum_size = size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", int(size.y * 0.72))
	return label

func _make_ability_button(fallback: String, tooltip: String, icon_path: String = "") -> Button:
	var button := Button.new()
	button.theme = _hud_theme
	button.text = fallback
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(62.0, 62.0)
	var normal := _stylebox(Color(0.30, 0.20, 0.12, 0.94), Color(0.88, 0.64, 0.22, 0.96), 2, 31)
	var pressed := _stylebox(Color(0.75, 0.48, 0.16, 0.98), Color(1.0, 0.86, 0.38, 1.0), 3, 31)
	var disabled := _stylebox(Color(0.13, 0.12, 0.11, 0.78), Color(0.32, 0.29, 0.23, 0.9), 1, 31)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", pressed)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	if icon_path != "" and ResourceLoader.exists(icon_path):
		button.text = ""
		var icon := TextureRect.new()
		icon.texture = load(icon_path) as Texture2D
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 10.0
		icon.offset_top = 10.0
		icon.offset_right = -10.0
		icon.offset_bottom = -10.0
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
	return button

func _add_hud_bar(parent: VBoxContainer, id: String, label_text: String, fill_color: Color) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(104.0, 24.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.step = 0.001
	bar.value = 1.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(650.0, 24.0)
	bar.add_theme_stylebox_override("background", _stylebox(Color(0.08, 0.07, 0.05, 0.84), Color(0.19, 0.12, 0.07, 0.95), 1, 5))
	bar.add_theme_stylebox_override("fill", _stylebox(fill_color, Color(0.96, 0.82, 0.32, 0.75), 0, 5))
	row.add_child(bar)
	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(54.0, 24.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(value_label)
	_bar_rows[id] = { "row": row, "label": label, "bar": bar, "value": value_label, "base_modulate": row.modulate }

func _build_background() -> void:
	var bg_path := _BattlefieldTheme.background_path(_theme)
	if ResourceLoader.exists(bg_path):
		var tex := load(bg_path) as Texture2D
		if tex != null:
			var bg := Sprite2D.new()
			bg.name = "ThemeBackground"
			bg.centered = false
			bg.texture = tex
			bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var tex_size := tex.get_size()
			if tex_size.x > 0.0 and tex_size.y > 0.0:
				bg.scale = Vector2(1920.0 / tex_size.x, 1080.0 / tex_size.y)
			bg.modulate = _theme.get("ambient", Color.WHITE)
			bg.z_index = -1000
			_background_layer.add_child(bg)
			return
	_build_fallback_background()

func _build_fallback_background() -> void:
	var sky := Polygon2D.new()
	sky.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1920.0, 0.0), Vector2(1920.0, 420.0), Vector2(0.0, 500.0)])
	sky.color = Color(0.13, 0.16, 0.22)
	_background_layer.add_child(sky)
	var ground := Polygon2D.new()
	ground.polygon = PackedVector2Array([Vector2(0.0, 390.0), Vector2(1920.0, 320.0), Vector2(1920.0, 1080.0), Vector2(0.0, 1080.0)])
	ground.color = Color(0.11, 0.18, 0.12)
	_background_layer.add_child(ground)

func _build_iso_base() -> void:
	var tile_texture := _load_texture(_BattlefieldTheme.tile_path(_theme))
	for col in BattleSim.COL_COUNT:
		for row in RunManager.get_board_rows():
			var block_key := _tile_key(col, row)
			var center := field_to_screen_position(BattleSim.position_for_tile(col, row))
			var tile_sprite := Sprite2D.new()
			tile_sprite.texture = tile_texture
			tile_sprite.centered = true
			tile_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tile_sprite.position = center
			tile_sprite.scale = Vector2(TILE_TEXTURE_SCALE, TILE_TEXTURE_SCALE)
			tile_sprite.z_index = int(center.y)
			tile_sprite.modulate = Color(1.0, 1.0, 1.0, 0.5)
			_iso_base_layer.add_child(tile_sprite)
			var fallback_poly: Polygon2D = null
			if tile_texture == null:
				fallback_poly = Polygon2D.new()
				fallback_poly.polygon = _diamond_points()
				fallback_poly.position = center
				fallback_poly.color = Color(0.20, 0.34, 0.20, 0.90)
				fallback_poly.z_index = int(center.y)
				_iso_base_layer.add_child(fallback_poly)
			var label := Label.new()
			label.text = ""
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.position = center + Vector2(-58.0, -12.0)
			label.size = Vector2(116.0, 24.0)
			label.add_theme_font_size_override("font_size", 12)
			label.modulate = Color(0.10, 0.07, 0.03, 0.86)
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_iso_base_layer.add_child(label)
			var area := Area2D.new()
			area.position = center
			area.input_pickable = true
			area.input_event.connect(_on_tile_area_input.bind(block_key))
			var shape := CollisionPolygon2D.new()
			shape.polygon = _diamond_points()
			area.add_child(shape)
			_iso_base_layer.add_child(area)
			_tile_buttons[block_key] = { "area": area, "sprite": tile_sprite, "poly": fallback_poly, "label": label }

func _diamond_points() -> PackedVector2Array:
	return PackedVector2Array([Vector2(0.0, -ISO_HALF_H), Vector2(ISO_HALF_W, 0.0), Vector2(0.0, ISO_HALF_H), Vector2(-ISO_HALF_W, 0.0)])

func _ellipse_points(radius_x: float, radius_y: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count := maxi(8, segments)
	for idx in count:
		var angle := TAU * float(idx) / float(count)
		points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points

func field_to_screen(px: float, py: float) -> Vector2:
	return VIEW_ORIGIN + Vector2(px * VIEW_SCALE_X, py * VIEW_SCALE_Y)

func field_to_screen_position(pos: Vector2) -> Vector2:
	return field_to_screen(pos.x, pos.y)

func _build_panel() -> void:
	var panel_frame := PanelContainer.new()
	panel_frame.theme = _hud_theme
	panel_frame.position = Vector2(32.0, 148.0)
	panel_frame.custom_minimum_size = Vector2(400.0, 0.0)
	panel_frame.size = Vector2(400.0, 0.0)
	panel_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	panel_frame.add_theme_stylebox_override("panel", _stylebox(Color(0.70, 0.60, 0.42, 0.97), Color(0.16, 0.09, 0.04, 1.0), 2, 8))
	_deploy_panel.add_child(panel_frame)
	_panel = VBoxContainer.new()
	_panel.theme = _hud_theme
	_panel.custom_minimum_size = Vector2(376.0, 0.0)
	_panel.add_theme_constant_override("separation", 10)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel_frame.add_child(_panel)

	var stage := Label.new()
	stage.text = _StageCadence.stage_label(RunManager.stage_index())
	stage.add_theme_font_size_override("font_size", 24)
	if RunManager.is_boss_stage():
		stage.modulate = Color(1.0, 0.55, 0.35)
	_panel.add_child(stage)

	var title := Label.new()
	var lord_name := _lord.display_name if _lord != null else "?"
	title.text = "군주 — %s (%s)" % [lord_name, _nation_label()]
	title.add_theme_font_size_override("font_size", 26)
	_panel.add_child(title)

	if _lord != null and _lord.trait_name != "":
		var trait_label := Label.new()
		trait_label.text = "특성 — %s" % _lord.trait_name
		trait_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_panel.add_child(trait_label)

	var perk := RunManager.terrain_perk_info()
	if not perk.is_empty():
		var perk_label := Label.new()
		perk_label.text = "지형 특전 — %s: %s" % [String(perk.get("name", "")), String(perk.get("text", ""))]
		perk_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_panel.add_child(perk_label)

	_wave_label = Label.new()
	_wave_label.add_theme_font_size_override("font_size", 22)
	_wave_label.visible = false
	_panel.add_child(_wave_label)
	_update_wave_label()

	var guide := Label.new()
	guide.text = "1. 성 위치를 먼저 고르고 2. 손패 3장 중 1장을 빈 타일에 두면 바로 교전합니다."
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide.add_theme_font_size_override("font_size", 18)
	_panel.add_child(guide)

	_board_head = Label.new()
	_board_head.add_theme_font_size_override("font_size", 20)
	_panel.add_child(_board_head)

	_board_box = VBoxContainer.new()
	_board_box.add_theme_constant_override("separation", 4)
	_panel.add_child(_board_box)

	_hand_box = VBoxContainer.new()
	_hand_box.add_theme_constant_override("separation", 4)
	_panel.add_child(_hand_box)

	_gold_label = Label.new()
	_panel.add_child(_gold_label)

	_scheme_button = Button.new()
	_scheme_button.theme = _hud_theme
	_scheme_button.text = "계략 발동"
	_scheme_button.tooltip_text = "선택한 계략 카드를 발동합니다."
	_scheme_button.custom_minimum_size = Vector2(0.0, 40.0)
	_scheme_button.pressed.connect(_on_scheme_pressed)
	_panel.add_child(_scheme_button)

	_well_button = Button.new()
	_well_button.theme = _hud_theme
	_well_button.tooltip_text = "선택한 손패 카드를 버리고 +%d골드를 얻습니다." % RunState.WELL_GOLD
	_well_button.custom_minimum_size = Vector2(0.0, 40.0)
	_well_button.pressed.connect(_on_well_pressed)
	_panel.add_child(_well_button)

	_start_button = Button.new()
	_start_button.theme = _hud_theme
	_start_button.text = "전투 시작"
	_start_button.tooltip_text = "현재 보드 군세로 전투를 시작합니다."
	_start_button.custom_minimum_size = Vector2(0.0, 44.0)
	_start_button.pressed.connect(_on_start_pressed)
	_panel.add_child(_start_button)

	_hint_label = Label.new()
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.modulate = Color(1.0, 0.8, 0.4)
	_panel.add_child(_hint_label)
	_refresh_deploy_ui()

func _make_board_row(block_key: String, card_id: StringName) -> Control:
	var card := CardLibrary.get_card(card_id)
	var row := HBoxContainer.new()
	row.tooltip_text = _CardUiText.tooltip(card) if card != null else String(card_id)
	var slot_label := Label.new()
	slot_label.text = _block_label(block_key)
	slot_label.custom_minimum_size = Vector2(92.0, 0.0)
	row.add_child(slot_label)
	var name_label := Label.new()
	var level := RunManager.get_board_level(block_key)
	if card != null:
		name_label.text = "%s Lv.%d (%d)" % [card.display_name, level, card.cost]
		name_label.tooltip_text = _CardUiText.tooltip(card)
	else:
		name_label.text = String(card_id)
		name_label.tooltip_text = String(card_id)
	name_label.custom_minimum_size = Vector2(300.0, 0.0)
	row.add_child(name_label)
	return row

func _refresh_deploy_ui() -> void:
	_sync_deploy_panel_visibility()
	var hand := RunManager.get_hand()
	if _selected_hand_index >= hand.size():
		_selected_hand_index = -1
	var has_castle := RunManager.has_castle()
	var played_this_deploy := not RunManager.can_place_deploy_card()
	if _board_head != null:
		var castle_text := _block_label(RunManager.get_castle_key()) if has_castle else "미선택"
		_board_head.text = "전장 — 성 %s · 이번 배치 %d/1 · 보드 %d / %d" % [
			castle_text,
			1 if played_this_deploy else 0,
			RunManager.get_board().size(),
			RunManager.get_board_capacity(),
		]
	if _gold_label != null:
		_gold_label.text = "골드 — %d" % RunManager.get_gold()
	_rebuild_board_summary()
	_rebuild_hand_list(hand)
	if _scheme_button != null:
		_scheme_button.disabled = _phase != Phase.DEPLOY or not RunManager.can_cast_scheme_from_hand(_selected_hand_index)
		_scheme_button.tooltip_text = _scheme_button_tooltip(_selected_hand_card())
	if _well_button != null:
		_well_button.text = "우물 +%d골드" % RunState.WELL_GOLD
		_well_button.disabled = _phase != Phase.DEPLOY or _selected_hand_index < 0 or not RunManager.can_discard_from_hand(_selected_hand_index)
		_well_button.tooltip_text = _well_button_tooltip(_selected_hand_card())
	if _start_button != null:
		_start_button.text = "교전 시작"
		_start_button.disabled = _phase != Phase.DEPLOY or not has_castle or not played_this_deploy or _board_unit_count() <= 0
		if not has_castle:
			_start_button.tooltip_text = "먼저 빈 타일을 클릭해 성 위치를 고르세요."
		elif not played_this_deploy:
			_start_button.tooltip_text = "손패 3장 중 1장을 배치하면 자동으로 교전합니다."
		elif _board_unit_count() <= 0:
			_start_button.tooltip_text = "전투할 아군 유닛이 없습니다."
		else:
			_start_button.tooltip_text = "이번 한 수로 교전을 시작합니다."
	_refresh_board_tiles()
	_sync_hud()

func _rebuild_board_summary() -> void:
	if _board_box == null:
		return
	_clear_children(_board_box)
	var board := RunManager.get_board()
	if RunManager.has_castle():
		var castle_row := HBoxContainer.new()
		var slot := Label.new()
		slot.text = _block_label(RunManager.get_castle_key())
		slot.custom_minimum_size = Vector2(92.0, 0.0)
		castle_row.add_child(slot)
		var castle_name := Label.new()
		castle_name.text = "성"
		castle_name.custom_minimum_size = Vector2(300.0, 0.0)
		castle_row.add_child(castle_name)
		_board_box.add_child(castle_row)
	var any := false
	for key in RunState.block_keys_for(RunManager.get_board_rows()):
		if not board.has(key):
			continue
		any = true
		_board_box.add_child(_make_board_row(key, StringName(board[key])))
	if not any:
		var empty := Label.new()
		empty.text = "보드 군세 없음 — 성을 고른 뒤 손패 1장을 배치"
		empty.tooltip_text = "이번 교전에는 손패 3장 중 1장만 배치합니다."
		_board_box.add_child(empty)

func _rebuild_hand_list(hand: Array[StringName]) -> void:
	if _hand_box == null:
		return
	_clear_children(_hand_box)
	var head := Label.new()
	head.add_theme_font_size_override("font_size", 20)
	if hand.size() > RunState.HAND_MAX:
		head.text = "손패 — %d장 / 권장 %d장" % [hand.size(), RunState.HAND_MAX]
	else:
		head.text = "손패 — %d장 중 1장 선택" % hand.size()
	_hand_box.add_child(head)
	if hand.is_empty():
		var empty := Label.new()
		empty.text = "손패 없음"
		_hand_box.add_child(empty)
		return
	for idx in hand.size():
		var card_id: StringName = hand[idx]
		var card := CardLibrary.get_card(card_id)
		var card_name := card.display_name if card != null else String(card_id)
		var card_cost := card.cost if card != null else 0
		var upgrades_existing := RunManager.hand_card_would_upgrade(idx)
		var action_label := _CardUiText.deploy_action_label(card, upgrades_existing)
		var b := Button.new()
		b.theme = _hud_theme
		b.toggle_mode = true
		b.button_pressed = idx == _selected_hand_index
		b.text = "%d. %s · %s (%d)" % [idx + 1, action_label, card_name, card_cost]
		b.tooltip_text = _hand_card_tooltip(card, upgrades_existing)
		b.custom_minimum_size = Vector2(0.0, 36.0)
		b.disabled = _phase != Phase.DEPLOY or not RunManager.can_place_deploy_card()
		b.pressed.connect(_select_hand.bind(idx))
		_hand_box.add_child(b)

func _refresh_board_tiles() -> void:
	var board := RunManager.get_board()
	var castle_key := RunManager.get_castle_key()
	if _phase == Phase.DEPLOY and _iso_base_layer != null:
		_iso_base_layer.visible = true
		_iso_base_layer.modulate.a = 1.0
	for key in _tile_buttons.keys():
		var tile: Dictionary = _tile_buttons[key]
		var label := tile.get("label", null) as Label
		var poly := tile.get("poly", null) as Polygon2D
		var sprite := tile.get("sprite", null) as Sprite2D
		var area := tile.get("area", null) as Area2D
		if key == castle_key:
			if label != null:
				label.text = "성"
				label.tooltip_text = "선택한 성 위치입니다."
			if poly != null:
				poly.color = Color(0.48, 0.28, 0.18, 0.98)
			if sprite != null:
				sprite.modulate = Color(1.18, 0.92, 0.62, 1.0)
			if area != null:
				area.input_pickable = false
		elif board.has(key):
			var card := CardLibrary.get_card(StringName(board[key]))
			if label != null:
				label.text = "%s Lv.%d" % [card.display_name, RunManager.get_board_level(key)] if card != null else String(board[key])
				label.tooltip_text = _CardUiText.tooltip(card) if card != null else String(board[key])
			if poly != null:
				poly.color = Color(0.24, 0.42, 0.26, 0.95)
			if sprite != null:
				sprite.modulate = Color(1.10, 1.10, 0.88, 1.0)
			if area != null:
				area.input_pickable = false
		else:
			var preview := _placement_preview_for_block(key)
			if label != null:
				label.text = String(preview.get("label", ""))
				if _phase != Phase.DEPLOY:
					label.tooltip_text = ""
				elif not RunManager.has_castle():
					label.tooltip_text = "이 빈 타일을 성 위치로 선택합니다."
				elif not preview.is_empty():
					label.tooltip_text = String(preview.get("tooltip", ""))
				else:
					label.tooltip_text = "선택한 손패 1장을 이 빈 타일에 배치합니다."
			if poly != null:
				if _phase != Phase.DEPLOY:
					poly.color = Color(0.17, 0.27, 0.17, 0.0)
				elif not preview.is_empty():
					poly.color = Color(0.40, 0.54, 0.20, 0.98)
				else:
					poly.color = Color(0.25, 0.42, 0.28, 0.92)
			if sprite != null:
				sprite.modulate = Color(1.0, 1.0, 1.0, 0.5) if _phase == Phase.DEPLOY else Color(1.0, 1.0, 1.0, 0.0)
			if area != null:
				area.input_pickable = _phase == Phase.DEPLOY

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _placement_preview_for_block(block_key: String) -> Dictionary:
	if _phase != Phase.DEPLOY or not RunManager.has_castle() or not RunManager.can_place_deploy_card():
		return {}
	var hand := RunManager.get_hand()
	if _selected_hand_index < 0 or _selected_hand_index >= hand.size():
		return {}
	if RunManager.can_cast_scheme_from_hand(_selected_hand_index) or RunManager.can_upgrade_from_hand(_selected_hand_index):
		return {}
	if not RunManager.can_place_hand_card(_selected_hand_index):
		return {}
	var card_id: StringName = hand[_selected_hand_index]
	var card := CardLibrary.get_card(card_id)
	if card == null or not (card is UnitCardData):
		return {}
	var board := RunManager.get_board()
	if board.has(block_key):
		return {}
	board[block_key] = card_id
	var levels := RunManager.get_board_levels()
	levels[block_key] = 1
	var army := CardLibrary.catalog.build_board_army(board, _lord, RunManager.get_board_rows(), RunManager.get_edicts(), RunManager.get_castle_key(), RunManager.get_terrain_perk_id(), levels)
	var unit := _find_army_unit_at_block(army, block_key)
	return _FormationTactics.preview_for_unit(unit, army, card.display_name)

func _find_army_unit_at_block(army: Array, block_key: String) -> BattleUnit:
	var parts := block_key.split(":")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return null
	var col := int(parts[0])
	var row := int(parts[1])
	for unit in army:
		if unit != null and unit.lane == col and unit.row == row:
			return unit
	return null

# ── 입력 ────────────────────────────────────────────────────
func _select_hand(index: int) -> void:
	if _phase != Phase.DEPLOY:
		return
	if not RunManager.can_place_deploy_card():
		_hint_label.text = "이번 교전에는 이미 한 장을 냈습니다."
		return
	var hand := RunManager.get_hand()
	if index < 0 or index >= hand.size():
		_selected_hand_index = -1
		_refresh_deploy_ui()
		return
	if RunManager.can_upgrade_from_hand(index):
		_upgrade_from_hand(index)
		return
	if _selected_hand_index == index:
		_selected_hand_index = -1
		_hint_label.text = "카드 선택 해제"
	else:
		_selected_hand_index = index
		var card := CardLibrary.get_card(hand[index])
		var card_name := card.display_name if card != null else String(hand[index])
		if RunManager.can_cast_scheme_from_hand(index):
			_hint_label.text = "선택 — %s. 계략 발동으로 사용합니다." % card_name
		elif RunManager.can_place_hand_card(index):
			if RunManager.has_castle():
				_hint_label.text = "선택 — %s. 빈 타일에 두면 바로 교전합니다." % card_name
			else:
				_hint_label.text = "선택 — %s. 먼저 성 위치를 고르세요." % card_name
		else:
			_hint_label.text = "선택 — %s. 지금 사용할 수 없는 카드입니다." % card_name
	_refresh_deploy_ui()

func _upgrade_from_hand(index: int) -> void:
	var hand := RunManager.get_hand()
	if index < 0 or index >= hand.size():
		return
	var card_id: StringName = hand[index]
	var card := CardLibrary.get_card(card_id)
	var card_name := card.display_name if card != null else String(card_id)
	var key := RunManager.upgrade_from_hand(index)
	if key == "":
		_hint_label.text = "증원할 부대를 찾지 못했습니다."
		_refresh_deploy_ui()
		return
	_respawn_unit_for_board_key(key)
	_selected_hand_index = -1
	_hint_label.text = "증원 — %s Lv.%d. 교전을 시작합니다." % [card_name, RunManager.get_board_level(key)]
	AudioManager.play_sfx(_BattleFeel.rally_sfx_id(RunManager.stage_index(), _sim.enemy_units))
	_refresh_deploy_ui()
	call_deferred("_on_start_pressed")

func _on_tile_area_input(_viewport: Node, event: InputEvent, _shape_idx: int, block_key: String) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_button := event as InputEventMouseButton
	if mouse_button.button_index != MOUSE_BUTTON_LEFT or not mouse_button.pressed:
		return
	_on_tile_pressed(block_key)
	get_viewport().set_input_as_handled()

func _tile_key_at_screen_position(screen_pos: Vector2) -> String:
	for col in BattleSim.COL_COUNT:
		for row in RunManager.get_board_rows():
			var block_key := _tile_key(col, row)
			if not _tile_buttons.is_empty() and not _tile_buttons.has(block_key):
				continue
			var center := field_to_screen_position(BattleSim.position_for_tile(col, row))
			if _is_screen_position_on_tile(screen_pos, center):
				return block_key
	return ""

func _is_screen_position_on_tile(screen_pos: Vector2, center: Vector2) -> bool:
	var local := screen_pos - center
	var normalized := absf(local.x) / ISO_HALF_W + absf(local.y) / ISO_HALF_H
	return normalized <= TILE_CLICK_MARGIN

func _on_tile_pressed(block_key: String) -> void:
	if _phase != Phase.DEPLOY:
		return
	if not RunManager.has_castle():
		if not RunManager.set_castle_key(block_key):
			_hint_label.text = "이 칸에는 성을 둘 수 없습니다."
			_refresh_deploy_ui()
			return
		_ensure_castle()
		AudioManager.play_sfx(&"ui")
		_hint_label.text = "성 위치 — %s. 이제 손패 3장 중 1장을 배치하세요." % _block_label(block_key)
		_refresh_deploy_ui()
		return
	if not RunManager.can_place_deploy_card():
		_hint_label.text = "이번 교전에는 이미 한 장을 냈습니다."
		_refresh_deploy_ui()
		return
	if _selected_hand_index < 0:
		_hint_label.text = "손패 3장 중 한 장을 먼저 선택하세요."
		return
	var hand := RunManager.get_hand()
	if _selected_hand_index >= hand.size():
		_selected_hand_index = -1
		_hint_label.text = "선택한 카드가 없습니다."
		_refresh_deploy_ui()
		return
	var card_id: StringName = hand[_selected_hand_index]
	if RunManager.can_cast_scheme_from_hand(_selected_hand_index):
		_hint_label.text = "계략은 타일에 배치하지 않고 발동합니다."
		_refresh_deploy_ui()
		return
	if not RunManager.can_place_hand_card(_selected_hand_index):
		_hint_label.text = "이 카드는 보드에 배치할 수 없습니다."
		_refresh_deploy_ui()
		return
	if RunManager.can_upgrade_from_hand(_selected_hand_index):
		_upgrade_from_hand(_selected_hand_index)
		return
	if not RunManager.place_from_hand(_selected_hand_index, block_key):
		_hint_label.text = "배치할 수 없습니다."
		_refresh_deploy_ui()
		return
	_spawn_unit_for_board_key(block_key)
	var card := CardLibrary.get_card(card_id)
	var card_name := card.display_name if card != null else String(card_id)
	_selected_hand_index = -1
	_hint_label.text = "배치 — %s. 교전을 시작합니다." % card_name
	_refresh_deploy_ui()
	call_deferred("_on_start_pressed")

func _on_scheme_pressed() -> void:
	if _phase != Phase.DEPLOY:
		return
	if not RunManager.has_castle():
		_hint_label.text = "먼저 성 위치를 고르세요."
		_refresh_deploy_ui()
		return
	if not RunManager.can_place_deploy_card():
		_hint_label.text = "이번 교전에는 이미 한 장을 냈습니다."
		_refresh_deploy_ui()
		return
	var hand := RunManager.get_hand()
	if _selected_hand_index < 0 or _selected_hand_index >= hand.size():
		_hint_label.text = "발동할 계략을 선택하세요."
		_refresh_deploy_ui()
		return
	if not RunManager.can_cast_scheme_from_hand(_selected_hand_index):
		_hint_label.text = "선택한 카드는 계략이 아닙니다."
		_refresh_deploy_ui()
		return
	var card_id: StringName = hand[_selected_hand_index]
	if not RunManager.cast_scheme_from_hand(_selected_hand_index):
		_hint_label.text = "계략을 발동할 수 없습니다."
		_refresh_deploy_ui()
		return
	var card := CardLibrary.get_card(card_id)
	var card_name := card.display_name if card != null else String(card_id)
	var result := RunManager.get_last_scheme_result()
	_apply_scheme_battle_result(result)
	_selected_hand_index = -1
	_hint_label.text = "계략 발동 — %s%s. 교전을 시작합니다." % [card_name, _scheme_result_brief(result)]
	_refresh_deploy_ui()
	call_deferred("_on_start_pressed")

func _on_well_pressed() -> void:
	if _phase != Phase.DEPLOY:
		return
	var hand := RunManager.get_hand()
	if _selected_hand_index < 0 or _selected_hand_index >= hand.size():
		_hint_label.text = "우물에 보낼 카드를 선택하세요."
		_refresh_deploy_ui()
		return
	var card_id: StringName = hand[_selected_hand_index]
	if not RunManager.discard_from_hand(_selected_hand_index):
		_hint_label.text = "우물에 보낼 수 없습니다."
		_refresh_deploy_ui()
		return
	var card := CardLibrary.get_card(card_id)
	var card_name := card.display_name if card != null else String(card_id)
	_selected_hand_index = -1
	_hint_label.text = "우물 — %s, +%d골드. 교전을 시작합니다." % [card_name, RunState.WELL_GOLD]
	_refresh_deploy_ui()
	call_deferred("_on_start_pressed")

func _on_ability_well_pressed() -> void:
	_on_well_pressed()
	_sync_hud()

func _on_focus_toggled() -> void:
	if _ability_buttons.size() < 2:
		return
	_command_toggle_active = _ability_buttons[1].button_pressed
	if _command_toggle_active:
		_hint_label.text = "집중표적 — 적을 클릭하세요."
	else:
		_clear_hero_command(true, _BattleCommandFeedback.manual_clear_hint())
	_sync_hud()

func _on_pause_toggled() -> void:
	_paused = _pause_button != null and _pause_button.button_pressed
	_sync_hud()

func _on_auto_toggled() -> void:
	_auto_enabled = _auto_button != null and _auto_button.button_pressed
	_sync_hud()

func _set_speed(value: float) -> void:
	_speed = clampf(value, 1.0, 3.0)
	_sync_hud()

func _on_start_pressed() -> void:
	if _phase != Phase.DEPLOY:
		return
	_ensure_castle()
	if not RunManager.has_castle():
		_hint_label.text = "성 위치를 먼저 선택하세요."
		_refresh_deploy_ui()
		return
	if RunManager.can_place_deploy_card():
		_hint_label.text = "손패 3장 중 1장을 먼저 내세요."
		_refresh_deploy_ui()
		return
	if _board_unit_count() <= 0:
		_hint_label.text = "보드 군세가 비어 있습니다."
		_refresh_deploy_ui()
		return
	AudioManager.play_sfx(&"start")
	_sim.set_waves(RunManager.current_waves())
	_enemy_force_max = maxi(1, _sim.enemy_units.size())
	_apply_pending_scheme_battle_effects()
	_apply_formation_tactics()
	_apply_building_auras()
	RunManager.apply_treasure_battle_modifiers(_sim.player_units)
	_battle_gold_per_sec = _BoardEconomy.gold_per_sec(RunManager.get_board(), CardLibrary.catalog)
	_battle_gold_accum = 0.0
	_update_building_gold_labels()
	_phase = Phase.BATTLE
	_clear_hero_command(false)
	_fade_iso_tiles_out()
	_sync_visuals()
	_spawn_battle_start_vfx()
	_start_button.disabled = true
	_hint_label.text = _BattleFeel.rally_text(RunManager.stage_index(), _sim.enemy_units)
	_refresh_deploy_ui()

func _run_export_first_battle_smoke() -> void:
	if not _ExportSmoke.is_first_battle_requested():
		return
	if _phase != Phase.DEPLOY:
		_ExportSmoke.fail_and_quit(get_tree(), "battle_not_in_deploy_phase", { "phase": _phase })
		return
	var placement := { "ok": true, "source": "existing" }
	if not RunManager.has_castle() or _board_unit_count() <= 0:
		placement = _ExportSmoke.ensure_first_battle_board()
		if not bool(placement.get("ok", false)):
			_ExportSmoke.fail_and_quit(get_tree(), "battle_has_no_unit", placement)
			return
		if placement.has("block_key"):
			_spawn_unit_for_board_key(String(placement["block_key"]))
		_refresh_deploy_ui()
	_ExportSmoke.log_marker("battle_ready", {
		"stage": RunManager.stage_index(),
		"board_units": _board_unit_count(),
		"placement": placement,
	})
	_on_start_pressed()
	await get_tree().process_frame
	if _phase != Phase.BATTLE:
		_ExportSmoke.fail_and_quit(get_tree(), "first_battle_start_failed", { "phase": _phase })
		return
	_ExportSmoke.log_marker("first_battle_reached", {
		"stage": RunManager.stage_index(),
		"player_units": _sim.player_units.size(),
		"enemy_units": _sim.enemy_units.size(),
		"wave_total": _sim.wave_total,
	})
	get_tree().quit(0)

# ── 시각화 ──────────────────────────────────────────────────
func _spawn_visual(u: BattleUnit) -> void:
	var size := _unit_size(u)
	var root := Node2D.new()
	root.position = field_to_screen(u.px, u.py)
	root.y_sort_enabled = true
	var shadow := Polygon2D.new()
	shadow.polygon = _ellipse_points(size.x * 0.28, size.y * 0.075, 18)
	shadow.color = Color(0.02, 0.01, 0.0, 0.34)
	shadow.position = Vector2(0.0, -3.0)
	shadow.z_index = -2
	root.add_child(shadow)
	var command_marker := Polygon2D.new()
	command_marker.polygon = PackedVector2Array([Vector2(0.0, -18.0), Vector2(34.0, 0.0), Vector2(0.0, 18.0), Vector2(-34.0, 0.0)])
	command_marker.color = Color(1.0, 0.85, 0.1, 0.55)
	command_marker.position = Vector2(0.0, -6.0)
	command_marker.visible = false
	root.add_child(command_marker)
	var command_label := Label.new()
	command_label.text = ""
	command_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	command_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	command_label.position = Vector2(-38.0, -size.y - 70.0)
	command_label.size = Vector2(76.0, 44.0)
	command_label.add_theme_font_size_override("font_size", 16)
	command_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.0, 0.92))
	command_label.add_theme_constant_override("shadow_offset_x", 2)
	command_label.add_theme_constant_override("shadow_offset_y", 2)
	command_label.modulate = Color(1.0, 0.84, 0.18, 1.0)
	command_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	command_label.visible = false
	if _damage_font != null:
		command_label.add_theme_font_override("font", _damage_font)
	root.add_child(command_label)
	var texture := _unit_texture(u)
	var body := _create_unit_body(u, texture, size)
	root.add_child(body)
	var hp_bg := ColorRect.new()
	hp_bg.color = Color(0, 0, 0, 0.65)
	hp_bg.position = Vector2(-size.x * 0.5, -size.y - 12.0)
	hp_bg.size = Vector2(size.x, 6.0)
	hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hp_bg)
	var hp := ColorRect.new()
	hp.color = Color(0.4, 0.9, 0.4) if u.team == BattleUnit.Team.PLAYER else Color(0.95, 0.6, 0.3)
	hp.position = hp_bg.position
	hp.size = hp_bg.size
	hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hp)
	var name_label := Label.new()
	name_label.text = _unit_name_label(u)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(-size.x * 0.75, -size.y - 36.0)
	name_label.size = Vector2(size.x * 1.5, 22.0)
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(name_label)
	_units_layer.add_child(root)
	_vis[u] = { "root": root, "body": body, "shadow": shadow, "base_color": body.modulate, "hp": hp, "command_marker": command_marker, "command_label": command_label, "hp_width": size.x, "last_px": u.px, "last_py": u.py }
	_position_visual(u)

func _unit_name_label(u: BattleUnit) -> String:
	if u == null:
		return ""
	if u.squad_level > 1 and u.squad_count > 1:
		return "%s Lv.%d · %d" % [u.display_name, u.squad_level, u.squad_count]
	if u.squad_count > 1:
		return "%s · %d" % [u.display_name, u.squad_count]
	if u.squad_level > 1:
		return "%s Lv.%d" % [u.display_name, u.squad_level]
	return u.display_name

func _sync_visuals() -> void:
	var active_units := _sim_units()
	var active := {}
	for u in active_units:
		if u == null or not u.is_alive():
			continue
		active[u] = true
		if not _vis.has(u):
			_spawn_visual(u)
	var to_remove: Array = []
	for u in _vis.keys():
		if not active.has(u) or not u.is_alive():
			to_remove.append(u)
	for u in to_remove:
		var root: Node = _vis[u].get("root", null)
		if root != null:
			root.queue_free()
		_vis.erase(u)
	var command_hero_count := _BattleCommandFeedback.controllable_hero_count(_sim.player_units)
	for u in active_units:
		if _vis.has(u):
			_sync_unit_walk_animation(u)
			_position_visual(u)
			var hp: ColorRect = _vis[u].get("hp", null)
			if hp != null:
				hp.size.x = float(_vis[u].get("hp_width", UNIT_W)) * u.hp_ratio()
			var is_commanded := u == _commanded_target
			var marker: Polygon2D = _vis[u].get("command_marker", null)
			if marker != null:
				marker.visible = is_commanded
			var command_label: Label = _vis[u].get("command_label", null)
			if command_label != null:
				command_label.visible = is_commanded
				command_label.text = _BattleCommandFeedback.marker_text(command_hero_count) if is_commanded else ""
	_update_wave_label()
	_sync_hud()

func _sync_hud() -> void:
	if _top_gold_label != null:
		_top_gold_label.text = "%d" % RunManager.get_gold()
	_sync_stage_ladder()
	_sync_speed_controls()
	_sync_ability_bar()
	_sync_bottom_bars()

func _sync_stage_ladder() -> void:
	if _stage_ladder_box == null:
		return
	var current_stage := RunManager.stage_index()
	if _stage_year_label != null:
		_stage_year_label.text = "%d년 전선" % _BattleHudState.stage_year(current_stage)
	if current_stage == _last_ladder_stage and _stage_ladder_box.get_child_count() > 0:
		return
	_last_ladder_stage = current_stage
	_clear_children(_stage_ladder_box)
	for node in _BattleHudState.stage_nodes(current_stage):
		var kind := String(node.get("kind", "combat"))
		var is_current := bool(node.get("is_current", false))
		var item := PanelContainer.new()
		item.theme = _hud_theme
		item.custom_minimum_size = Vector2(104.0, 50.0)
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bg := Color(0.80, 0.68, 0.42, 0.98) if is_current else Color(0.42, 0.31, 0.18, 0.88)
		var border := Color(1.0, 0.84, 0.34, 1.0) if is_current else Color(0.74, 0.55, 0.24, 0.90)
		item.add_theme_stylebox_override("panel", _stylebox(bg, border, 2, 8))
		var v := VBoxContainer.new()
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_theme_constant_override("separation", 0)
		item.add_child(v)
		var icon := _hud_icon("res://assets/sprites/ui/node_%s.png" % kind, String(node.get("icon", "?")), Vector2(30.0, 28.0))
		v.add_child(icon)
		var label := Label.new()
		label.text = "%s %d" % [String(node.get("label", "")), int(node.get("stage", 0))]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 13)
		label.modulate = Color(0.13, 0.08, 0.04) if is_current else Color(0.93, 0.83, 0.63)
		v.add_child(label)
		_stage_ladder_box.add_child(item)

func _sync_speed_controls() -> void:
	if _pause_button != null:
		_pause_button.button_pressed = _paused
		_pause_button.text = "▶" if _paused else "Ⅱ"
		_pause_button.tooltip_text = "전투를 재개합니다." if _paused else "전투를 일시정지합니다."
	if _auto_button != null:
		_auto_button.button_pressed = _auto_enabled
		_auto_button.tooltip_text = "자동 진행을 끕니다." if _auto_enabled else "자동 진행을 켭니다."
	for button in _speed_buttons:
		var label := button.text.replace("×", "")
		button.button_pressed = is_equal_approx(label.to_float(), _speed)

func _sync_ability_bar() -> void:
	if _ability_buttons.size() < 2:
		return
	_ability_buttons[0].disabled = _phase != Phase.DEPLOY or _selected_hand_index < 0
	_ability_buttons[1].disabled = _phase != Phase.BATTLE
	_ability_buttons[1].button_pressed = _command_toggle_active
	_ability_buttons[1].tooltip_text = _BattleCommandFeedback.focus_button_tooltip(
		_phase == Phase.BATTLE,
		_command_toggle_active,
		_commanded_target,
		_BattleCommandFeedback.controllable_hero_count(_sim.player_units)
	)

func _sync_bottom_bars() -> void:
	if _sim.enemy_units.size() > _enemy_force_max:
		_enemy_force_max = _sim.enemy_units.size()
	_update_bar_row("castle", _BattleHudState.castle_ratio(_sim.castle), true, "성")
	var champion := _BattleHudState.champion_state(_sim.enemy_units)
	_update_bar_row("champion", float(champion.get("ratio", 0.0)), bool(champion.get("active", false)), String(champion.get("label", "챔피언")))
	var force_ratio := _BattleHudState.enemy_force_ratio(_sim.enemy_units.size(), _enemy_force_max, _sim.wave_index, _sim.wave_total)
	_update_bar_row("force", force_ratio, _phase == Phase.BATTLE or _sim.wave_total > 0, "군세")

func _update_bar_row(id: String, ratio: float, active: bool, label_text: String) -> void:
	if not _bar_rows.has(id):
		return
	var row_data: Dictionary = _bar_rows[id]
	var row := row_data.get("row", null) as HBoxContainer
	var label := row_data.get("label", null) as Label
	var bar := row_data.get("bar", null) as ProgressBar
	var value_label := row_data.get("value", null) as Label
	if row != null:
		row.modulate = Color(1.0, 1.0, 1.0, 1.0) if active else Color(0.55, 0.52, 0.45, 0.60)
	if label != null:
		label.text = label_text
	if bar != null:
		bar.value = clampf(ratio, 0.0, 1.0)
	if value_label != null:
		value_label.text = "%d%%" % int(round(clampf(ratio, 0.0, 1.0) * 100.0)) if active else "-"

func _position_visual(u: BattleUnit) -> void:
	var root := _vis[u]["root"] as Node2D
	var offset := _unit_visual_offset(u)
	root.position = field_to_screen(u.px, u.py) + offset
	root.z_index = int(u.py)

func _sync_unit_walk_animation(u: BattleUnit) -> void:
	var visual: Dictionary = _vis[u]
	var bodies := _animated_bodies(visual.get("body", null) as Node)
	var last_px := float(visual.get("last_px", u.px))
	var last_py := float(visual.get("last_py", u.py))
	var delta := Vector2(u.px - last_px, u.py - last_py)
	for body in bodies:
		if delta.length_squared() > WALK_MOVE_EPSILON:
			if not body.is_playing():
				body.play("walk")
		else:
			body.stop()
			body.frame = 0
	visual["last_px"] = u.px
	visual["last_py"] = u.py

func _animated_bodies(root: Node) -> Array[AnimatedSprite2D]:
	var out: Array[AnimatedSprite2D] = []
	if root == null:
		return out
	if root is AnimatedSprite2D:
		out.append(root as AnimatedSprite2D)
	for child in root.get_children():
		out.append_array(_animated_bodies(child))
	return out

func _flash_skill_casts() -> void:
	for cast in _sim.last_skill_casts:
		var caster: BattleUnit = cast.get("caster", null)
		if caster == null or not _vis.has(caster):
			continue
		var body := _vis[caster].get("body", null) as CanvasItem
		if body == null or not is_instance_valid(body):
			continue
		var base_color: Color = _vis[caster].get("base_color", body.modulate)
		body.modulate = Color(1.0, 1.0, 1.0)
		var tween := create_tween()
		tween.tween_property(body, "modulate", base_color, 0.15)

func _play_damage_events() -> void:
	for event in _sim.last_damage_events:
		_spawn_damage_number(event)
		_flash_damaged_target(event)

func _spawn_battle_start_vfx() -> void:
	if _vfx_layer == null:
		return
	_spawn_rally_banner(_BattleFeel.rally_text(RunManager.stage_index(), _sim.enemy_units))
	_spawn_charge_lines()
	_spawn_clash_pulses()
	_shake_camera()

func _spawn_rally_banner(text: String) -> void:
	var label := Label.new()
	label.name = "RallyBanner"
	label.set_meta("battle_start_vfx", "rally")
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(690.0, 330.0)
	label.size = Vector2(540.0, 72.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = VFX_RALLY_Z
	label.add_theme_font_size_override("font_size", 46)
	label.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.0, 0.92))
	label.add_theme_constant_override("shadow_offset_x", 4)
	label.add_theme_constant_override("shadow_offset_y", 4)
	if _damage_font != null:
		label.add_theme_font_override("font", _damage_font)
	label.modulate = Color(1.0, 0.86, 0.32, 1.0)
	_vfx_layer.add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 44.0, 0.82).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.82).set_delay(0.18)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _spawn_charge_lines() -> void:
	for y in BattleSim.COL_Y:
		_spawn_charge_line(Vector2(260.0, y), Vector2(470.0, y), Color(0.46, 0.92, 0.58, 0.85))
		_spawn_charge_line(Vector2(840.0, y), Vector2(610.0, y), Color(1.0, 0.34, 0.26, 0.78))

func _spawn_charge_line(from_field: Vector2, to_field: Vector2, color: Color) -> void:
	var line := Line2D.new()
	line.name = "ChargeLine"
	line.set_meta("battle_start_vfx", "charge")
	line.width = 7.0
	line.default_color = color
	line.z_index = VFX_RALLY_Z - 1
	line.points = PackedVector2Array([field_to_screen(from_field.x, from_field.y), field_to_screen(to_field.x, to_field.y)])
	_vfx_layer.add_child(line)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(line, "width", 1.0, 0.54)
	tween.tween_property(line, "modulate:a", 0.0, 0.54).set_delay(0.08)
	tween.set_parallel(false)
	tween.tween_callback(Callable(line, "queue_free"))

func _spawn_clash_pulses() -> void:
	for y in BattleSim.COL_Y:
		var pulse := Polygon2D.new()
		pulse.name = "ClashPulse"
		pulse.set_meta("battle_start_vfx", "pulse")
		pulse.polygon = _ellipse_points(38.0, 16.0, 18)
		pulse.color = Color(1.0, 0.78, 0.34, 0.40)
		pulse.position = field_to_screen(555.0, y)
		pulse.z_index = VFX_RALLY_Z - 2
		_vfx_layer.add_child(pulse)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(pulse, "scale", Vector2(1.55, 1.55), 0.62).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(pulse, "modulate:a", 0.0, 0.62).set_delay(0.08)
		tween.set_parallel(false)
		tween.tween_callback(Callable(pulse, "queue_free"))

func _shake_camera() -> void:
	if _camera == null:
		return
	_camera.offset = Vector2(-8.0, 0.0)
	var tween := create_tween()
	tween.tween_property(_camera, "offset", Vector2(7.0, 0.0), 0.05)
	tween.tween_property(_camera, "offset", Vector2(-5.0, 2.0), 0.05)
	tween.tween_property(_camera, "offset", Vector2(3.0, -1.0), 0.05)
	tween.tween_property(_camera, "offset", Vector2.ZERO, 0.08)

func _spawn_command_vfx(target: BattleUnit, heroes: Array[BattleUnit]) -> void:
	if _vfx_layer == null or target == null:
		return
	for hero: BattleUnit in heroes:
		if hero == null or not hero.is_alive():
			continue
		_spawn_command_line(hero, target)
	_spawn_command_banner(target, heroes.size())

func _spawn_command_line(hero: BattleUnit, target: BattleUnit) -> void:
	var line := Line2D.new()
	line.width = 5.0
	line.default_color = Color(1.0, 0.86, 0.18, 0.78)
	line.z_index = VFX_RALLY_Z - 1
	line.points = PackedVector2Array([
		field_to_screen(hero.px, hero.py) + Vector2(0.0, -44.0),
		field_to_screen(target.px, target.py) + Vector2(0.0, -72.0),
	])
	_vfx_layer.add_child(line)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(line, "width", 1.0, 0.36)
	tween.tween_property(line, "modulate:a", 0.0, 0.36).set_delay(0.08)
	tween.set_parallel(false)
	tween.tween_callback(Callable(line, "queue_free"))

func _spawn_command_banner(target: BattleUnit, hero_count: int) -> void:
	var label := Label.new()
	label.text = _BattleCommandFeedback.command_banner(target, hero_count)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = field_to_screen(target.px, target.py) + Vector2(-120.0, -148.0)
	label.size = Vector2(240.0, 58.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = VFX_RALLY_Z
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.0, 0.92))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	if _damage_font != null:
		label.add_theme_font_override("font", _damage_font)
	label.modulate = Color(1.0, 0.86, 0.22, 1.0)
	_vfx_layer.add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 32.0, 0.62).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.62).set_delay(0.16)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _spawn_damage_number(event: Dictionary) -> void:
	if _vfx_layer == null:
		return
	while _vfx_layer.get_child_count() >= MAX_FLOATING_DAMAGE_LABELS:
		var oldest := _vfx_layer.get_child(0)
		_vfx_layer.remove_child(oldest)
		oldest.queue_free()
	var amount := int(event.get("amount", 0))
	var kind := String(event.get("kind", "attack"))
	var is_crit := bool(event.get("is_crit", false))
	var label := Label.new()
	label.text = "%d%s" % [amount, "!" if is_crit else ""]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = field_to_screen(float(event.get("px", 0.0)), float(event.get("py", 0.0))) + Vector2(-48.0, -96.0)
	label.size = Vector2(96.0, 34.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = VFX_FLOATING_Z
	label.add_theme_font_size_override("font_size", 27 if is_crit else 22)
	label.add_theme_color_override("font_shadow_color", Color(0.05, 0.02, 0.01, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	if _damage_font != null:
		label.add_theme_font_override("font", _damage_font)
	if kind == "skill":
		label.modulate = Color(0.78, 0.48, 1.0, 1.0)
	elif is_crit:
		label.modulate = Color(1.0, 0.20, 0.16, 1.0)
	else:
		label.modulate = Color(1.0, 0.95, 0.72, 1.0)
	_vfx_layer.add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 58.0, 0.62).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.62).set_delay(0.14)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _flash_damaged_target(event: Dictionary) -> void:
	var target: BattleUnit = event.get("target", null)
	if target == null or not _vis.has(target):
		return
	var body := _vis[target].get("body", null) as CanvasItem
	if body == null or not is_instance_valid(body):
		return
	var base_color: Color = _vis[target].get("base_color", body.modulate)
	body.modulate = Color(1.0, 1.0, 1.0)
	var tween := create_tween()
	tween.tween_property(body, "modulate", base_color, 0.12)

func _sync_deploy_panel_visibility() -> void:
	if _deploy_panel != null:
		_deploy_panel.visible = _phase != Phase.BATTLE

func _sim_units() -> Array[BattleUnit]:
	var units: Array[BattleUnit] = []
	units.append_array(_sim.player_units)
	units.append_array(_sim.enemy_units)
	return units

func _spawn_board_army() -> void:
	var board := RunManager.get_board()
	var army := CardLibrary.catalog.build_board_army(board, _lord, RunManager.get_board_rows(), RunManager.get_edicts(), RunManager.get_castle_key(), RunManager.get_terrain_perk_id(), RunManager.get_board_levels())
	for unit in army:
		_sim.add_unit(unit)
		_spawn_visual(unit)
		_update_tile_label(unit.lane, unit.row, _unit_tile_label(unit))
	_spawn_board_buildings(board)
	_refresh_unit_tile_labels()
	_refresh_board_tiles()

func _spawn_unit_for_board_key(block_key: String) -> void:
	var board := RunManager.get_board()
	if not board.has(block_key):
		return
	if _spawn_building_for_board_key(block_key, board):
		return
	var single := {}
	single[block_key] = board[block_key]
	var levels := {}
	levels[block_key] = RunManager.get_board_level(block_key)
	var army := CardLibrary.catalog.build_board_army(single, _lord, RunManager.get_board_rows(), RunManager.get_edicts(), RunManager.get_castle_key(), RunManager.get_terrain_perk_id(), levels)
	for unit in army:
		_sim.add_unit(unit)
		_spawn_visual(unit)
		_update_tile_label(unit.lane, unit.row, _unit_tile_label(unit))
	_apply_formation_tactics()

func _respawn_unit_for_board_key(block_key: String) -> void:
	var parts := block_key.split(":")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return
	var col := int(parts[0])
	var row := int(parts[1])
	var removed: Array[BattleUnit] = []
	for unit in _sim.player_units:
		if unit == null or unit.is_castle:
			continue
		if unit.lane == col and unit.row == row:
			removed.append(unit)
	for unit in removed:
		_sim.player_units.erase(unit)
		if _vis.has(unit):
			var root := _vis[unit].get("root", null) as Node
			if root != null:
				root.queue_free()
			_vis.erase(unit)
	_spawn_unit_for_board_key(block_key)

func _spawn_board_buildings(board: Dictionary) -> void:
	for entry in _BoardEconomy.buildings_on_board(board, CardLibrary.catalog):
		_spawn_building_for_board_key(String(entry.get("key", "")), board)

func _spawn_building_for_board_key(block_key: String, board: Dictionary) -> bool:
	if not board.has(block_key):
		return false
	var card := CardLibrary.get_card(StringName(board[block_key]))
	if card == null or String(card.get("card_type")) != "building":
		return false
	if _building_vis.has(block_key):
		return true
	var parts := block_key.split(":")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return true
	var col := int(parts[0])
	var row := int(parts[1])
	var center := field_to_screen_position(BattleSim.position_for_tile(col, row))
	var root := Node2D.new()
	root.position = center
	root.z_index = int(center.y) - 1
	var body := Sprite2D.new()
	body.centered = true
	var texture := _building_texture(card)
	body.texture = texture
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_fit_sprite_to_size(body, texture, Vector2(BUILDING_W, BUILDING_H))
	body.position = Vector2(0.0, -BUILDING_H * 0.48)
	root.add_child(body)
	var name_label := Label.new()
	name_label.text = card.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(-58.0, -BUILDING_H - 30.0)
	name_label.size = Vector2(116.0, 22.0)
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(name_label)
	var gold_label := Label.new()
	gold_label.text = ""
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.position = Vector2(-58.0, -BUILDING_H - 56.0)
	gold_label.size = Vector2(116.0, 26.0)
	gold_label.add_theme_font_size_override("font_size", 21)
	gold_label.add_theme_color_override("font_shadow_color", Color(0.05, 0.02, 0.01, 0.9))
	gold_label.add_theme_constant_override("shadow_offset_x", 2)
	gold_label.add_theme_constant_override("shadow_offset_y", 2)
	gold_label.modulate = Color(1.0, 0.86, 0.26, 1.0)
	gold_label.visible = false
	gold_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _damage_font != null:
		gold_label.add_theme_font_override("font", _damage_font)
	root.add_child(gold_label)
	_buildings_layer.add_child(root)
	_building_vis[block_key] = {
		"root": root,
		"gold_label": gold_label,
		"gold_per_sec": maxi(0, int(card.get("gold_per_sec"))),
	}
	return true

func _building_texture(card: CardData) -> Texture2D:
	var path := ""
	if card != null and card.id == &"building_dunjeon":
		path = "res://assets/sprites/buildings/farm.png"
	elif card != null and card.id == &"building_mangru":
		path = "res://assets/sprites/buildings/tower.png"
	if not path.is_empty() and ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		if tex != null:
			return tex
	return _placeholder_texture(int(BUILDING_W), int(BUILDING_H), Color(0.58, 0.42, 0.22))

func _apply_building_auras() -> void:
	_BoardEconomy.apply_auras(_sim.player_units, RunManager.get_board(), CardLibrary.catalog)

func _apply_formation_tactics() -> void:
	_FormationTactics.apply_to_army(_sim.player_units)
	_refresh_unit_tile_labels()

func _refresh_unit_tile_labels() -> void:
	for unit in _sim.player_units:
		if unit == null or unit.is_castle or unit.row < 0:
			continue
		_update_tile_label(unit.lane, unit.row, _unit_tile_label(unit))

func _apply_scheme_battle_result(result: Dictionary) -> void:
	var battle: Dictionary = result.get("battle", {})
	if battle.is_empty():
		return
	var castle_delta := maxi(0, int(battle.get("castle_hp_delta", 0)))
	if castle_delta > 0:
		_sim.apply_battle_effect({"castle_hp_delta": castle_delta})
	if battle.has("damage_enemy"):
		var damage: Dictionary = battle.get("damage_enemy", {})
		var effect := {"damage_enemy": damage.duplicate(true)}
		if _sim.enemy_units.is_empty():
			_pending_scheme_battle_effects.append(effect)
		else:
			_sim.apply_battle_effect(effect)
			_play_damage_events()
	_sync_visuals()

func _apply_pending_scheme_battle_effects() -> void:
	if _pending_scheme_battle_effects.is_empty():
		return
	var remaining: Array[Dictionary] = []
	for effect in _pending_scheme_battle_effects:
		if _sim.enemy_units.is_empty():
			remaining.append(effect)
			continue
		_sim.apply_battle_effect(effect)
	_pending_scheme_battle_effects = remaining

func _accumulate_building_gold(delta: float) -> void:
	if _battle_gold_per_sec <= 0:
		return
	_battle_gold_accum += float(_battle_gold_per_sec) * delta
	_update_building_gold_labels()

func _update_building_gold_labels() -> void:
	var total := int(floor(_battle_gold_accum))
	for data in _building_vis.values():
		var label := data.get("gold_label", null) as Label
		if label == null:
			continue
		var rate := int(data.get("gold_per_sec", 0))
		label.visible = rate > 0 and (_phase == Phase.BATTLE or total > 0)
		if rate > 0:
			label.text = "+%d" % total

func _ensure_castle() -> void:
	var castle_key := RunManager.get_castle_key()
	if castle_key == "":
		return
	var parts := castle_key.split(":")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return
	var pos := BattleSim.position_for_tile(int(parts[0]), int(parts[1]))
	var hp := int(round(BattleSim.CASTLE_HP * (1.0 + _EdictCatalog.castle_hp_pct(RunManager.get_edicts()))))
	var castle := _sim.add_castle_at(pos.x, pos.y, hp)
	if not _vis.has(castle):
		_spawn_visual(castle)

func _unit_texture(u: BattleUnit) -> Texture2D:
	var path := _unit_texture_path(u)
	if not path.is_empty() and ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		if tex != null:
			return tex
	var size := _unit_size(u)
	return _placeholder_texture(int(size.x), int(size.y), _unit_color(u))

func _create_unit_body(u: BattleUnit, fallback_texture: Texture2D, target_size: Vector2) -> Node2D:
	if _uses_formation_visual(u):
		return _create_formation_body(u)
	return _create_single_unit_body(u, fallback_texture, target_size, _unit_walk_sheet_path(u))

func _create_single_unit_body(u: BattleUnit, fallback_texture: Texture2D, target_size: Vector2, walk_sheet_path: String = "") -> Node2D:
	if not walk_sheet_path.is_empty() and ResourceLoader.exists(walk_sheet_path):
		var walk_sheet := load(walk_sheet_path) as Texture2D
		if walk_sheet != null:
			var animated := AnimatedSprite2D.new()
			animated.centered = true
			animated.sprite_frames = _build_walk_sprite_frames(walk_sheet)
			animated.animation = &"walk"
			animated.frame = 0
			animated.stop()
			var frame_texture := animated.sprite_frames.get_frame_texture(&"walk", 0)
			_apply_unit_body_visuals(animated, u, frame_texture, target_size)
			return animated
	var sprite := Sprite2D.new()
	sprite.centered = true
	sprite.texture = fallback_texture
	_apply_unit_body_visuals(sprite, u, fallback_texture, target_size)
	return sprite

func _create_formation_body(u: BattleUnit) -> Node2D:
	var group := Node2D.new()
	if String(u.card_id).begins_with("general_"):
		_add_retinue_members(group, u)
		var main_texture := _unit_texture(u)
		var main := _create_single_unit_body(u, main_texture, Vector2(GENERAL_BODY_W, GENERAL_BODY_H), _unit_walk_sheet_path(u))
		main.position += Vector2(0.0, -18.0)
		main.z_index = 20
		group.add_child(main)
	else:
		var count := mini(maxi(1, u.squad_count), _BattleFeel.TROOP_VISIBLE_CAP)
		var texture_path := _unit_texture_path_for_troop_type(u, u.troop_type)
		var texture := _texture_or_placeholder(texture_path, Vector2(UNIT_MEMBER_W, UNIT_MEMBER_H), _unit_color(u))
		var walk_path := _walk_sheet_path_for_texture(texture_path)
		var offsets := _FormationRenderer.troop_offsets(count)
		for i in count:
			var member := _create_single_unit_body(u, texture, Vector2(UNIT_MEMBER_W, UNIT_MEMBER_H), walk_path)
			member.position += offsets[i]
			member.z_index = i
			group.add_child(member)
	return group

func _add_retinue_members(group: Node2D, u: BattleUnit) -> void:
	var retinue := mini(maxi(0, u.retinue_count), _BattleFeel.RETINUE_VISIBLE_CAP)
	if retinue <= 0:
		return
	var texture_path := _unit_texture_path_for_troop_type(u, u.troop_type)
	var texture := _texture_or_placeholder(texture_path, Vector2(UNIT_MEMBER_W, UNIT_MEMBER_H), _unit_color(u))
	var walk_path := _walk_sheet_path_for_texture(texture_path)
	var offsets := _FormationRenderer.retinue_offsets(retinue)
	for i in retinue:
		var member := _create_single_unit_body(u, texture, Vector2(42.0, 48.0), walk_path)
		member.position += offsets[i]
		member.z_index = i
		group.add_child(member)

func _apply_unit_body_visuals(body: Node2D, u: BattleUnit, texture: Texture2D, target_size: Vector2) -> void:
	if body == null:
		return
	var item := body as CanvasItem
	if item != null:
		item.modulate = Color.WHITE
		item.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if body is Sprite2D:
		(body as Sprite2D).flip_h = u.team == BattleUnit.Team.ENEMY
	elif body is AnimatedSprite2D:
		(body as AnimatedSprite2D).flip_h = u.team == BattleUnit.Team.ENEMY
	_fit_sprite_to_size(body, texture, target_size)
	body.position = Vector2(0.0, -target_size.y * 0.5)

func _build_walk_sprite_frames(sheet: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(&"walk")
	frames.set_animation_speed(&"walk", WALK_FPS)
	frames.set_animation_loop(&"walk", true)
	var sheet_size := sheet.get_size()
	var frame_width := sheet_size.x / float(WALK_FRAME_COUNT)
	for i in range(WALK_FRAME_COUNT):
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(frame_width * float(i), 0.0, frame_width, sheet_size.y)
		frames.add_frame(&"walk", atlas)
	return frames

func _unit_walk_sheet_path(u: BattleUnit) -> String:
	if u.is_castle:
		return ""
	var texture_path := _unit_texture_path(u)
	return _walk_sheet_path_for_texture(texture_path)

func _walk_sheet_path_for_texture(texture_path: String) -> String:
	if texture_path.ends_with(".png"):
		return texture_path.trim_suffix(".png") + "_walk.png"
	return ""

func _uses_formation_visual(u: BattleUnit) -> bool:
	if u == null or u.is_castle or _is_boss(u):
		return false
	return u.squad_count > 1 or u.retinue_count > 0

func _texture_or_placeholder(path: String, size: Vector2, color: Color) -> Texture2D:
	if not path.is_empty() and ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		if tex != null:
			return tex
	return _placeholder_texture(int(size.x), int(size.y), color)

func _unit_texture_path_for_troop_type(u: BattleUnit, troop_type: String) -> String:
	var faction := String(RunManager.player_faction()) if u.team == BattleUnit.Team.PLAYER else "demon"
	return "res://assets/sprites/units/%s/%s.png" % [faction, troop_type]

func _formation_offsets(count: int, columns: int, dx: float, dy: float) -> Array[Vector2]:
	return _FormationRenderer.member_offsets(count, columns, dx, dy)

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

func _player_realm() -> String:
	if _lord != null:
		return String(_lord.realm)
	var lord := CardLibrary.get_lord(RunManager.state.lord_id)
	if lord == null:
		return "mortal"
	return String(lord.realm)

func _fit_sprite_to_size(sprite: Node2D, texture: Texture2D, target_size: Vector2) -> void:
	if sprite == null or texture == null:
		return
	var source_size := texture.get_size()
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		return
	var scale_factor := minf(target_size.x / source_size.x, target_size.y / source_size.y)
	sprite.scale = Vector2(scale_factor, scale_factor)

func _unit_texture_path(u: BattleUnit) -> String:
	if u.is_castle:
		return "res://assets/sprites/buildings/castle.png"
	var faction := String(RunManager.player_faction()) if u.team == BattleUnit.Team.PLAYER else "demon"
	if _is_boss(u):
		return _boss_texture_path(u, faction)
	if u.team == BattleUnit.Team.PLAYER and not u.card_id.is_empty():
		var general_path := "res://assets/sprites/units/%s/%s.png" % [faction, String(u.card_id)]
		if ResourceLoader.exists(general_path):
			return general_path
	return "res://assets/sprites/units/%s/%s.png" % [faction, u.troop_type]

func _boss_texture_path(u: BattleUnit, fallback_faction: String) -> String:
	var mapped_path: String = String(BOSS_TEXTURE_PATHS.get(u.display_name, ""))
	if mapped_path != "" and ResourceLoader.exists(mapped_path):
		return mapped_path
	return "res://assets/sprites/units/%s/boss_dongzhuo.png" % fallback_faction

func _placeholder_texture(width: int, height: int, color: Color) -> Texture2D:
	var key := "%d:%d:%s" % [width, height, color.to_html(true)]
	if _placeholder_textures.has(key):
		return _placeholder_textures[key]
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(color)
	var texture := ImageTexture.create_from_image(image)
	_placeholder_textures[key] = texture
	return texture

func _unit_size(u: BattleUnit) -> Vector2:
	if u.is_castle:
		return Vector2(CASTLE_W, CASTLE_H)
	if _is_boss(u):
		return Vector2(BOSS_W, BOSS_H)
	if String(u.card_id).begins_with("general_"):
		return Vector2(GENERAL_W, GENERAL_H)
	return Vector2(UNIT_W, UNIT_H)

func _unit_color(u: BattleUnit) -> Color:
	if u.is_castle:
		return Color(0.62, 0.56, 0.40)
	if u.team == BattleUnit.Team.PLAYER:
		return Color(0.25, 0.70, 0.55)
	if _is_boss(u):
		return Color(0.64, 0.12, 0.32)
	return Color(0.62, 0.18, 0.42)

func _is_boss(u: BattleUnit) -> bool:
	return WaveFactory.is_boss_name(u.display_name)

func _apply_hero_command_at(screen_pos: Vector2) -> void:
	var target := _enemy_near_screen_pos(screen_pos)
	if target == null:
		_clear_hero_command(true, _BattleCommandFeedback.no_target_hint())
		return
	var heroes := _controllable_heroes()
	if heroes.is_empty():
		_clear_hero_command(false)
		_hint_label.text = _BattleCommandFeedback.no_heroes_hint()
		_sync_hud()
		return
	for hero in heroes:
		hero.commanded_target = target
	_commanded_target = target
	_hint_label.text = _BattleCommandFeedback.command_hint(target, heroes.size())
	AudioManager.play_sfx(&"ui")
	_spawn_command_vfx(target, heroes)
	_sync_visuals()

func _clear_hero_command(update_hint: bool = true, hint_text: String = "") -> void:
	for hero in _controllable_heroes():
		hero.commanded_target = null
	_commanded_target = null
	if update_hint and _phase == Phase.BATTLE:
		_hint_label.text = hint_text if not hint_text.is_empty() else "자동 표적"
	_sync_hud()

func _prune_command_target() -> void:
	if _commanded_target == null:
		return
	if _commanded_target.is_alive() and _sim.enemy_units.has(_commanded_target):
		return
	var target_name := _commanded_target.display_name
	_clear_hero_command(true, _BattleCommandFeedback.defeated_target_hint(target_name))

func _controllable_heroes() -> Array[BattleUnit]:
	var heroes: Array[BattleUnit] = []
	for u in _sim.player_units:
		if u != null and u.is_alive() and u.controllable:
			heroes.append(u)
	return heroes

func _enemy_near_screen_pos(screen_pos: Vector2) -> BattleUnit:
	var field_pos := _screen_to_field(screen_pos)
	return _BattleCommandFeedback.nearest_enemy_to_field(field_pos, _sim.enemy_units, COMMAND_PICK_RADIUS)

func _screen_to_field(screen_pos: Vector2) -> Vector2:
	return Vector2(
		(screen_pos.x - VIEW_ORIGIN.x) / VIEW_SCALE_X,
		(screen_pos.y - VIEW_ORIGIN.y) / VIEW_SCALE_Y
	)

func _tile_key(col: int, row: int) -> String:
	return "%d:%d" % [col, row]

func _update_tile_label(col: int, row: int, text: String) -> void:
	var tile: Dictionary = _tile_buttons.get(_tile_key(col, row), {})
	var label := tile.get("label", null) as Label
	if label != null:
		label.text = text

func _unit_tile_label(unit: BattleUnit) -> String:
	if unit == null:
		return ""
	var base := unit.display_name
	if unit.squad_level > 1:
		base = "%s Lv.%d" % [unit.display_name, unit.squad_level]
	var tags := _FormationTactics.tag_text_for_unit(unit, _sim.player_units)
	if not tags.is_empty():
		return "%s · %s" % [base, tags]
	return base

func _unit_visual_offset(u: BattleUnit) -> Vector2:
	var index := 0
	for other in _sim_units():
		if other == u:
			break
		if other.team == u.team and other.position().distance_to(u.position()) < 4.0:
			index += 1
	return Vector2(float((index % 3) - 1) * 18.0, float(index / 3) * 14.0)

func _fade_iso_tiles_out() -> void:
	for tile in _tile_buttons.values():
		var area := tile.get("area", null) as Area2D
		if area != null:
			area.input_pickable = false
	if _iso_base_layer == null:
		return
	var tween := create_tween()
	tween.tween_property(_iso_base_layer, "modulate:a", 0.0, 0.22)
	tween.tween_callback(func() -> void:
		_iso_base_layer.visible = false
		_iso_base_layer.modulate.a = 1.0
	)

func _update_wave_label() -> void:
	if _wave_label == null:
		return
	if _sim.wave_total <= 0:
		_wave_label.text = "교전 - / -"
		_wave_label.visible = false
		return
	_wave_label.text = "교전 %d / %d" % [_sim.wave_index, _sim.wave_total]
	_wave_label.visible = _phase != Phase.DEPLOY

# ── 종료 · 전리(보상) ───────────────────────────────────────
func _end_battle() -> void:
	_phase = Phase.DONE
	# 재정(財政) 칙령은 둔전 생산 골드(_battle_gold_accum)에만 적용 — 우물 골드(discard 보상)는 제외(feat-021 설계).
	var produced_gold := int(floor(_battle_gold_accum))
	if produced_gold > 0:
		var gold_bonus_pct := _EdictCatalog.gold_pct(RunManager.get_edicts()) + RunManager.gold_reward_pct()
		var gold := int(round(produced_gold * (1.0 + gold_bonus_pct)))
		RunManager.add_gold(gold)
		_update_building_gold_labels()
		_sync_hud()
	_sync_deploy_panel_visibility()
	_command_toggle_active = false
	_clear_hero_command(false)
	_result_label.visible = true
	var win := _sim.result == BattleSim.Result.PLAYER_WIN
	_battle_outcome = RunManager.record_battle_outcome(win)
	var run_victory := bool(_battle_outcome.get("run_victory", false))
	if win:
		AudioManager.play_sfx(&"victory")
		_result_label.text = "구주 정복!" if run_victory else "승리!"
		_result_label.modulate = Color(0.5, 1.0, 0.5)
		_hint_label.text = "최종 보스를 격파했습니다." if run_victory else "전리품을 고르세요."
		EventBus.battle_won.emit()
	else:
		AudioManager.play_sfx(&"defeat")
		_result_label.text = "런 실패"
		_result_label.modulate = Color(1.0, 0.5, 0.5)
		_hint_label.text = "전투 종료."
		EventBus.battle_lost.emit()
	_build_outcome_ui(win)

func _build_outcome_ui(win: bool) -> void:
	var box := _new_overlay_box()
	_add_profile_result_summary(box, _battle_outcome)
	if not win:
		var fail := Label.new()
		fail.text = "런 실패"
		fail.add_theme_font_size_override("font_size", 24)
		fail.add_theme_color_override("font_color", Color(1.0, 0.62, 0.62))
		box.add_child(fail)
		box.add_child(_make_button("군주 선택으로 새 런", _restart_run))
		return
	if bool(_battle_outcome.get("run_victory", false)):
		var clear := Label.new()
		clear.text = "런 승리 — 구주 정복"
		clear.add_theme_font_size_override("font_size", 24)
		clear.add_theme_color_override("font_color", Color(0.72, 1.0, 0.78))
		box.add_child(clear)
		box.add_child(_make_button("군주 선택으로 새 런", _restart_run))
		return
	var candidates := RunManager.reward_candidates(RunManager.reward_choice_count(3))
	_add_expand_reward_notice(box)
	if candidates.is_empty():
		var none := Label.new()
		none.text = "획득 가능한 보상이 없습니다."
		none.add_theme_color_override("font_color", Color(0.96, 0.90, 0.74))
		box.add_child(none)
		_advance_stage_once()
		_add_next_stage_button(box)
		return
	var head := Label.new()
	head.text = "전리품 — 한 장을 고르세요"
	head.add_theme_font_size_override("font_size", 24)
	head.add_theme_color_override("font_color", Color(0.96, 0.90, 0.74))
	box.add_child(head)
	var reward_guide := Label.new()
	reward_guide.text = "카드 버튼을 누르면 보상이 적용되고 다음 스테이지 버튼이 열립니다."
	reward_guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward_guide.add_theme_font_size_override("font_size", 18)
	reward_guide.add_theme_color_override("font_color", Color(0.86, 0.90, 1.0))
	box.add_child(reward_guide)
	var choice_context := _CardChoiceAdvisor.context(
		RunManager.get_board(),
		RunManager.get_board_levels(),
		RunManager.get_hand(),
		RunManager.get_gold(),
		CardLibrary.catalog
	)
	candidates = _CardChoiceAdvisor.ranked_ids(
		candidates,
		choice_context,
		CardLibrary.catalog,
		_CardChoiceAdvisor.MODE_REWARD
	)
	for id in candidates:
		var card := CardLibrary.get_card(id)
		var advice_line := _CardChoiceAdvisor.line_for_card(card, choice_context, _CardChoiceAdvisor.MODE_REWARD)
		var reward_button := _make_button("선택 — %s (%d) — %s\n%s" % [card.display_name, card.cost, _card_brief(card), advice_line], _pick_reward.bind(id))
		reward_button.tooltip_text = "이 전리품을 선택합니다.\n%s\n%s" % [
			_CardUiText.tooltip(card),
			_CardChoiceAdvisor.tooltip_for_card(card, choice_context, _CardChoiceAdvisor.MODE_REWARD),
		]
		box.add_child(reward_button)

func _add_expand_reward_notice(box: VBoxContainer) -> void:
	if not RunManager.is_expand_stage():
		return
	if RunManager.get_board_rows() >= RunState.BOARD_ROWS_MAX:
		return
	var before := RunManager.get_board_rows()
	if RunManager.expand_board():
		_hint_label.text = "보드 확장 — %d행" % RunManager.get_board_rows()
		var got := Label.new()
		got.text = "보드 확장 — %d→%d행" % [before, RunManager.get_board_rows()]
		got.add_theme_font_size_override("font_size", 22)
		got.add_theme_color_override("font_color", Color(0.72, 1.0, 0.60))
		box.add_child(got)

func _pick_reward(id: StringName) -> void:
	var card := CardLibrary.get_card(id)
	var got_name := card.display_name if card != null else String(id)
	var acquired := RunManager.acquire_card(id)
	if not acquired:
		_hint_label.text = "획득 실패 — %s" % got_name
		return
	EventBus.card_rewarded.emit(id)
	_hint_label.text = _CardUiText.acquisition_hint(card, got_name)
	_advance_stage_once()
	var box := _new_overlay_box()
	_add_profile_result_summary(box, _battle_outcome)
	var got := Label.new()
	got.text = _CardUiText.acquisition_hint(card, got_name)
	got.add_theme_font_size_override("font_size", 24)
	got.add_theme_color_override("font_color", Color(0.72, 1.0, 0.78))
	box.add_child(got)
	_add_next_stage_button(box)

func _add_next_stage_button(box: VBoxContainer) -> void:
	box.add_child(_make_button("다음 스테이지로 (보드 %d장 / 손패 %d장)" % [RunManager.get_deck().size(), RunManager.get_hand().size()], _go_to_run_map))
	box.add_child(_make_button("군주 선택으로 새 런", _restart_run))

func _advance_stage_once() -> void:
	if _stage_advanced:
		return
	RunManager.advance_stage()
	_stage_advanced = true

func _go_to_run_map() -> void:
	GameManager.change_scene("res://scenes/screens/run_map.tscn")

func _restart_run() -> void:
	RunManager.reset_run()
	GameManager.change_scene(LORD_SELECT_SCENE)

func _add_profile_result_summary(box: VBoxContainer, outcome: Dictionary) -> void:
	if outcome.is_empty():
		return
	var profile := RunManager.get_profile()
	var summary := Label.new()
	summary.text = "기록 — 스테이지 %d · 점수 %d · 최고 %d/%d" % [
		int(outcome.get("stage", RunManager.stage_index())),
		int(outcome.get("score", 0)),
		profile.best_stage,
		profile.best_score,
	]
	summary.add_theme_font_size_override("font_size", 20)
	summary.add_theme_color_override("font_color", Color(0.86, 0.90, 1.0))
	box.add_child(summary)

	var unlocked_lords: Array = outcome.get("unlocked_lords", [])
	for lord_id in unlocked_lords:
		var lord := CardLibrary.get_lord(StringName(lord_id))
		var lord_name := lord.display_name if lord != null else String(lord_id)
		var unlock := Label.new()
		unlock.text = "해금 — %s" % lord_name
		unlock.add_theme_font_size_override("font_size", 22)
		unlock.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
		box.add_child(unlock)

# ── 헬퍼 ────────────────────────────────────────────────────
func _new_overlay_box() -> VBoxContainer:
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.queue_free()
	var panel := PanelContainer.new()
	panel.theme = _hud_theme
	panel.position = Vector2(560.0, 180.0)
	panel.custom_minimum_size = Vector2(980.0, 0.0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _stylebox(Color(0.12, 0.08, 0.04, 0.88), Color(0.95, 0.67, 0.24, 0.95), 2, 8))
	_deploy_panel.add_child(panel)
	_overlay = panel

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(948.0, 0.0)
	box.add_theme_constant_override("separation", 10)
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	margin.add_child(box)
	return box

func _make_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.theme = _hud_theme
	b.text = text
	b.custom_minimum_size = Vector2(0.0, 40.0)
	b.pressed.connect(cb)
	return b

func _card_brief(card: CardData) -> String:
	return _CardUiText.battle_brief(card)

func _card_type_label(card: CardData) -> String:
	return _CardUiText.type_label(card)

func _nation_label() -> String:
	if _lord == null:
		return "?"
	match _lord.nation:
		&"wei":
			return "위"
		&"wu":
			return "오"
		_:
			return "촉"

func _selected_hand_card() -> CardData:
	var hand := RunManager.get_hand()
	if _selected_hand_index < 0 or _selected_hand_index >= hand.size():
		return null
	return CardLibrary.get_card(StringName(hand[_selected_hand_index]))

func _hand_card_tooltip(card: CardData, upgrades_existing: bool = false) -> String:
	var text := _CardUiText.tooltip(card)
	if card == null:
		return text
	var action := _CardUiText.deploy_action_label(card, upgrades_existing)
	text = "%s\n행동 — %s" % [text, action]
	match String(card.get("card_type")):
		"scheme":
			return "%s\n계략 발동 버튼으로 사용합니다." % text
		"building":
			return "%s\n빈 타일을 클릭해 건물로 배치하거나 우물로 보낼 수 있습니다." % text
		"treasure":
			return "%s\n보패는 획득 즉시 장착되어 손패에 남지 않아야 합니다." % text
		_:
			return "%s\n빈 타일을 클릭해 배치하거나 우물로 보낼 수 있습니다." % text

func _scheme_button_tooltip(card: CardData) -> String:
	if _phase != Phase.DEPLOY:
		return "전투 중에는 새 계략을 발동할 수 없습니다."
	if card == null:
		return "손패에서 계략 카드를 선택하면 발동할 수 있습니다."
	if String(card.get("card_type")) != "scheme":
		return "선택한 카드는 계략이 아닙니다.\n%s" % _CardUiText.tooltip(card)
	return "선택한 계략을 발동합니다.\n%s" % _CardUiText.tooltip(card)

func _well_button_tooltip(card: CardData) -> String:
	if _phase != Phase.DEPLOY:
		return "전투 중에는 우물을 사용할 수 없습니다."
	if card == null:
		return "손패 카드를 선택하면 버리고 +%d골드를 얻을 수 있습니다." % RunState.WELL_GOLD
	if not RunManager.has_castle():
		return "먼저 성 위치를 고르세요.\n%s" % _CardUiText.tooltip(card)
	if not RunManager.can_place_deploy_card():
		return "이번 교전에는 이미 한 장을 냈습니다.\n%s" % _CardUiText.tooltip(card)
	if RunManager.board_unit_count() <= 0:
		return "우물은 이미 전투할 보드 군세가 있을 때만 이번 한 수로 사용할 수 있습니다.\n%s" % _CardUiText.tooltip(card)
	return "선택한 카드를 우물에 보내고 +%d골드를 얻은 뒤 이번 한 수로 교전합니다.\n%s" % [RunState.WELL_GOLD, _CardUiText.tooltip(card)]

func _scheme_result_brief(result: Dictionary) -> String:
	if result.is_empty():
		return ""
	var run: Dictionary = result.get("run", {})
	if run.has("gold_delta"):
		return " (+%d골드)" % int(run.get("gold_delta", 0))
	var battle: Dictionary = result.get("battle", {})
	if battle.has("damage_enemy"):
		var damage: Dictionary = battle.get("damage_enemy", {})
		return " (피해 %d)" % int(damage.get("amount", 0))
	if battle.has("castle_hp_delta"):
		return " (성 +%d)" % int(battle.get("castle_hp_delta", 0))
	return ""

func _board_unit_count() -> int:
	var count := 0
	for u in _sim.player_units:
		if u != null and not u.is_castle:
			count += 1
	return count

func _block_label(block_key: String) -> String:
	var parts := block_key.split(":")
	if parts.size() != 2:
		return block_key
	return "%d열 %d행" % [int(parts[0]) + 1, int(parts[1]) + 1]
