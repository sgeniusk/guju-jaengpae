# 전투 화면 — 군주의 덱을 3×3 시작 진형에 배치하고 "전투 시작"을 누르면 2D 오픈필드 오토배틀이 진행된다.
# 순수 전투 로직은 BattleSim에 있다. 이 스크립트는 입력·배치 UI·유닛 시각화만 담당한다.
extends Control

enum Phase { DEPLOY, BATTLE, DONE }

const LORD_ID := &"lord_liubei"
const START_POINTS := 12

const FIELD_LEFT := 560.0
const FIELD_RIGHT := 1840.0
const FIELD_TOP := 120.0
const FIELD_BOTTOM := 900.0
const TILE_W := 150.0
const TILE_H := 82.0
const UNIT_W := 70.0
const UNIT_H := 52.0

var _phase: int = Phase.DEPLOY
var _sim := BattleSim.new()
var _lord: LordData
var _points: int = START_POINTS
var _max_points: int = START_POINTS
var _vis: Dictionary = {}            # BattleUnit -> { root: Control, hp: ColorRect }
var _tile_buttons: Dictionary = {}   # "col:row" -> Button
var _occupied_tiles: Dictionary = {} # "col:row" -> BattleUnit
var _selected_card_id: StringName = &""
var _node_completed := false

var _units_layer: Control
var _points_label: Label
var _wave_label: Label
var _hint_label: Label
var _start_button: Button
var _result_label: Label
var _overlay: Control            # 승리 보상 / 패배 재시도 패널

func _ready() -> void:
	_lord = CardLibrary.get_lord(LORD_ID)
	RunManager.ensure_started(LORD_ID)
	_max_points = RunManager.get_command_points()
	_points = _max_points
	_build_field()
	_ensure_castle()
	_build_panel()
	if _lord == null:
		_hint_label.text = "오류 — 군주(%s)를 불러오지 못했습니다." % LORD_ID

func _process(delta: float) -> void:
	if _phase != Phase.BATTLE:
		return
	_sim.step(delta)
	_sync_visuals()
	_flash_skill_casts()
	if _sim.is_over():
		_end_battle()

# ── 화면 구성 ───────────────────────────────────────────────
func _build_field() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.08, 0.11)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var field := ColorRect.new()
	field.color = Color(0.12, 0.15, 0.10)
	field.position = Vector2(FIELD_LEFT, FIELD_TOP)
	field.size = Vector2(FIELD_RIGHT - FIELD_LEFT, FIELD_BOTTOM - FIELD_TOP)
	add_child(field)
	for col in BattleSim.COL_COUNT:
		var guide := ColorRect.new()
		guide.color = Color(0.20, 0.24, 0.16, 0.45)
		guide.position = Vector2(FIELD_LEFT, _map_py(BattleSim.start_y_for_col(col)) - 2.0)
		guide.size = Vector2(FIELD_RIGHT - FIELD_LEFT, 4.0)
		add_child(guide)
	var p_base := ColorRect.new()
	p_base.color = Color(0.25, 0.4, 0.75)
	p_base.position = Vector2(FIELD_LEFT - 16.0, FIELD_TOP)
	p_base.size = Vector2(8.0, FIELD_BOTTOM - FIELD_TOP)
	add_child(p_base)
	var e_base := ColorRect.new()
	e_base.color = Color(0.75, 0.25, 0.25)
	e_base.position = Vector2(FIELD_RIGHT + 8.0, FIELD_TOP)
	e_base.size = Vector2(8.0, FIELD_BOTTOM - FIELD_TOP)
	add_child(e_base)
	for col in BattleSim.COL_COUNT:
		for row in BattleSim.ROW_COUNT:
			var tile := Button.new()
			tile.position = _tile_position(col, row)
			tile.size = Vector2(TILE_W, TILE_H)
			tile.text = ""
			tile.add_theme_font_size_override("font_size", 15)
			tile.pressed.connect(_on_tile_pressed.bind(col, row))
			add_child(tile)
			_tile_buttons[_tile_key(col, row)] = tile
	_units_layer = Control.new()
	_units_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_units_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_units_layer)
	# 결과 오버레이
	_result_label = Label.new()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.position = Vector2(FIELD_LEFT, 32.0)
	_result_label.size = Vector2(FIELD_RIGHT - FIELD_LEFT, 70.0)
	_result_label.add_theme_font_size_override("font_size", 56)
	_result_label.visible = false
	add_child(_result_label)

func _build_panel() -> void:
	var panel := VBoxContainer.new()
	panel.position = Vector2(28.0, 28.0)
	panel.custom_minimum_size = Vector2(440.0, 0.0)
	panel.add_theme_constant_override("separation", 10)
	add_child(panel)

	var title := Label.new()
	var lord_name := _lord.display_name if _lord != null else "?"
	title.text = "군주 — %s (촉)" % lord_name
	title.add_theme_font_size_override("font_size", 26)
	panel.add_child(title)

	if _lord != null and _lord.trait_name != "":
		var trait_label := Label.new()
		trait_label.text = "특성 — %s" % _lord.trait_name
		trait_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel.add_child(trait_label)

	_points_label = Label.new()
	_points_label.add_theme_font_size_override("font_size", 22)
	panel.add_child(_points_label)
	_update_points()

	_wave_label = Label.new()
	_wave_label.add_theme_font_size_override("font_size", 22)
	_wave_label.visible = false
	panel.add_child(_wave_label)
	_update_wave_label()

	var guide := Label.new()
	guide.text = "카드를 선택한 뒤 전장 타일을 클릭해 배치하세요."
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(guide)

	# 덱 카드 행 (런 상태의 현재 덱 — 시작 덱 + 전리 보상)
	for card_id in RunManager.get_deck():
		panel.add_child(_make_card_row(card_id))

	_start_button = Button.new()
	_start_button.text = "전투 시작"
	_start_button.custom_minimum_size = Vector2(0.0, 44.0)
	_start_button.pressed.connect(_on_start_pressed)
	panel.add_child(_start_button)

	_hint_label = Label.new()
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.modulate = Color(1.0, 0.8, 0.4)
	panel.add_child(_hint_label)

func _make_card_row(card_id: StringName) -> Control:
	var card := CardLibrary.get_card(card_id)
	var row := HBoxContainer.new()
	var name_label := Label.new()
	if card != null:
		name_label.text = "%s (%d)" % [card.display_name, card.cost]
	else:
		name_label.text = String(card_id)
	name_label.custom_minimum_size = Vector2(300.0, 0.0)
	row.add_child(name_label)
	var b := Button.new()
	b.text = "선택"
	b.custom_minimum_size = Vector2(84.0, 0.0)
	b.pressed.connect(_on_card_selected.bind(card_id))
	row.add_child(b)
	return row

# ── 입력 ────────────────────────────────────────────────────
func _on_card_selected(card_id: StringName) -> void:
	if _phase != Phase.DEPLOY:
		return
	var card := CardLibrary.get_card(card_id)
	if card == null:
		return
	_selected_card_id = card_id
	_hint_label.text = "%s 선택됨 — 빈 타일을 클릭하세요." % card.display_name

func _on_tile_pressed(col: int, row: int) -> void:
	if _phase != Phase.DEPLOY or _lord == null:
		return
	if _selected_card_id == &"":
		_hint_label.text = "먼저 배치할 카드를 선택하세요."
		return
	var key := _tile_key(col, row)
	if _occupied_tiles.has(key):
		_hint_label.text = "이미 배치된 타일입니다."
		return
	var card_id := _selected_card_id
	var card := CardLibrary.get_card(card_id)
	if card == null:
		return
	if _points < card.cost:
		_hint_label.text = "지휘력이 부족합니다 (필요 %d)." % card.cost
		return
	var start := BattleSim.position_for_tile(col, row)
	var u := CardLibrary.build_player_unit(card_id, col, start.x, _lord)
	if u == null:
		return
	u.row = row
	u.set_position(start.x, start.y)
	_sim.add_unit(u)
	_spawn_visual(u)
	_occupied_tiles[key] = u
	_update_tile_label(col, row, u.display_name)
	_points -= card.cost
	_update_points()
	_hint_label.text = "%s → 시작 진형 %d열 %d행 배치" % [card.display_name, col + 1, row + 1]

func _on_start_pressed() -> void:
	if _phase != Phase.DEPLOY:
		return
	_ensure_castle()
	if _sim.player_units.is_empty():
		_hint_label.text = "최소 한 유닛을 배치해야 합니다."
		return
	_sim.set_waves(WaveFactory.waves_for_node(RunManager.active_node_type()))
	_phase = Phase.BATTLE
	_sync_visuals()
	_start_button.disabled = true
	_hint_label.text = "전투 중…"

# ── 시각화 ──────────────────────────────────────────────────
func _spawn_visual(u: BattleUnit) -> void:
	var root := Control.new()
	root.size = Vector2(UNIT_W, UNIT_H)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var body := ColorRect.new()
	if u.is_castle:
		body.color = Color(0.62, 0.56, 0.40)
	else:
		body.color = Color(0.32, 0.52, 0.9) if u.team == BattleUnit.Team.PLAYER else Color(0.85, 0.32, 0.32)
	body.size = Vector2(UNIT_W, UNIT_H)
	body.position = Vector2.ZERO
	root.add_child(body)
	var hp_bg := ColorRect.new()
	hp_bg.color = Color(0, 0, 0, 0.6)
	hp_bg.position = Vector2(3.0, 3.0)
	hp_bg.size = Vector2(UNIT_W - 6.0, 6.0)
	root.add_child(hp_bg)
	var hp := ColorRect.new()
	hp.color = Color(0.4, 0.9, 0.4) if u.team == BattleUnit.Team.PLAYER else Color(0.95, 0.6, 0.3)
	hp.position = Vector2(3.0, 3.0)
	hp.size = Vector2(UNIT_W - 6.0, 6.0)
	root.add_child(hp)
	var name_label := Label.new()
	name_label.text = u.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(0.0, 14.0)
	name_label.size = Vector2(UNIT_W, UNIT_H - 14.0)
	name_label.add_theme_font_size_override("font_size", 14)
	root.add_child(name_label)
	_units_layer.add_child(root)
	_vis[u] = { "root": root, "body": body, "base_color": body.color, "hp": hp }
	_position_visual(u)

func _sync_visuals() -> void:
	var active_units := _sim_units()
	var active := {}
	for u in active_units:
		if u == null or not u.is_alive():
			continue
		active[u] = true
		if not _vis.has(u):
			_spawn_visual(u)
	for u in _vis.keys():
		if not active.has(u) or not u.is_alive():
			_vis[u]["root"].queue_free()
			_vis.erase(u)
	for u in active_units:
		if _vis.has(u):
			_position_visual(u)
			_vis[u]["hp"].size.x = (UNIT_W - 6.0) * u.hp_ratio()
	_update_wave_label()

func _position_visual(u: BattleUnit) -> void:
	var offset := _unit_visual_offset(u)
	var sx := _map_px(u.px) - UNIT_W * 0.5 + offset.x
	var sy := _map_py(u.py) - UNIT_H * 0.5 + offset.y
	_vis[u]["root"].position = Vector2(sx, sy)

func _flash_skill_casts() -> void:
	for cast in _sim.last_skill_casts:
		var caster: BattleUnit = cast.get("caster", null)
		if caster == null or not _vis.has(caster):
			continue
		var body: ColorRect = _vis[caster].get("body", null)
		if body == null or not is_instance_valid(body):
			continue
		var base_color: Color = _vis[caster].get("base_color", body.color)
		body.color = Color(1.0, 1.0, 1.0)
		var tween := create_tween()
		tween.tween_property(body, "color", base_color, 0.15)

func _sim_units() -> Array[BattleUnit]:
	var units: Array[BattleUnit] = []
	units.append_array(_sim.player_units)
	units.append_array(_sim.enemy_units)
	return units

func _ensure_castle() -> void:
	var castle := _sim.add_castle()
	if not _vis.has(castle):
		_spawn_visual(castle)

func _map_px(px: float) -> float:
	var t := clampf(px / BattleSim.FIELD_W, 0.0, 1.0)
	return FIELD_LEFT + t * (FIELD_RIGHT - FIELD_LEFT)

func _map_py(py: float) -> float:
	var t := clampf(py / BattleSim.FIELD_H, 0.0, 1.0)
	return FIELD_TOP + t * (FIELD_BOTTOM - FIELD_TOP)

func _tile_position(col: int, row: int) -> Vector2:
	var p := BattleSim.position_for_tile(col, row)
	return Vector2(_map_px(p.x) - TILE_W * 0.5, _map_py(p.y) - TILE_H * 0.5)

func _tile_key(col: int, row: int) -> String:
	return "%d:%d" % [col, row]

func _update_tile_label(col: int, row: int, text: String) -> void:
	var tile: Button = _tile_buttons.get(_tile_key(col, row), null)
	if tile != null:
		tile.text = text
		tile.disabled = true

func _unit_visual_offset(u: BattleUnit) -> Vector2:
	var index := 0
	for other in _sim_units():
		if other == u:
			break
		if other.team == u.team and other.position().distance_to(u.position()) < 4.0:
			index += 1
	return Vector2(float((index % 3) - 1) * 18.0, float(index / 3) * 14.0)

func _update_wave_label() -> void:
	if _wave_label == null:
		return
	if _sim.wave_total <= 0:
		_wave_label.text = "파도 - / -"
		_wave_label.visible = false
		return
	_wave_label.text = "파도 %d / %d" % [_sim.wave_index, _sim.wave_total]
	_wave_label.visible = _phase != Phase.DEPLOY

# ── 종료 · 전리(보상) ───────────────────────────────────────
func _end_battle() -> void:
	_phase = Phase.DONE
	_result_label.visible = true
	var win := _sim.result == BattleSim.Result.PLAYER_WIN
	if win:
		_result_label.text = "승리!"
		_result_label.modulate = Color(0.5, 1.0, 0.5)
		_hint_label.text = "전리품을 고르세요."
		EventBus.battle_won.emit()
	else:
		_result_label.text = "런 실패"
		_result_label.modulate = Color(1.0, 0.5, 0.5)
		_hint_label.text = "전투 종료."
		EventBus.battle_lost.emit()
	_build_outcome_ui(win)

func _build_outcome_ui(win: bool) -> void:
	var box := _new_overlay_box()
	if not win:
		var fail := Label.new()
		fail.text = "런 실패"
		fail.add_theme_font_size_override("font_size", 24)
		box.add_child(fail)
		box.add_child(_make_button("새 런", _restart_run))
		return
	var candidates := RunManager.reward_candidates(3)
	if candidates.is_empty():
		var none := Label.new()
		none.text = "획득 가능한 보상이 없습니다."
		box.add_child(none)
		_complete_node_once()
		_add_map_or_conquest_button(box)
		return
	var head := Label.new()
	head.text = "전리품 — 한 장을 골라 덱에 넣으세요"
	head.add_theme_font_size_override("font_size", 24)
	box.add_child(head)
	for id in candidates:
		var card := CardLibrary.get_card(id)
		box.add_child(_make_button("%s (%d) — %s" % [card.display_name, card.cost, _card_brief(card)], _pick_reward.bind(id)))

func _pick_reward(id: StringName) -> void:
	RunManager.add_card(id)
	var card := CardLibrary.get_card(id)
	var got_name := card.display_name if card != null else String(id)
	EventBus.card_rewarded.emit(id)
	_hint_label.text = "획득 — %s! 덱에 편입되었습니다." % got_name
	_complete_node_once()
	var box := _new_overlay_box()
	var got := Label.new()
	got.text = "획득 — %s" % got_name
	got.add_theme_font_size_override("font_size", 24)
	box.add_child(got)
	_add_map_or_conquest_button(box)

func _add_map_or_conquest_button(box: VBoxContainer) -> void:
	if RunManager.map_finished():
		_result_label.text = "구주 정복!"
		var done := Label.new()
		done.text = "구주 정복!"
		done.add_theme_font_size_override("font_size", 30)
		box.add_child(done)
		box.add_child(_make_button("새 런", _restart_run))
	else:
		box.add_child(_make_button("지도로 (덱 %d장)" % RunManager.get_deck().size(), _go_to_run_map))

func _complete_node_once() -> void:
	if _node_completed:
		return
	RunManager.complete_node()
	_node_completed = true

func _go_to_run_map() -> void:
	GameManager.change_scene("res://scenes/screens/run_map.tscn")

func _restart_run() -> void:
	RunManager.reset_run()
	GameManager.change_scene("res://scenes/screens/run_map.tscn")

# ── 헬퍼 ────────────────────────────────────────────────────
func _new_overlay_box() -> VBoxContainer:
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.queue_free()
	var box := VBoxContainer.new()
	box.position = Vector2(FIELD_LEFT, 150.0)
	box.custom_minimum_size = Vector2(FIELD_RIGHT - FIELD_LEFT, 0.0)
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	_overlay = box
	return box

func _make_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0.0, 40.0)
	b.pressed.connect(cb)
	return b

func _card_brief(card: CardData) -> String:
	if card is UnitCardData:
		return "%s/%s" % [card.troop_type, card.attack_range]
	return card.card_type

func _update_points() -> void:
	_points_label.text = "지휘력 — %d / %d" % [_points, _max_points]
